import { ClothingItemRow } from "../_shared/domain.ts";
import { handleOptions, jsonResponse, readJson } from "../_shared/http.ts";
import { outfitSchema, openAiJson } from "../_shared/openai.ts";
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

    const [{ data: profile }, { data: items }, { data: events }] = await Promise.all([
      supabase.from("profiles").select("*").eq("id", userId).single(),
      supabase.from("clothing_items")
        .select("id,name,brand,category,tags,dominant_colors,primary_color,wear_count,last_worn")
        .is("archived_at", null)
        .order("last_worn", { ascending: true, nullsFirst: true }),
      supabase.from("wear_events").select("style,colors,worn_at").order("worn_at", { ascending: false }).limit(20),
    ]);

    const wardrobe = (items ?? []) as ClothingItemRow[];
    const categories = new Set(wardrobe.map((item) => item.category));
    if (!categories.has("top") || !categories.has("pants") || !categories.has("shoes")) {
      return jsonResponse({ error: "Add at least one top, one bottom, and one pair of shoes first." }, 422);
    }

    let generated;
    try {
      generated = await openAiJson<{ outfits: Array<{ name: string; item_ids: string[]; style: string; reason: string; score: number }> }>({
        instructions:
          "You are a fashion outfit planner. Choose item_ids only from the provided wardrobe. Prefer complete outfits with top, pants, and shoes. Respect weather, lucky colors, personal color season, and avoid recent repetition when possible.",
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
              profile,
              wardrobe,
              recent_wear_events: events ?? [],
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
      return jsonResponse({
        error: error instanceof Error ? error.message : "AI outfit generation failed.",
      }, 502);
    }

    const validIds = new Set(wardrobe.map((item) => item.id));
    const saved = [];
    for (const outfit of generated.outfits) {
      const itemIds = outfit.item_ids.filter((id) => validIds.has(id));
      if (itemIds.length === 0) continue;

      const { data: inserted, error } = await supabase.from("outfits").insert({
        user_id: userId,
        name: outfit.name,
        style: outfit.style,
        reason: outfit.reason,
        score: outfit.score,
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
      return jsonResponse({ error: "AI did not return usable outfits from your wardrobe." }, 502);
    }

    return jsonResponse({ outfits: saved });
  } catch (error) {
    return jsonResponse({ error: error instanceof Error ? error.message : "Unknown error" }, 500);
  }
});
