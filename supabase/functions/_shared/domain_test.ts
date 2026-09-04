import {
  buildValidOutfitCandidates,
  normalizeMissingPieceItems,
  repetitionInsights,
  scoreOutfitCandidate,
  selectUsableOutfitsFromGenerated,
} from "./domain.ts";
import type { ClothingItemRow } from "./domain.ts";

const baseItem = (overrides: Partial<ClothingItemRow>): ClothingItemRow => ({
  id: overrides.id ?? crypto.randomUUID(),
  name: overrides.name ?? "Item",
  brand: null,
  category: overrides.category ?? "top",
  tags: overrides.tags ?? [],
  dominant_colors: overrides.dominant_colors ?? [],
  primary_color: overrides.primary_color ?? null,
  detected_attributes: overrides.detected_attributes ?? {},
  ai_confidence: overrides.ai_confidence ?? 0.9,
  wear_count: overrides.wear_count ?? 0,
  last_worn: overrides.last_worn ?? null,
});

Deno.test("buildValidOutfitCandidates requires top pants and shoes", () => {
  const candidates = buildValidOutfitCandidates([
    baseItem({ id: "top", category: "top" }),
    baseItem({ id: "pants", category: "pants" }),
  ]);

  assertEquals(candidates.length, 0);
});

Deno.test("signed-in outfit contract keeps dress and ranking directions", () => {
  const casual = [
    baseItem({
      id: "black-tee",
      category: "top",
      name: "Black cotton tee",
      primary_color: "#111111",
      tags: ["casual", "streetwear"],
    }),
    baseItem({
      id: "blue-jeans",
      category: "pants",
      name: "Blue jeans",
      primary_color: "#3366FF",
      tags: ["casual", "streetwear"],
    }),
    baseItem({
      id: "white-sneakers",
      category: "shoes",
      name: "White sneakers",
      primary_color: "#FFFFFF",
      tags: ["casual", "streetwear"],
    }),
  ];
  const formal = [
    baseItem({ id: "formal-shirt", category: "top", tags: ["formal"] }),
    baseItem({ id: "formal-trousers", category: "pants", tags: ["formal"] }),
    baseItem({ id: "formal-shoes", category: "shoes", tags: ["formal"] }),
  ];

  const casualScore = scoreOutfitCandidate(casual, {
    style: "streetwear",
    weather: { temperature_band: "hot" },
  });
  const formalScore = scoreOutfitCandidate(formal, {
    style: "streetwear",
    weather: { temperature_band: "hot" },
  });
  assert(casualScore.score > formalScore.score);

  const candidates = buildValidOutfitCandidates([
    ...casual,
    baseItem({ id: "dress", category: "dress", tags: ["casual"] }),
  ]);
  assert(
    candidates.some((candidate) =>
      candidate.item_ids.includes("dress") &&
      !candidate.item_ids.includes("black-tee") &&
      !candidate.item_ids.includes("blue-jeans")
    ),
  );

  const repeated = scoreOutfitCandidate(casual, {
    recentEvents: [{
      style: "streetwear",
      colors: [],
      worn_at: new Date().toISOString(),
      clothing_item_ids: casual.map((item) => item.id),
    }],
  });
  assert(casualScore.score > repeated.score);

  const rainFriendly = scoreOutfitCandidate([
    ...casual.slice(0, 2),
    baseItem({ id: "boots", category: "shoes", name: "Rain boots" }),
  ], { weather: { rain: true } });
  const sandals = scoreOutfitCandidate([
    ...casual.slice(0, 2),
    baseItem({ id: "sandals", category: "shoes", name: "Open sandals" }),
  ], { weather: { rain: true } });
  assert(rainFriendly.score > sandals.score);

  const target = scoreOutfitCandidate(casual, { targetHex: "#111111" });
  const noTarget = scoreOutfitCandidate(formal, { targetHex: "#FF00FF" });
  assert(target.score > noTarget.score);
});

Deno.test("generated outfit selection accepts dress and shoes", () => {
  const wardrobe = [
    baseItem({ id: "dress", category: "dress" }),
    baseItem({ id: "shoes", category: "shoes" }),
  ];
  const candidates = buildValidOutfitCandidates(wardrobe);
  const selected = selectUsableOutfitsFromGenerated(
    [{
      name: "Dress outfit",
      item_ids: ["dress", "shoes"],
      style: "casual",
      reason: "A complete one-piece outfit.",
      score: 80,
    }],
    candidates,
    wardrobe,
  );

  assertEquals(selected.length, 1);
  assertEquals(selected[0].item_ids.slice().sort(), ["dress", "shoes"]);
});

Deno.test("basic outfits can include bags", () => {
  const candidates = buildValidOutfitCandidates([
    baseItem({ id: "top", category: "top" }),
    baseItem({ id: "pants", category: "pants" }),
    baseItem({ id: "shoes", category: "shoes" }),
    baseItem({ id: "bag", category: "bag" }),
  ]);

  assert(
    candidates.some((candidate) => candidate.item_ids.includes("bag")),
  );
});

Deno.test("signed-in extras do not starve bags", () => {
  const wardrobe = [
    baseItem({ id: "top", category: "top" }),
    baseItem({ id: "pants", category: "pants" }),
    baseItem({ id: "shoes", category: "shoes" }),
    baseItem({ id: "bag", category: "bag", wear_count: 5 }),
    baseItem({ id: "accessory-a", category: "accessory", wear_count: 0 }),
    baseItem({ id: "accessory-b", category: "accessory", wear_count: 1 }),
  ];
  const candidates = buildValidOutfitCandidates(wardrobe);

  assert(
    candidates.some((candidate) => candidate.item_ids.includes("bag")),
  );
  assert(
    candidates.some((candidate) =>
      candidate.item_ids.includes("accessory-a")
    ),
  );
});

Deno.test("dress outfits can include bags and outerwear", () => {
  const wardrobe = [
    baseItem({ id: "dress", category: "dress" }),
    baseItem({ id: "shoes", category: "shoes" }),
    baseItem({ id: "bag", category: "bag" }),
    baseItem({ id: "jacket", category: "outerwear" }),
  ];
  const candidates = buildValidOutfitCandidates(wardrobe);

  assert(
    candidates.some((candidate) =>
      candidate.item_ids.includes("dress") &&
      candidate.item_ids.includes("shoes") &&
      candidate.item_ids.includes("bag")
    ),
  );
  assert(
    candidates.some((candidate) =>
      candidate.item_ids.includes("dress") &&
      candidate.item_ids.includes("shoes") &&
      candidate.item_ids.includes("jacket")
    ),
  );
  assert(
    candidates.every((candidate) => {
      const categories = new Set(
        candidate.item_ids.map((id) =>
          wardrobe.find((item) => item.id === id)?.category
        ),
      );
      return (categories.has("top") && categories.has("pants") &&
        categories.has("shoes")) ||
        (categories.has("dress") && categories.has("shoes"));
    }),
  );
});

Deno.test("normalizeMissingPieceItems preserves selected visual context", () => {
  const selected = normalizeMissingPieceItems([
    baseItem({
      id: "top",
      name: "Striped Shirt",
      category: "top",
      tags: ["casual"],
      dominant_colors: ["#FFFFFF", "#334455"],
      primary_color: "white",
      detected_attributes: { pattern: "striped", silhouette: "regular" },
    }),
    baseItem({
      id: "pants",
      category: "pants",
      dominant_colors: ["#111111"],
      detected_attributes: { pattern: "solid" },
    }),
    baseItem({
      id: "unknown",
      category: "shoes",
      detected_attributes: null,
    }),
  ]);

  assertEquals(selected[0], {
    id: "top",
    name: "Striped Shirt",
    category: "top",
    tags: ["casual"],
    colors: ["#FFFFFF", "#334455"],
    primary_color: "white",
    pattern: "striped",
    silhouette: "regular",
    wear_count: 0,
    last_worn: null,
  });
  assertEquals(selected[1].pattern, "solid");
  assertEquals(selected[2].pattern, null);
  assertEquals(selected[2].silhouette, null);
});

Deno.test("scoreOutfitCandidate boosts lucky and personal colors", () => {
  const candidate = scoreOutfitCandidate([
    baseItem({ id: "top", category: "top", primary_color: "coral" }),
    baseItem({ id: "pants", category: "pants", primary_color: "navy" }),
    baseItem({ id: "shoes", category: "shoes", primary_color: "white" }),
  ], {
    usePersonalColor: true,
    colorSeason: "spring",
    luckyColors: ["coral"],
  });

  assert(candidate.selection_factors.includes("lucky_color"));
  assert(candidate.selection_factors.includes("personal_color"));
});

Deno.test("scoreOutfitCandidate uses HEX distance and modest pattern rules", () => {
  const close = scoreOutfitCandidate([
    baseItem({ id: "top", category: "top", primary_color: "#3366FF" }),
    baseItem({ id: "pants", category: "pants", primary_color: "#335FEA" }),
    baseItem({ id: "shoes", category: "shoes", primary_color: "#223355" }),
  ], { targetHex: "#3360F0" });
  const loud = scoreOutfitCandidate([
    baseItem({
      id: "top",
      category: "top",
      primary_color: "#FF0000",
      detected_attributes: { pattern: "floral" },
    }),
    baseItem({
      id: "pants",
      category: "pants",
      primary_color: "#00FFFF",
      detected_attributes: { pattern: "graphic" },
    }),
    baseItem({ id: "shoes", category: "shoes" }),
  ], { targetHex: "#3360F0" });

  assert(close.score > loud.score);
  assert(close.selection_factors.includes("target_color"));
  assert(loud.selection_factors.includes("pattern_balance"));
});

Deno.test("scoreOutfitCandidate boosts selected style exact matches", () => {
  const matching = scoreOutfitCandidate([
    baseItem({ id: "top", category: "top", tags: ["streetwear"] }),
    baseItem({ id: "pants", category: "pants" }),
    baseItem({ id: "shoes", category: "shoes" }),
  ], { style: "streetwear" });
  const plain = scoreOutfitCandidate([
    baseItem({ id: "top", category: "top", tags: ["minimal"] }),
    baseItem({ id: "pants", category: "pants" }),
    baseItem({ id: "shoes", category: "shoes" }),
  ], { style: "streetwear" });

  assert(matching.score > plain.score);
});

Deno.test("scoreOutfitCandidate boosts saved profile style preferences", () => {
  const matching = scoreOutfitCandidate([
    baseItem({ id: "top", category: "top", tags: ["minimal", "clean"] }),
    baseItem({ id: "pants", category: "pants" }),
    baseItem({ id: "shoes", category: "shoes" }),
  ], { stylePreferences: ["minimal"] });
  const plain = scoreOutfitCandidate([
    baseItem({ id: "top", category: "top", tags: ["sport"] }),
    baseItem({ id: "pants", category: "pants" }),
    baseItem({ id: "shoes", category: "shoes" }),
  ], { stylePreferences: ["minimal"] });

  assert(matching.score > plain.score);
  assert(matching.selection_factors.includes("style_preferences"));
});

Deno.test("scoreOutfitCandidate uses AI attributes when names are generic", () => {
  const metadataMatch = scoreOutfitCandidate([
    baseItem({
      id: "top",
      category: "top",
      name: "Wardrobe item",
      tags: ["minimal"],
      detected_attributes: { style: ["minimal"], material: "linen" },
    }),
    baseItem({ id: "pants", category: "pants", name: "Wardrobe item" }),
    baseItem({ id: "shoes", category: "shoes", name: "Wardrobe item" }),
  ], { style: "minimal" });
  const noMetadata = scoreOutfitCandidate([
    baseItem({ id: "top", category: "top", name: "Wardrobe item", tags: [] }),
    baseItem({ id: "pants", category: "pants", name: "Wardrobe item" }),
    baseItem({ id: "shoes", category: "shoes", name: "Wardrobe item" }),
  ], { style: "minimal" });

  assert(metadataMatch.score > noMetadata.score);
  assert(metadataMatch.selection_factors.includes("ai_metadata"));
});

Deno.test("scoreOutfitCandidate prefers rainy-weather practical items", () => {
  const rainy = scoreOutfitCandidate([
    baseItem({ id: "top", category: "top", name: "Cotton tee" }),
    baseItem({ id: "pants", category: "pants", name: "Denim pants" }),
    baseItem({ id: "shoes", category: "shoes", name: "Rain boots" }),
  ], { weather: { rain: true, temperature_band: "warm" } });

  const suede = scoreOutfitCandidate([
    baseItem({ id: "top", category: "top", name: "Cotton tee" }),
    baseItem({ id: "pants", category: "pants", name: "Denim pants" }),
    baseItem({ id: "shoes", category: "shoes", name: "Suede shoes" }),
  ], { weather: { rain: true, temperature_band: "warm" } });

  assert(rainy.score > suede.score);
  assert(rainy.selection_factors.includes("weather"));
});

Deno.test("scoreOutfitCandidate penalizes recent item repetition", () => {
  const items = [
    baseItem({ id: "top", category: "top" }),
    baseItem({ id: "pants", category: "pants" }),
    baseItem({ id: "shoes", category: "shoes" }),
  ];
  const repeated = scoreOutfitCandidate(items, {
    recentEvents: [{
      style: null,
      colors: [],
      worn_at: new Date().toISOString(),
      clothing_item_ids: ["top"],
    }],
  });
  const fresh = scoreOutfitCandidate(items, { recentEvents: [] });

  assert(fresh.score > repeated.score);
});

Deno.test("scoreOutfitCandidate detects repeated combinations order independently", () => {
  const items = [
    baseItem({ id: "top", category: "top" }),
    baseItem({ id: "pants", category: "pants" }),
    baseItem({ id: "shoes", category: "shoes" }),
  ];
  const repeated = scoreOutfitCandidate(items, {
    recentEvents: [{
      style: null,
      colors: [],
      worn_at: new Date().toISOString(),
      clothing_item_ids: ["shoes", "top", "pants"],
    }],
  });

  assert(repeated.selection_factors.includes("repeat_combination"));
});

Deno.test("learned preference tokens boost matching candidates", () => {
  const matching = scoreOutfitCandidate([
    baseItem({
      id: "top",
      category: "top",
      tags: ["minimal"],
      primary_color: "black",
    }),
    baseItem({ id: "pants", category: "pants", tags: ["clean"] }),
    baseItem({ id: "shoes", category: "shoes", tags: ["leather"] }),
  ], {
    style: "minimal",
    preferenceEvents: [{
      style: "minimal",
      tags: ["minimal", "clean"],
      colors: ["black"],
      selection_factors: ["style_match"],
      score: 88,
      created_at: new Date().toISOString(),
    }],
  });
  const plain = scoreOutfitCandidate([
    baseItem({
      id: "top",
      category: "top",
      tags: ["sport"],
      primary_color: "orange",
    }),
    baseItem({ id: "pants", category: "pants" }),
    baseItem({ id: "shoes", category: "shoes" }),
  ], {
    style: "minimal",
    preferenceEvents: [{
      style: "minimal",
      tags: ["minimal", "clean"],
      colors: ["black"],
      selection_factors: ["style_match"],
      score: 88,
      created_at: new Date().toISOString(),
    }],
  });

  assert(matching.score > plain.score);
});

Deno.test("recent learned events weigh more than older events", () => {
  const minimalCandidate = [
    baseItem({ id: "top", category: "top", tags: ["minimal"] }),
    baseItem({ id: "pants", category: "pants", primary_color: "black" }),
    baseItem({ id: "shoes", category: "shoes" }),
  ];
  const minimalRecent = scoreOutfitCandidate(minimalCandidate, {
    style: "casual",
    preferenceEvents: [
      {
        style: "minimal",
        tags: ["minimal"],
        colors: ["black"],
        selection_factors: [],
        score: 80,
        created_at: new Date().toISOString(),
      },
      {
        style: "sport",
        tags: ["sport"],
        colors: ["orange"],
        selection_factors: [],
        score: 80,
        created_at: new Date(Date.now() - 120 * 24 * 60 * 60 * 1000)
          .toISOString(),
      },
    ],
  });
  const sportRecent = scoreOutfitCandidate(minimalCandidate, {
    style: "casual",
    preferenceEvents: [
      {
        style: "minimal",
        tags: ["minimal"],
        colors: ["black"],
        selection_factors: [],
        score: 80,
        created_at: new Date(Date.now() - 120 * 24 * 60 * 60 * 1000)
          .toISOString(),
      },
      {
        style: "sport",
        tags: ["sport"],
        colors: ["orange"],
        selection_factors: [],
        score: 80,
        created_at: new Date().toISOString(),
      },
    ],
  });

  assert(minimalRecent.score >= sportRecent.score);
});

Deno.test("explicit style still beats weak learned noise", () => {
  const explicitMatch = scoreOutfitCandidate([
    baseItem({ id: "top", category: "top", tags: ["formal"] }),
    baseItem({ id: "pants", category: "pants" }),
    baseItem({ id: "shoes", category: "shoes" }),
  ], {
    style: "formal",
    preferenceEvents: [{
      style: "sport",
      tags: ["sport"],
      colors: ["orange"],
      selection_factors: [],
      score: 62,
      created_at: new Date().toISOString(),
    }],
  });
  const noiseOnly = scoreOutfitCandidate([
    baseItem({ id: "top", category: "top", tags: ["sport"] }),
    baseItem({ id: "pants", category: "pants" }),
    baseItem({ id: "shoes", category: "shoes" }),
  ], {
    style: "formal",
    preferenceEvents: [{
      style: "sport",
      tags: ["sport"],
      colors: ["orange"],
      selection_factors: [],
      score: 62,
      created_at: new Date().toISOString(),
    }],
  });

  assert(explicitMatch.score > noiseOnly.score);
});

Deno.test("learned events can be disabled", () => {
  const withLearn = scoreOutfitCandidate([
    baseItem({ id: "top", category: "top", tags: ["minimal"] }),
    baseItem({ id: "pants", category: "pants", primary_color: "black" }),
    baseItem({ id: "shoes", category: "shoes" }),
  ], {
    preferenceEvents: [{
      style: "minimal",
      tags: ["minimal"],
      colors: ["black"],
      selection_factors: [],
      score: 80,
      created_at: new Date().toISOString(),
    }],
    learnPreferences: true,
  });
  const disabled = scoreOutfitCandidate([
    baseItem({ id: "top", category: "top", tags: ["minimal"] }),
    baseItem({ id: "pants", category: "pants", primary_color: "black" }),
    baseItem({ id: "shoes", category: "shoes" }),
  ], {
    preferenceEvents: [{
      style: "minimal",
      tags: ["minimal"],
      colors: ["black"],
      selection_factors: [],
      score: 80,
      created_at: new Date().toISOString(),
    }],
    learnPreferences: false,
  });
  assert(withLearn.score > disabled.score);
});

Deno.test("low confidence is penalized only when stronger metadata alternatives exist", () => {
  const highConfidence = [
    baseItem({
      id: "top",
      category: "top",
      tags: ["casual"],
      ai_confidence: 0.95,
      detected_attributes: { material: "cotton" },
    }),
    baseItem({
      id: "pants",
      category: "pants",
      tags: ["casual"],
      ai_confidence: 0.95,
      detected_attributes: { fit: "regular" },
    }),
    baseItem({
      id: "shoes",
      category: "shoes",
      tags: ["casual"],
      ai_confidence: 0.95,
      detected_attributes: { material: "leather" },
    }),
  ];

  const lowConfidence = [
    baseItem({
      id: "top-low",
      category: "top",
      tags: ["needs-review"],
      ai_confidence: 0.3,
      detected_attributes: { needs_review: true },
    }),
    baseItem({
      id: "pants-low",
      category: "pants",
      tags: ["casual"],
      ai_confidence: 0.35,
      detected_attributes: {},
    }),
    baseItem({
      id: "shoes-low",
      category: "shoes",
      tags: ["casual"],
      ai_confidence: 0.4,
      detected_attributes: {},
    }),
  ];

  const onlyLowAvailable = scoreOutfitCandidate(lowConfidence, {
    style: "casual",
    metadataQualityBaseline: 0.4,
  });
  const lowWhenHighExists = scoreOutfitCandidate(lowConfidence, {
    style: "casual",
    metadataQualityBaseline: 1,
  });
  const high = scoreOutfitCandidate(highConfidence, {
    style: "casual",
    metadataQualityBaseline: 1,
  });

  assert(
    lowWhenHighExists.score < onlyLowAvailable.score,
    "low confidence should only lose points when better metadata exists",
  );
  assert(high.score > lowWhenHighExists.score);
});

Deno.test("generated outfit selection rejects invalid ids and incomplete combinations", () => {
  const wardrobe = [
    baseItem({ id: "top", category: "top" }),
    baseItem({ id: "pants", category: "pants" }),
    baseItem({ id: "shoes", category: "shoes" }),
    baseItem({ id: "hat", category: "hat" }),
  ];
  const candidates = buildValidOutfitCandidates(wardrobe, { style: "casual" });
  const target = candidates[0];
  const invalid = ["top", "pants", "ghost-id"];
  const incomplete = target.item_ids.filter((id) => id !== "shoes");

  const selected = selectUsableOutfitsFromGenerated(
    [
      {
        name: "invalid ids",
        item_ids: invalid,
        style: "casual",
        reason: "bad",
        score: 90,
      },
      {
        name: "incomplete",
        item_ids: incomplete,
        style: "casual",
        reason: "bad",
        score: 90,
      },
      {
        name: "valid",
        item_ids: target.item_ids,
        style: "casual",
        reason: "ok",
        score: 88,
      },
    ],
    candidates,
    wardrobe,
  );

  assertEquals(
    selected[0].item_ids.slice().sort(),
    target.item_ids.slice().sort(),
  );
});

Deno.test("repetition insights alert only at threshold", () => {
  const below = repetitionInsights([
    { style: "casual", colors: ["black"], worn_at: new Date().toISOString() },
    { style: "casual", colors: ["black"], worn_at: new Date().toISOString() },
    { style: "work", colors: ["white"], worn_at: new Date().toISOString() },
  ]);
  const atThreshold = repetitionInsights([
    { style: "casual", colors: ["black"], worn_at: new Date().toISOString() },
    { style: "casual", colors: ["black"], worn_at: new Date().toISOString() },
    { style: "casual", colors: ["black"], worn_at: new Date().toISOString() },
    { style: "casual", colors: ["black"], worn_at: new Date().toISOString() },
  ]);

  assert(below.alert === false);
  assert(atThreshold.alert === true);
});

function assert(value: unknown, message = "Assertion failed") {
  if (!value) throw new Error(message);
}

function assertEquals(actual: unknown, expected: unknown) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
    );
  }
}
