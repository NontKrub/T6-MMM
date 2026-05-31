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
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authContinueAsGuest => 'Continue as guest';

  @override
  String get authUnavailable =>
      'Sign in is unavailable until Supabase is configured.';

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
  String get chatStatusUnlocked => 'Always styled';

  @override
  String get chatInputHint => 'Ask about fashion…';

  @override
  String get chatLockedTitle => 'Fashion AI needs a login';

  @override
  String get chatLockedMessage =>
      'Chat uses your saved wardrobe and backend AI. Continue with Google after Supabase is configured.';

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
  String get settingsRepetitionAlerts => 'Repetition alerts';

  @override
  String get settingsAI => 'AI Features';

  @override
  String get settingsLearnPreferences => 'Learn my preferences';

  @override
  String get settingsLearnPreferencesSubtitle =>
      'AI tracks your choices to improve suggestions';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsVersionValue => '1.0.0 (build 1)';

  @override
  String get settingsPrivacy => 'Privacy Policy';

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
}
