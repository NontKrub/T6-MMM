import { ClothingItemRow, fallbackOutfits } from "../_shared/domain.ts";
import { handleOptions, jsonResponse, readJson } from "../_shared/http.ts";
import { requireUser } from "../_shared/supabase.ts";

type Body = { style?: string };

Deno.serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    const { supabase, userId } = await requireUser(req);
    const body = await readJson<Body>(req);
    const style = body.style ?? "rush";

    const { data: items, error } = await supabase.from("clothing_items")
      .select("id,name,brand,category,tags,dominant_colors,primary_color,wear_count,last_worn")
      .is("archived_at", null)
      .order("last_worn", { ascending: true, nullsFirst: true });
    if (error) throw error;

    const wardrobe = (items ?? []) as ClothingItemRow[];
    const [outfit] = fallbackOutfits(wardrobe, style, 1);
    if (!outfit) {
      return jsonResponse({ error: "Add at least one top, one bottom, and one pair of shoes first." }, 422);
    }

    const { data: inserted, error: outfitError } = await supabase.from("outfits").insert({
      user_id: userId,
      name: "Rush Outfit",
      style,
      reason: "Fast practical pick using least-recently-worn complete outfit categories.",
      score: 80,
      generation_context: { mode: "rush" },
    }).select().single();
    if (outfitError || !inserted) throw outfitError;

    await supabase.from("outfit_items").insert(outfit.item_ids.map((id, index) => {
      const item = wardrobe.find((candidate) => candidate.id === id);
      return {
        outfit_id: inserted.id,
        clothing_item_id: id,
        slot: item?.category ?? "accessory",
        position: index,
      };
    }));

    return jsonResponse({ outfit: { ...inserted, item_ids: outfit.item_ids } });
  } catch (error) {
    return jsonResponse({ error: error instanceof Error ? error.message : "Unknown error" }, 500);
  }
});
