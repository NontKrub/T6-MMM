// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Mix Match Mood';

  @override
  String get appTagline => 'match your wardrobe to your mood';

  @override
  String get languageScreenTitle => 'Choose your language';

  @override
  String get languageScreenSubtitle => 'เลือกภาษา';

  @override
  String get languageContinue => 'Continue';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageThai => 'ภาษาไทย';

  @override
  String get authHeroTitle => 'Your wardrobe,\nreimagined.';

  @override
  String get authHeroSubtitle =>
      'AI-powered outfit suggestions,\npersonalized just for you.';

  @override
  String get authGetStarted => 'Get started';

  @override
  String get authContinueWithApple => 'Continue with Apple';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authContinueWithFacebook => 'Continue with Facebook';

  @override
  String get authContinueAsGuest => 'Continue as guest';

  @override
  String get authUnavailable =>
      'Sign in is unavailable until Supabase is configured.';

  @override
  String get authImportGuestTitle => 'Import your guest wardrobe?';

  @override
  String get authImportGuestMessage =>
      'MMM found a local guest wardrobe. Import it into this signed-in account?';

  @override
  String get authImportGuest => 'Import wardrobe';

  @override
  String get authContinueWithoutImport => 'Not now';

  @override
  String get authImportFailed => 'Local wardrobe import failed';

  @override
  String onboardingStep(int current, int total) {
    return '$current / $total';
  }

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingEnter => 'Enter MMM';

  @override
  String get onboardingUserInfoTitle => 'Tell us about you';

  @override
  String get onboardingUserInfoSubtitle =>
      'We use this to personalise your experience.';

  @override
  String get onboardingYourName => 'Your name';

  @override
  String get onboardingNameHint => 'e.g. Alex';

  @override
  String get onboardingDateOfBirth => 'Date of birth';

  @override
  String get onboardingSelectDate => 'Select date';

  @override
  String get onboardingDobHint =>
      'Optional — helps us tailor lucky colour predictions.';

  @override
  String get onboardingStyleTitle => 'Your style & build';

  @override
  String get onboardingStyleSubtitle =>
      'Pick your body type and the vibes that resonate.';

  @override
  String get onboardingBodyType => 'BODY TYPE';

  @override
  String get onboardingStyleVibes => 'STYLE VIBES';

  @override
  String get onboardingStyleVibesHint => 'Pick everything that resonates.';

  @override
  String get onboardingColorSeasonTitle => 'Your color season';

  @override
  String get onboardingColorSeasonSubtitle =>
      'Determines which color palette flatters you most.';

  @override
  String get onboardingLifestyleTitle => 'Your lifestyle';

  @override
  String get onboardingLifestyleSubtitle => 'What occasions do you dress for?';

  @override
  String get bodyTypeStraight => 'Straight';

  @override
  String get bodyTypeHourglass => 'Hourglass';

  @override
  String get bodyTypePear => 'Pear';

  @override
  String get bodyTypeApple => 'Apple';

  @override
  String get bodyTypeAthletic => 'Athletic';

  @override
  String get styleVibesCasual => 'Casual';

  @override
  String get styleVibesMinimalist => 'Minimalist';

  @override
  String get styleVibesStreetwear => 'Streetwear';

  @override
  String get styleVibesFormal => 'Formal';

  @override
  String get styleVibesVintage => 'Vintage';

  @override
  String get styleVibesY2K => 'Y2K';

  @override
  String get styleVibesCottagecore => 'Cottagecore';

  @override
  String get styleVibesPreppy => 'Preppy';

  @override
  String get styleVibesBohemian => 'Bohemian';

  @override
  String get styleVibesAthleisure => 'Athleisure';

  @override
  String get styleVibesDarkAcademia => 'Dark Academia';

  @override
  String get styleVibesCleanGirl => 'Clean Girl';

  @override
  String get seasonSpring => 'Spring';

  @override
  String get seasonSummer => 'Summer';

  @override
  String get seasonAutumn => 'Autumn';

  @override
  String get seasonWinter => 'Winter';

  @override
  String get occasionWork => 'Work';

  @override
  String get occasionWeekend => 'Weekend';

  @override
  String get occasionDates => 'Dates';

  @override
  String get occasionSports => 'Sports';

  @override
  String get occasionEvents => 'Events';

  @override
  String get occasionTravel => 'Travel';

  @override
  String get navHome => 'Home';

  @override
  String get navWardrobe => 'Wardrobe';

  @override
  String get navMissing => 'Missing';

  @override
  String get navChat => 'Chat';

  @override
  String get homeCustomize => 'Customize';

  @override
  String get homeGenerateOutfit => 'Generate Outfit';

  @override
  String get wardrobeTitle => 'Wardrobe';

  @override
  String wardrobeItemCount(int count) {
    return '$count items';
  }

  @override
  String get wardrobeSearchHint => 'Search by name, brand, or tag…';

  @override
  String get wardrobeEmpty => 'Your wardrobe is empty';

  @override
  String get wardrobeEmptyHint => 'Tap + to add your first item';

  @override
  String get wardrobeNoResults => 'No items found';

  @override
  String get missingTitle => 'Your wardrobe needs...';

  @override
  String get missingSubtitleLocked =>
      'Sign in to generate wardrobe gap recommendations';

  @override
  String get missingSubtitleUnlocked =>
      'Curated to fill the gaps in your collection';

  @override
  String get missingLockedTitle => 'Recommendations need a login';

  @override
  String get missingLockedMessage =>
      'Missing pieces use backend AI and your Supabase wardrobe. Guest accounts keep wardrobe data local only.';

  @override
  String get missingEmptyTitle => 'No recommendations yet';

  @override
  String get missingEmptyMessage =>
      'The backend did not return any missing pieces.';

  @override
  String get missingErrorTitle => 'Could not generate recommendations';

  @override
  String get missingWhyExpand => 'Why?';

  @override
  String get missingWhyCollapse => 'Hide reason';

  @override
  String get chatTitle => 'Fashion AI';

  @override
  String get chatStatusLocked => 'Sign in required';

  @override
  String get chatStatusConsentRequired => 'Consent required';

  @override
  String get chatStatusUnlocked => 'Always styled';

  @override
  String get chatInputHint => 'Ask about fashion…';

  @override
  String get chatLockedTitle => 'Fashion AI needs a login';

  @override
  String get chatLockedMessage =>
      'Chat uses your saved wardrobe and backend AI. Continue with Google after Supabase is configured.';

  @override
  String get authImportingGuest => 'Importing local wardrobe…';

  @override
  String get chatConsentTitle => 'Fashion AI needs your consent';

  @override
  String get chatConsentMessage =>
      'Allow MMM to send wardrobe images, wardrobe metadata, and fashion questions to its configured AI provider. You can revoke this permission in Settings.';

  @override
  String get chatPrompt1 => 'What\'s my color season?';

  @override
  String get chatPrompt2 => 'Name this style';

  @override
  String get chatPrompt3 => 'Build a capsule wardrobe';

  @override
  String get chatPrompt4 => 'Streetwear basics';

  @override
  String get chatPrompt5 => 'Quiet luxury look';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileItems => 'Items';

  @override
  String get profileOutfits => 'Outfits';

  @override
  String get profileFavItem => 'Fav item';

  @override
  String get profileColorSeason => 'Color Season';

  @override
  String get profileStylePreferences => 'Style Preferences';

  @override
  String get profileSignOut => 'Sign Out';

  @override
  String get profileDeleteAccount => 'Delete Account';

  @override
  String get profileDeleteAccountTitle => 'Delete your account?';

  @override
  String get profileDeleteAccountMessage =>
      'This permanently removes your profile, wardrobe images, outfits, and activity from MMM.';

  @override
  String get profileDeleteAccountConfirm => 'Delete Account';

  @override
  String get profileDeleteAccountFailed => 'Account deletion failed';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsDarkMode => 'Dark Mode';

  @override
  String get settingsDarkModeOn => 'On';

  @override
  String get settingsDarkModeOff => 'Off';

  @override
  String get settingsPersonalization => 'Personalization';

  @override
  String get settingsLuckyColor => 'Lucky Color Method';

  @override
  String get settingsLuckyColorValue => 'Random daily';

  @override
  String get settingsWeather => 'Weather Location';

  @override
  String get settingsWeatherValue => 'Auto-detect';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsDailyReminder => 'Daily outfit reminder';

  @override
  String get settingsNotificationsPermissionDenied =>
      'Notifications are disabled. MMM will continue without reminders.';

  @override
  String get settingsRepetitionAlerts => 'Repetition alerts';

  @override
  String get settingsImportLocal => 'Import local wardrobe';

  @override
  String get settingsImportLocalSubtitle =>
      'Resume importing your guest wardrobe';

  @override
  String get settingsImportLocalComplete => 'Local wardrobe imported.';

  @override
  String get settingsImportLocalFailed => 'Import failed';

  @override
  String get settingsAI => 'AI Features';

  @override
  String get settingsLearnPreferences => 'Learn my preferences';

  @override
  String get settingsLearnPreferencesSubtitle =>
      'AI tracks your choices to improve suggestions';

  @override
  String get settingsAIConsent => 'Third-party AI analysis';

  @override
  String get settingsAIConsentGranted => 'Allowed — revoke anytime';

  @override
  String get settingsAIConsentOff =>
      'Off — local and deterministic fallbacks stay available';

  @override
  String get settingsAIConsentSignIn =>
      'Sign in to manage third-party AI consent';

  @override
  String get settingsAIConsentTitle => 'Allow third-party AI?';

  @override
  String get settingsAIConsentMessage =>
      'MMM may send wardrobe images, wardrobe metadata, and fashion questions to the configured AI provider for analysis and recommendations. This is optional and can be revoked in Settings.';

  @override
  String get settingsAIConsentAccept => 'Allow AI analysis';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsVersionValue => '1.0.0 (build 1)';

  @override
  String get settingsPrivacy => 'Privacy Policy';

  @override
  String get settingsPrivacyNotConfigured =>
      'A public HTTPS privacy-policy URL has not been configured yet.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageValue => 'English';

  @override
  String get avatarTitle => 'Your Avatar';

  @override
  String get avatarBodyShape => 'Body Shape';

  @override
  String get avatarHairStyle => 'Hair Style';

  @override
  String get avatarSkinTone => 'Skin Tone';

  @override
  String get avatarHair => 'Hair';

  @override
  String get avatarDone => 'Done';

  @override
  String get avatarHuman => 'Human';

  @override
  String get avatarDog => 'Dog';

  @override
  String get avatarCat => 'Cat';

  @override
  String get avatarFemale => 'Female';

  @override
  String get avatarMale => 'Male';

  @override
  String get avatarHairBlack => 'Black';

  @override
  String get avatarHairDark => 'Dark';

  @override
  String get avatarHairBrown => 'Brown';

  @override
  String get avatarHairBlonde => 'Blonde';

  @override
  String get avatarHairAuburn => 'Auburn';

  @override
  String get avatarHairPlatinum => 'Platinum';

  @override
  String get avatarHairTousled => 'Tousled';

  @override
  String get avatarHairSideSwept => 'Side Swept';

  @override
  String get avatarHairUndercut => 'Undercut';

  @override
  String get avatarHairLong => 'Long';

  @override
  String get avatarHairPonytail => 'Ponytail';

  @override
  String get avatarHairBob => 'Bob';

  @override
  String get repetitionStyleReminder => 'Style reminder';

  @override
  String repetitionMessage(String color) {
    return 'You\'ve been wearing $color tones frequently. Try mixing in something different today!';
  }

  @override
  String get outfitGeneratorTitle => 'Generate Outfit';

  @override
  String get outfitGeneratorStyleLabel => 'Style';

  @override
  String get outfitGeneratorFiltersLabel => 'Filters';

  @override
  String get outfitGeneratorUsePersonalColor => 'Use my personal color season';

  @override
  String get outfitGeneratorLuckyColor => 'Today\'s lucky color';

  @override
  String get outfitGeneratorMatchWeather => 'Match weather';

  @override
  String get outfitGeneratorWeatherOff =>
      'Turn on Weather Location in Settings';

  @override
  String get outfitGeneratorWeatherAuto => 'Auto-detect location';

  @override
  String get outfitGeneratorGenerating => 'Generating...';

  @override
  String get outfitGeneratorGenerate => 'Generate';

  @override
  String get outfitGeneratorResults => 'Results';

  @override
  String get outfitGeneratorLockedTitle => 'AI outfit generation needs a login';

  @override
  String get outfitGeneratorLockedMessage =>
      'Guest wardrobes stay local. Sign in with Supabase to generate real outfits, weather matches, and lucky color looks.';

  @override
  String get outfitGeneratorNoOutfits => 'No outfits were generated.';

  @override
  String get outfitGeneratorErrorNotDeployed =>
      'Outfit generation is not deployed yet. Please try again after the backend is updated.';

  @override
  String get outfitGeneratorErrorNeedWardrobe =>
      'Add at least one top, one bottom, and one pair of shoes first.';

  @override
  String get outfitGeneratorErrorLocationPermission =>
      'Location permission is needed to match the weather.';

  @override
  String get outfitGeneratorErrorLocationOff =>
      'Turn on location services to match the weather.';

  @override
  String get outfitGeneratorErrorGeneric =>
      'Could not generate outfits. Please try again.';

  @override
  String get outfitStyleCasual => 'Casual';

  @override
  String get outfitStyleWork => 'Work';

  @override
  String get outfitStyleFormal => 'Formal';

  @override
  String get outfitStyleSport => 'Sport';

  @override
  String get outfitStyleDate => 'Date';

  @override
  String get rushTitle => 'In a Rush';

  @override
  String get rushStatusSignInRequired => 'Sign in required';

  @override
  String get rushStatusNeedsSetup => 'Needs a little setup';

  @override
  String get rushStatusReady => 'Your outfit is ready';

  @override
  String get rushLockedMessage =>
      'Rush outfit uses backend AI. Sign in with Supabase to use it.';

  @override
  String get rushDefaultReason => 'Fast practical pick from your wardrobe.';

  @override
  String get rushReshuffle => 'Reshuffle';

  @override
  String get rushSignIn => 'Sign In';

  @override
  String get rushGotIt => 'Got It';

  @override
  String get rushWearThis => 'Wear This';

  @override
  String get rushErrorNeedWardrobe =>
      'Rush outfits need a complete wardrobe first. Add at least one top, one bottom, and one pair of shoes.';

  @override
  String get rushErrorUnavailable =>
      'No compatible rush outfit is available. Add shoes and a top + bottom or a dress.';

  @override
  String get rushErrorSignIn =>
      'Rush outfit uses your saved backend wardrobe. Sign in to use it.';

  @override
  String get rushErrorNotDeployed =>
      'Rush outfit is not deployed yet. Please try again after the backend is updated.';

  @override
  String get rushErrorGeneric =>
      'Could not pick a rush outfit right now. Check your wardrobe and try again.';

  @override
  String get addItemTitle => 'Add Item';

  @override
  String get addItemCategory => 'Category';

  @override
  String get addItemNameHint => 'Item name (e.g. White Linen Shirt)';

  @override
  String get addItemBrandHint => 'Brand (optional)';

  @override
  String get addItemTags => 'Tags';

  @override
  String get addItemSaving => 'Saving...';

  @override
  String get addItemSave => 'Save to Wardrobe';

  @override
  String get addItemCamera => 'Camera';

  @override
  String get addItemPhotoLibrary => 'Photo Library';

  @override
  String get addItemTapToAddPhoto => 'Tap to add photo';

  @override
  String addItemCategoryLabel(String category) {
    return 'Category: $category';
  }

  @override
  String get tagCasual => 'casual';

  @override
  String get tagFormal => 'formal';

  @override
  String get tagWork => 'work';

  @override
  String get tagSport => 'sport';

  @override
  String get tagSummer => 'summer';

  @override
  String get tagWinter => 'winter';

  @override
  String get itemNotFound => 'Item not found';

  @override
  String get itemNotFoundMessage => 'This item has been removed.';

  @override
  String get itemOutfitsTitle => 'Outfits featuring this item';

  @override
  String get itemStatsTimesWorn => 'Times worn';

  @override
  String get itemStatsLastWorn => 'Last worn';

  @override
  String get itemStatsCostPerWear => 'Cost per wear';

  @override
  String get itemStatsNever => 'Never';

  @override
  String get itemStatsNotWornYet => 'Not worn yet';

  @override
  String get itemStatsToday => 'Today';

  @override
  String get itemStatsYesterday => 'Yesterday';

  @override
  String itemStatsDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String itemStatsWeeksAgo(int weeks) {
    return '${weeks}w ago';
  }

  @override
  String itemStatsMonthsAgo(int months) {
    return '${months}mo ago';
  }

  @override
  String get itemDeleteTitle => 'Remove Item';

  @override
  String itemDeleteMessage(String name) {
    return 'Remove \"$name\" from your wardrobe?';
  }

  @override
  String get itemDeleteCancel => 'Cancel';

  @override
  String get itemDeleteConfirm => 'Remove';

  @override
  String get settingsLuckyColorBirthProfile => 'Birth profile';

  @override
  String get settingsLuckyColorBirthProfileSubtitle =>
      'Uses your saved birth date and weekday.';

  @override
  String get settingsLuckyColorRandomDaily => 'Random daily';

  @override
  String get settingsLuckyColorRandomDailySubtitle =>
      'Uses a stable daily color set without profile data.';

  @override
  String get settingsWeatherAutoDetect => 'Auto-detect';

  @override
  String get settingsWeatherAutoDetectSubtitle =>
      'Uses device location when weather matching is enabled.';

  @override
  String get settingsWeatherOff => 'Off';

  @override
  String get settingsWeatherOffSubtitle =>
      'Outfit generation will skip weather matching.';

  @override
  String get settingsPrivacyContent =>
      'Guest profile and wardrobe data stay on this device. Signed-in accounts store wardrobe, outfit, and preference data in Supabase. The app contains public Supabase configuration, while privileged API keys and secrets remain server-side.';

  @override
  String get dialogClose => 'Close';
}
