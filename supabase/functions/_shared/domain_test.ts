import { buildValidOutfitCandidates, scoreOutfitCandidate } from "./domain.ts";
import type { ClothingItemRow } from "./domain.ts";

const baseItem = (overrides: Partial<ClothingItemRow>): ClothingItemRow => ({
  id: overrides.id ?? crypto.randomUUID(),
  name: overrides.name ?? "Item",
  brand: null,
  category: overrides.category ?? "top",
  tags: overrides.tags ?? [],
  dominant_colors: overrides.dominant_colors ?? [],
  primary_color: overrides.primary_color ?? null,
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
