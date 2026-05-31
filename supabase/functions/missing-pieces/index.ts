import { handleOptions, jsonResponse } from "../_shared/http.ts";
import { recommendationsSchema, openAiJson } from "../_shared/openai.ts";
import { requireUser } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    const { supabase, userId } = await requireUser(req);
    const [{ data: profile }, { data: preferences }, { data: wardrobe }] = await Promise.all([
      supabase.from("profiles").select("*").eq("id", userId).single(),
      supabase.from("style_preferences").select("kind,value"),
      supabase.from("clothing_items")
        .select("id,name,brand,category,tags,dominant_colors,primary_color,wear_count,last_worn")
        .is("archived_at", null),
    ]);

    let result;
    try {
      result = await openAiJson<{ recommendations: Array<{
        category: "hat" | "top" | "pants" | "shoes" | "accessory";
        title: string;
        reason: string;
        suggestion: string;
        priority: string;
      }> }>({
        instructions:
          "Recommend missing wardrobe pieces. Be concrete, useful, and avoid recommending items the user already owns.",
        input: [{
          role: "user",
          content: [{
            type: "input_text",
            text: JSON.stringify({ profile, preferences, wardrobe }),
          }],
        }],
        responseFormat: {
          type: "json_schema",
          name: "missing_piece_recommendations",
          schema: recommendationsSchema,
          strict: true,
        },
      });
    } catch {
      const categories = new Set((wardrobe ?? []).map((item) => item.category));
      result = {
        recommendations: [
          !categories.has("shoes")
            ? {
              category: "shoes",
              title: "Everyday neutral shoes",
              reason: "A reliable shoe category unlocks more complete outfits.",
              suggestion: "Try white sneakers or simple loafers.",
              priority: "essential",
            }
            : {
              category: "top",
              title: "Versatile layering top",
              reason: "A clean neutral top pairs across your existing wardrobe.",
              suggestion: "Try a white shirt, ribbed tee, or lightweight knit.",
              priority: "high_impact",
            },
        ],
      };
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
    const { data: inserted, error } = await supabase.from("missing_piece_recommendations")
      .insert(rows)
      .select();
    if (error) throw error;

    return jsonResponse({ recommendations: inserted ?? [] });
  } catch (error) {
    return jsonResponse({ error: error instanceof Error ? error.message : "Unknown error" }, 500);
  }
});
