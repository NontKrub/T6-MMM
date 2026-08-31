import { clothingAnalysisSchema } from "./openai.ts";

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
