import {
  buildValidOutfitCandidates,
  ClothingItemRow,
  OutfitCandidate,
  scoreOutfitCandidate,
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
};

Deno.serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    const { supabase, userId } = await requireUser(req);
    const body = await readJson<Body>(req);
    const style = body.style ?? "casual";

    const [{ data: profile }, { data: items }, { data: events }] = await Promise
      .all([
        supabase.from("profiles").select("*").eq("id", userId).single(),
        supabase.from("clothing_items")
          .select(
            "id,name,brand,category,tags,dominant_colors,primary_color,wear_count,last_worn",
          )
          .is("archived_at", null)
          .order("last_worn", { ascending: true, nullsFirst: true }),
        supabase.from("wear_events").select(
          "style,colors,worn_at,clothing_item_ids",
        ).order("worn_at", { ascending: false }).limit(20),
      ]);

    const wardrobe = (items ?? []) as ClothingItemRow[];
    const recentEvents = (events ?? []) as WearEventRow[];
    const scoreOptions = {
      style,
      usePersonalColor: body.use_personal_color ?? false,
      colorSeason: typeof profile?.color_season === "string"
        ? profile.color_season
        : null,
      luckyColors: body.use_lucky_color ? body.lucky_colors ?? [] : [],
      weather: body.match_weather ? body.weather ?? null : null,
      recentEvents,
    };
    const candidates = buildValidOutfitCandidates(wardrobe, scoreOptions);
    if (candidates.length === 0) {
      return jsonResponse({
        error: "Add at least one top, one bottom, and one pair of shoes first.",
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
              profile: {
                color_season: profile?.color_season ?? null,
                body_type: profile?.body_type ?? null,
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
      scoreOptions,
    );
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
        generation_context: body,
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
  generated: Array<
    {
      name: string;
      item_ids: string[];
      style: string;
      reason: string;
      score: number;
    }
  >,
  candidates: OutfitCandidate[],
  wardrobe: ClothingItemRow[],
  scoreOptions: Parameters<typeof scoreOutfitCandidate>[1],
) {
  const validIds = new Set(wardrobe.map((item) => item.id));
  const selected: OutfitCandidate[] = [];
  const seen = new Set<string>();

  for (const outfit of generated) {
    const itemIds = [
      ...new Set(outfit.item_ids.filter((id) => validIds.has(id))),
    ];
    const candidateItems = itemIds
      .map((id) => wardrobe.find((item) => item.id === id))
      .filter(Boolean) as ClothingItemRow[];
    const categories = new Set(candidateItems.map((item) => item.category));
    if (
      !categories.has("top") || !categories.has("pants") ||
      !categories.has("shoes")
    ) continue;

    const key = itemIds.slice().sort().join("|");
    if (seen.has(key)) continue;
    const exact = candidates.find((candidate) =>
      candidate.item_ids.slice().sort().join("|") === key
    );
    const scored = exact ?? scoreOutfitCandidate(candidateItems, scoreOptions);
    selected.push({
      ...scored,
      name: outfit.name || scored.name,
      style: outfit.style || scored.style,
      reason: outfit.reason || scored.reason,
      score: Math.round(
        Math.max(
          0,
          Math.min(100, (outfit.score + scored.score) / 2 || scored.score),
        ),
      ),
      item_ids: itemIds,
    });
    seen.add(key);
  }

  if (selected.length > 0) {
    return selected.sort((a, b) => b.score - a.score);
  }

  return candidates.slice(0, 5);
}
