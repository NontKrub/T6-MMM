export type ClothingItemRow = {
  id: string;
  name: string;
  brand: string | null;
  category: "hat" | "top" | "pants" | "shoes" | "accessory";
  tags: string[];
  dominant_colors: string[];
  primary_color: string | null;
  wear_count: number;
  last_worn: string | null;
};

export function leastRecentlyWornOutfit(items: ClothingItemRow[], style = "casual") {
  const byCategory = (category: ClothingItemRow["category"]) =>
    items.filter((item) => item.category === category);

  const tops = byCategory("top");
  const pants = byCategory("pants");
  const shoes = byCategory("shoes");
  const accessories = byCategory("accessory");
  const hats = byCategory("hat");

  if (tops.length === 0 || pants.length === 0 || shoes.length === 0) {
    return null;
  }

  return {
    name: "Rush Outfit",
    item_ids: [
      tops[0].id,
      pants[0].id,
      shoes[0].id,
      ...(accessories.length ? [accessories[0].id] : []),
      ...(hats.length ? [hats[0].id] : []),
    ],
    style,
    reason: "Fast practical pick using least-recently-worn complete outfit categories.",
    score: 80,
  };
}

export function repetitionInsights(events: Array<{ style: string | null; colors: string[]; worn_at: string }>) {
  const colorCounts = new Map<string, number>();
  const styleCounts = new Map<string, number>();

  for (const event of events) {
    for (const color of event.colors ?? []) {
      colorCounts.set(color, (colorCounts.get(color) ?? 0) + 1);
    }
    if (event.style) {
      styleCounts.set(event.style, (styleCounts.get(event.style) ?? 0) + 1);
    }
  }

  const topColor = [...colorCounts.entries()].sort((a, b) => b[1] - a[1])[0];
  const topStyle = [...styleCounts.entries()].sort((a, b) => b[1] - a[1])[0];

  return {
    dominant_color: topColor?.[0] ?? null,
    dominant_color_count: topColor?.[1] ?? 0,
    dominant_style: topStyle?.[0] ?? null,
    dominant_style_count: topStyle?.[1] ?? 0,
    alert: Boolean((topColor?.[1] ?? 0) >= 4 || (topStyle?.[1] ?? 0) >= 4),
  };
}

export function luckyColorsFor(date: Date, birthDate?: string | null, birthWeekday?: number | null) {
  const palettes = [
    ["white", "silver", "sky blue"],
    ["yellow", "cream", "gold"],
    ["pink", "coral", "rose"],
    ["green", "olive", "mint"],
    ["orange", "tan", "brown"],
    ["blue", "navy", "teal"],
    ["purple", "black", "charcoal"],
  ];

  let seed = date.getUTCFullYear() + date.getUTCMonth() + date.getUTCDate();
  if (birthDate) {
    seed += birthDate.replaceAll("-", "").split("").reduce((sum, value) => sum + Number(value), 0);
  }
  if (birthWeekday) {
    seed += birthWeekday * 3;
  }

  return palettes[seed % palettes.length];
}
