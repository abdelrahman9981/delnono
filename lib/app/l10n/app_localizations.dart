import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  static const List<Locale> supportedLocales = <Locale>[Locale('ar')];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'دكتور النونو'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get navHome;

  /// No description provided for @navBooking.
  ///
  /// In ar, this message translates to:
  /// **'حجز'**
  String get navBooking;

  /// No description provided for @navMyChild.
  ///
  /// In ar, this message translates to:
  /// **'طفلي'**
  String get navMyChild;

  /// No description provided for @navContent.
  ///
  /// In ar, this message translates to:
  /// **'محتوى'**
  String get navContent;

  /// No description provided for @placeholderTag.
  ///
  /// In ar, this message translates to:
  /// **'مؤقت'**
  String get placeholderTag;

  /// No description provided for @placeholderBody.
  ///
  /// In ar, this message translates to:
  /// **'الشاشة دي لسه بتتعمل.'**
  String get placeholderBody;

  /// No description provided for @placeholderHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get placeholderHome;

  /// No description provided for @placeholderBooking.
  ///
  /// In ar, this message translates to:
  /// **'الحجز'**
  String get placeholderBooking;

  /// No description provided for @placeholderContent.
  ///
  /// In ar, this message translates to:
  /// **'المحتوى'**
  String get placeholderContent;

  /// No description provided for @placeholderNotifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get placeholderNotifications;

  /// No description provided for @screenWelcome.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا بيكي'**
  String get screenWelcome;

  /// No description provided for @screenSignIn.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل'**
  String get screenSignIn;

  /// No description provided for @screenOtp.
  ///
  /// In ar, this message translates to:
  /// **'كود التحقق'**
  String get screenOtp;

  /// No description provided for @screenGuardian.
  ///
  /// In ar, this message translates to:
  /// **'بياناتك'**
  String get screenGuardian;

  /// No description provided for @screenConsent.
  ///
  /// In ar, this message translates to:
  /// **'الموافقة على الخصوصية'**
  String get screenConsent;

  /// No description provided for @screenLinkChildren.
  ///
  /// In ar, this message translates to:
  /// **'أطفالك في العيادة'**
  String get screenLinkChildren;

  /// No description provided for @screenAddChild.
  ///
  /// In ar, this message translates to:
  /// **'إضافة طفل'**
  String get screenAddChild;

  /// No description provided for @screenChildren.
  ///
  /// In ar, this message translates to:
  /// **'أطفالي'**
  String get screenChildren;

  /// No description provided for @screenChildProfile.
  ///
  /// In ar, this message translates to:
  /// **'ملف الطفل'**
  String get screenChildProfile;

  /// No description provided for @screenReverify.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الحساب'**
  String get screenReverify;

  /// No description provided for @screenAccount.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get screenAccount;

  /// No description provided for @screenChangePhone.
  ///
  /// In ar, this message translates to:
  /// **'تغيير رقم الموبايل'**
  String get screenChangePhone;

  /// No description provided for @screenDeleteAccount.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب'**
  String get screenDeleteAccount;

  /// No description provided for @stepOf.
  ///
  /// In ar, this message translates to:
  /// **'الخطوة {current} من {total}'**
  String stepOf(String current, String total);

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// No description provided for @signInTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get signInTitle;

  /// No description provided for @phoneHeading.
  ///
  /// In ar, this message translates to:
  /// **'رقم موبايلك إيه؟'**
  String get phoneHeading;

  /// No description provided for @phoneIntro.
  ///
  /// In ar, this message translates to:
  /// **'هنبعتلك كود في رسالة عشان نتأكد إن الرقم بتاعك. الرقم ده هو حسابك في التطبيق.'**
  String get phoneIntro;

  /// No description provided for @phoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل'**
  String get phoneLabel;

  /// No description provided for @phoneClinicHint.
  ///
  /// In ar, this message translates to:
  /// **'لو العيادة سجلت أطفالك قبل كده، استخدمي نفس الرقم.'**
  String get phoneClinicHint;

  /// No description provided for @phoneStaySignedIn.
  ///
  /// In ar, this message translates to:
  /// **'هتفضلي مسجلة دخول على الموبايل ده، ومش هنطلب كود تاني غير لو خرجتي من الحساب.'**
  String get phoneStaySignedIn;

  /// No description provided for @phoneSendCode.
  ///
  /// In ar, this message translates to:
  /// **'ابعتيلي الكود'**
  String get phoneSendCode;

  /// No description provided for @phonePrivacyNote.
  ///
  /// In ar, this message translates to:
  /// **'بالمتابعة هتشوفي سياسة الخصوصية قبل ما نحفظ أي بيانات.'**
  String get phonePrivacyNote;

  /// No description provided for @phoneInvalid.
  ///
  /// In ar, this message translates to:
  /// **'اكتبي رقم موبايل مصري صحيح، زي 010 1234 5678.'**
  String get phoneInvalid;

  /// No description provided for @otpHeading.
  ///
  /// In ar, this message translates to:
  /// **'اكتبي الكود'**
  String get otpHeading;

  /// No description provided for @otpSentTo.
  ///
  /// In ar, this message translates to:
  /// **'بعتنا كود من ٦ أرقام على {phone}'**
  String otpSentTo(String phone);

  /// No description provided for @otpChangeNumber.
  ///
  /// In ar, this message translates to:
  /// **'غيّري الرقم'**
  String get otpChangeNumber;

  /// No description provided for @otpCodeField.
  ///
  /// In ar, this message translates to:
  /// **'كود التحقق من ٦ أرقام'**
  String get otpCodeField;

  /// No description provided for @otpValidFor.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{الكود صالح دقيقة واحدة} =2{الكود صالح دقيقتين} few{الكود صالح {countText} دقايق} other{الكود صالح {countText} دقيقة}}'**
  String otpValidFor(int count, String countText);

  /// No description provided for @otpResendIn.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الإرسال بعد {time}'**
  String otpResendIn(String time);

  /// No description provided for @otpResend.
  ///
  /// In ar, this message translates to:
  /// **'ابعتي الكود تاني'**
  String get otpResend;

  /// No description provided for @otpConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get otpConfirm;

  /// No description provided for @otpAttempts.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{محاولة واحدة} =2{محاولتين} few{{countText} محاولات} other{{countText} محاولة}}'**
  String otpAttempts(int count, String countText);

  /// No description provided for @otpWrongCode.
  ///
  /// In ar, this message translates to:
  /// **'الكود مش صح. فاضلك {attempts}، وبعدها اطلبي كود جديد.'**
  String otpWrongCode(String attempts);

  /// No description provided for @otpNoAttemptsLeft.
  ///
  /// In ar, this message translates to:
  /// **'الكود مش صح، والمحاولات خلصت. اطلبي كود جديد.'**
  String get otpNoAttemptsLeft;

  /// No description provided for @next.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get next;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @guardianHeading.
  ///
  /// In ar, this message translates to:
  /// **'نتعرف عليكي'**
  String get guardianHeading;

  /// No description provided for @guardianIntro.
  ///
  /// In ar, this message translates to:
  /// **'البيانات دي بتظهر للعيادة مع كل حجز.'**
  String get guardianIntro;

  /// No description provided for @guardianFullName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم بالكامل'**
  String get guardianFullName;

  /// No description provided for @guardianRelation.
  ///
  /// In ar, this message translates to:
  /// **'صلة القرابة بالطفل'**
  String get guardianRelation;

  /// No description provided for @relationMother.
  ///
  /// In ar, this message translates to:
  /// **'أم'**
  String get relationMother;

  /// No description provided for @relationFather.
  ///
  /// In ar, this message translates to:
  /// **'أب'**
  String get relationFather;

  /// No description provided for @relationOther.
  ///
  /// In ar, this message translates to:
  /// **'آخر'**
  String get relationOther;

  /// No description provided for @guardianEmail.
  ///
  /// In ar, this message translates to:
  /// **'الإيميل (اختياري)'**
  String get guardianEmail;

  /// No description provided for @guardianEmailHelp.
  ///
  /// In ar, this message translates to:
  /// **'بنستخدمه بس لو احتجنا نبعتلك حاجة مكتوبة.'**
  String get guardianEmailHelp;

  /// No description provided for @guardianNothingSaved.
  ///
  /// In ar, this message translates to:
  /// **'مش هنحفظ أي بيانات غير بعد ما توافقي على سياسة الخصوصية في الخطوة الجاية.'**
  String get guardianNothingSaved;

  /// No description provided for @errFullName.
  ///
  /// In ar, this message translates to:
  /// **'اكتبي اسمك بالكامل، من حرفين لحد ٨٠ حرف.'**
  String get errFullName;

  /// No description provided for @errRelation.
  ///
  /// In ar, this message translates to:
  /// **'اختاري صلة القرابة.'**
  String get errRelation;

  /// No description provided for @errEmail.
  ///
  /// In ar, this message translates to:
  /// **'الإيميل مش مكتوب صح.'**
  String get errEmail;

  /// No description provided for @consentTitle.
  ///
  /// In ar, this message translates to:
  /// **'الخصوصية'**
  String get consentTitle;

  /// No description provided for @consentHeading.
  ///
  /// In ar, this message translates to:
  /// **'بيانات طفلك أمانة'**
  String get consentHeading;

  /// No description provided for @consentIntro.
  ///
  /// In ar, this message translates to:
  /// **'قبل ما نحفظ أي حاجة، اعرفي هنعمل إيه بالبيانات.'**
  String get consentIntro;

  /// No description provided for @consentUpdatedHeading.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية اتحدثت'**
  String get consentUpdatedHeading;

  /// No description provided for @consentUpdatedIntro.
  ///
  /// In ar, this message translates to:
  /// **'راجعي الإصدار الجديد ووافقي عليه عشان تكملي.'**
  String get consentUpdatedIntro;

  /// No description provided for @consentWhat.
  ///
  /// In ar, this message translates to:
  /// **'بنجمع إيه: بياناتك، وبيانات طفلك، وقياساته وتطعيماته وزياراته.'**
  String get consentWhat;

  /// No description provided for @consentWho.
  ///
  /// In ar, this message translates to:
  /// **'مين يشوفها: انتي، والدكتور. السكرتارية تشوف المواعيد والقياسات بس.'**
  String get consentWho;

  /// No description provided for @consentDelete.
  ///
  /// In ar, this message translates to:
  /// **'الحذف: تقدري تمسحي حسابك في أي وقت. السجل الطبي بيفضل عند العيادة.'**
  String get consentDelete;

  /// No description provided for @consentReadFull.
  ///
  /// In ar, this message translates to:
  /// **'اقري سياسة الخصوصية وشروط الاستخدام كاملة'**
  String get consentReadFull;

  /// No description provided for @consentPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'نص مؤقت · يراجعه المحامي قبل الإطلاق'**
  String get consentPlaceholder;

  /// No description provided for @consentPolicyCheck.
  ///
  /// In ar, this message translates to:
  /// **'موافقة على سياسة الخصوصية وشروط الاستخدام'**
  String get consentPolicyCheck;

  /// No description provided for @consentVersion.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {version}'**
  String consentVersion(String version);

  /// No description provided for @consentVersionDated.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {version} · {date}'**
  String consentVersionDated(String version, String date);

  /// No description provided for @consentChildDataCheck.
  ///
  /// In ar, this message translates to:
  /// **'موافقة على جمع بيانات طفلي الصحية'**
  String get consentChildDataCheck;

  /// No description provided for @consentChildDataSub.
  ///
  /// In ar, this message translates to:
  /// **'عشان نسجل ملفه وتطعيماته ونفكرك بمواعيده'**
  String get consentChildDataSub;

  /// No description provided for @consentAccept.
  ///
  /// In ar, this message translates to:
  /// **'موافقة ومتابعة'**
  String get consentAccept;

  /// No description provided for @consentBothRequired.
  ///
  /// In ar, this message translates to:
  /// **'لازم الموافقتين عشان تكملي.'**
  String get consentBothRequired;

  /// No description provided for @policyPrivacyTitle.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية'**
  String get policyPrivacyTitle;

  /// No description provided for @policyTermsTitle.
  ///
  /// In ar, this message translates to:
  /// **'شروط الاستخدام'**
  String get policyTermsTitle;

  /// No description provided for @childName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الطفل'**
  String get childName;

  /// No description provided for @childBirthDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الميلاد'**
  String get childBirthDate;

  /// No description provided for @childBirthDatePick.
  ///
  /// In ar, this message translates to:
  /// **'اختاري التاريخ'**
  String get childBirthDatePick;

  /// No description provided for @childSex.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get childSex;

  /// No description provided for @sexMale.
  ///
  /// In ar, this message translates to:
  /// **'ولد'**
  String get sexMale;

  /// No description provided for @sexFemale.
  ///
  /// In ar, this message translates to:
  /// **'بنت'**
  String get sexFemale;

  /// No description provided for @childFixedFieldsNote.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الميلاد والنوع بيحددوا جدول التطعيمات، فتعديلهم بعد كده بيبقى من العيادة.'**
  String get childFixedFieldsNote;

  /// No description provided for @childBirthWeight.
  ///
  /// In ar, this message translates to:
  /// **'وزن الولادة (اختياري)'**
  String get childBirthWeight;

  /// No description provided for @kg.
  ///
  /// In ar, this message translates to:
  /// **'كجم'**
  String get kg;

  /// No description provided for @childAllergies.
  ///
  /// In ar, this message translates to:
  /// **'الحساسية (اختياري)'**
  String get childAllergies;

  /// No description provided for @childDuplicateLinked.
  ///
  /// In ar, this message translates to:
  /// **'«{name}» متسجل في حسابك بنفس تاريخ الميلاد، فمش هنضيفه تاني.'**
  String childDuplicateLinked(String name);

  /// No description provided for @childDuplicateClinic.
  ///
  /// In ar, this message translates to:
  /// **'فيه طفل اسمه «{name}» بنفس تاريخ الميلاد مسجل على رقمك بالفعل، فمش هنضيفه تاني. لو ده غلط كلمي العيادة.'**
  String childDuplicateClinic(String name);

  /// No description provided for @errChildName.
  ///
  /// In ar, this message translates to:
  /// **'اكتبي اسم الطفل، من حرفين لحد ٦٠ حرف.'**
  String get errChildName;

  /// No description provided for @errBirthDate.
  ///
  /// In ar, this message translates to:
  /// **'اختاري تاريخ الميلاد.'**
  String get errBirthDate;

  /// No description provided for @errSex.
  ///
  /// In ar, this message translates to:
  /// **'اختاري النوع.'**
  String get errSex;

  /// No description provided for @errBirthWeight.
  ///
  /// In ar, this message translates to:
  /// **'الوزن لازم يكون بين ٠٫٣ و٧ كجم.'**
  String get errBirthWeight;

  /// No description provided for @errAllergies.
  ///
  /// In ar, this message translates to:
  /// **'اكتبي الحساسية في أقل من ٥٠٠ حرف.'**
  String get errAllergies;

  /// No description provided for @welcomeClinic.
  ///
  /// In ar, this message translates to:
  /// **'دكتور النونو'**
  String get welcomeClinic;

  /// No description provided for @welcomeDoctorName.
  ///
  /// In ar, this message translates to:
  /// **'د. أحمد العبد'**
  String get welcomeDoctorName;

  /// No description provided for @welcomeDoctorTitle.
  ///
  /// In ar, this message translates to:
  /// **'استشاري طب الأطفال وحديثي الولادة · المقطم'**
  String get welcomeDoctorTitle;

  /// No description provided for @welcomePhotoPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'صورة د. أحمد'**
  String get welcomePhotoPlaceholder;

  /// No description provided for @welcomePhotoSoon.
  ///
  /// In ar, this message translates to:
  /// **'هنضيف الصورة الحقيقية قريب'**
  String get welcomePhotoSoon;

  /// No description provided for @welcomeHeading.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا بيكي'**
  String get welcomeHeading;

  /// No description provided for @welcomeIntro.
  ///
  /// In ar, this message translates to:
  /// **'احجزي ميعادك وتابعي نمو وتطعيمات طفلك من مكان واحد.'**
  String get welcomeIntro;

  /// No description provided for @welcomeBookTitle.
  ///
  /// In ar, this message translates to:
  /// **'احجزي من التطبيق'**
  String get welcomeBookTitle;

  /// No description provided for @welcomeBookBody.
  ///
  /// In ar, this message translates to:
  /// **'اختاري اليوم والساعة وشوفي الأماكن الفاضية'**
  String get welcomeBookBody;

  /// No description provided for @welcomeProfileTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملف طفلك معاكي'**
  String get welcomeProfileTitle;

  /// No description provided for @welcomeProfileBody.
  ///
  /// In ar, this message translates to:
  /// **'القياسات والتطعيمات والزيارات'**
  String get welcomeProfileBody;

  /// No description provided for @welcomeTipsTitle.
  ///
  /// In ar, this message translates to:
  /// **'نصايح من الدكتور'**
  String get welcomeTipsTitle;

  /// No description provided for @welcomeTipsBody.
  ///
  /// In ar, this message translates to:
  /// **'فيديوهات حسب سن طفلك'**
  String get welcomeTipsBody;

  /// No description provided for @welcomeRegister.
  ///
  /// In ar, this message translates to:
  /// **'سجّلي برقم موبايلك'**
  String get welcomeRegister;

  /// No description provided for @welcomeBrowse.
  ///
  /// In ar, this message translates to:
  /// **'اتفرجي على المحتوى الأول'**
  String get welcomeBrowse;

  /// No description provided for @welcomeDisclaimer.
  ///
  /// In ar, this message translates to:
  /// **'التطبيق للحجز والمتابعة بس، ومش بديل للكشف أو تشخيص الطبيب.'**
  String get welcomeDisclaimer;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// No description provided for @linkHeading.
  ///
  /// In ar, this message translates to:
  /// **'فيه ملفات أطفال على رقمك'**
  String get linkHeading;

  /// No description provided for @linkIntro.
  ///
  /// In ar, this message translates to:
  /// **'العيادة سجلت قبل كده أطفال على الرقم ده. عشان نتأكد إنهم أطفالك، جاوبي على سؤال واحد.'**
  String get linkIntro;

  /// No description provided for @linkBirthDateLabel.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ ميلاد واحد من أطفالك المسجلين في العيادة'**
  String get linkBirthDateLabel;

  /// No description provided for @linkPrivacyNote.
  ///
  /// In ar, this message translates to:
  /// **'مش هنعرض أي بيانات غير لما الإجابة تبقى صح.'**
  String get linkPrivacyNote;

  /// No description provided for @linkWrongDate.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ مش مطابق. فاضلك {attempts}. بعدها هنوقف الربط وتقدري تكلمي العيادة.'**
  String linkWrongDate(String attempts);

  /// No description provided for @linkLocked.
  ///
  /// In ar, this message translates to:
  /// **'وقفنا الربط بعد المحاولات دي. كلمي العيادة عشان تربط أطفالك بحسابك.'**
  String get linkLocked;

  /// No description provided for @linkSuccess.
  ///
  /// In ar, this message translates to:
  /// **'اتضاف {names} لحسابك.'**
  String linkSuccess(String names);

  /// No description provided for @linkNotMine.
  ///
  /// In ar, this message translates to:
  /// **'دول مش أطفالي · ضيفي طفل جديد'**
  String get linkNotMine;

  /// No description provided for @childrenEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش أطفال في حسابك.'**
  String get childrenEmpty;

  /// No description provided for @childrenAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة طفل'**
  String get childrenAdd;

  /// No description provided for @ageYears.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{سنة} =2{سنتين} few{{countText} سنين} other{{countText} سنة}}'**
  String ageYears(int count, String countText);

  /// No description provided for @ageMonths.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{شهر} =2{شهرين} few{{countText} شهور} other{{countText} شهر}}'**
  String ageMonths(int count, String countText);

  /// No description provided for @ageNewborn.
  ///
  /// In ar, this message translates to:
  /// **'أقل من شهر'**
  String get ageNewborn;

  /// No description provided for @ageAnd.
  ///
  /// In ar, this message translates to:
  /// **'{years} و{months}'**
  String ageAnd(String years, String months);

  /// No description provided for @childFixedFieldsLocked.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الميلاد والنوع بيصححهم الدكتور أو السكرتارية بس، لأنهم بيحددوا جدول التطعيمات. لو فيهم غلط كلمي العيادة.'**
  String get childFixedFieldsLocked;

  /// No description provided for @childSaved.
  ///
  /// In ar, this message translates to:
  /// **'اتحفظت التعديلات.'**
  String get childSaved;

  /// No description provided for @childNotFound.
  ///
  /// In ar, this message translates to:
  /// **'الطفل ده مش موجود في حسابك.'**
  String get childNotFound;

  /// No description provided for @accountChildren.
  ///
  /// In ar, this message translates to:
  /// **'أطفالي'**
  String get accountChildren;

  /// No description provided for @accountChangePhone.
  ///
  /// In ar, this message translates to:
  /// **'تغيير رقم الموبايل'**
  String get accountChangePhone;

  /// No description provided for @accountChangePhoneSub.
  ///
  /// In ar, this message translates to:
  /// **'بكود على الرقم الجديد'**
  String get accountChangePhoneSub;

  /// No description provided for @accountNotifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get accountNotifications;

  /// No description provided for @accountPrivacy.
  ///
  /// In ar, this message translates to:
  /// **'الخصوصية والشروط'**
  String get accountPrivacy;

  /// No description provided for @accountPrivacySub.
  ///
  /// In ar, this message translates to:
  /// **'وافقتي على الإصدار {version}'**
  String accountPrivacySub(String version);

  /// No description provided for @accountWhatsApp.
  ///
  /// In ar, this message translates to:
  /// **'كلمي العيادة على واتساب'**
  String get accountWhatsApp;

  /// No description provided for @accountWhatsAppSub.
  ///
  /// In ar, this message translates to:
  /// **'للاستفسار والدعم، مش للحجز'**
  String get accountWhatsAppSub;

  /// No description provided for @accountWhatsAppUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'رقم واتساب العيادة لسه مش متاح.'**
  String get accountWhatsAppUnavailable;

  /// No description provided for @accountSignOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get accountSignOut;

  /// No description provided for @accountDeleteTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب'**
  String get accountDeleteTitle;

  /// No description provided for @accountDeleteBody.
  ///
  /// In ar, this message translates to:
  /// **'هنمسح حسابك وبياناتك من التطبيق. ملفات أطفالك الطبية بتفضل عند العيادة للمدة اللي يحددها القانون.'**
  String get accountDeleteBody;

  /// No description provided for @accountDeleteButton.
  ///
  /// In ar, this message translates to:
  /// **'حذف حسابي'**
  String get accountDeleteButton;

  /// No description provided for @changePhoneHeading.
  ///
  /// In ar, this message translates to:
  /// **'رقمك الجديد'**
  String get changePhoneHeading;

  /// No description provided for @changePhoneIntro.
  ///
  /// In ar, this message translates to:
  /// **'هنبعت كود على الرقم الجديد. أطفالك وبياناتك بيفضلوا زي ما هما.'**
  String get changePhoneIntro;

  /// No description provided for @changePhoneSend.
  ///
  /// In ar, this message translates to:
  /// **'ابعتي الكود'**
  String get changePhoneSend;

  /// No description provided for @changePhoneSame.
  ///
  /// In ar, this message translates to:
  /// **'ده نفس رقمك الحالي.'**
  String get changePhoneSame;

  /// No description provided for @changePhoneDone.
  ///
  /// In ar, this message translates to:
  /// **'اتغير رقمك لـ {phone}.'**
  String changePhoneDone(String phone);

  /// No description provided for @deleteHeading.
  ///
  /// In ar, this message translates to:
  /// **'قبل ما تمسحي حسابك'**
  String get deleteHeading;

  /// No description provided for @deleteRemovedTitle.
  ///
  /// In ar, this message translates to:
  /// **'هنمسح من التطبيق'**
  String get deleteRemovedTitle;

  /// No description provided for @deleteRemoved.
  ///
  /// In ar, this message translates to:
  /// **'حسابك ورقمك واسمك وإعداداتك. هتخرجي من التطبيق على الموبايل ده.'**
  String get deleteRemoved;

  /// No description provided for @deleteKeptTitle.
  ///
  /// In ar, this message translates to:
  /// **'هيفضل عند العيادة'**
  String get deleteKeptTitle;

  /// No description provided for @deleteKept.
  ///
  /// In ar, this message translates to:
  /// **'ملفات أطفالك الطبية وسجل موافقتك، للمدة اللي يحددها القانون.'**
  String get deleteKept;

  /// No description provided for @deleteComeBack.
  ///
  /// In ar, this message translates to:
  /// **'لو سجلتي تاني بنفس الرقم، هتبدأي من الأول وتقدري تربطي أطفالك تاني.'**
  String get deleteComeBack;

  /// No description provided for @deleteConfirmCheck.
  ///
  /// In ar, this message translates to:
  /// **'فاهمة، وعايزة أمسح حسابي'**
  String get deleteConfirmCheck;

  /// No description provided for @deleteButton.
  ///
  /// In ar, this message translates to:
  /// **'حذف حسابي نهائيًا'**
  String get deleteButton;

  /// No description provided for @deleteDone.
  ///
  /// In ar, this message translates to:
  /// **'اتمسح حسابك.'**
  String get deleteDone;

  /// No description provided for @reverifyHeading.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد إنك صاحبة الحساب'**
  String get reverifyHeading;

  /// No description provided for @reverifyIntro.
  ///
  /// In ar, this message translates to:
  /// **'بقالك فترة مدخلتيش التطبيق. عشان نحمي بيانات أطفالك، اكتبي تاريخ ميلاد واحد منهم.'**
  String get reverifyIntro;

  /// No description provided for @reverifyBirthDateLabel.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ ميلاد واحد من أطفالك'**
  String get reverifyBirthDateLabel;

  /// No description provided for @reverifyWrongDate.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ مش مطابق. فاضلك {attempts}. بعدها هنقفل بيانات الأطفال لحد ما تكلمي العيادة.'**
  String reverifyWrongDate(String attempts);

  /// No description provided for @reverifyLocked.
  ///
  /// In ar, this message translates to:
  /// **'قفلنا بيانات الأطفال بعد المحاولات دي. كلمي العيادة عشان نفتحها تاني.'**
  String get reverifyLocked;

  /// No description provided for @nameListSeparator.
  ///
  /// In ar, this message translates to:
  /// **' و'**
  String get nameListSeparator;

  /// No description provided for @bookingTitle.
  ///
  /// In ar, this message translates to:
  /// **'احجزي زيارة'**
  String get bookingTitle;

  /// No description provided for @visitTypeVisit.
  ///
  /// In ar, this message translates to:
  /// **'كشف أطفال'**
  String get visitTypeVisit;

  /// No description provided for @visitTypeVaccine.
  ///
  /// In ar, this message translates to:
  /// **'تطعيم'**
  String get visitTypeVaccine;

  /// No description provided for @visitTypeVaccineSub.
  ///
  /// In ar, this message translates to:
  /// **'حسب الجرعة'**
  String get visitTypeVaccineSub;

  /// No description provided for @priceEgp.
  ///
  /// In ar, this message translates to:
  /// **'{amount} جنيه'**
  String priceEgp(String amount);

  /// No description provided for @chooseDay.
  ///
  /// In ar, this message translates to:
  /// **'اختاري اليوم'**
  String get chooseDay;

  /// No description provided for @chooseHour.
  ///
  /// In ar, this message translates to:
  /// **'اختاري الساعة'**
  String get chooseHour;

  /// No description provided for @arrivalOrder.
  ///
  /// In ar, this message translates to:
  /// **'الدخول بالأسبقية'**
  String get arrivalOrder;

  /// No description provided for @hourRange.
  ///
  /// In ar, this message translates to:
  /// **'{from} لـ {to}'**
  String hourRange(String from, String to);

  /// No description provided for @periodAm.
  ///
  /// In ar, this message translates to:
  /// **'ص'**
  String get periodAm;

  /// No description provided for @periodPm.
  ///
  /// In ar, this message translates to:
  /// **'م'**
  String get periodPm;

  /// No description provided for @placesLeft.
  ///
  /// In ar, this message translates to:
  /// **'فاضل {left} من {capacity}'**
  String placesLeft(String left, String capacity);

  /// No description provided for @hourFull.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get hourFull;

  /// No description provided for @noHoursThatDay.
  ///
  /// In ar, this message translates to:
  /// **'مفيش ساعات متاحة في اليوم ده.'**
  String get noHoursThatDay;

  /// No description provided for @whoIsComing.
  ///
  /// In ar, this message translates to:
  /// **'مين هييجي؟'**
  String get whoIsComing;

  /// No description provided for @chooseMoreThanOne.
  ///
  /// In ar, this message translates to:
  /// **'اختاري أكتر من طفل'**
  String get chooseMoreThanOne;

  /// No description provided for @vaccinesFor.
  ///
  /// In ar, this message translates to:
  /// **'تطعيمات {name}'**
  String vaccinesFor(String name);

  /// No description provided for @noVaccine.
  ///
  /// In ar, this message translates to:
  /// **'من غير تطعيم'**
  String get noVaccine;

  /// No description provided for @summaryTotal.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الزيارة'**
  String get summaryTotal;

  /// No description provided for @coveredByPackage.
  ///
  /// In ar, this message translates to:
  /// **'مغطّى بالباقة'**
  String get coveredByPackage;

  /// No description provided for @activePackage.
  ///
  /// In ar, this message translates to:
  /// **'باقة نشطة'**
  String get activePackage;

  /// No description provided for @summaryWhen.
  ///
  /// In ar, this message translates to:
  /// **'المعاد'**
  String get summaryWhen;

  /// No description provided for @summaryChildren.
  ///
  /// In ar, this message translates to:
  /// **'الأطفال'**
  String get summaryChildren;

  /// No description provided for @summaryPayment.
  ///
  /// In ar, this message translates to:
  /// **'الدفع'**
  String get summaryPayment;

  /// No description provided for @cashAtClinic.
  ///
  /// In ar, this message translates to:
  /// **'كاش في العيادة'**
  String get cashAtClinic;

  /// No description provided for @summaryVisit.
  ///
  /// In ar, this message translates to:
  /// **'الكشف'**
  String get summaryVisit;

  /// No description provided for @priceAtClinic.
  ///
  /// In ar, this message translates to:
  /// **'بالسعر في العيادة'**
  String get priceAtClinic;

  /// No description provided for @totalExcludesHidden.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي من غير التطعيمات اللي سعرها في العيادة.'**
  String get totalExcludesHidden;

  /// No description provided for @hoursCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{ساعة} =2{ساعتين} few{{countText} ساعات} other{{countText} ساعة}}'**
  String hoursCount(int count, String countText);

  /// No description provided for @cancelUntil.
  ///
  /// In ar, this message translates to:
  /// **'تقدري تلغي لحد {hours} قبل الميعاد'**
  String cancelUntil(String hours);

  /// No description provided for @confirmBooking.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الحجز'**
  String get confirmBooking;

  /// No description provided for @myBookings.
  ///
  /// In ar, this message translates to:
  /// **'حجوزاتي'**
  String get myBookings;

  /// No description provided for @noChildrenToBook.
  ///
  /// In ar, this message translates to:
  /// **'ضيفي طفل الأول عشان تحجزي.'**
  String get noChildrenToBook;

  /// No description provided for @bookingFull.
  ///
  /// In ar, this message translates to:
  /// **'الميعاد اتحجز. اختاري ساعة تانية.'**
  String get bookingFull;

  /// No description provided for @priceChanged.
  ///
  /// In ar, this message translates to:
  /// **'السعر اتغير. الإجمالي دلوقتي {total} جنيه، أكدي تاني.'**
  String priceChanged(String total);

  /// No description provided for @bookingClosedDay.
  ///
  /// In ar, this message translates to:
  /// **'العيادة مقفولة في اليوم ده.'**
  String get bookingClosedDay;

  /// No description provided for @bookingStarted.
  ///
  /// In ar, this message translates to:
  /// **'الساعة دي بدأت خلاص. اختاري ساعة تانية.'**
  String get bookingStarted;

  /// No description provided for @bookingBeyondHorizon.
  ///
  /// In ar, this message translates to:
  /// **'الحجز متاح للأيام الجاية بس، مش أبعد من كده.'**
  String get bookingBeyondHorizon;

  /// No description provided for @bookingNotVaccineDay.
  ///
  /// In ar, this message translates to:
  /// **'التطعيمات في أيام التطعيم بس.'**
  String get bookingNotVaccineDay;

  /// No description provided for @bookingAlreadyThatDay.
  ///
  /// In ar, this message translates to:
  /// **'عندك حجز في اليوم ده بالفعل. عدّليه لو عايزة تضيفي طفل.'**
  String get bookingAlreadyThatDay;

  /// No description provided for @bookingTooMany.
  ///
  /// In ar, this message translates to:
  /// **'عندك أقصى عدد من الحجوزات الجاية. استني لما واحد يخلص أو الغيه.'**
  String get bookingTooMany;

  /// No description provided for @bookingVaccineRequired.
  ///
  /// In ar, this message translates to:
  /// **'اختاري تطعيم واحد على الأقل.'**
  String get bookingVaccineRequired;

  /// No description provided for @successTag.
  ///
  /// In ar, this message translates to:
  /// **'تم الحجز بنجاح'**
  String get successTag;

  /// No description provided for @successTitle.
  ///
  /// In ar, this message translates to:
  /// **'ميعادكم اتأكد يا {name}'**
  String successTitle(String name);

  /// No description provided for @successWaiting.
  ///
  /// In ar, this message translates to:
  /// **'مستنيين {children} في العيادة'**
  String successWaiting(String children);

  /// No description provided for @bookingNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الحجز'**
  String get bookingNumber;

  /// No description provided for @bookingNumberValue.
  ///
  /// In ar, this message translates to:
  /// **'# نونو {number}'**
  String bookingNumberValue(String number);

  /// No description provided for @statusConfirmed.
  ///
  /// In ar, this message translates to:
  /// **'مؤكد'**
  String get statusConfirmed;

  /// No description provided for @statusArrived.
  ///
  /// In ar, this message translates to:
  /// **'وصل'**
  String get statusArrived;

  /// No description provided for @statusDone.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get statusDone;

  /// No description provided for @statusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get statusCancelled;

  /// No description provided for @statusNoShow.
  ///
  /// In ar, this message translates to:
  /// **'لم يحضر'**
  String get statusNoShow;

  /// No description provided for @statusSoon.
  ///
  /// In ar, this message translates to:
  /// **'قريب'**
  String get statusSoon;

  /// No description provided for @labelDay.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get labelDay;

  /// No description provided for @labelHour.
  ///
  /// In ar, this message translates to:
  /// **'الساعة'**
  String get labelHour;

  /// No description provided for @labelVisit.
  ///
  /// In ar, this message translates to:
  /// **'الزيارة'**
  String get labelVisit;

  /// No description provided for @payAtClinic.
  ///
  /// In ar, this message translates to:
  /// **'الدفع في العيادة'**
  String get payAtClinic;

  /// No description provided for @arrivalOrderInHour.
  ///
  /// In ar, this message translates to:
  /// **'الدخول بالأسبقية جوه الساعة المحجوزة'**
  String get arrivalOrderInHour;

  /// No description provided for @viewMyBookings.
  ///
  /// In ar, this message translates to:
  /// **'عرض حجوزاتي'**
  String get viewMyBookings;

  /// No description provided for @backHome.
  ///
  /// In ar, this message translates to:
  /// **'الرجوع للرئيسية'**
  String get backHome;

  /// No description provided for @tabUpcoming.
  ///
  /// In ar, this message translates to:
  /// **'القادمة'**
  String get tabUpcoming;

  /// No description provided for @tabPast.
  ///
  /// In ar, this message translates to:
  /// **'السابقة'**
  String get tabPast;

  /// No description provided for @dueAtClinic.
  ///
  /// In ar, this message translates to:
  /// **'المطلوب في العيادة'**
  String get dueAtClinic;

  /// No description provided for @canChange.
  ///
  /// In ar, this message translates to:
  /// **'لسه ينفع تعدلي أو تلغي'**
  String get canChange;

  /// No description provided for @canChangeSub.
  ///
  /// In ar, this message translates to:
  /// **'متبقي أكتر من {hours} على الميعاد'**
  String canChangeSub(String hours);

  /// No description provided for @lessThan.
  ///
  /// In ar, this message translates to:
  /// **'فاضل أقل من {hours}'**
  String lessThan(String hours);

  /// No description provided for @lessThanSub.
  ///
  /// In ar, this message translates to:
  /// **'التعديل والإلغاء عن طريق العيادة'**
  String get lessThanSub;

  /// No description provided for @changeBooking.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get changeBooking;

  /// No description provided for @cancelBooking.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الحجز'**
  String get cancelBooking;

  /// No description provided for @callClinic.
  ///
  /// In ar, this message translates to:
  /// **'كلمي العيادة'**
  String get callClinic;

  /// No description provided for @newBooking.
  ///
  /// In ar, this message translates to:
  /// **'احجزي ميعاد جديد'**
  String get newBooking;

  /// No description provided for @noBookings.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش حجوزات.'**
  String get noBookings;

  /// No description provided for @cancelConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'تلغي الحجز؟'**
  String get cancelConfirmTitle;

  /// No description provided for @cancelConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'هيتلغى حجز {when} والمكان هيرجع متاح لغيرك.'**
  String cancelConfirmBody(String when);

  /// No description provided for @keepBooking.
  ///
  /// In ar, this message translates to:
  /// **'لأ، خليه'**
  String get keepBooking;

  /// No description provided for @bookingCancelled.
  ///
  /// In ar, this message translates to:
  /// **'اتلغى الحجز.'**
  String get bookingCancelled;

  /// No description provided for @titleVisit.
  ///
  /// In ar, this message translates to:
  /// **'كشف {names}'**
  String titleVisit(String names);

  /// No description provided for @titleVaccine.
  ///
  /// In ar, this message translates to:
  /// **'تطعيم {names}'**
  String titleVaccine(String names);

  /// No description provided for @titleVisitAndVaccine.
  ///
  /// In ar, this message translates to:
  /// **'كشف وتطعيم {names}'**
  String titleVisitAndVaccine(String names);

  /// No description provided for @changeTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الحجز'**
  String get changeTitle;

  /// No description provided for @confirmChange.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد التعديل'**
  String get confirmChange;

  /// No description provided for @bookingChanged.
  ///
  /// In ar, this message translates to:
  /// **'اتعدل الحجز.'**
  String get bookingChanged;

  /// No description provided for @errInvalidCode.
  ///
  /// In ar, this message translates to:
  /// **'الكود مش صح.'**
  String get errInvalidCode;

  /// No description provided for @errCodeExpired.
  ///
  /// In ar, this message translates to:
  /// **'الكود خلص وقته. اطلبي كود جديد.'**
  String get errCodeExpired;

  /// No description provided for @errTooManyRequests.
  ///
  /// In ar, this message translates to:
  /// **'محاولات كتير. استني شوية وجربي تاني.'**
  String get errTooManyRequests;

  /// No description provided for @errNoConnection.
  ///
  /// In ar, this message translates to:
  /// **'محتاجة إنترنت عشان تكملي. اتأكدي من الاتصال وجربي تاني.'**
  String get errNoConnection;

  /// No description provided for @errNumberInUse.
  ///
  /// In ar, this message translates to:
  /// **'الرقم ده عليه حساب تاني. كلمي العيادة عشان نساعدك.'**
  String get errNumberInUse;

  /// No description provided for @errSmsQuota.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نبعت كود دلوقتي. جربي بعد شوية.'**
  String get errSmsQuota;

  /// No description provided for @errUnauthenticated.
  ///
  /// In ar, this message translates to:
  /// **'سجلي دخول الأول.'**
  String get errUnauthenticated;

  /// No description provided for @errAlreadyExists.
  ///
  /// In ar, this message translates to:
  /// **'البيانات دي موجودة قبل كده.'**
  String get errAlreadyExists;

  /// No description provided for @errPolicyOutdated.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية اتحدثت. راجعيها ووافقي عليها الأول.'**
  String get errPolicyOutdated;

  /// No description provided for @errInvalidInput.
  ///
  /// In ar, this message translates to:
  /// **'في بيانات مش صح. راجعيها وجربي تاني.'**
  String get errInvalidInput;

  /// No description provided for @errNoClinicChildren.
  ///
  /// In ar, this message translates to:
  /// **'مفيش أطفال على رقمك في العيادة.'**
  String get errNoClinicChildren;

  /// No description provided for @errBirthDateMismatch.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ مش مطابق.'**
  String get errBirthDateMismatch;

  /// No description provided for @errLocked.
  ///
  /// In ar, this message translates to:
  /// **'وقفنا المحاولات. كلمي العيادة عشان نكمل.'**
  String get errLocked;

  /// No description provided for @errGeneric.
  ///
  /// In ar, this message translates to:
  /// **'حصلت مشكلة. جربي تاني.'**
  String get errGeneric;

  /// No description provided for @childProfileTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملف طفلي'**
  String get childProfileTitle;

  /// No description provided for @latestMeasurements.
  ///
  /// In ar, this message translates to:
  /// **'آخر قياسات {name}'**
  String latestMeasurements(String name);

  /// No description provided for @measurementsUpdated.
  ///
  /// In ar, this message translates to:
  /// **'اتحدثت {date}'**
  String measurementsUpdated(String date);

  /// No description provided for @measuredOn.
  ///
  /// In ar, this message translates to:
  /// **'اتقاس {date}'**
  String measuredOn(String date);

  /// No description provided for @measureWeight.
  ///
  /// In ar, this message translates to:
  /// **'الوزن'**
  String get measureWeight;

  /// No description provided for @measureLength.
  ///
  /// In ar, this message translates to:
  /// **'الطول'**
  String get measureLength;

  /// No description provided for @measureHead.
  ///
  /// In ar, this message translates to:
  /// **'محيط الرأس'**
  String get measureHead;

  /// No description provided for @unitKg.
  ///
  /// In ar, this message translates to:
  /// **'كجم'**
  String get unitKg;

  /// No description provided for @unitCm.
  ///
  /// In ar, this message translates to:
  /// **'سم'**
  String get unitCm;

  /// No description provided for @notRecordedYet.
  ///
  /// In ar, this message translates to:
  /// **'لسه متسجلش'**
  String get notRecordedYet;

  /// No description provided for @noMeasurements.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش قياسات متسجلة. القياسات بتتسجل في العيادة وقت الكشف.'**
  String get noMeasurements;

  /// No description provided for @growthChart.
  ///
  /// In ar, this message translates to:
  /// **'منحنى النمو'**
  String get growthChart;

  /// No description provided for @growthChartSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'{metric} بالنسبة للعمر'**
  String growthChartSubtitle(String metric);

  /// No description provided for @chartBirth.
  ///
  /// In ar, this message translates to:
  /// **'الولادة'**
  String get chartBirth;

  /// No description provided for @chartBirthWeight.
  ///
  /// In ar, this message translates to:
  /// **'وزن الولادة'**
  String get chartBirthWeight;

  /// No description provided for @chartMonthsAxis.
  ///
  /// In ar, this message translates to:
  /// **'{months} شهور'**
  String chartMonthsAxis(String months);

  /// No description provided for @doctorReviewsMeasurements.
  ///
  /// In ar, this message translates to:
  /// **'الدكتور هيراجع القياسات معاكي في الكشف'**
  String get doctorReviewsMeasurements;

  /// No description provided for @entryVaccines.
  ///
  /// In ar, this message translates to:
  /// **'التطعيمات'**
  String get entryVaccines;

  /// No description provided for @entryVisits.
  ///
  /// In ar, this message translates to:
  /// **'سجل الزيارات'**
  String get entryVisits;

  /// No description provided for @entryFollowUp.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة حسب العمر'**
  String get entryFollowUp;

  /// No description provided for @entryDetails.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الطفل'**
  String get entryDetails;

  /// No description provided for @detailsAllergies.
  ///
  /// In ar, this message translates to:
  /// **'حساسية: {allergies}'**
  String detailsAllergies(String allergies);

  /// No description provided for @detailsNoAllergies.
  ///
  /// In ar, this message translates to:
  /// **'مفيش حساسية متسجلة'**
  String get detailsNoAllergies;

  /// No description provided for @vaccinesTitle.
  ///
  /// In ar, this message translates to:
  /// **'التطعيمات'**
  String get vaccinesTitle;

  /// No description provided for @vaccinesSource.
  ///
  /// In ar, this message translates to:
  /// **'المصدر: {source}'**
  String vaccinesSource(String source);

  /// No description provided for @vaccinesReviewed.
  ///
  /// In ar, this message translates to:
  /// **'آخر مراجعة: {date}'**
  String vaccinesReviewed(String date);

  /// No description provided for @vaccinesBasic.
  ///
  /// In ar, this message translates to:
  /// **'التطعيمات الأساسية'**
  String get vaccinesBasic;

  /// No description provided for @vaccinesAdditional.
  ///
  /// In ar, this message translates to:
  /// **'تطعيمات إضافية'**
  String get vaccinesAdditional;

  /// No description provided for @additionalBadge.
  ///
  /// In ar, this message translates to:
  /// **'إضافي'**
  String get additionalBadge;

  /// No description provided for @additionalChoice.
  ///
  /// In ar, this message translates to:
  /// **'التطعيمات الإضافية اختيارية، والقرار ليكي بعد ما تتكلمي مع الدكتور.'**
  String get additionalChoice;

  /// No description provided for @doseNumber.
  ///
  /// In ar, this message translates to:
  /// **'الجرعة {number}'**
  String doseNumber(String number);

  /// No description provided for @doseDueOn.
  ///
  /// In ar, this message translates to:
  /// **'ميعادها {date}'**
  String doseDueOn(String date);

  /// No description provided for @doseGivenOn.
  ///
  /// In ar, this message translates to:
  /// **'اتاخدت {date}'**
  String doseGivenOn(String date);

  /// No description provided for @doseLot.
  ///
  /// In ar, this message translates to:
  /// **'رقم التشغيلة: {lot}'**
  String doseLot(String lot);

  /// No description provided for @doseScheduled.
  ///
  /// In ar, this message translates to:
  /// **'مجدولة'**
  String get doseScheduled;

  /// No description provided for @doseDue.
  ///
  /// In ar, this message translates to:
  /// **'مستحقة'**
  String get doseDue;

  /// No description provided for @doseGiven.
  ///
  /// In ar, this message translates to:
  /// **'اتاخدت'**
  String get doseGiven;

  /// No description provided for @doseLate.
  ///
  /// In ar, this message translates to:
  /// **'متأخرة'**
  String get doseLate;

  /// No description provided for @doseMissed.
  ///
  /// In ar, this message translates to:
  /// **'فائتة'**
  String get doseMissed;

  /// No description provided for @additionalSuggestedAge.
  ///
  /// In ar, this message translates to:
  /// **'العمر المناسب: {age}'**
  String additionalSuggestedAge(String age);

  /// No description provided for @additionalDoses.
  ///
  /// In ar, this message translates to:
  /// **'عدد الجرعات: {count}'**
  String additionalDoses(String count);

  /// No description provided for @additionalInterval.
  ///
  /// In ar, this message translates to:
  /// **'الفاصل بين الجرعات: {weeks} أسابيع'**
  String additionalInterval(String weeks);

  /// No description provided for @additionalPrice.
  ///
  /// In ar, this message translates to:
  /// **'السعر: {price} جنيه'**
  String additionalPrice(String price);

  /// No description provided for @vaccinesEmpty.
  ///
  /// In ar, this message translates to:
  /// **'جدول التطعيمات لسه مش متاح.'**
  String get vaccinesEmpty;

  /// No description provided for @visitsTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل الزيارات'**
  String get visitsTitle;

  /// No description provided for @visitsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش زيارات متسجلة.'**
  String get visitsEmpty;

  /// No description provided for @visitClinic.
  ///
  /// In ar, this message translates to:
  /// **'كشف'**
  String get visitClinic;

  /// No description provided for @visitVaccine.
  ///
  /// In ar, this message translates to:
  /// **'تطعيم'**
  String get visitVaccine;

  /// No description provided for @visitWalkIn.
  ///
  /// In ar, this message translates to:
  /// **'كشف بدون حجز'**
  String get visitWalkIn;

  /// No description provided for @visitMeasurements.
  ///
  /// In ar, this message translates to:
  /// **'القياسات: {values}'**
  String visitMeasurements(String values);

  /// No description provided for @visitDoses.
  ///
  /// In ar, this message translates to:
  /// **'التطعيمات: {names}'**
  String visitDoses(String names);

  /// No description provided for @followUpTitle.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة حسب العمر'**
  String get followUpTitle;

  /// No description provided for @followUpPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'أمثلة مؤقتة · يعتمدها الدكتور'**
  String get followUpPlaceholder;

  /// No description provided for @whenToCall.
  ///
  /// In ar, this message translates to:
  /// **'متى تتصلين بالدكتور'**
  String get whenToCall;

  /// No description provided for @whenToCallIntro.
  ///
  /// In ar, this message translates to:
  /// **'لو لاحظتي أي علامة من دول، كلمي العيادة فورًا'**
  String get whenToCallIntro;

  /// No description provided for @callClinicPhone.
  ///
  /// In ar, this message translates to:
  /// **'اتصلي بالعيادة'**
  String get callClinicPhone;

  /// No description provided for @callAmbulance.
  ///
  /// In ar, this message translates to:
  /// **'الإسعاف ١٢٣'**
  String get callAmbulance;

  /// No description provided for @followUpDisclaimer.
  ///
  /// In ar, this message translates to:
  /// **'القوايم دي للمتابعة بس، ومش بتشخّص حالة طفلك.'**
  String get followUpDisclaimer;

  /// No description provided for @followUpOverAge.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة حسب العمر بتغطي لحد {years} سنين.'**
  String followUpOverAge(String years);

  /// No description provided for @followUpNoBand.
  ///
  /// In ar, this message translates to:
  /// **'مفيش قائمة متابعة للسن ده لسه.'**
  String get followUpNoBand;

  /// No description provided for @packageTitle.
  ///
  /// In ar, this message translates to:
  /// **'الباقة السنوية للعيلة'**
  String get packageTitle;

  /// No description provided for @packageActiveUntil.
  ///
  /// In ar, this message translates to:
  /// **'نشطة لحد {date}'**
  String packageActiveUntil(String date);

  /// No description provided for @packageEndedOn.
  ///
  /// In ar, this message translates to:
  /// **'خلصت في {date}'**
  String packageEndedOn(String date);

  /// No description provided for @packageActive.
  ///
  /// In ar, this message translates to:
  /// **'نشطة'**
  String get packageActive;

  /// No description provided for @packageEnded.
  ///
  /// In ar, this message translates to:
  /// **'خلصت'**
  String get packageEnded;

  /// No description provided for @packageMonthsLeft.
  ///
  /// In ar, this message translates to:
  /// **'متبقي {months}'**
  String packageMonthsLeft(String months);

  /// No description provided for @offlineBanner.
  ///
  /// In ar, this message translates to:
  /// **'إنتي أوفلاين · دي آخر بيانات اتحملت'**
  String get offlineBanner;

  /// No description provided for @needsConnectionFirstTime.
  ///
  /// In ar, this message translates to:
  /// **'محتاجين إنترنت أول مرة عشان نحمّل البيانات.'**
  String get needsConnectionFirstTime;
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
      <String>['ar'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
