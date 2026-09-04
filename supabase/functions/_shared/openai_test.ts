import { clothingAnalysisSchema, recommendationsSchema } from "./openai.ts";

Deno.test("clothing analysis schema has no arbitrary attributes object", () => {
  const required = clothingAnalysisSchema.required as string[];
  const properties = clothingAnalysisSchema.properties as Record<
    string,
    unknown
  >;

  if (required.includes("attributes")) {
    throw new Error("attributes must not be required");
  }
  if ("attributes" in properties) {
    throw new Error("attributes must not be present in schema properties");
  }
});

Deno.test("missing-piece schema uses V3 recommendation categories", () => {
  const recommendations = recommendationsSchema.properties
    ?.recommendations as Record<string, unknown>;
  const items = recommendations.items as Record<string, unknown>;
  const properties = items.properties as Record<string, unknown>;
  const category = properties.category as Record<string, unknown>;
  const expected = [
    "hat",
    "top",
    "pants",
    "shoes",
    "outerwear",
    "dress",
    "bag",
    "accessory",
  ];

  if (JSON.stringify(category.enum) !== JSON.stringify(expected)) {
    throw new Error(`Unexpected recommendation categories: ${category.enum}`);
  }
});
