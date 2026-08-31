import { handleOptions, jsonResponse, readJson } from "../_shared/http.ts";
import {
  type ClothingItemRow,
  normalizeMissingPieceItems,
} from "../_shared/domain.ts";
import { openAiJson, recommendationsSchema } from "../_shared/openai.ts";
import { requireUser } from "../_shared/supabase.ts";

type MissingPiecesBody = {
  action?: "generate" | "dismiss";
  id?: string;
  selected_item_ids?: string[];
};

Deno.serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    const { supabase, userId } = await requireUser(req);
    const body = await readJson<MissingPiecesBody>(req);

    if (
      body.selected_item_ids != null &&
      (!Array.isArray(body.selected_item_ids) ||
        body.selected_item_ids.some((id) => typeof id !== "string"))
    ) {
      return jsonResponse({ error: "selected_item_ids must be strings." }, 400);
    }

    if (body.action === "dismiss") {
      if (!body.id) {
        return jsonResponse({
          error: "id is required to dismiss a recommendation.",
        }, 400);
      }

      const { data, error } = await supabase.from(
        "missing_piece_recommendations",
      )
        .update({ dismissed_at: new Date().toISOString() })
        .eq("id", body.id)
        .eq("user_id", userId)
        .is("dismissed_at", null)
        .select()
        .maybeSingle();
      if (error) throw error;

      return jsonResponse({ recommendation: data });
    }

    const [{ data: profile }, { data: preferences }, { data: wardrobe }] =
      await Promise.all([
        supabase.from("profiles").select("*").eq("id", userId).single(),
        supabase.from("style_preferences").select("kind,value"),
        supabase.from("clothing_items")
          .select(
            "id,name,brand,category,tags,dominant_colors,primary_color,subtype,pattern,material,fit,silhouette,styles,formality,seasons,weather_suitability,warmth_level,analysis_confidence,analysis_status,user_corrected,detected_attributes,wear_count,last_worn",
          )
          .is("archived_at", null),
      ]);

    const wardrobeRows = (wardrobe ?? []) as ClothingItemRow[];
    const selectedIds = new Set(body.selected_item_ids ?? []);
    const selectedRows = wardrobeRows.filter((item) =>
      selectedIds.has(item.id)
    );
    if (selectedRows.length !== selectedIds.size) {
      return jsonResponse({
        error: "Selected items must belong to your wardrobe.",
      }, 400);
    }
    const wardrobeContext = normalizeMissingPieceItems(wardrobeRows);
    const selectedItems = normalizeMissingPieceItems(selectedRows);
    let result;
    try {
      result = await openAiJson<{
        recommendations: Array<{
          category: "hat" | "top" | "pants" | "shoes" | "accessory";
          title: string;
          reason: string;
          suggestion: string;
          priority: string;
        }>;
      }>({
        instructions:
          "Recommend missing wardrobe pieces. When selected_items is non-empty, complete those garments first using category, color, pattern, silhouette, and style tags. Do not recommend an owned item unless explaining how to use it.",
        input: [{
          role: "user",
          content: [{
            type: "input_text",
            text: JSON.stringify({
              profile,
              preferences,
              wardrobe: wardrobeContext,
              selected_items: selectedItems,
            }),
          }],
        }],
        responseFormat: {
          type: "json_schema",
          name: "missing_piece_recommendations",
          schema: recommendationsSchema,
          strict: true,
        },
      });
    } catch (error) {
      console.error(
        error instanceof Error
          ? error.message
          : "AI missing-piece recommendations failed.",
      );
      result = fallbackRecommendations(wardrobe ?? []);
    }

    const { error: clearError } = await supabase.from(
      "missing_piece_recommendations",
    )
      .update({ dismissed_at: new Date().toISOString() })
      .eq("user_id", userId)
      .is("dismissed_at", null);
    if (clearError) throw clearError;

    if (result.recommendations.length === 0) {
      result = fallbackRecommendations(wardrobe ?? []);
    }

    const rows = result.recommendations.map((rec) => ({
      user_id: userId,
      category: rec.category,
      title: rec.title,
      reason: rec.reason,
      suggestion: rec.suggestion,
      priority: rec.priority,
      metadata: { source: "edge_function" },
    }));
    const { data: inserted, error } = await supabase.from(
      "missing_piece_recommendations",
    )
      .insert(rows)
      .select();
    if (error) throw error;

    return jsonResponse({ recommendations: inserted ?? [] });
  } catch (error) {
    return jsonResponse({
      error: error instanceof Error ? error.message : "Unknown error",
    }, 500);
  }
});

function fallbackRecommendations(
  wardrobe: Array<{ category: unknown }>,
) {
  const categories = new Set(
    wardrobe
      .map((item) => item.category)
      .filter((category): category is string => typeof category === "string"),
  );
  return {
    recommendations: [
      !categories.has("shoes")
        ? {
          category: "shoes" as const,
          title: "Everyday neutral shoes",
          reason: "A reliable shoe category unlocks more complete outfits.",
          suggestion: "Try white sneakers or simple loafers.",
          priority: "essential",
        }
        : {
          category: "top" as const,
          title: "Versatile layering top",
          reason: "A clean neutral top pairs across your existing wardrobe.",
          suggestion: "Try a white shirt, ribbed tee, or lightweight knit.",
          priority: "high_impact",
        },
    ],
  };
}
