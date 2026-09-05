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

  /// No description provided for @welcomeLanguageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get welcomeLanguageTooltip;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Mix Match Mood'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your wardrobe, mixed around your mood.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeValueProp.
  ///
  /// In en, this message translates to:
  /// **'Build outfits from the clothes you already own.'**
  String get welcomeValueProp;

  /// No description provided for @welcomeCreate.
  ///
  /// In en, this message translates to:
  /// **'Create my wardrobe'**
  String get welcomeCreate;

  /// No description provided for @welcomeSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get welcomeSignIn;

  /// No description provided for @welcomeLocalNote.
  ///
  /// In en, this message translates to:
  /// **'Your local wardrobe stays on this device until you choose to sign in.'**
  String get welcomeLocalNote;

  /// No description provided for @welcomeAuthTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeAuthTitle;

  /// No description provided for @welcomeAuthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your wardrobe is waiting.'**
  String get welcomeAuthSubtitle;

  /// No description provided for @welcomeNewToMmm.
  ///
  /// In en, this message translates to:
  /// **'New to MMM? Create a wardrobe'**
  String get welcomeNewToMmm;

  /// No description provided for @welcomeTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get welcomeTerms;

  /// No description provided for @welcomePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get welcomePrivacy;

  /// No description provided for @legalLinkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'This link could not be opened. Check your connection and try again.'**
  String get legalLinkOpenFailed;

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to MMM'**
  String get authSignInTitle;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Access your wardrobe across supported cloud features.'**
  String get authSignInSubtitle;

  /// No description provided for @authUnlockAiTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to use Fashion AI'**
  String get authUnlockAiTitle;

  /// No description provided for @authUnlockAiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect an account to use MMM Stylist with cloud AI features.'**
  String get authUnlockAiSubtitle;

  /// No description provided for @authBackToChat.
  ///
  /// In en, this message translates to:
  /// **'Back to Chat'**
  String get authBackToChat;

  /// No description provided for @authBackToWelcome.
  ///
  /// In en, this message translates to:
  /// **'Back to welcome'**
  String get authBackToWelcome;

  /// No description provided for @authBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get authBack;

  /// No description provided for @authExternalPending.
  ///
  /// In en, this message translates to:
  /// **'Continue in the browser to finish signing in.'**
  String get authExternalPending;

  /// No description provided for @authImportWarningsTitle.
  ///
  /// In en, this message translates to:
  /// **'Wardrobe imported with warnings'**
  String get authImportWarningsTitle;

  /// No description provided for @authImportingGuest.
  ///
  /// In en, this message translates to:
  /// **'Importing local wardrobe…'**
  String get authImportingGuest;

  /// No description provided for @authRetryMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign in could not be completed. Please try again.'**
  String get authRetryMessage;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading Mix Match Mood'**
  String get splashLoading;

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

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get commonSettings;

  /// No description provided for @commonProfile.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get commonProfile;

  /// No description provided for @commonAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get commonAddItem;

  /// No description provided for @commonClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get commonClearSearch;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

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

  /// No description provided for @authContinueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authContinueWithApple;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authContinueWithFacebook.
  ///
  /// In en, this message translates to:
  /// **'Continue with Facebook'**
  String get authContinueWithFacebook;

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

  /// No description provided for @authImportGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Import your guest wardrobe?'**
  String get authImportGuestTitle;

  /// No description provided for @authImportGuestMessage.
  ///
  /// In en, this message translates to:
  /// **'MMM found a local guest wardrobe. Import it into this signed-in account?'**
  String get authImportGuestMessage;

  /// No description provided for @authImportGuest.
  ///
  /// In en, this message translates to:
  /// **'Import wardrobe'**
  String get authImportGuest;

  /// No description provided for @authContinueWithoutImport.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get authContinueWithoutImport;

  /// No description provided for @authImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Local wardrobe import failed'**
  String get authImportFailed;

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

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeGreetingGeneric.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGreetingGeneric;

  /// No description provided for @homePrompt.
  ///
  /// In en, this message translates to:
  /// **'What are we wearing today?'**
  String get homePrompt;

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

  /// No description provided for @wardrobeNoResultsHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different name, brand, or tag.'**
  String get wardrobeNoResultsHint;

  /// No description provided for @wardrobeEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your wardrobe is ready for its first piece.'**
  String get wardrobeEmptyMessage;

  /// No description provided for @wardrobeEmptyAdd.
  ///
  /// In en, this message translates to:
  /// **'Add an item'**
  String get wardrobeEmptyAdd;

  /// No description provided for @wardrobeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get wardrobeAll;

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

  /// No description provided for @missingTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get missingTop;

  /// No description provided for @missingBottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get missingBottom;

  /// No description provided for @missingChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose {label}'**
  String missingChoose(String label);

  /// No description provided for @missingAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze the gap'**
  String get missingAnalyze;

  /// No description provided for @missingLoading.
  ///
  /// In en, this message translates to:
  /// **'Finding the gap…'**
  String get missingLoading;

  /// No description provided for @missingTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again in a moment.'**
  String get missingTryAgain;

  /// No description provided for @missingAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Add {category}'**
  String missingAddCategory(String category);

  /// No description provided for @missingSelectionShoesTitle.
  ///
  /// In en, this message translates to:
  /// **'Add neutral shoes'**
  String get missingSelectionShoesTitle;

  /// No description provided for @missingReasonCategory.
  ///
  /// In en, this message translates to:
  /// **'Your wardrobe needs this category for complete outfits.'**
  String get missingReasonCategory;

  /// No description provided for @missingSuggestionNeutral.
  ///
  /// In en, this message translates to:
  /// **'Choose a versatile neutral piece you will wear often.'**
  String get missingSuggestionNeutral;

  /// No description provided for @missingSelectionShoesReason.
  ///
  /// In en, this message translates to:
  /// **'Your selected top and pants need shoes to complete the outfit.'**
  String get missingSelectionShoesReason;

  /// No description provided for @missingSelectionShoesSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Try white, black, gray, beige, or brown footwear.'**
  String get missingSelectionShoesSuggestion;

  /// No description provided for @missingReasonPattern.
  ///
  /// In en, this message translates to:
  /// **'A simple piece balances the selected patterns.'**
  String get missingReasonPattern;

  /// No description provided for @missingReasonColors.
  ///
  /// In en, this message translates to:
  /// **'Its colors and style fit the selected top and pants.'**
  String get missingReasonColors;

  /// No description provided for @missingSuggestionBalanced.
  ///
  /// In en, this message translates to:
  /// **'This neutral piece keeps the outfit balanced.'**
  String get missingSuggestionBalanced;

  /// No description provided for @missingSuggestionAccent.
  ///
  /// In en, this message translates to:
  /// **'Use this piece as the outfit accent.'**
  String get missingSuggestionAccent;

  /// No description provided for @missingAccessoryReason.
  ///
  /// In en, this message translates to:
  /// **'Your base wardrobe is complete but has no finishing piece.'**
  String get missingAccessoryReason;

  /// No description provided for @missingAccessorySuggestion.
  ///
  /// In en, this message translates to:
  /// **'Try a neutral belt, bag, watch, or scarf.'**
  String get missingAccessorySuggestion;

  /// No description provided for @missingTryItem.
  ///
  /// In en, this message translates to:
  /// **'Try {name}'**
  String missingTryItem(String name);

  /// No description provided for @missingPriorityEssential.
  ///
  /// In en, this message translates to:
  /// **'Essential'**
  String get missingPriorityEssential;

  /// No description provided for @missingPriorityRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get missingPriorityRecommended;

  /// No description provided for @missingPriorityNiceToHave.
  ///
  /// In en, this message translates to:
  /// **'Nice to have'**
  String get missingPriorityNiceToHave;

  /// No description provided for @missingPriorityHighImpact.
  ///
  /// In en, this message translates to:
  /// **'High impact'**
  String get missingPriorityHighImpact;

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

  /// No description provided for @chatStatusConsentRequired.
  ///
  /// In en, this message translates to:
  /// **'Consent required'**
  String get chatStatusConsentRequired;

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

  /// No description provided for @chatConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Fashion AI needs your consent'**
  String get chatConsentTitle;

  /// No description provided for @chatConsentMessage.
  ///
  /// In en, this message translates to:
  /// **'Allow MMM to send wardrobe images and metadata, fashion questions, and limited style-profile information such as your color season to its configured AI provider. You can revoke this permission in Settings.'**
  String get chatConsentMessage;

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

  /// No description provided for @chatSend.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get chatSend;

  /// No description provided for @chatRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get chatRetry;

  /// No description provided for @chatThinking.
  ///
  /// In en, this message translates to:
  /// **'MMM is thinking…'**
  String get chatThinking;

  /// No description provided for @chatSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get chatSignIn;

  /// No description provided for @chatReviewConsent.
  ///
  /// In en, this message translates to:
  /// **'Review AI permissions'**
  String get chatReviewConsent;

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

  /// No description provided for @profileDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get profileDeleteAccount;

  /// No description provided for @profileDeleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get profileDeleteAccountTitle;

  /// No description provided for @profileDeleteAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes your profile, wardrobe images, outfits, and activity from MMM.'**
  String get profileDeleteAccountMessage;

  /// No description provided for @profileDeleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get profileDeleteAccountConfirm;

  /// No description provided for @profileDeleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Account deletion failed'**
  String get profileDeleteAccountFailed;

  /// No description provided for @profileAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccount;

  /// No description provided for @profileDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get profileDangerZone;

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

  /// No description provided for @settingsNotificationsPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled. MMM will continue without reminders.'**
  String get settingsNotificationsPermissionDenied;

  /// No description provided for @settingsRepetitionAlerts.
  ///
  /// In en, this message translates to:
  /// **'Repetition alerts'**
  String get settingsRepetitionAlerts;

  /// No description provided for @settingsImportLocal.
  ///
  /// In en, this message translates to:
  /// **'Import local wardrobe'**
  String get settingsImportLocal;

  /// No description provided for @settingsImportLocalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Resume importing your guest wardrobe'**
  String get settingsImportLocalSubtitle;

  /// No description provided for @settingsImportLocalComplete.
  ///
  /// In en, this message translates to:
  /// **'Local wardrobe imported.'**
  String get settingsImportLocalComplete;

  /// No description provided for @settingsImportLocalFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get settingsImportLocalFailed;

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

  /// No description provided for @settingsAIConsent.
  ///
  /// In en, this message translates to:
  /// **'Third-party AI analysis'**
  String get settingsAIConsent;

  /// No description provided for @settingsAIConsentGranted.
  ///
  /// In en, this message translates to:
  /// **'Allowed — revoke anytime'**
  String get settingsAIConsentGranted;

  /// No description provided for @settingsAIConsentOff.
  ///
  /// In en, this message translates to:
  /// **'Off — local and deterministic fallbacks stay available'**
  String get settingsAIConsentOff;

  /// No description provided for @settingsAIConsentSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage third-party AI consent'**
  String get settingsAIConsentSignIn;

  /// No description provided for @settingsAIConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow third-party AI?'**
  String get settingsAIConsentTitle;

  /// No description provided for @settingsAIConsentMessage.
  ///
  /// In en, this message translates to:
  /// **'MMM may send wardrobe images and metadata, fashion questions, and limited style-profile information such as your color season to the configured AI provider for analysis and recommendations. This is optional and can be revoked in Settings.'**
  String get settingsAIConsentMessage;

  /// No description provided for @settingsAIConsentAccept.
  ///
  /// In en, this message translates to:
  /// **'Allow AI analysis'**
  String get settingsAIConsentAccept;

  /// No description provided for @settingsAIConsentFailed.
  ///
  /// In en, this message translates to:
  /// **'AI permission could not be updated. Please try again.'**
  String get settingsAIConsentFailed;

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
  /// **'—'**
  String get settingsVersionValue;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacyNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'A public HTTPS privacy-policy URL has not been configured yet.'**
  String get settingsPrivacyNotConfigured;

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

  /// No description provided for @repetitionStyleReminder.
  ///
  /// In en, this message translates to:
  /// **'Style reminder'**
  String get repetitionStyleReminder;

  /// No description provided for @repetitionMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been wearing {color} tones frequently. Try mixing in something different today!'**
  String repetitionMessage(String color);

  /// No description provided for @outfitGeneratorTitle.
  ///
  /// In en, this message translates to:
  /// **'Generate Outfit'**
  String get outfitGeneratorTitle;

  /// No description provided for @outfitGeneratorStyleLabel.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get outfitGeneratorStyleLabel;

  /// No description provided for @outfitGeneratorFiltersLabel.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get outfitGeneratorFiltersLabel;

  /// No description provided for @outfitGeneratorUsePersonalColor.
  ///
  /// In en, this message translates to:
  /// **'Use my personal color season'**
  String get outfitGeneratorUsePersonalColor;

  /// No description provided for @outfitGeneratorLuckyColor.
  ///
  /// In en, this message translates to:
  /// **'Today\'s lucky color'**
  String get outfitGeneratorLuckyColor;

  /// No description provided for @outfitGeneratorMatchWeather.
  ///
  /// In en, this message translates to:
  /// **'Match weather'**
  String get outfitGeneratorMatchWeather;

  /// No description provided for @outfitGeneratorWeatherOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on Weather Location in Settings'**
  String get outfitGeneratorWeatherOff;

  /// No description provided for @outfitGeneratorWeatherAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect location'**
  String get outfitGeneratorWeatherAuto;

  /// No description provided for @outfitGeneratorGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get outfitGeneratorGenerating;

  /// No description provided for @outfitGeneratorGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get outfitGeneratorGenerate;

  /// No description provided for @outfitGeneratorResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get outfitGeneratorResults;

  /// No description provided for @outfitGeneratorLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'AI outfit generation needs a login'**
  String get outfitGeneratorLockedTitle;

  /// No description provided for @outfitGeneratorLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Guest wardrobes stay local. Sign in with Supabase to generate real outfits, weather matches, and lucky color looks.'**
  String get outfitGeneratorLockedMessage;

  /// No description provided for @outfitGeneratorNoOutfits.
  ///
  /// In en, this message translates to:
  /// **'No outfits were generated.'**
  String get outfitGeneratorNoOutfits;

  /// No description provided for @outfitGeneratorErrorNotDeployed.
  ///
  /// In en, this message translates to:
  /// **'Outfit generation is not deployed yet. Please try again after the backend is updated.'**
  String get outfitGeneratorErrorNotDeployed;

  /// No description provided for @outfitGeneratorErrorNeedWardrobe.
  ///
  /// In en, this message translates to:
  /// **'Add at least one top, one bottom, and one pair of shoes first.'**
  String get outfitGeneratorErrorNeedWardrobe;

  /// No description provided for @outfitGeneratorErrorLocationPermission.
  ///
  /// In en, this message translates to:
  /// **'Location permission is needed to match the weather.'**
  String get outfitGeneratorErrorLocationPermission;

  /// No description provided for @outfitGeneratorErrorLocationOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services to match the weather.'**
  String get outfitGeneratorErrorLocationOff;

  /// No description provided for @outfitGeneratorErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not generate outfits. Please try again.'**
  String get outfitGeneratorErrorGeneric;

  /// No description provided for @outfitStyleCasual.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get outfitStyleCasual;

  /// No description provided for @outfitStyleWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get outfitStyleWork;

  /// No description provided for @outfitStyleFormal.
  ///
  /// In en, this message translates to:
  /// **'Formal'**
  String get outfitStyleFormal;

  /// No description provided for @outfitStyleSport.
  ///
  /// In en, this message translates to:
  /// **'Sport'**
  String get outfitStyleSport;

  /// No description provided for @outfitStyleDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get outfitStyleDate;

  /// No description provided for @outfitRepeatTitle.
  ///
  /// In en, this message translates to:
  /// **'Repeat outfit'**
  String get outfitRepeatTitle;

  /// No description provided for @outfitRepeatMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ve worn this combination {count} times.'**
  String outfitRepeatMessage(int count);

  /// No description provided for @outfitGenerateAnother.
  ///
  /// In en, this message translates to:
  /// **'Generate another'**
  String get outfitGenerateAnother;

  /// No description provided for @outfitWearAnyway.
  ///
  /// In en, this message translates to:
  /// **'Wear anyway'**
  String get outfitWearAnyway;

  /// No description provided for @outfitWear.
  ///
  /// In en, this message translates to:
  /// **'Wear'**
  String get outfitWear;

  /// No description provided for @outfitTargetColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Optional outfit color (HEX)'**
  String get outfitTargetColorLabel;

  /// No description provided for @outfitTargetColorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid HEX color such as #3366FF.'**
  String get outfitTargetColorInvalid;

  /// No description provided for @outfitSignInColor.
  ///
  /// In en, this message translates to:
  /// **'Sign in to use profile color season'**
  String get outfitSignInColor;

  /// No description provided for @rushTitle.
  ///
  /// In en, this message translates to:
  /// **'In a Rush'**
  String get rushTitle;

  /// No description provided for @rushStatusSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in required'**
  String get rushStatusSignInRequired;

  /// No description provided for @rushStatusNeedsSetup.
  ///
  /// In en, this message translates to:
  /// **'Needs a little setup'**
  String get rushStatusNeedsSetup;

  /// No description provided for @rushStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Your outfit is ready'**
  String get rushStatusReady;

  /// No description provided for @rushLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Rush outfit uses backend AI. Sign in with Supabase to use it.'**
  String get rushLockedMessage;

  /// No description provided for @rushDefaultReason.
  ///
  /// In en, this message translates to:
  /// **'Fast practical pick from your wardrobe.'**
  String get rushDefaultReason;

  /// No description provided for @rushReshuffle.
  ///
  /// In en, this message translates to:
  /// **'Reshuffle'**
  String get rushReshuffle;

  /// No description provided for @rushSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get rushSignIn;

  /// No description provided for @rushGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got It'**
  String get rushGotIt;

  /// No description provided for @rushWearThis.
  ///
  /// In en, this message translates to:
  /// **'Wear This'**
  String get rushWearThis;

  /// No description provided for @rushErrorNeedWardrobe.
  ///
  /// In en, this message translates to:
  /// **'Rush outfits need a complete wardrobe first. Add at least one top, one bottom, and one pair of shoes.'**
  String get rushErrorNeedWardrobe;

  /// No description provided for @rushErrorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No compatible rush outfit is available. Add shoes and a top + bottom or a dress.'**
  String get rushErrorUnavailable;

  /// No description provided for @rushErrorSignIn.
  ///
  /// In en, this message translates to:
  /// **'Rush outfit uses your saved backend wardrobe. Sign in to use it.'**
  String get rushErrorSignIn;

  /// No description provided for @rushErrorNotDeployed.
  ///
  /// In en, this message translates to:
  /// **'Rush outfit is not deployed yet. Please try again after the backend is updated.'**
  String get rushErrorNotDeployed;

  /// No description provided for @rushErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not pick a rush outfit right now. Check your wardrobe and try again.'**
  String get rushErrorGeneric;

  /// No description provided for @addItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItemTitle;

  /// No description provided for @addItemCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get addItemCategory;

  /// No description provided for @addItemNameHint.
  ///
  /// In en, this message translates to:
  /// **'Item name (e.g. White Linen Shirt)'**
  String get addItemNameHint;

  /// No description provided for @addItemBrandHint.
  ///
  /// In en, this message translates to:
  /// **'Brand (optional)'**
  String get addItemBrandHint;

  /// No description provided for @addItemTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get addItemTags;

  /// No description provided for @addItemSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get addItemSaving;

  /// No description provided for @addItemSave.
  ///
  /// In en, this message translates to:
  /// **'Save to Wardrobe'**
  String get addItemSave;

  /// No description provided for @addItemCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get addItemCamera;

  /// No description provided for @addItemPhotoLibrary.
  ///
  /// In en, this message translates to:
  /// **'Photo Library'**
  String get addItemPhotoLibrary;

  /// No description provided for @addItemTapToAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to add photo'**
  String get addItemTapToAddPhoto;

  /// No description provided for @addItemCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category: {category}'**
  String addItemCategoryLabel(String category);

  /// No description provided for @addItemAnalysisReading.
  ///
  /// In en, this message translates to:
  /// **'MMM is reading this piece…'**
  String get addItemAnalysisReading;

  /// No description provided for @addItemAnalysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Image analysis failed. You can still tag this item manually.'**
  String get addItemAnalysisFailed;

  /// No description provided for @addItemPhotoRequired.
  ///
  /// In en, this message translates to:
  /// **'Please add a photo before saving.'**
  String get addItemPhotoRequired;

  /// No description provided for @addItemCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a category before saving.'**
  String get addItemCategoryRequired;

  /// No description provided for @addItemDetectedColors.
  ///
  /// In en, this message translates to:
  /// **'Detected colors'**
  String get addItemDetectedColors;

  /// No description provided for @addItemNoColors.
  ///
  /// In en, this message translates to:
  /// **'No colors selected'**
  String get addItemNoColors;

  /// No description provided for @addItemAddHex.
  ///
  /// In en, this message translates to:
  /// **'Add custom HEX'**
  String get addItemAddHex;

  /// No description provided for @addItemPattern.
  ///
  /// In en, this message translates to:
  /// **'Pattern'**
  String get addItemPattern;

  /// No description provided for @addItemSilhouette.
  ///
  /// In en, this message translates to:
  /// **'Silhouette'**
  String get addItemSilhouette;

  /// No description provided for @addItemSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save item. Try again.'**
  String get addItemSaveFailed;

  /// No description provided for @addItemInvalidHex.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid HEX color such as #3366FF.'**
  String get addItemInvalidHex;

  /// No description provided for @addItemRecoveryFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t recover the last photo. Please choose it again.'**
  String get addItemRecoveryFailed;

  /// No description provided for @addItemCameraOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the camera. Try again or choose a photo.'**
  String get addItemCameraOpenFailed;

  /// No description provided for @addItemPhotoLibraryOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open your photo library. Try again.'**
  String get addItemPhotoLibraryOpenFailed;

  /// No description provided for @addItemImagePathUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This image isn\'t available. Please try again.'**
  String get addItemImagePathUnavailable;

  /// No description provided for @addItemPhotoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'That photo is no longer available. Please choose another.'**
  String get addItemPhotoUnavailable;

  /// No description provided for @addItemCameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is off. Enable it in Settings or choose a photo instead.'**
  String get addItemCameraPermissionDenied;

  /// No description provided for @addItemPhotoPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Photo access is off. Enable it in Settings or choose another photo.'**
  String get addItemPhotoPermissionDenied;

  /// No description provided for @addItemCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t capture a photo. Please try again.'**
  String get addItemCaptureFailed;

  /// No description provided for @addItemSelectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t select that photo. Please try again.'**
  String get addItemSelectionFailed;

  /// No description provided for @clothingCategoryHat.
  ///
  /// In en, this message translates to:
  /// **'Hat'**
  String get clothingCategoryHat;

  /// No description provided for @clothingCategoryTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get clothingCategoryTop;

  /// No description provided for @clothingCategoryPants.
  ///
  /// In en, this message translates to:
  /// **'Pants'**
  String get clothingCategoryPants;

  /// No description provided for @clothingCategoryShoes.
  ///
  /// In en, this message translates to:
  /// **'Shoes'**
  String get clothingCategoryShoes;

  /// No description provided for @clothingCategoryOuterwear.
  ///
  /// In en, this message translates to:
  /// **'Outerwear'**
  String get clothingCategoryOuterwear;

  /// No description provided for @clothingCategoryDress.
  ///
  /// In en, this message translates to:
  /// **'Dress'**
  String get clothingCategoryDress;

  /// No description provided for @clothingCategoryBag.
  ///
  /// In en, this message translates to:
  /// **'Bag'**
  String get clothingCategoryBag;

  /// No description provided for @clothingCategoryAccessory.
  ///
  /// In en, this message translates to:
  /// **'Accessory'**
  String get clothingCategoryAccessory;

  /// No description provided for @clothingCategoryUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get clothingCategoryUnknown;

  /// No description provided for @tagCasual.
  ///
  /// In en, this message translates to:
  /// **'casual'**
  String get tagCasual;

  /// No description provided for @tagFormal.
  ///
  /// In en, this message translates to:
  /// **'formal'**
  String get tagFormal;

  /// No description provided for @tagWork.
  ///
  /// In en, this message translates to:
  /// **'work'**
  String get tagWork;

  /// No description provided for @tagSport.
  ///
  /// In en, this message translates to:
  /// **'sport'**
  String get tagSport;

  /// No description provided for @tagSummer.
  ///
  /// In en, this message translates to:
  /// **'summer'**
  String get tagSummer;

  /// No description provided for @tagWinter.
  ///
  /// In en, this message translates to:
  /// **'winter'**
  String get tagWinter;

  /// No description provided for @itemNotFound.
  ///
  /// In en, this message translates to:
  /// **'Item not found'**
  String get itemNotFound;

  /// No description provided for @itemNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This item has been removed.'**
  String get itemNotFoundMessage;

  /// No description provided for @itemOutfitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Outfits featuring this item'**
  String get itemOutfitsTitle;

  /// No description provided for @itemStatsTimesWorn.
  ///
  /// In en, this message translates to:
  /// **'Times worn'**
  String get itemStatsTimesWorn;

  /// No description provided for @itemStatsLastWorn.
  ///
  /// In en, this message translates to:
  /// **'Last worn'**
  String get itemStatsLastWorn;

  /// No description provided for @itemStatsCostPerWear.
  ///
  /// In en, this message translates to:
  /// **'Cost per wear'**
  String get itemStatsCostPerWear;

  /// No description provided for @itemStatsNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get itemStatsNever;

  /// No description provided for @itemStatsNotWornYet.
  ///
  /// In en, this message translates to:
  /// **'Not worn yet'**
  String get itemStatsNotWornYet;

  /// No description provided for @itemStatsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get itemStatsToday;

  /// No description provided for @itemStatsYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get itemStatsYesterday;

  /// No description provided for @itemStatsDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String itemStatsDaysAgo(int days);

  /// No description provided for @itemStatsWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{weeks}w ago'**
  String itemStatsWeeksAgo(int weeks);

  /// No description provided for @itemStatsMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{months}mo ago'**
  String itemStatsMonthsAgo(int months);

  /// No description provided for @itemDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Item'**
  String get itemDeleteTitle;

  /// No description provided for @itemDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from your wardrobe?'**
  String itemDeleteMessage(String name);

  /// No description provided for @itemDeleteCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get itemDeleteCancel;

  /// No description provided for @itemDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get itemDeleteConfirm;

  /// No description provided for @itemMoreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get itemMoreActions;

  /// No description provided for @itemRetryAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Retry analysis'**
  String get itemRetryAnalysis;

  /// No description provided for @itemAnalysisUpdated.
  ///
  /// In en, this message translates to:
  /// **'Analysis updated.'**
  String get itemAnalysisUpdated;

  /// No description provided for @itemAnalysisRetryFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not retry analysis. Try again.'**
  String get itemAnalysisRetryFailed;

  /// No description provided for @itemDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get itemDetails;

  /// No description provided for @itemColors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get itemColors;

  /// No description provided for @itemPattern.
  ///
  /// In en, this message translates to:
  /// **'Pattern'**
  String get itemPattern;

  /// No description provided for @itemSilhouette.
  ///
  /// In en, this message translates to:
  /// **'Silhouette'**
  String get itemSilhouette;

  /// No description provided for @itemAnalysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed. Your item is still saved.'**
  String get itemAnalysisFailed;

  /// No description provided for @itemAnalysisPartial.
  ///
  /// In en, this message translates to:
  /// **'Some details may be incomplete.'**
  String get itemAnalysisPartial;

  /// No description provided for @onboardingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// No description provided for @onboardingProgress.
  ///
  /// In en, this message translates to:
  /// **'Onboarding progress'**
  String get onboardingProgress;

  /// No description provided for @settingsLuckyColorBirthProfile.
  ///
  /// In en, this message translates to:
  /// **'Birth profile'**
  String get settingsLuckyColorBirthProfile;

  /// No description provided for @settingsLuckyColorBirthProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Uses your saved birth date and weekday.'**
  String get settingsLuckyColorBirthProfileSubtitle;

  /// No description provided for @settingsLuckyColorRandomDaily.
  ///
  /// In en, this message translates to:
  /// **'Random daily'**
  String get settingsLuckyColorRandomDaily;

  /// No description provided for @settingsLuckyColorRandomDailySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Uses a stable daily color set without profile data.'**
  String get settingsLuckyColorRandomDailySubtitle;

  /// No description provided for @settingsWeatherAutoDetect.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect'**
  String get settingsWeatherAutoDetect;

  /// No description provided for @settingsWeatherAutoDetectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Uses device location when weather matching is enabled.'**
  String get settingsWeatherAutoDetectSubtitle;

  /// No description provided for @settingsWeatherOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsWeatherOff;

  /// No description provided for @settingsWeatherOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Outfit generation will skip weather matching.'**
  String get settingsWeatherOffSubtitle;

  /// No description provided for @settingsPrivacyContent.
  ///
  /// In en, this message translates to:
  /// **'Guest profile and wardrobe data stay on this device. Signed-in accounts store wardrobe, outfit, and preference data in Supabase. The app contains public Supabase configuration, while privileged API keys and secrets remain server-side.'**
  String get settingsPrivacyContent;

  /// No description provided for @dialogClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get dialogClose;
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
