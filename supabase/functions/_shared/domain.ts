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

export type WearEventRow = {
  style: string | null;
  colors: string[];
  worn_at: string;
  clothing_item_ids?: string[] | null;
};

export type OutfitCandidate = {
  id: string;
  name: string;
  item_ids: string[];
  style: string;
  reason: string;
  score: number;
  selection_factors: string[];
};

type ScoreOptions = {
  style?: string;
  usePersonalColor?: boolean;
  colorSeason?: string | null;
  luckyColors?: string[];
  weather?: Record<string, unknown> | null;
  recentEvents?: WearEventRow[];
  rush?: boolean;
};

const seasonColors: Record<string, string[]> = {
  spring: ["cream", "coral", "peach", "yellow", "gold", "green"],
  summer: ["rose", "pink", "lavender", "sky blue", "blue", "silver"],
  autumn: ["olive", "orange", "tan", "brown", "gold", "cream"],
  winter: ["black", "white", "navy", "charcoal", "silver", "purple"],
};

export function groupWardrobeItems(items: ClothingItemRow[]) {
  return {
    hat: sortedByPracticality(items.filter((item) => item.category === "hat")),
    top: sortedByPracticality(items.filter((item) => item.category === "top")),
    pants: sortedByPracticality(
      items.filter((item) => item.category === "pants"),
    ),
    shoes: sortedByPracticality(
      items.filter((item) => item.category === "shoes"),
    ),
    accessory: sortedByPracticality(
      items.filter((item) => item.category === "accessory"),
    ),
  };
}

export function buildValidOutfitCandidates(
  items: ClothingItemRow[],
  options: ScoreOptions = {},
): OutfitCandidate[] {
  const groups = groupWardrobeItems(items);

  if (
    groups.top.length === 0 || groups.pants.length === 0 ||
    groups.shoes.length === 0
  ) {
    return [];
  }

  const tops = groups.top.slice(0, options.rush ? 4 : 8);
  const pants = groups.pants.slice(0, options.rush ? 4 : 8);
  const shoes = groups.shoes.slice(0, options.rush ? 4 : 8);
  const hats = [null, ...groups.hat.slice(0, 2)] as Array<
    ClothingItemRow | null
  >;
  const accessories = [null, ...groups.accessory.slice(0, 2)] as Array<
    ClothingItemRow | null
  >;
  const candidates: OutfitCandidate[] = [];

  for (const top of tops) {
    for (const bottom of pants) {
      for (const shoe of shoes) {
        for (const hat of hats) {
          for (const accessory of accessories) {
            const candidateItems = [top, bottom, shoe, hat, accessory].filter(
              Boolean,
            ) as ClothingItemRow[];
            candidates.push(scoreOutfitCandidate(candidateItems, options));
          }
        }
      }
    }
  }

  return candidates
    .sort((a, b) => b.score - a.score)
    .slice(0, options.rush ? 12 : 40)
    .map((candidate, index) => ({
      ...candidate,
      id: `candidate_${index + 1}`,
      name: options.rush && index === 0 ? "Rush Outfit" : candidate.name,
    }));
}

export function scoreOutfitCandidate(
  items: ClothingItemRow[],
  options: ScoreOptions = {},
): OutfitCandidate {
  const style = options.style ?? "casual";
  const factors = new Set<string>();
  let score = 58;
  const colors = normalizedColors(items);
  const text = items.flatMap((item) => [
    item.name,
    item.brand ?? "",
    item.primary_color ?? "",
    ...item.dominant_colors,
    ...item.tags,
  ]).join(" ").toLowerCase();

  if (
    items.some((item) =>
      item.tags.some((tag) => tag.toLowerCase() === style.toLowerCase())
    )
  ) {
    score += 10;
    factors.add("style_match");
  } else if (text.includes(style.toLowerCase())) {
    score += 6;
    factors.add("style_match");
  }

  const luckyColors = (options.luckyColors ?? []).map(normalizeColor);
  if (
    luckyColors.length && colors.some((color) => luckyColors.includes(color))
  ) {
    score += 9;
    factors.add("lucky_color");
  }

  if (options.usePersonalColor && options.colorSeason) {
    const palette = seasonColors[options.colorSeason] ?? [];
    if (colors.some((color) => palette.map(normalizeColor).includes(color))) {
      score += 8;
      factors.add("personal_color");
    }
  }

  const weather = options.weather ?? null;
  const rain = weather?.rain === true ||
    String(weather?.condition ?? "").toLowerCase().includes("rain");
  const tempBand = String(weather?.temperature_band ?? "");
  if (weather) {
    if (rain) {
      if (text.includes("suede") || text.includes("delicate")) {
        score -= 12;
        factors.add("weather");
      } else if (
        text.includes("water") || text.includes("rain") || text.includes("boot")
      ) {
        score += 8;
        factors.add("weather");
      } else {
        score += 3;
        factors.add("weather");
      }
    }
    if (
      tempBand === "hot" &&
      (text.includes("linen") || text.includes("cotton") ||
        text.includes("breathable"))
    ) {
      score += 5;
      factors.add("weather");
    }
    if (
      tempBand === "cold" &&
      (text.includes("jacket") || text.includes("coat") ||
        text.includes("layer"))
    ) {
      score += 5;
      factors.add("weather");
    }
  }

  const averageWear =
    items.reduce((sum, item) => sum + (item.wear_count ?? 0), 0) / items.length;
  score += Math.max(0, 8 - averageWear);
  if (averageWear <= 2) factors.add("low_repetition");

  const daysSinceLastWorn = Math.min(
    ...items.map(daysSince).filter((value) => Number.isFinite(value)),
  );
  if (!Number.isFinite(daysSinceLastWorn) || daysSinceLastWorn >= 7) {
    score += 6;
    factors.add("low_repetition");
  } else if (daysSinceLastWorn <= 1) {
    score -= 12;
  }

  const recentEvents = options.recentEvents ?? [];
  const recentIds = new Set(
    recentEvents.slice(0, 5).flatMap((event) => event.clothing_item_ids ?? []),
  );
  const repeatedItems = items.filter((item) => recentIds.has(item.id)).length;
  if (repeatedItems === 0) {
    score += 6;
    factors.add("low_repetition");
  } else {
    score -= repeatedItems * 5;
  }
  if (
    recentEvents.slice(0, 5).filter((event) => event.style === style).length >=
      3
  ) {
    score -= 4;
  }

  const boundedScore = Math.max(0, Math.min(100, Math.round(score)));
  return {
    id: "",
    name: titleFor(style, items),
    item_ids: items.map((item) => item.id),
    style,
    reason: explainScoreFactors([...factors], options),
    score: boundedScore,
    selection_factors: [...factors],
  };
}

export function explainScoreFactors(
  factors: string[],
  options: ScoreOptions = {},
) {
  const labels = [];
  if (factors.includes("style_match")) {
    labels.push(`matches ${options.style ?? "your"} style`);
  }
  if (factors.includes("weather")) labels.push("fits today's weather");
  if (factors.includes("lucky_color")) labels.push("uses today's lucky color");
  if (factors.includes("personal_color")) {
    labels.push("works with your color season");
  }
  if (factors.includes("low_repetition")) {
    labels.push("keeps recent repeats low");
  }
  return labels.length
    ? labels.join(", ")
    : "Complete outfit balanced across your wardrobe.";
}

export function leastRecentlyWornOutfit(
  items: ClothingItemRow[],
  style = "casual",
) {
  return buildValidOutfitCandidates(items, { style, rush: true })[0] ?? null;
}

export function repetitionInsights(
  events: Array<{ style: string | null; colors: string[]; worn_at: string }>,
) {
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

export function luckyColorsFor(
  date: Date,
  birthDate?: string | null,
  birthWeekday?: number | null,
) {
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
    seed += birthDate.replaceAll("-", "").split("").reduce(
      (sum, value) => sum + Number(value),
      0,
    );
  }
  if (birthWeekday) {
    seed += birthWeekday * 3;
  }

  return palettes[seed % palettes.length];
}

function sortedByPracticality(items: ClothingItemRow[]) {
  return [...items].sort((a, b) => {
    const worn = (a.wear_count ?? 0) - (b.wear_count ?? 0);
    if (worn !== 0) return worn;
    const aDays = daysSince(a);
    const bDays = daysSince(b);
    if (!Number.isFinite(aDays) && !Number.isFinite(bDays)) return 0;
    if (!Number.isFinite(aDays)) return -1;
    if (!Number.isFinite(bDays)) return 1;
    return bDays - aDays;
  });
}

function normalizedColors(items: ClothingItemRow[]) {
  return items.flatMap((item) => [
    item.primary_color,
    ...item.dominant_colors,
  ]).filter(Boolean).map((color) => normalizeColor(String(color)));
}

function normalizeColor(color: string) {
  return color.trim().toLowerCase();
}

function daysSince(item: ClothingItemRow) {
  if (!item.last_worn) return Number.POSITIVE_INFINITY;
  const last = new Date(item.last_worn).getTime();
  if (Number.isNaN(last)) return Number.POSITIVE_INFINITY;
  return (Date.now() - last) / 86_400_000;
}

function titleFor(style: string, items: ClothingItemRow[]) {
  const top = items.find((item) => item.category === "top")?.name ?? "Top";
  const shoes = items.find((item) => item.category === "shoes")?.name ??
    "Shoes";
  return `${capitalize(style)} ${top} + ${shoes}`;
}

function capitalize(value: string) {
  return value.length ? value[0].toUpperCase() + value.slice(1) : value;
}
