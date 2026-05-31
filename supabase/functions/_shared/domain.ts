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

export function fallbackOutfits(items: ClothingItemRow[], style = "casual", count = 3) {
  const byCategory = (category: ClothingItemRow["category"]) =>
    items.filter((item) => item.category === category);

  const tops = byCategory("top");
  const pants = byCategory("pants");
  const shoes = byCategory("shoes");
  const accessories = byCategory("accessory");
  const hats = byCategory("hat");

  if (tops.length === 0 || pants.length === 0 || shoes.length === 0) {
    return [];
  }

  return Array.from({ length: Math.min(count, tops.length, 3) }).map((_, index) => ({
    name: index === 0 ? "Ready Set Look" : `Generated Look ${index + 1}`,
    item_ids: [
      tops[index % tops.length].id,
      pants[index % pants.length].id,
      shoes[index % shoes.length].id,
      ...(accessories.length ? [accessories[index % accessories.length].id] : []),
      ...(index === 0 && hats.length ? [hats[0].id] : []),
    ],
    style,
    reason: "Built from complete outfit categories in your wardrobe.",
    score: 72 - index,
  }));
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
