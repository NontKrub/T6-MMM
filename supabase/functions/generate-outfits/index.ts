import {
  buildValidOutfitCandidates,
  ClothingItemRow,
  GeneratedOutfitDraft,
  OutfitCandidate,
  PreferenceEventRow,
  selectUsableOutfitsFromGenerated,
  WearEventRow,
} from "../_shared/domain.ts";
import { handleOptions, jsonResponse, readJson } from "../_shared/http.ts";
import { openAiJson, outfitSchema } from "../_shared/openai.ts";
import { requireUser } from "../_shared/supabase.ts";

type Body = {
  style?: string;
  use_personal_color?: boolean;
  use_lucky_color?: boolean;
  match_weather?: boolean;
  weather?: Record<string, unknown>;
  lucky_colors?: string[];
  learn_preferences?: boolean;
  target_hex?: string;
};

Deno.serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    const { supabase, userId } = await requireUser(req);
    const body = await readJson<Body>(req);
    const style = body.style ?? "casual";

    const learnPreferences = body.learn_preferences ?? true;

    const [{ data: profile }, { data: stylePreferencesRows }, { data: items }, {
      data: events,
    }, { data: preferenceEvents }] = await Promise
      .all([
        supabase.from("profiles").select("*").eq("id", userId).single(),
        supabase.from("style_preferences").select("kind,value"),
        supabase.from("clothing_items")
          .select(
            "id,name,brand,category,tags,dominant_colors,primary_color,subtype,pattern,material,fit,silhouette,styles,formality,seasons,weather_suitability,warmth_level,analysis_confidence,analysis_status,user_corrected,detected_attributes,ai_confidence,wear_count,last_worn",
          )
          .is("archived_at", null)
          .order("last_worn", { ascending: true, nullsFirst: true }),
        supabase.from("wear_events").select(
          "style,colors,worn_at,clothing_item_ids",
        ).order("worn_at", { ascending: false }).limit(20),
        supabase.from("outfit_preference_events").select(
          "style,tags,colors,selection_factors,score,created_at",
        ).order("created_at", { ascending: false }).limit(40),
      ]);

    const wardrobe = (items ?? []) as ClothingItemRow[];
    const recentEvents = (events ?? []) as WearEventRow[];
    const learnedEvents = (preferenceEvents ?? []) as PreferenceEventRow[];
    const stylePreferences = (stylePreferencesRows ?? [])
      .filter((row) =>
        (!row.kind || row.kind === "style") && typeof row.value === "string"
      )
      .map((row) => String(row.value).trim().toLowerCase())
      .filter(Boolean);
    const scoreOptions = {
      style,
      stylePreferences,
      usePersonalColor: body.use_personal_color ?? false,
      colorSeason: typeof profile?.color_season === "string"
        ? profile.color_season
        : null,
      luckyColors: body.use_lucky_color ? body.lucky_colors ?? [] : [],
      weather: body.match_weather ? body.weather ?? null : null,
      recentEvents,
      preferenceEvents: learnPreferences ? learnedEvents : [],
      learnPreferences,
      targetHex: body.target_hex ?? null,
    };
    const candidates = buildValidOutfitCandidates(wardrobe, scoreOptions);
    if (candidates.length === 0) {
      return jsonResponse({
        error: "Add compatible clothing and at least one pair of shoes first.",
      }, 422);
    }

    let generated: {
      outfits: Array<
        {
          name: string;
          item_ids: string[];
          style: string;
          reason: string;
          score: number;
        }
      >;
    } | null = null;
    try {
      generated = await openAiJson<
        {
          outfits: Array<
            {
              name: string;
              item_ids: string[];
              style: string;
              reason: string;
              score: number;
            }
          >;
        }
      >({
        instructions:
          "You are a fashion outfit planner. Choose only from the provided scored candidates. Return complete outfits with top, pants, and shoes. Preserve practical weather, lucky color, personal color, and low-repetition reasoning.",
        input: [{
          role: "user",
          content: [{
            type: "input_text",
            text: JSON.stringify({
              requested_style: style,
              use_personal_color: body.use_personal_color ?? false,
              use_lucky_color: body.use_lucky_color ?? false,
              match_weather: body.match_weather ?? false,
              weather: body.weather ?? null,
              lucky_colors: body.lucky_colors ?? [],
              target_hex: body.target_hex ?? null,
              profile: {
                color_season: profile?.color_season ?? null,
                body_type: profile?.body_type ?? null,
                style_preferences: stylePreferences,
              },
              candidates: candidates.slice(0, 16).map((candidate) => ({
                name: candidate.name,
                item_ids: candidate.item_ids,
                style: candidate.style,
                reason: candidate.reason,
                score: candidate.score,
                selection_factors: candidate.selection_factors,
                items: candidate.item_ids.map((id) => {
                  const item = wardrobe.find((wardrobeItem) =>
                    wardrobeItem.id === id
                  );
                  return item
                    ? {
                      id: item.id,
                      name: item.name,
                      category: item.category,
                      color: item.primary_color,
                      tags: item.tags,
                      detected_attributes: item.detected_attributes ?? {},
                      ai_confidence: item.ai_confidence ?? null,
                    }
                    : null;
                }).filter(Boolean),
              })),
            }),
          }],
        }],
        responseFormat: {
          type: "json_schema",
          name: "outfit_generation",
          schema: outfitSchema,
          strict: true,
        },
      });
    } catch (error) {
      console.error(
        error instanceof Error ? error.message : "AI outfit generation failed.",
      );
    }

    const validIds = new Set(wardrobe.map((item) => item.id));
    const selected = selectUsableOutfits(
      generated?.outfits ?? [],
      candidates,
      wardrobe,
    );
    const generationContext = {
      requested_style: style,
      style_preferences: stylePreferences,
      use_personal_color: body.use_personal_color ?? false,
      use_lucky_color: body.use_lucky_color ?? false,
      match_weather: body.match_weather ?? false,
      weather: scoreOptions.weather,
      lucky_colors: scoreOptions.luckyColors,
      color_season: scoreOptions.colorSeason,
      learn_preferences: learnPreferences,
      target_hex: body.target_hex ?? null,
    };

    const saved = [];
    for (const outfit of selected.slice(0, 5)) {
      const itemIds = outfit.item_ids.filter((id) => validIds.has(id));

      const { data: inserted, error } = await supabase.from("outfits").insert({
        user_id: userId,
        name: outfit.name,
        style: outfit.style,
        reason: outfit.reason,
        score: outfit.score,
        selection_factors: outfit.selection_factors,
        generation_context: generationContext,
      }).select().single();
      if (error || !inserted) continue;

      const rows = itemIds.map((id, index) => {
        const item = wardrobe.find((candidate) => candidate.id === id);
        return {
          outfit_id: inserted.id,
          clothing_item_id: id,
          slot: item?.category ?? "accessory",
          position: index,
        };
      });
      await supabase.from("outfit_items").insert(rows);
      saved.push({ ...inserted, item_ids: itemIds });
    }

    if (saved.length === 0) {
      return jsonResponse({
        error: "No usable outfits could be saved from your wardrobe.",
      }, 502);
    }

    return jsonResponse({ outfits: saved });
  } catch (error) {
    return jsonResponse({
      error: error instanceof Error ? error.message : "Unknown error",
    }, 500);
  }
});

function selectUsableOutfits(
  generated: GeneratedOutfitDraft[],
  candidates: OutfitCandidate[],
  wardrobe: ClothingItemRow[],
) {
  return selectUsableOutfitsFromGenerated(generated, candidates, wardrobe);
}
