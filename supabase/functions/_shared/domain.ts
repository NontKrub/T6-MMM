export type ClothingItemRow = {
  id: string;
  name: string;
  brand: string | null;
  category:
    | "hat"
    | "top"
    | "pants"
    | "shoes"
    | "outerwear"
    | "dress"
    | "bag"
    | "accessory"
    | "unknown";
  tags: string[];
  dominant_colors: string[];
  primary_color: string | null;
  subtype?: string | null;
  pattern?: string | null;
  material?: string | null;
  fit?: string | null;
  silhouette?: string | null;
  styles?: string[] | null;
  formality?: string | null;
  seasons?: string[] | null;
  weather_suitability?: string[] | null;
  warmth_level?: number | null;
  analysis_confidence?: number | null;
  analysis_status?: string | null;
  user_corrected?: boolean | null;
  detected_attributes?: Record<string, unknown> | null;
  ai_confidence?: number | null;
  wear_count: number;
  last_worn: string | null;
};

export type WearEventRow = {
  style: string | null;
  colors: string[];
  worn_at: string;
  clothing_item_ids?: string[] | null;
};

export type PreferenceEventRow = {
  style: string | null;
  tags: string[];
  colors: string[];
  selection_factors: string[];
  score: number | null;
  created_at: string;
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

export type GeneratedOutfitDraft = {
  name: string;
  item_ids: string[];
  style: string;
  reason: string;
  score: number;
};

export type MissingPieceItemContext = {
  id: string;
  name: string;
  category: ClothingItemRow["category"];
  tags: string[];
  colors: string[];
  primary_color: string | null;
  pattern: string | null;
  silhouette: string | null;
  wear_count: number;
  last_worn: string | null;
};

export function normalizeMissingPieceItems(
  items: ClothingItemRow[],
): MissingPieceItemContext[] {
  return items.map((item) => {
    const attributes = item.detected_attributes ?? {};
    return {
      id: item.id,
      name: item.name,
      category: item.category,
      tags: item.tags,
      colors: item.dominant_colors,
      primary_color: item.primary_color,
      pattern: item.pattern ??
        (typeof attributes.pattern === "string" ? attributes.pattern : null),
      silhouette: item.silhouette ??
        (typeof attributes.silhouette === "string"
          ? attributes.silhouette
          : null),
      wear_count: item.wear_count,
      last_worn: item.last_worn,
    };
  });
}

type ScoreOptions = {
  style?: string;
  stylePreferences?: string[];
  usePersonalColor?: boolean;
  colorSeason?: string | null;
  luckyColors?: string[];
  weather?: Record<string, unknown> | null;
  recentEvents?: WearEventRow[];
  preferenceEvents?: PreferenceEventRow[];
  learnPreferences?: boolean;
  rush?: boolean;
  metadataQualityBaseline?: number;
  targetHex?: string | null;
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
    outerwear: sortedByPracticality(
      items.filter((item) => item.category === "outerwear"),
    ),
    dress: sortedByPracticality(
      items.filter((item) => item.category === "dress"),
    ),
    bag: sortedByPracticality(items.filter((item) => item.category === "bag")),
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

  if (groups.shoes.length === 0) {
    return [];
  }

  const tops = groups.top.slice(0, options.rush ? 4 : 8);
  const pants = groups.pants.slice(0, options.rush ? 4 : 8);
  const shoes = groups.shoes.slice(0, options.rush ? 4 : 8);
  const outerwear = [null, ...groups.outerwear.slice(0, 2)] as Array<
    ClothingItemRow | null
  >;
  const dresses = groups.dress.slice(0, options.rush ? 4 : 8);
  const hats = [null, ...groups.hat.slice(0, 2)] as Array<
    ClothingItemRow | null
  >;
  const extras = [
    null,
    ...sortedByPracticality([
      ...groups.bag,
      ...groups.accessory,
    ]).slice(0, 2),
  ] as Array<
    ClothingItemRow | null
  >;
  const candidateItemSets: ClothingItemRow[][] = [];

  if (tops.length > 0 && pants.length > 0) {
    for (const top of tops) {
      for (const bottom of pants) {
        for (const shoe of shoes) {
          for (const layer of outerwear) {
            for (const hat of hats) {
              for (const extra of extras) {
                const candidateItems = [
                  top,
                  bottom,
                  shoe,
                  layer,
                  hat,
                  extra,
                ].filter(Boolean) as ClothingItemRow[];
                candidateItemSets.push(candidateItems);
              }
            }
          }
        }
      }
    }
  }

  for (const onePiece of dresses) {
    for (const shoe of shoes) {
      for (const layer of outerwear) {
        for (const hat of hats) {
          for (const extra of extras) {
            candidateItemSets.push(
              [onePiece, shoe, layer, hat, extra].filter(
                Boolean,
              ) as ClothingItemRow[],
            );
          }
        }
      }
    }
  }

  if (candidateItemSets.length === 0) return [];

  const metadataQualityBaseline = candidateItemSets.reduce(
    (best, candidate) => Math.max(best, metadataQualityScore(candidate)),
    0,
  );
  const candidates = candidateItemSets.map((candidateItems) =>
    scoreOutfitCandidate(candidateItems, {
      ...options,
      metadataQualityBaseline,
    })
  );

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
  const styleLower = style.toLowerCase();
  const stylePreferences = (options.stylePreferences ?? [])
    .map((value) => value.trim().toLowerCase())
    .filter(Boolean);
  const factors = new Set<string>();
  let score = 58;
  const colors = normalizedColors(items);
  const metadataTokens = items.flatMap(itemMetadataTokens);
  const text = metadataTokens.join(" ");
  const tokenSet = new Set(metadataTokens);
  const genericCount = items.filter((item) => isGenericName(item.name)).length;
  const matchedByTag = items.some((item) =>
    item.tags.some((tag) => tag.toLowerCase() === styleLower)
  );
  const matchedByAttribute = items.some((item) =>
    flattenAttributeValues(item.detected_attributes).some((value) =>
      value === styleLower
    )
  );

  if (matchedByTag || matchedByAttribute) {
    score += 14;
    factors.add("style_match");
  } else if (text.includes(styleLower)) {
    score += 8;
    factors.add("style_match");
  }
  if ((matchedByTag || matchedByAttribute) && genericCount > 0) {
    score += 6;
    factors.add("ai_metadata");
  }

  const preferenceMatches = stylePreferences.filter((preference) =>
    text.includes(preference)
  );
  if (preferenceMatches.length > 0) {
    score += Math.min(12, preferenceMatches.length * 4);
    factors.add("style_preferences");
  }

  if (options.learnPreferences ?? true) {
    const learned = deriveLearnedPreferenceTokens(
      options.preferenceEvents ?? [],
    );
    const learnedTagMatches = learned.tags.filter((tag) => tokenSet.has(tag))
      .length;
    const learnedColorMatches = learned.colors.filter((color) =>
      colors.includes(color)
    ).length;
    const learnedAttributeMatches = learned.attributes.filter((token) =>
      tokenSet.has(token)
    ).length;
    const styleWeight = learned.styles.get(styleLower) ?? 0;

    const learnedScore = styleWeight * 1.4 +
      learnedTagMatches * 1.8 +
      learnedColorMatches * 1.6 +
      learnedAttributeMatches * 1.2;
    if (learnedScore > 0) {
      score += Math.min(20, learnedScore);
      factors.add("learned_preferences");
    }
  }

  const luckyColors = (options.luckyColors ?? []).map(normalizeColor);
  if (
    luckyColors.length && colors.some((color) => luckyColors.includes(color))
  ) {
    score += 9;
    factors.add("lucky_color");
  }

  if (options.targetHex) {
    const distances = colors.map((color) =>
      hexDistance(color, options.targetHex!)
    )
      .filter((distance): distance is number => distance !== null);
    if (distances.length > 0) {
      const closest = Math.min(...distances);
      if (closest <= 80) score += 8;
      else if (closest <= 180) score += 4;
      if (closest <= 180) factors.add("target_color");
    }
  }

  const loudPatterns = items.filter((item) => {
    const pattern = normalizeToken(
      item.pattern ?? String(item.detected_attributes?.pattern ?? ""),
    );
    return pattern !== "" && pattern !== "solid" && pattern !== "unknown";
  }).length;
  if (loudPatterns > 1) {
    score -= 4;
    factors.add("pattern_balance");
  }

  const silhouettes = items.map((item) =>
    normalizeToken(
      item.silhouette ?? String(item.detected_attributes?.silhouette ?? ""),
    )
  ).filter((value) => value && value !== "unknown");
  if (silhouettes.length > 1 && new Set(silhouettes).size > 1) {
    score += 2;
    factors.add("silhouette_balance");
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
  const itemKey = candidateKey(items.map((item) => item.id));
  const exactRepeats =
    recentEvents.filter((event) =>
      candidateKey(event.clothing_item_ids ?? []) === itemKey
    ).length;
  if (exactRepeats > 0) {
    score -= exactRepeats * 10;
    factors.add("repeat_combination");
  }
  if (
    recentEvents.slice(0, 5).filter((event) => event.style === style).length >=
      3
  ) {
    score -= 4;
  }

  if (
    typeof options.metadataQualityBaseline === "number" &&
    options.metadataQualityBaseline > metadataQualityScore(items) + 0.15
  ) {
    const lowConfidenceItems = items.filter((item) => isLowConfidence(item))
      .length;
    if (hasNeedsReview(items) || lowConfidenceItems > 0) {
      score -= Math.min(8, 4 + lowConfidenceItems * 2);
      factors.add("metadata_quality");
    }
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
  if (factors.includes("target_color")) {
    labels.push("matches your chosen color");
  }
  if (factors.includes("pattern_balance")) {
    labels.push("keeps patterns balanced");
  }
  if (factors.includes("silhouette_balance")) {
    labels.push("balances silhouettes");
  }
  if (factors.includes("style_preferences")) {
    labels.push("aligns with your saved style preferences");
  }
  if (factors.includes("learned_preferences")) {
    labels.push("aligns with outfits you actually wear");
  }
  if (factors.includes("ai_metadata")) {
    labels.push("uses AI-detected clothing details");
  }
  if (factors.includes("low_repetition")) {
    labels.push("keeps recent repeats low");
  }
  if (factors.includes("repeat_combination")) {
    labels.push("flags a repeated combination");
  }
  if (factors.includes("metadata_quality")) {
    labels.push("avoids items with uncertain metadata");
  }
  return labels.length
    ? labels.join(", ")
    : "Complete outfit balanced across your wardrobe.";
}

type LearnedTokens = {
  tags: string[];
  colors: string[];
  attributes: string[];
  styles: Map<string, number>;
};

function deriveLearnedPreferenceTokens(
  events: PreferenceEventRow[],
): LearnedTokens {
  const nowMs = Date.now();
  const tagWeights = new Map<string, number>();
  const colorWeights = new Map<string, number>();
  const attributeWeights = new Map<string, number>();
  const styleWeights = new Map<string, number>();

  for (const [index, event] of events.slice(0, 40).entries()) {
    const ageDays = Math.max(
      0,
      (nowMs - new Date(event.created_at).getTime()) / (24 * 60 * 60 * 1000),
    );
    const recencyWeight = Math.exp(-ageDays / 12);
    const rankWeight = Math.max(0.35, 1 - index * 0.03);
    const scoreWeight = typeof event.score === "number"
      ? Math.max(0.6, Math.min(1.4, event.score / 70))
      : 1;
    const weight = recencyWeight * rankWeight * scoreWeight;

    for (const tag of event.tags ?? []) {
      const token = normalizeToken(tag);
      if (!token) continue;
      tagWeights.set(token, (tagWeights.get(token) ?? 0) + weight);
    }
    for (const color of event.colors ?? []) {
      const token = normalizeColor(color);
      if (!token) continue;
      colorWeights.set(token, (colorWeights.get(token) ?? 0) + weight);
    }
    for (const factor of event.selection_factors ?? []) {
      const token = normalizeToken(factor);
      if (!token) continue;
      attributeWeights.set(
        token,
        (attributeWeights.get(token) ?? 0) + weight * 0.8,
      );
    }
    const style = normalizeToken(event.style ?? "");
    if (style) {
      styleWeights.set(style, (styleWeights.get(style) ?? 0) + weight * 1.1);
    }
  }

  return {
    tags: topWeightedTokens(tagWeights, 12),
    colors: topWeightedTokens(colorWeights, 8),
    attributes: topWeightedTokens(attributeWeights, 10),
    styles: styleWeights,
  };
}

function topWeightedTokens(map: Map<string, number>, limit: number) {
  return [...map.entries()].sort((a, b) => b[1] - a[1]).slice(0, limit).map((
    [key],
  ) => key);
}

export function selectUsableOutfitsFromGenerated(
  generated: GeneratedOutfitDraft[],
  candidates: OutfitCandidate[],
  wardrobe: ClothingItemRow[],
) {
  const byKey = new Map<string, OutfitCandidate>();
  for (const candidate of candidates) {
    byKey.set(candidateKey(candidate.item_ids), candidate);
  }

  const wardrobeById = new Map(wardrobe.map((item) => [item.id, item]));
  const selected: OutfitCandidate[] = [];
  const seen = new Set<string>();

  for (const outfit of generated) {
    const itemIds = [
      ...new Set(outfit.item_ids.filter((id) => wardrobeById.has(id))),
    ];
    const key = candidateKey(itemIds);
    if (seen.has(key)) continue;

    const exact = byKey.get(key);
    if (!exact) continue;

    const categorySet = new Set(
      exact.item_ids
        .map((id) => wardrobeById.get(id)?.category)
        .filter(Boolean),
    );
    const isBasicOutfit = categorySet.has("top") &&
      categorySet.has("pants") && categorySet.has("shoes");
    const isOnePieceOutfit = categorySet.has("dress") &&
      categorySet.has("shoes");
    if (!isBasicOutfit && !isOnePieceOutfit) continue;

    selected.push({
      ...exact,
      name: outfit.name || exact.name,
      style: outfit.style || exact.style,
      reason: outfit.reason || exact.reason,
      // Keep AI influence, but never allow non-finite scores into persisted rows.
      score: Math.max(
        0,
        Math.min(
          100,
          Math.round(
            (exact.score +
              (Number.isFinite(outfit.score) ? outfit.score : exact.score)) / 2,
          ),
        ),
      ),
    });
    seen.add(key);
  }

  if (selected.length > 0) {
    return selected.sort((a, b) => b.score - a.score);
  }

  return candidates.slice(0, 5);
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

function candidateKey(itemIds: string[]) {
  return [...itemIds].sort().join("|");
}

function metadataQualityScore(items: ClothingItemRow[]) {
  if (items.length === 0) return 0;

  let total = 0;
  for (const item of items) {
    const confidence = boundedConfidence(
      item.analysis_confidence ?? item.ai_confidence,
    );
    const tags = item.tags.length > 0 ? 0.15 : 0;
    const colors = item.primary_color || item.dominant_colors.length > 0
      ? 0.15
      : 0;
    const attributes = hasStructuredMetadata(item) ? 0.2 : 0;
    const reviewPenalty = hasNeedsReview([item]) ? 0.2 : 0;
    total += Math.max(
      0,
      confidence * 0.5 + tags + colors + attributes -
        reviewPenalty,
    );
  }

  return total / items.length;
}

function boundedConfidence(value: number | null | undefined) {
  if (typeof value !== "number" || Number.isNaN(value)) return 0;
  return Math.max(0, Math.min(1, value));
}

function isLowConfidence(item: ClothingItemRow) {
  const confidence = boundedConfidence(
    item.analysis_confidence ?? item.ai_confidence,
  );
  return confidence > 0 && confidence < 0.55;
}

function hasNeedsReview(items: ClothingItemRow[]) {
  return items.some((item) => {
    if (
      item.analysis_status === "partial" || item.analysis_status === "failed"
    ) {
      return true;
    }
    if (item.tags.some((tag) => normalizeToken(tag) === "needs-review")) {
      return true;
    }
    const attrs = item.detected_attributes ?? {};
    const value = attrs["needs_review"];
    return value === true;
  });
}

function hasUsableAttributes(
  attributes: Record<string, unknown> | null | undefined,
) {
  if (!attributes || typeof attributes !== "object") return false;
  return flattenAttributeValues(attributes).length > 0;
}

function hasStructuredMetadata(item: ClothingItemRow) {
  return Boolean(
    item.subtype || item.pattern || item.material || item.fit ||
      item.silhouette || item.formality || (item.styles?.length ?? 0) > 0 ||
      (item.seasons?.length ?? 0) > 0 ||
      (item.weather_suitability?.length ?? 0) > 0 ||
      item.warmth_level !== null && item.warmth_level !== undefined ||
      hasUsableAttributes(item.detected_attributes),
  );
}

function itemMetadataTokens(item: ClothingItemRow) {
  return [
    normalizeToken(item.name),
    normalizeToken(item.brand ?? ""),
    normalizeToken(item.subtype ?? ""),
    normalizeToken(item.primary_color ?? ""),
    ...item.dominant_colors.map(normalizeToken),
    ...item.tags.map(normalizeToken),
    normalizeToken(item.pattern ?? ""),
    normalizeToken(item.material ?? ""),
    normalizeToken(item.fit ?? ""),
    normalizeToken(item.silhouette ?? ""),
    ...(item.styles ?? []).map(normalizeToken),
    normalizeToken(item.formality ?? ""),
    ...(item.seasons ?? []).map(normalizeToken),
    ...(item.weather_suitability ?? []).map(normalizeToken),
    ...flattenAttributeValues(item.detected_attributes),
  ].filter(Boolean);
}

function flattenAttributeValues(
  value: Record<string, unknown> | unknown[] | unknown | null | undefined,
): string[] {
  if (value == null) return [];
  if (typeof value === "string") return [normalizeToken(value)];
  if (typeof value === "number" || typeof value === "boolean") {
    return [String(value)];
  }
  if (Array.isArray(value)) {
    return value.flatMap((entry) => flattenAttributeValues(entry));
  }
  if (typeof value === "object") {
    const entries = Object.entries(value as Record<string, unknown>);
    return entries.flatMap(([key, nested]) => [
      normalizeToken(key),
      ...flattenAttributeValues(nested),
    ]);
  }
  return [];
}

function normalizeToken(token: string) {
  return token.trim().toLowerCase();
}

function isGenericName(name: string) {
  const normalized = name.trim().toLowerCase();
  return normalized === "item" ||
    normalized === "wardrobe item" ||
    normalized === "top" ||
    normalized === "pants" ||
    normalized === "shoes" ||
    normalized === "accessory";
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

function hexDistance(first: string, second: string) {
  const pattern = /^#([0-9a-f]{6})$/i;
  const a = pattern.exec(first.trim());
  const b = pattern.exec(second.trim());
  if (!a || !b) return null;
  const firstValue = Number.parseInt(a[1], 16);
  const secondValue = Number.parseInt(b[1], 16);
  const red = (firstValue >> 16) - (secondValue >> 16);
  const green = ((firstValue >> 8) & 0xff) - ((secondValue >> 8) & 0xff);
  const blue = (firstValue & 0xff) - (secondValue & 0xff);
  return Math.sqrt(red * red + green * green + blue * blue);
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
