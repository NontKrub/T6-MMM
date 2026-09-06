import '../../l10n/app_localizations.dart';
import '../../shared/models/clothing_item.dart';
import '../../shared/models/user_profile.dart';

String profileCategoryLabel(
  AppLocalizations? l10n,
  ClothingCategory category,
) => switch (category) {
  ClothingCategory.hat => l10n?.clothingCategoryHat ?? category.label,
  ClothingCategory.top => l10n?.clothingCategoryTop ?? category.label,
  ClothingCategory.pants => l10n?.clothingCategoryPants ?? category.label,
  ClothingCategory.shoes => l10n?.clothingCategoryShoes ?? category.label,
  ClothingCategory.outerwear =>
    l10n?.clothingCategoryOuterwear ?? category.label,
  ClothingCategory.dress => l10n?.clothingCategoryDress ?? category.label,
  ClothingCategory.bag => l10n?.clothingCategoryBag ?? category.label,
  ClothingCategory.accessory =>
    l10n?.clothingCategoryAccessory ?? category.label,
  ClothingCategory.unknown => l10n?.clothingCategoryUnknown ?? category.label,
};

String profileStyleLabel(AppLocalizations? l10n, ClothingStyle style) =>
    switch (style) {
      ClothingStyle.casual => l10n?.styleVibesCasual ?? 'Casual',
      ClothingStyle.streetwear => l10n?.styleVibesStreetwear ?? 'Streetwear',
      ClothingStyle.formal => l10n?.styleVibesFormal ?? 'Formal',
      ClothingStyle.minimal => l10n?.styleVibesMinimalist ?? 'Minimalist',
      ClothingStyle.vintage => l10n?.styleVibesVintage ?? 'Vintage',
      ClothingStyle.preppy => l10n?.styleVibesPreppy ?? 'Preppy',
      ClothingStyle.business => l10n?.profileStyleBusiness ?? 'Business',
      ClothingStyle.sport => l10n?.profileStyleSport ?? 'Sport',
      ClothingStyle.smartCasual =>
        l10n?.profileStyleSmartCasual ?? 'Smart casual',
      ClothingStyle.unknown => l10n?.clothingCategoryUnknown ?? 'Unknown',
    };

String profileSeasonLabel(AppLocalizations? l10n, ColorSeason season) =>
    switch (season) {
      ColorSeason.spring => l10n?.seasonSpring ?? season.label,
      ColorSeason.summer => l10n?.seasonSummer ?? season.label,
      ColorSeason.autumn => l10n?.seasonAutumn ?? season.label,
      ColorSeason.winter => l10n?.seasonWinter ?? season.label,
    };

String profilePreferenceLabel(AppLocalizations? l10n, String value) =>
    switch (value) {
      'Casual' => l10n?.styleVibesCasual ?? value,
      'Minimalist' => l10n?.styleVibesMinimalist ?? value,
      'Streetwear' => l10n?.styleVibesStreetwear ?? value,
      'Formal' => l10n?.styleVibesFormal ?? value,
      'Vintage' => l10n?.styleVibesVintage ?? value,
      'Preppy' => l10n?.styleVibesPreppy ?? value,
      'Y2K' => l10n?.styleVibesY2K ?? value,
      'Cottagecore' => l10n?.styleVibesCottagecore ?? value,
      'Bohemian' => l10n?.styleVibesBohemian ?? value,
      'Athleisure' => l10n?.styleVibesAthleisure ?? value,
      'Dark Academia' => l10n?.styleVibesDarkAcademia ?? value,
      'Clean Girl' => l10n?.styleVibesCleanGirl ?? value,
      _ => value,
    };

String profileOccasionLabel(AppLocalizations? l10n, String value) =>
    switch (value) {
      'Work' => l10n?.occasionWork ?? value,
      'Weekend' => l10n?.occasionWeekend ?? value,
      'Dates' => l10n?.occasionDates ?? value,
      'Sports' => l10n?.occasionSports ?? value,
      'Events' => l10n?.occasionEvents ?? value,
      'Travel' => l10n?.occasionTravel ?? value,
      _ => value,
    };
