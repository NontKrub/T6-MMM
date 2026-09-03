// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appName => 'Mix Match Mood';

  @override
  String get appTagline => 'จับคู่ตู้เสื้อผ้ากับอารมณ์ของคุณ';

  @override
  String get languageScreenTitle => 'Choose your language';

  @override
  String get languageScreenSubtitle => 'เลือกภาษา';

  @override
  String get languageContinue => 'ดำเนินการต่อ';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageThai => 'ภาษาไทย';

  @override
  String get authHeroTitle => 'ตู้เสื้อผ้าของคุณ\nถูกสร้างใหม่แล้ว';

  @override
  String get authHeroSubtitle => 'แนะนำชุดด้วย AI\nปรับแต่งเฉพาะสำหรับคุณ';

  @override
  String get authGetStarted => 'เริ่มต้นใช้งาน';

  @override
  String get authContinueWithApple => 'ดำเนินการต่อด้วย Apple';

  @override
  String get authContinueWithGoogle => 'ดำเนินการต่อด้วย Google';

  @override
  String get authContinueWithFacebook => 'ดำเนินการต่อด้วย Facebook';

  @override
  String get authContinueAsGuest => 'ดำเนินการต่อในฐานะผู้เยี่ยมชม';

  @override
  String get authUnavailable =>
      'ไม่สามารถเข้าสู่ระบบได้จนกว่าจะตั้งค่า Supabase';

  @override
  String onboardingStep(int current, int total) {
    return '$current / $total';
  }

  @override
  String get onboardingContinue => 'ดำเนินการต่อ';

  @override
  String get onboardingEnter => 'เข้าสู่ MMM';

  @override
  String get onboardingUserInfoTitle => 'บอกเราเกี่ยวกับคุณ';

  @override
  String get onboardingUserInfoSubtitle =>
      'เราใช้ข้อมูลนี้เพื่อปรับแต่งประสบการณ์ของคุณ';

  @override
  String get onboardingYourName => 'ชื่อของคุณ';

  @override
  String get onboardingNameHint => 'เช่น อเล็กซ์';

  @override
  String get onboardingDateOfBirth => 'วันเกิด';

  @override
  String get onboardingSelectDate => 'เลือกวันที่';

  @override
  String get onboardingDobHint =>
      'ไม่บังคับ — ช่วยให้เราปรับแต่งการทำนายสีมงคล';

  @override
  String get onboardingStyleTitle => 'สไตล์และรูปร่างของคุณ';

  @override
  String get onboardingStyleSubtitle => 'เลือกประเภทร่างกายและสไตล์ที่ใช่คุณ';

  @override
  String get onboardingBodyType => 'ประเภทร่างกาย';

  @override
  String get onboardingStyleVibes => 'สไตล์ที่ชื่นชอบ';

  @override
  String get onboardingStyleVibesHint => 'เลือกทุกอย่างที่ตรงใจ';

  @override
  String get onboardingColorSeasonTitle => 'ฤดูกาลสีของคุณ';

  @override
  String get onboardingColorSeasonSubtitle =>
      'กำหนดว่าพาเลตสีใดที่เข้ากับคุณมากที่สุด';

  @override
  String get onboardingLifestyleTitle => 'ไลฟ์สไตล์ของคุณ';

  @override
  String get onboardingLifestyleSubtitle => 'คุณแต่งตัวเพื่อโอกาสใดบ้าง?';

  @override
  String get bodyTypeStraight => 'ตรง';

  @override
  String get bodyTypeHourglass => 'นาฬิกาทราย';

  @override
  String get bodyTypePear => 'ลูกแพร์';

  @override
  String get bodyTypeApple => 'แอปเปิ้ล';

  @override
  String get bodyTypeAthletic => 'นักกีฬา';

  @override
  String get styleVibesCasual => 'แคชชวล';

  @override
  String get styleVibesMinimalist => 'มินิมอล';

  @override
  String get styleVibesStreetwear => 'สตรีทแวร์';

  @override
  String get styleVibesFormal => 'ทางการ';

  @override
  String get styleVibesVintage => 'วินเทจ';

  @override
  String get styleVibesY2K => 'Y2K';

  @override
  String get styleVibesCottagecore => 'ค็อทเทจคอร์';

  @override
  String get styleVibesPreppy => 'เพรปปี้';

  @override
  String get styleVibesBohemian => 'โบฮีเมียน';

  @override
  String get styleVibesAthleisure => 'แอธเลเชอร์';

  @override
  String get styleVibesDarkAcademia => 'ดาร์กอะคาเดเมีย';

  @override
  String get styleVibesCleanGirl => 'คลีนเกิร์ล';

  @override
  String get seasonSpring => 'ฤดูใบไม้ผลิ';

  @override
  String get seasonSummer => 'ฤดูร้อน';

  @override
  String get seasonAutumn => 'ฤดูใบไม้ร่วง';

  @override
  String get seasonWinter => 'ฤดูหนาว';

  @override
  String get occasionWork => 'ทำงาน';

  @override
  String get occasionWeekend => 'วันหยุด';

  @override
  String get occasionDates => 'เดต';

  @override
  String get occasionSports => 'กีฬา';

  @override
  String get occasionEvents => 'งานอีเวนต์';

  @override
  String get occasionTravel => 'ท่องเที่ยว';

  @override
  String get navHome => 'หน้าหลัก';

  @override
  String get navWardrobe => 'ตู้เสื้อผ้า';

  @override
  String get navMissing => 'ขาดอยู่';

  @override
  String get navChat => 'แชท';

  @override
  String get homeCustomize => 'ปรับแต่ง';

  @override
  String get homeGenerateOutfit => 'สร้างชุด';

  @override
  String get wardrobeTitle => 'ตู้เสื้อผ้า';

  @override
  String wardrobeItemCount(int count) {
    return '$count ชิ้น';
  }

  @override
  String get wardrobeSearchHint => 'ค้นหาตามชื่อ แบรนด์ หรือแท็ก…';

  @override
  String get wardrobeEmpty => 'ตู้เสื้อผ้าของคุณยังว่างอยู่';

  @override
  String get wardrobeEmptyHint => 'กด + เพื่อเพิ่มชิ้นแรกของคุณ';

  @override
  String get wardrobeNoResults => 'ไม่พบรายการ';

  @override
  String get missingTitle => 'ตู้เสื้อผ้าของคุณต้องการ...';

  @override
  String get missingSubtitleLocked =>
      'เข้าสู่ระบบเพื่อสร้างคำแนะนำช่องว่างในตู้เสื้อผ้า';

  @override
  String get missingSubtitleUnlocked => 'คัดสรรเพื่อเติมเต็มคอลเลกชันของคุณ';

  @override
  String get missingLockedTitle => 'คำแนะนำต้องการการเข้าสู่ระบบ';

  @override
  String get missingLockedMessage =>
      'ชิ้นที่ขาดหายไปใช้ AI และตู้เสื้อผ้า Supabase บัญชีผู้เยี่ยมชมเก็บข้อมูลตู้เสื้อผ้าไว้ในเครื่องเท่านั้น';

  @override
  String get missingEmptyTitle => 'ยังไม่มีคำแนะนำ';

  @override
  String get missingEmptyMessage => 'เซิร์ฟเวอร์ไม่ได้ส่งชิ้นที่ขาดกลับมา';

  @override
  String get missingErrorTitle => 'ไม่สามารถสร้างคำแนะนำได้';

  @override
  String get missingWhyExpand => 'ทำไม?';

  @override
  String get missingWhyCollapse => 'ซ่อนเหตุผล';

  @override
  String get chatTitle => 'Fashion AI';

  @override
  String get chatStatusLocked => 'ต้องเข้าสู่ระบบ';

  @override
  String get chatStatusUnlocked => 'พร้อมแนะนำเสมอ';

  @override
  String get chatInputHint => 'ถามเกี่ยวกับแฟชั่น…';

  @override
  String get chatLockedTitle => 'Fashion AI ต้องการการเข้าสู่ระบบ';

  @override
  String get chatLockedMessage =>
      'แชทใช้ตู้เสื้อผ้าที่บันทึกไว้และ AI ดำเนินการต่อด้วย Google หลังจากตั้งค่า Supabase';

  @override
  String get chatPrompt1 => 'ฤดูกาลสีของฉันคืออะไร?';

  @override
  String get chatPrompt2 => 'สไตล์นี้ชื่ออะไร';

  @override
  String get chatPrompt3 => 'สร้างตู้เสื้อผ้าแคปซูล';

  @override
  String get chatPrompt4 => 'พื้นฐานสตรีทแวร์';

  @override
  String get chatPrompt5 => 'ลุคควายเอท ลักชัวรี่';

  @override
  String get profileTitle => 'โปรไฟล์';

  @override
  String get profileItems => 'ชิ้น';

  @override
  String get profileOutfits => 'ชุด';

  @override
  String get profileFavItem => 'ชิ้นโปรด';

  @override
  String get profileColorSeason => 'ฤดูกาลสี';

  @override
  String get profileStylePreferences => 'สไตล์ที่ชื่นชอบ';

  @override
  String get profileSignOut => 'ออกจากระบบ';

  @override
  String get settingsTitle => 'การตั้งค่า';

  @override
  String get settingsAppearance => 'การแสดงผล';

  @override
  String get settingsDarkMode => 'โหมดมืด';

  @override
  String get settingsDarkModeOn => 'เปิด';

  @override
  String get settingsDarkModeOff => 'ปิด';

  @override
  String get settingsPersonalization => 'การปรับแต่ง';

  @override
  String get settingsLuckyColor => 'วิธีสีมงคล';

  @override
  String get settingsLuckyColorValue => 'สุ่มทุกวัน';

  @override
  String get settingsWeather => 'ตำแหน่งสภาพอากาศ';

  @override
  String get settingsWeatherValue => 'ตรวจจับอัตโนมัติ';

  @override
  String get settingsNotifications => 'การแจ้งเตือน';

  @override
  String get settingsDailyReminder => 'เตือนชุดประจำวัน';

  @override
  String get settingsRepetitionAlerts => 'แจ้งเตือนการซ้ำ';

  @override
  String get settingsAI => 'ฟีเจอร์ AI';

  @override
  String get settingsLearnPreferences => 'เรียนรู้ความชอบของฉัน';

  @override
  String get settingsLearnPreferencesSubtitle =>
      'AI ติดตามตัวเลือกของคุณเพื่อปรับปรุงคำแนะนำ';

  @override
  String get settingsAbout => 'เกี่ยวกับ';

  @override
  String get settingsVersion => 'เวอร์ชัน';

  @override
  String get settingsVersionValue => '1.0.0 (build 1)';

  @override
  String get settingsPrivacy => 'นโยบายความเป็นส่วนตัว';

  @override
  String get settingsLanguage => 'ภาษา';

  @override
  String get settingsLanguageValue => 'ภาษาไทย';

  @override
  String get avatarTitle => 'อวาตาร์ของคุณ';

  @override
  String get avatarBodyShape => 'รูปร่าง';

  @override
  String get avatarHairStyle => 'ทรงผม';

  @override
  String get avatarSkinTone => 'สีผิว';

  @override
  String get avatarHair => 'ผม';

  @override
  String get avatarDone => 'เสร็จสิ้น';

  @override
  String get avatarHuman => 'มนุษย์';

  @override
  String get avatarDog => 'สุนัข';

  @override
  String get avatarCat => 'แมว';

  @override
  String get avatarFemale => 'หญิง';

  @override
  String get avatarMale => 'ชาย';

  @override
  String get avatarHairBlack => 'ดำ';

  @override
  String get avatarHairDark => 'เข้ม';

  @override
  String get avatarHairBrown => 'น้ำตาล';

  @override
  String get avatarHairBlonde => 'บลอนด์';

  @override
  String get avatarHairAuburn => 'น้ำตาลแดง';

  @override
  String get avatarHairPlatinum => 'แพลทินัม';

  @override
  String get avatarHairTousled => 'ยุ่ง';

  @override
  String get avatarHairSideSwept => 'ปัดข้าง';

  @override
  String get avatarHairUndercut => 'อันเดอร์คัต';

  @override
  String get avatarHairLong => 'ยาว';

  @override
  String get avatarHairPonytail => 'มัดหางม้า';

  @override
  String get avatarHairBob => 'บ็อบ';

  @override
  String get repetitionStyleReminder => 'เตือนสไตล์';

  @override
  String repetitionMessage(String color) {
    return 'คุณใส่โทนสี $color บ่อยมาก ลองเปลี่ยนเป็นอะไรที่แตกต่างวันนี้สิ!';
  }

  @override
  String get outfitGeneratorTitle => 'สร้างชุด';

  @override
  String get outfitGeneratorStyleLabel => 'สไตล์';

  @override
  String get outfitGeneratorFiltersLabel => 'ตัวกรอง';

  @override
  String get outfitGeneratorUsePersonalColor => 'ใช้ฤดูกาลสีส่วนตัวของฉัน';

  @override
  String get outfitGeneratorLuckyColor => 'สีมงคลวันนี้';

  @override
  String get outfitGeneratorMatchWeather => 'จับคู่สภาพอากาศ';

  @override
  String get outfitGeneratorWeatherOff => 'เปิด Weather Location ในการตั้งค่า';

  @override
  String get outfitGeneratorWeatherAuto => 'ตรวจจับตำแหน่งอัตโนมัติ';

  @override
  String get outfitGeneratorGenerating => 'กำลังสร้าง...';

  @override
  String get outfitGeneratorGenerate => 'สร้าง';

  @override
  String get outfitGeneratorResults => 'ผลลัพธ์';

  @override
  String get outfitGeneratorLockedTitle => 'การสร้างชุดด้วย AI ต้องเข้าสู่ระบบ';

  @override
  String get outfitGeneratorLockedMessage =>
      'ตู้เสื้อผ้าของผู้เยี่ยมชมเก็บไว้ในเครื่อง เข้าสู่ระบบด้วย Supabase เพื่อสร้างชุดจริง จับคู่สภาพอากาศ และลุคสีมงคล';

  @override
  String get outfitGeneratorNoOutfits => 'ไม่มีชุดที่ถูกสร้าง';

  @override
  String get outfitGeneratorErrorNotDeployed =>
      'ยังไม่ได้เปิดใช้งานการสร้างชุด กรุณาลองใหม่หลังจากอัปเดตเซิร์ฟเวอร์';

  @override
  String get outfitGeneratorErrorNeedWardrobe =>
      'เพิ่มเสื้อด้านบน กางเกง/กระโปรง และรองเท้าอย่างน้อยอย่างละ 1 ชิ้นก่อน';

  @override
  String get outfitGeneratorErrorLocationPermission =>
      'ต้องการสิทธิ์ตำแหน่งเพื่อจับคู่สภาพอากาศ';

  @override
  String get outfitGeneratorErrorLocationOff =>
      'เปิดบริการตำแหน่งเพื่อจับคู่สภาพอากาศ';

  @override
  String get outfitGeneratorErrorGeneric =>
      'ไม่สามารถสร้างชุดได้ กรุณาลองใหม่อีกครั้ง';

  @override
  String get outfitStyleCasual => 'แคชชวล';

  @override
  String get outfitStyleWork => 'งาน';

  @override
  String get outfitStyleFormal => 'ทางการ';

  @override
  String get outfitStyleSport => 'กีฬา';

  @override
  String get outfitStyleDate => 'เดต';

  @override
  String get rushTitle => 'เร่งรีบ';

  @override
  String get rushStatusSignInRequired => 'ต้องเข้าสู่ระบบ';

  @override
  String get rushStatusNeedsSetup => 'ต้องตั้งค่าเล็กน้อย';

  @override
  String get rushStatusReady => 'ชุดของคุณพร้อมแล้ว';

  @override
  String get rushLockedMessage =>
      'ชุดเร่งรีบใช้ AI ของเซิร์ฟเวอร์ เข้าสู่ระบบด้วย Supabase เพื่อใช้งาน';

  @override
  String get rushDefaultReason =>
      'เลือกชุดที่เหมาะสมและรวดเร็วจากตู้เสื้อผ้าของคุณ';

  @override
  String get rushReshuffle => 'สุ่มใหม่';

  @override
  String get rushSignIn => 'เข้าสู่ระบบ';

  @override
  String get rushGotIt => 'รับทราบ';

  @override
  String get rushWearThis => 'ใส่ชุดนี้';

  @override
  String get rushErrorNeedWardrobe =>
      'ชุดเร่งรีบต้องการตู้เสื้อผ้าครบก่อน เพิ่มเสื้อด้านบน กางเกง/กระโปรง และรองเท้าอย่างละ 1 ชิ้น';

  @override
  String get rushErrorUnavailable =>
      'ไม่มีชุดเร่งรีบที่เข้ากันได้ เพิ่มรองเท้าและเสื้อด้านบนกับกางเกง/กระโปรง หรือเดรส';

  @override
  String get rushErrorSignIn =>
      'ชุดเร่งรีบใช้ตู้เสื้อผ้าที่บันทึกไว้ในเซิร์ฟเวอร์ เข้าสู่ระบบเพื่อใช้งาน';

  @override
  String get rushErrorNotDeployed =>
      'ยังไม่ได้เปิดใช้งานชุดเร่งรีบ กรุณาลองใหม่หลังจากอัปเดตเซิร์ฟเวอร์';

  @override
  String get rushErrorGeneric =>
      'ไม่สามารถเลือกชุดเร่งรีบได้ตอนนี้ ตรวจสอบตู้เสื้อผ้าและลองใหม่';

  @override
  String get addItemTitle => 'เพิ่มชิ้น';

  @override
  String get addItemCategory => 'หมวดหมู่';

  @override
  String get addItemNameHint => 'ชื่อชิ้น (เช่น เสื้อลินินขาว)';

  @override
  String get addItemBrandHint => 'แบรนด์ (ไม่บังคับ)';

  @override
  String get addItemTags => 'แท็ก';

  @override
  String get addItemSaving => 'กำลังบันทึก...';

  @override
  String get addItemSave => 'บันทึกลงตู้เสื้อผ้า';

  @override
  String get addItemCamera => 'กล้อง';

  @override
  String get addItemPhotoLibrary => 'คลังรูปภาพ';

  @override
  String get addItemTapToAddPhoto => 'แตะเพื่อเพิ่มรูปภาพ';

  @override
  String addItemCategoryLabel(String category) {
    return 'หมวดหมู่: $category';
  }

  @override
  String get tagCasual => 'แคชชวล';

  @override
  String get tagFormal => 'ทางการ';

  @override
  String get tagWork => 'งาน';

  @override
  String get tagSport => 'กีฬา';

  @override
  String get tagSummer => 'ฤดูร้อน';

  @override
  String get tagWinter => 'ฤดูหนาว';

  @override
  String get itemNotFound => 'ไม่พบชิ้น';

  @override
  String get itemNotFoundMessage => 'ชิ้นนี้ถูกลบออกแล้ว';

  @override
  String get itemOutfitsTitle => 'ชุดที่มีชิ้นนี้';

  @override
  String get itemStatsTimesWorn => 'ครั้งที่สวมใส่';

  @override
  String get itemStatsLastWorn => 'สวมใส่ล่าสุด';

  @override
  String get itemStatsCostPerWear => 'ต้นทุนต่อครั้ง';

  @override
  String get itemStatsNever => 'ยังไม่เคย';

  @override
  String get itemStatsNotWornYet => 'ยังไม่ได้สวมใส่';

  @override
  String get itemStatsToday => 'วันนี้';

  @override
  String get itemStatsYesterday => 'เมื่อวาน';

  @override
  String itemStatsDaysAgo(int days) {
    return 'เมื่อ $days วันที่แล้ว';
  }

  @override
  String itemStatsWeeksAgo(int weeks) {
    return '$weeks สัปดาห์ที่แล้ว';
  }

  @override
  String itemStatsMonthsAgo(int months) {
    return '$months เดือนที่แล้ว';
  }

  @override
  String get itemDeleteTitle => 'ลบชิ้น';

  @override
  String itemDeleteMessage(String name) {
    return 'ลบ \"$name\" ออกจากตู้เสื้อผ้าของคุณ?';
  }

  @override
  String get itemDeleteCancel => 'ยกเลิก';

  @override
  String get itemDeleteConfirm => 'ลบ';

  @override
  String get settingsLuckyColorBirthProfile => 'โปรไฟล์วันเกิด';

  @override
  String get settingsLuckyColorBirthProfileSubtitle =>
      'ใช้วันเกิดและวันในสัปดาห์ที่บันทึกไว้';

  @override
  String get settingsLuckyColorRandomDaily => 'สุ่มทุกวัน';

  @override
  String get settingsLuckyColorRandomDailySubtitle =>
      'ใช้ชุดสีรายวันที่เสถียรโดยไม่ต้องใช้ข้อมูลโปรไฟล์';

  @override
  String get settingsWeatherAutoDetect => 'ตรวจจับอัตโนมัติ';

  @override
  String get settingsWeatherAutoDetectSubtitle =>
      'ใช้ตำแหน่งของอุปกรณ์เมื่อเปิดใช้การจับคู่สภาพอากาศ';

  @override
  String get settingsWeatherOff => 'ปิด';

  @override
  String get settingsWeatherOffSubtitle =>
      'การสร้างชุดจะข้ามการจับคู่สภาพอากาศ';

  @override
  String get settingsPrivacyContent =>
      'ข้อมูลโปรไฟล์และตู้เสื้อผ้าของผู้เยี่ยมชมเก็บอยู่ในอุปกรณ์นี้ บัญชีที่เข้าสู่ระบบจะเก็บข้อมูลตู้เสื้อผ้า ชุด และความชอบใน Supabase เพื่อให้ฟีเจอร์ AI สร้างคำแนะนำได้ API keys และ secrets ไม่ถูกเก็บในแอป';

  @override
  String get dialogClose => 'ปิด';
}
