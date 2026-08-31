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
  category: ClothingCategory;
  suggested_name: string;
  dominant_colors: string[];
  primary_color: string;
  subtype: string | null;
  pattern: string;
  material: string;
  fit: string;
  silhouette: string;
  styles: string[];
  formality: string;
  seasons: string[];
  weather_suitability: string[];
  warmth_level: number | null;
  tags: string[];
  confidence: number;
};

type ClothingCategory =
  | "hat"
  | "top"
  | "pants"
  | "shoes"
  | "outerwear"
  | "dress"
  | "bag"
  | "accessory"
  | "unknown";

Deno.serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    const { userId } = await requireUser(req);
    const body = await readJson<Body>(req);
    if (typeof body.image_path !== "string" || !body.image_path.trim()) {
      return jsonResponse({ error: "image_path is required." }, 400);
    }
    if (body.image_path.split("/")[0] !== userId) {
      return jsonResponse(
        { error: "Image path is outside the user scope." },
        403,
      );
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
          "Analyze this single clothing item for outfit generation. Return practical metadata only: category, primary and dominant colors, concise lowercase tags, confidence 0..1, and the explicit structured fields for subtype, pattern, material, fit, silhouette, styles, formality, seasons, weather suitability, and warmth.",
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
      suggested_name: normalizeWord(body.name) || analysis.suggested_name,
      tags: [
        ...new Set(
          [...normalizeStringArray(body.tags), ...analysis.tags]
            .map((tag) => normalizeWord(tag))
            .filter(Boolean),
        ),
      ].slice(0, 8),
      brand: typeof body.brand === "string" ? body.brand.trim() || null : null,
      analysis_source: "serverAI",
      analysis_status: "complete",
      analysis_version: "visual-v3",
    });
  } catch (error) {
    return jsonResponse({
      error: error instanceof Error ? error.message : "Unknown error",
    }, 500);
  }
});

function normalizeAnalysis(analysis: ClothingAnalysis): ClothingAnalysis {
  const normalizedPrimary = normalizeColor(analysis.primary_color);
  const normalizedDominant = [
    ...new Set(
      normalizeStringArray(analysis.dominant_colors)
        .map(normalizeColor)
        .filter((value) => value !== "unknown"),
    ),
  ].slice(0, 5);
  const tags = [
    ...new Set(
      normalizeStringArray(analysis.tags).map(normalizeWord).filter(Boolean),
    ),
  ].slice(0, 8);
  return {
    ...analysis,
    category: oneOf(analysis.category, clothingCategories),
    suggested_name: normalizeWord(analysis.suggested_name) || "Wardrobe item",
    primary_color: normalizedPrimary,
    dominant_colors: normalizedDominant.length > 0
      ? normalizedDominant
      : normalizedPrimary === "unknown"
      ? []
      : [normalizedPrimary],
    subtype: normalizeWord(analysis.subtype) || null,
    pattern: oneOf(analysis.pattern, patterns),
    material: oneOf(analysis.material, materials),
    fit: oneOf(analysis.fit, fits),
    silhouette: oneOf(analysis.silhouette, silhouettes),
    styles: normalizeEnumArray(analysis.styles, styles, 5),
    formality: oneOf(analysis.formality, formalities),
    seasons: normalizeEnumArray(analysis.seasons, seasons, 4),
    weather_suitability: normalizeEnumArray(
      analysis.weather_suitability,
      weatherSuitability,
      6,
    ),
    warmth_level: boundedNumber(analysis.warmth_level),
    tags,
    confidence: boundedNumber(analysis.confidence) ?? 0,
  };
}

const clothingCategories = [
  "hat",
  "top",
  "pants",
  "shoes",
  "outerwear",
  "dress",
  "bag",
  "accessory",
  "unknown",
] as const;
const patterns = [
  "solid",
  "striped",
  "checked",
  "floral",
  "graphic",
  "textured",
  "other",
  "unknown",
] as const;
const materials = [
  "cotton",
  "linen",
  "denim",
  "wool",
  "leather",
  "synthetic",
  "knit",
  "silk",
  "other",
  "unknown",
] as const;
const fits = [
  "slim",
  "regular",
  "relaxed",
  "oversized",
  "cropped",
  "wide",
  "unknown",
] as const;
const silhouettes = [
  "fitted",
  "regular",
  "relaxed",
  "oversized",
  "cropped",
  "wide-leg",
  "slim",
  "a-line",
  "straight",
  "unknown",
] as const;
const styles = [
  "casual",
  "streetwear",
  "formal",
  "business",
  "sport",
  "minimal",
  "vintage",
  "preppy",
  "smartCasual",
  "unknown",
] as const;
const formalities = [
  "veryCasual",
  "casual",
  "smartCasual",
  "business",
  "formal",
  "unknown",
] as const;
const seasons = ["spring", "summer", "autumn", "winter", "unknown"] as const;
const weatherSuitability = [
  "veryHot",
  "hot",
  "warm",
  "mild",
  "cool",
  "cold",
  "dry",
  "rainy",
  "unknown",
] as const;

function normalizeWord(value: unknown) {
  return typeof value === "string" ? value.trim().toLowerCase() : "";
}

function normalizeColor(value: unknown) {
  if (typeof value !== "string") return "unknown";
  const normalized = value.trim();
  if (/^#[0-9a-f]{6}$/i.test(normalized)) return normalized.toUpperCase();
  return /^[a-z][a-z -]{0,31}$/i.test(normalized)
    ? normalized.toLowerCase()
    : "unknown";
}

function normalizeStringArray(value: unknown): string[] {
  return Array.isArray(value)
    ? value.filter((entry): entry is string => typeof entry === "string")
    : [];
}

function normalizeEnumArray<T extends string>(
  value: unknown,
  allowed: readonly T[],
  max: number,
) {
  return [
    ...new Set(
      normalizeStringArray(value).map((entry) => oneOf(entry, allowed)),
    ),
  ].slice(0, max);
}

function oneOf<T extends string>(value: unknown, allowed: readonly T[]): T {
  return typeof value === "string" &&
      (allowed as readonly string[]).includes(value)
    ? value as T
    : "unknown" as T;
}

function boundedNumber(value: unknown) {
  if (typeof value !== "number" || !Number.isFinite(value)) return null;
  return Math.max(0, Math.min(1, value));
}
