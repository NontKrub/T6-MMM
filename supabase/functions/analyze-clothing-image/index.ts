import { handleOptions, jsonResponse, readJson } from "../_shared/http.ts";
import { requireUser, serviceClient } from "../_shared/supabase.ts";
import { clothingAnalysisSchema, openAiJson } from "../_shared/openai.ts";

type Body = {
  image_path: string;
  name?: string;
  brand?: string;
  tags?: string[];
};

Deno.serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    const { userId } = await requireUser(req);
    const body = await readJson<Body>(req);
    if (!body.image_path) {
      return jsonResponse({ error: "image_path is required." }, 400);
    }

    const admin = serviceClient();
    const { data, error } = await admin.storage
      .from("wardrobe-images")
      .createSignedUrl(body.image_path, 60);
    if (error || !data?.signedUrl) {
      return jsonResponse({ error: error?.message ?? "Unable to read uploaded image." }, 400);
    }

    const analysis = await openAiJson<{
      category: "hat" | "top" | "pants" | "shoes" | "accessory";
      suggested_name: string;
      dominant_colors: string[];
      primary_color: string;
      tags: string[];
      attributes: Record<string, unknown>;
      confidence: number;
    }>({
      instructions:
        "Analyze the clothing item photo for a wardrobe app. Return only practical metadata. Use short lowercase tags and simple color names.",
      input: [{
        role: "user",
        content: [
          { type: "input_text", text: "Categorize this clothing item for Mix Match Mood." },
          { type: "input_image", image_url: data.signedUrl },
        ],
      }],
      responseFormat: {
        type: "json_schema",
        name: "clothing_analysis",
        schema: clothingAnalysisSchema,
        strict: true,
      },
    });

    return jsonResponse({
      user_id: userId,
      ...analysis,
      suggested_name: body.name?.trim() || analysis.suggested_name,
      tags: [...new Set([...(body.tags ?? []), ...analysis.tags])],
      brand: body.brand ?? null,
    });
  } catch (error) {
    return jsonResponse({ error: error instanceof Error ? error.message : "Unknown error" }, 500);
  }
});
