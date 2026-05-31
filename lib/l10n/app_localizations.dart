import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('th'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Mix Match Mood'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'match your wardrobe to your mood'**
  String get appTagline;

  /// No description provided for @languageScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get languageScreenTitle;

  /// No description provided for @languageScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'เลือกภาษา'**
  String get languageScreenSubtitle;

  /// No description provided for @languageContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get languageContinue;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageThai.
  ///
  /// In en, this message translates to:
  /// **'ภาษาไทย'**
  String get languageThai;

  /// No description provided for @authHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your wardrobe,\nreimagined.'**
  String get authHeroTitle;

  /// No description provided for @authHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI-powered outfit suggestions,\npersonalized just for you.'**
  String get authHeroSubtitle;

  /// No description provided for @authGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get authGetStarted;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authContinueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get authContinueAsGuest;

  /// No description provided for @authUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sign in is unavailable until Supabase is configured.'**
  String get authUnavailable;

  /// No description provided for @onboardingStep.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String onboardingStep(int current, int total);

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter MMM'**
  String get onboardingEnter;

  /// No description provided for @onboardingUserInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about you'**
  String get onboardingUserInfoTitle;

  /// No description provided for @onboardingUserInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We use this to personalise your experience.'**
  String get onboardingUserInfoSubtitle;

  /// No description provided for @onboardingYourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get onboardingYourName;

  /// No description provided for @onboardingNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Alex'**
  String get onboardingNameHint;

  /// No description provided for @onboardingDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get onboardingDateOfBirth;

  /// No description provided for @onboardingSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get onboardingSelectDate;

  /// No description provided for @onboardingDobHint.
  ///
  /// In en, this message translates to:
  /// **'Optional — helps us tailor lucky colour predictions.'**
  String get onboardingDobHint;

  /// No description provided for @onboardingStyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Your style & build'**
  String get onboardingStyleTitle;

  /// No description provided for @onboardingStyleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your body type and the vibes that resonate.'**
  String get onboardingStyleSubtitle;

  /// No description provided for @onboardingBodyType.
  ///
  /// In en, this message translates to:
  /// **'BODY TYPE'**
  String get onboardingBodyType;

  /// No description provided for @onboardingStyleVibes.
  ///
  /// In en, this message translates to:
  /// **'STYLE VIBES'**
  String get onboardingStyleVibes;

  /// No description provided for @onboardingStyleVibesHint.
  ///
  /// In en, this message translates to:
  /// **'Pick everything that resonates.'**
  String get onboardingStyleVibesHint;

  /// No description provided for @onboardingColorSeasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Your color season'**
  String get onboardingColorSeasonTitle;

  /// No description provided for @onboardingColorSeasonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Determines which color palette flatters you most.'**
  String get onboardingColorSeasonSubtitle;

  /// No description provided for @onboardingLifestyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Your lifestyle'**
  String get onboardingLifestyleTitle;

  /// No description provided for @onboardingLifestyleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What occasions do you dress for?'**
  String get onboardingLifestyleSubtitle;

  /// No description provided for @bodyTypeStraight.
  ///
  /// In en, this message translates to:
  /// **'Straight'**
  String get bodyTypeStraight;

  /// No description provided for @bodyTypeHourglass.
  ///
  /// In en, this message translates to:
  /// **'Hourglass'**
  String get bodyTypeHourglass;

  /// No description provided for @bodyTypePear.
  ///
  /// In en, this message translates to:
  /// **'Pear'**
  String get bodyTypePear;

  /// No description provided for @bodyTypeApple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get bodyTypeApple;

  /// No description provided for @bodyTypeAthletic.
  ///
  /// In en, this message translates to:
  /// **'Athletic'**
  String get bodyTypeAthletic;

  /// No description provided for @styleVibesCasual.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get styleVibesCasual;

  /// No description provided for @styleVibesMinimalist.
  ///
  /// In en, this message translates to:
  /// **'Minimalist'**
  String get styleVibesMinimalist;

  /// No description provided for @styleVibesStreetwear.
  ///
  /// In en, this message translates to:
  /// **'Streetwear'**
  String get styleVibesStreetwear;

  /// No description provided for @styleVibesFormal.
  ///
  /// In en, this message translates to:
  /// **'Formal'**
  String get styleVibesFormal;

  /// No description provided for @styleVibesVintage.
  ///
  /// In en, this message translates to:
  /// **'Vintage'**
  String get styleVibesVintage;

  /// No description provided for @styleVibesY2K.
  ///
  /// In en, this message translates to:
  /// **'Y2K'**
  String get styleVibesY2K;

  /// No description provided for @styleVibesCottagecore.
  ///
  /// In en, this message translates to:
  /// **'Cottagecore'**
  String get styleVibesCottagecore;

  /// No description provided for @styleVibesPreppy.
  ///
  /// In en, this message translates to:
  /// **'Preppy'**
  String get styleVibesPreppy;

  /// No description provided for @styleVibesBohemian.
  ///
  /// In en, this message translates to:
  /// **'Bohemian'**
  String get styleVibesBohemian;

  /// No description provided for @styleVibesAthleisure.
  ///
  /// In en, this message translates to:
  /// **'Athleisure'**
  String get styleVibesAthleisure;

  /// No description provided for @styleVibesDarkAcademia.
  ///
  /// In en, this message translates to:
  /// **'Dark Academia'**
  String get styleVibesDarkAcademia;

  /// No description provided for @styleVibesCleanGirl.
  ///
  /// In en, this message translates to:
  /// **'Clean Girl'**
  String get styleVibesCleanGirl;

  /// No description provided for @seasonSpring.
  ///
  /// In en, this message translates to:
  /// **'Spring'**
  String get seasonSpring;

  /// No description provided for @seasonSummer.
  ///
  /// In en, this message translates to:
  /// **'Summer'**
  String get seasonSummer;

  /// No description provided for @seasonAutumn.
  ///
  /// In en, this message translates to:
  /// **'Autumn'**
  String get seasonAutumn;

  /// No description provided for @seasonWinter.
  ///
  /// In en, this message translates to:
  /// **'Winter'**
  String get seasonWinter;

  /// No description provided for @occasionWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get occasionWork;

  /// No description provided for @occasionWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend'**
  String get occasionWeekend;

  /// No description provided for @occasionDates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get occasionDates;

  /// No description provided for @occasionSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get occasionSports;

  /// No description provided for @occasionEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get occasionEvents;

  /// No description provided for @occasionTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get occasionTravel;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navWardrobe.
  ///
  /// In en, this message translates to:
  /// **'Wardrobe'**
  String get navWardrobe;

  /// No description provided for @navMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get navMissing;

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @homeCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get homeCustomize;

  /// No description provided for @homeGenerateOutfit.
  ///
  /// In en, this message translates to:
  /// **'Generate Outfit'**
  String get homeGenerateOutfit;

  /// No description provided for @wardrobeTitle.
  ///
  /// In en, this message translates to:
  /// **'Wardrobe'**
  String get wardrobeTitle;

  /// No description provided for @wardrobeItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String wardrobeItemCount(int count);

  /// No description provided for @wardrobeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, brand, or tag…'**
  String get wardrobeSearchHint;

  /// No description provided for @wardrobeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your wardrobe is empty'**
  String get wardrobeEmpty;

  /// No description provided for @wardrobeEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first item'**
  String get wardrobeEmptyHint;

  /// No description provided for @wardrobeNoResults.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get wardrobeNoResults;

  /// No description provided for @missingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your wardrobe needs...'**
  String get missingTitle;

  /// No description provided for @missingSubtitleLocked.
  ///
  /// In en, this message translates to:
  /// **'Sign in to generate wardrobe gap recommendations'**
  String get missingSubtitleLocked;

  /// No description provided for @missingSubtitleUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Curated to fill the gaps in your collection'**
  String get missingSubtitleUnlocked;

  /// No description provided for @missingLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommendations need a login'**
  String get missingLockedTitle;

  /// No description provided for @missingLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Missing pieces use backend AI and your Supabase wardrobe. Guest accounts keep wardrobe data local only.'**
  String get missingLockedMessage;

  /// No description provided for @missingEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No recommendations yet'**
  String get missingEmptyTitle;

  /// No description provided for @missingEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'The backend did not return any missing pieces.'**
  String get missingEmptyMessage;

  /// No description provided for @missingErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not generate recommendations'**
  String get missingErrorTitle;

  /// No description provided for @missingWhyExpand.
  ///
  /// In en, this message translates to:
  /// **'Why?'**
  String get missingWhyExpand;

  /// No description provided for @missingWhyCollapse.
  ///
  /// In en, this message translates to:
  /// **'Hide reason'**
  String get missingWhyCollapse;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Fashion AI'**
  String get chatTitle;

  /// No description provided for @chatStatusLocked.
  ///
  /// In en, this message translates to:
  /// **'Sign in required'**
  String get chatStatusLocked;

  /// No description provided for @chatStatusUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Always styled'**
  String get chatStatusUnlocked;

  /// No description provided for @chatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask about fashion…'**
  String get chatInputHint;

  /// No description provided for @chatLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Fashion AI needs a login'**
  String get chatLockedTitle;

  /// No description provided for @chatLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Chat uses your saved wardrobe and backend AI. Continue with Google after Supabase is configured.'**
  String get chatLockedMessage;

  /// No description provided for @chatPrompt1.
  ///
  /// In en, this message translates to:
  /// **'What\'s my color season?'**
  String get chatPrompt1;

  /// No description provided for @chatPrompt2.
  ///
  /// In en, this message translates to:
  /// **'Name this style'**
  String get chatPrompt2;

  /// No description provided for @chatPrompt3.
  ///
  /// In en, this message translates to:
  /// **'Build a capsule wardrobe'**
  String get chatPrompt3;

  /// No description provided for @chatPrompt4.
  ///
  /// In en, this message translates to:
  /// **'Streetwear basics'**
  String get chatPrompt4;

  /// No description provided for @chatPrompt5.
  ///
  /// In en, this message translates to:
  /// **'Quiet luxury look'**
  String get chatPrompt5;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get profileItems;

  /// No description provided for @profileOutfits.
  ///
  /// In en, this message translates to:
  /// **'Outfits'**
  String get profileOutfits;

  /// No description provided for @profileFavItem.
  ///
  /// In en, this message translates to:
  /// **'Fav item'**
  String get profileFavItem;

  /// No description provided for @profileColorSeason.
  ///
  /// In en, this message translates to:
  /// **'Color Season'**
  String get profileColorSeason;

  /// No description provided for @profileStylePreferences.
  ///
  /// In en, this message translates to:
  /// **'Style Preferences'**
  String get profileStylePreferences;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get profileSignOut;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settingsDarkMode;

  /// No description provided for @settingsDarkModeOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingsDarkModeOn;

  /// No description provided for @settingsDarkModeOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsDarkModeOff;

  /// No description provided for @settingsPersonalization.
  ///
  /// In en, this message translates to:
  /// **'Personalization'**
  String get settingsPersonalization;

  /// No description provided for @settingsLuckyColor.
  ///
  /// In en, this message translates to:
  /// **'Lucky Color Method'**
  String get settingsLuckyColor;

  /// No description provided for @settingsLuckyColorValue.
  ///
  /// In en, this message translates to:
  /// **'Random daily'**
  String get settingsLuckyColorValue;

  /// No description provided for @settingsWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather Location'**
  String get settingsWeather;

  /// No description provided for @settingsWeatherValue.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect'**
  String get settingsWeatherValue;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsDailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily outfit reminder'**
  String get settingsDailyReminder;

  /// No description provided for @settingsRepetitionAlerts.
  ///
  /// In en, this message translates to:
  /// **'Repetition alerts'**
  String get settingsRepetitionAlerts;

  /// No description provided for @settingsAI.
  ///
  /// In en, this message translates to:
  /// **'AI Features'**
  String get settingsAI;

  /// No description provided for @settingsLearnPreferences.
  ///
  /// In en, this message translates to:
  /// **'Learn my preferences'**
  String get settingsLearnPreferences;

  /// No description provided for @settingsLearnPreferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI tracks your choices to improve suggestions'**
  String get settingsLearnPreferencesSubtitle;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsVersionValue.
  ///
  /// In en, this message translates to:
  /// **'1.0.0 (build 1)'**
  String get settingsVersionValue;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacy;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageValue.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageValue;

  /// No description provided for @avatarTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Avatar'**
  String get avatarTitle;

  /// No description provided for @avatarBodyShape.
  ///
  /// In en, this message translates to:
  /// **'Body Shape'**
  String get avatarBodyShape;

  /// No description provided for @avatarHairStyle.
  ///
  /// In en, this message translates to:
  /// **'Hair Style'**
  String get avatarHairStyle;

  /// No description provided for @avatarSkinTone.
  ///
  /// In en, this message translates to:
  /// **'Skin Tone'**
  String get avatarSkinTone;

  /// No description provided for @avatarHair.
  ///
  /// In en, this message translates to:
  /// **'Hair'**
  String get avatarHair;

  /// No description provided for @avatarDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get avatarDone;

  /// No description provided for @avatarHuman.
  ///
  /// In en, this message translates to:
  /// **'Human'**
  String get avatarHuman;

  /// No description provided for @avatarDog.
  ///
  /// In en, this message translates to:
  /// **'Dog'**
  String get avatarDog;

  /// No description provided for @avatarCat.
  ///
  /// In en, this message translates to:
  /// **'Cat'**
  String get avatarCat;

  /// No description provided for @avatarFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get avatarFemale;

  /// No description provided for @avatarMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get avatarMale;

  /// No description provided for @avatarHairBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get avatarHairBlack;

  /// No description provided for @avatarHairDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get avatarHairDark;

  /// No description provided for @avatarHairBrown.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get avatarHairBrown;

  /// No description provided for @avatarHairBlonde.
  ///
  /// In en, this message translates to:
  /// **'Blonde'**
  String get avatarHairBlonde;

  /// No description provided for @avatarHairAuburn.
  ///
  /// In en, this message translates to:
  /// **'Auburn'**
  String get avatarHairAuburn;

  /// No description provided for @avatarHairPlatinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get avatarHairPlatinum;

  /// No description provided for @avatarHairTousled.
  ///
  /// In en, this message translates to:
  /// **'Tousled'**
  String get avatarHairTousled;

  /// No description provided for @avatarHairSideSwept.
  ///
  /// In en, this message translates to:
  /// **'Side Swept'**
  String get avatarHairSideSwept;

  /// No description provided for @avatarHairUndercut.
  ///
  /// In en, this message translates to:
  /// **'Undercut'**
  String get avatarHairUndercut;

  /// No description provided for @avatarHairLong.
  ///
  /// In en, this message translates to:
  /// **'Long'**
  String get avatarHairLong;

  /// No description provided for @avatarHairPonytail.
  ///
  /// In en, this message translates to:
  /// **'Ponytail'**
  String get avatarHairPonytail;

  /// No description provided for @avatarHairBob.
  ///
  /// In en, this message translates to:
  /// **'Bob'**
  String get avatarHairBob;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
