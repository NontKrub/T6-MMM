import { handleOptions, jsonResponse, readJson } from "../_shared/http.ts";
import { requireUser, serviceClient } from "../_shared/supabase.ts";
import { clothingAnalysisSchema, openAiJson } from "../_shared/openai.ts";

type Body = {
  image_path: string;
  name?: string;
  brand?: string;
  tags?: string[];
};

type ClothingAnalysis = {
  category: "hat" | "top" | "pants" | "shoes" | "accessory";
  suggested_name: string;
  dominant_colors: string[];
  primary_color: string;
  tags: string[];
  attributes: Record<string, unknown>;
  confidence: number;
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
      return jsonResponse({
        error: error?.message ?? "Unable to read uploaded image.",
      }, 400);
    }

    let analysis: ClothingAnalysis;
    try {
      analysis = await openAiJson<ClothingAnalysis>({
        instructions:
          "Analyze this single clothing item for outfit generation. Return practical metadata only: category, primary and dominant colors, concise lowercase tags, confidence 0..1, and detected attributes helpful for style/weather matching (material, fit, formality, seasonality, weather suitability, details).",
        input: [{
          role: "user",
          content: [
            {
              type: "input_text",
              text: "Categorize this clothing item for Mix Match Mood.",
            },
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
    } catch (error) {
      console.error(
        error instanceof Error ? error.message : "AI clothing analysis failed.",
      );
      return jsonResponse({
        error:
          "Clothing analysis is unavailable. Keep the image and tag it manually.",
      }, 502);
    }
    analysis = normalizeAnalysis(analysis);

    return jsonResponse({
      user_id: userId,
      ...analysis,
      suggested_name: body.name?.trim() || analysis.suggested_name,
      tags: [
        ...new Set(
          [...(body.tags ?? []), ...analysis.tags]
            .map((tag) => normalizeWord(tag))
            .filter(Boolean),
        ),
      ].slice(0, 8),
      brand: body.brand ?? null,
    });
  } catch (error) {
    return jsonResponse({
      error: error instanceof Error ? error.message : "Unknown error",
    }, 500);
  }
});

function normalizeAnalysis(analysis: ClothingAnalysis): ClothingAnalysis {
  const normalizedPrimary = normalizeWord(analysis.primary_color) || "unknown";
  const normalizedDominant = [
    ...new Set(
      analysis.dominant_colors
        .map(normalizeWord)
        .filter(Boolean),
    ),
  ].slice(0, 5);
  const tags = [
    ...new Set(analysis.tags.map(normalizeWord).filter(Boolean)),
  ].slice(0, 8);
  const attributes = analysis.attributes &&
      typeof analysis.attributes === "object" &&
      !Array.isArray(analysis.attributes)
    ? analysis.attributes
    : {};
  const confidence = Math.max(
    0,
    Math.min(1, Number.isFinite(analysis.confidence) ? analysis.confidence : 0),
  );

  return {
    ...analysis,
    category: analysis.category,
    suggested_name: analysis.suggested_name.trim() || "Wardrobe item",
    primary_color: normalizedPrimary,
    dominant_colors: normalizedDominant.length > 0
      ? normalizedDominant
      : normalizedPrimary === "unknown"
      ? []
      : [normalizedPrimary],
    tags,
    attributes,
    confidence,
  };
}

function normalizeWord(value: string) {
  return value.trim().toLowerCase();
}
