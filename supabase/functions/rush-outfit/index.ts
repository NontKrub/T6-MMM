import {
  buildValidOutfitCandidates,
  ClothingItemRow,
  WearEventRow,
} from "../_shared/domain.ts";
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

    const [{ data: items, error }, { data: events }] = await Promise.all([
      supabase.from("clothing_items")
        .select(
          "id,name,brand,category,tags,dominant_colors,primary_color,subtype,pattern,material,fit,silhouette,styles,formality,seasons,weather_suitability,warmth_level,analysis_confidence,analysis_status,user_corrected,wear_count,last_worn",
        )
        .is("archived_at", null)
        .order("last_worn", { ascending: true, nullsFirst: true }),
      supabase.from("wear_events")
        .select("style,colors,worn_at,clothing_item_ids")
        .order("worn_at", { ascending: false })
        .limit(10),
    ]);
    if (error) throw error;

    const wardrobe = (items ?? []) as ClothingItemRow[];
    const outfit = buildValidOutfitCandidates(wardrobe, {
      style,
      recentEvents: (events ?? []) as WearEventRow[],
      rush: true,
    })[0] ?? null;
    if (!outfit) {
      return jsonResponse({
        error: "Add compatible clothing and at least one pair of shoes first.",
      }, 422);
    }

    const { data: inserted, error: outfitError } = await supabase.rpc(
      "create_outfit_with_items",
      {
        p_name: outfit.name,
        p_style: style,
        p_reason: outfit.reason,
        p_score: outfit.score,
        p_selection_factors: outfit.selection_factors,
        p_generation_context: { mode: "rush" },
        p_item_ids: outfit.item_ids,
      },
    );
    if (outfitError || !inserted) {
      throw outfitError ?? new Error("Outfit persistence returned no data.");
    }

    return jsonResponse({ outfit: inserted });
  } catch (error) {
    return jsonResponse({
      error: error instanceof Error ? error.message : "Unknown error",
    }, 500);
  }
});
