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

  /// No description provided for @chooseClinic.
  ///
  /// In ar, this message translates to:
  /// **'اختاري العيادة'**
  String get chooseClinic;

  /// No description provided for @noClinics.
  ///
  /// In ar, this message translates to:
  /// **'مفيش عيادات متاحة للحجز دلوقتي.'**
  String get noClinics;

  /// No description provided for @changeClinic.
  ///
  /// In ar, this message translates to:
  /// **'تغيير'**
  String get changeClinic;

  /// No description provided for @bookingClinicInactive.
  ///
  /// In ar, this message translates to:
  /// **'العيادة دي مش بتستقبل حجوزات دلوقتي. اختاري عيادة تانية.'**
  String get bookingClinicInactive;

  /// No description provided for @labelClinic.
  ///
  /// In ar, this message translates to:
  /// **'العيادة'**
  String get labelClinic;

  /// No description provided for @labelAddress.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get labelAddress;

  /// No description provided for @listSeparator.
  ///
  /// In ar, this message translates to:
  /// **'، '**
  String get listSeparator;

  /// No description provided for @homeWelcome.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا بيكي'**
  String get homeWelcome;

  /// No description provided for @homeGreeting.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا يا {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeClinics.
  ///
  /// In ar, this message translates to:
  /// **'عياداتنا'**
  String get homeClinics;

  /// No description provided for @doctorName.
  ///
  /// In ar, this message translates to:
  /// **'د. أحمد العبد'**
  String get doctorName;

  /// No description provided for @doctorTitle.
  ///
  /// In ar, this message translates to:
  /// **'استشاري طب الأطفال وحديثي الولادة'**
  String get doctorTitle;

  /// No description provided for @doctorTagline.
  ///
  /// In ar, this message translates to:
  /// **'موجودين عشان نطمنك'**
  String get doctorTagline;

  /// No description provided for @bookHere.
  ///
  /// In ar, this message translates to:
  /// **'احجزي هنا'**
  String get bookHere;

  /// No description provided for @callClinicShort.
  ///
  /// In ar, this message translates to:
  /// **'اتصلي'**
  String get callClinicShort;

  /// No description provided for @whatsapp.
  ///
  /// In ar, this message translates to:
  /// **'واتساب'**
  String get whatsapp;

  /// No description provided for @callClinicAt.
  ///
  /// In ar, this message translates to:
  /// **'اتصلي بعيادة {area}'**
  String callClinicAt(String area);

  /// No description provided for @additionalPriceAt.
  ///
  /// In ar, this message translates to:
  /// **'السعر في {area}: {price} جنيه'**
  String additionalPriceAt(String area, String price);

  /// No description provided for @visitAtClinic.
  ///
  /// In ar, this message translates to:
  /// **'في {clinic}'**
  String visitAtClinic(String clinic);

  /// No description provided for @dashTitle.
  ///
  /// In ar, this message translates to:
  /// **'لوحة العيادة'**
  String get dashTitle;

  /// No description provided for @dashNavToday.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get dashNavToday;

  /// No description provided for @dashNavChildren.
  ///
  /// In ar, this message translates to:
  /// **'ملفات الأطفال'**
  String get dashNavChildren;

  /// No description provided for @dashNavClinic.
  ///
  /// In ar, this message translates to:
  /// **'العيادة'**
  String get dashNavClinic;

  /// No description provided for @dashNavContent.
  ///
  /// In ar, this message translates to:
  /// **'المحتوى'**
  String get dashNavContent;

  /// No description provided for @dashNavFollowUp.
  ///
  /// In ar, this message translates to:
  /// **'قوائم المتابعة'**
  String get dashNavFollowUp;

  /// No description provided for @dashNavReports.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get dashNavReports;

  /// No description provided for @dashNavVaccines.
  ///
  /// In ar, this message translates to:
  /// **'التطعيمات'**
  String get dashNavVaccines;

  /// No description provided for @dashNavSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get dashNavSettings;

  /// No description provided for @dashNavStaff.
  ///
  /// In ar, this message translates to:
  /// **'الموظفين'**
  String get dashNavStaff;

  /// No description provided for @dashNavAudit.
  ///
  /// In ar, this message translates to:
  /// **'سجل التدقيق'**
  String get dashNavAudit;

  /// No description provided for @dashSwitchClinic.
  ///
  /// In ar, this message translates to:
  /// **'تغيير العيادة'**
  String get dashSwitchClinic;

  /// No description provided for @dashSignInTitle.
  ///
  /// In ar, this message translates to:
  /// **'دخول الموظفين'**
  String get dashSignInTitle;

  /// No description provided for @dashEmail.
  ///
  /// In ar, this message translates to:
  /// **'الإيميل'**
  String get dashEmail;

  /// No description provided for @dashPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر'**
  String get dashPassword;

  /// No description provided for @dashSignIn.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get dashSignIn;

  /// No description provided for @dashErrSignIn.
  ///
  /// In ar, this message translates to:
  /// **'الإيميل أو كلمة السر مش صح.'**
  String get dashErrSignIn;

  /// No description provided for @dashErrDisabled.
  ///
  /// In ar, this message translates to:
  /// **'الحساب ده متوقف. كلمي الدكتور.'**
  String get dashErrDisabled;

  /// No description provided for @dashNotStaff.
  ///
  /// In ar, this message translates to:
  /// **'الحساب ده مش حساب موظف شغال. اخرجي وادخلي بحساب الموظف.'**
  String get dashNotStaff;

  /// No description provided for @dashPasswordTitle.
  ///
  /// In ar, this message translates to:
  /// **'غيّري كلمة السر'**
  String get dashPasswordTitle;

  /// No description provided for @dashPasswordIntro.
  ///
  /// In ar, this message translates to:
  /// **'دي أول مرة تدخلي. اختاري كلمة سر خاصة بيكي بدل المؤقتة.'**
  String get dashPasswordIntro;

  /// No description provided for @dashNewPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر الجديدة'**
  String get dashNewPassword;

  /// No description provided for @dashNewPasswordAgain.
  ///
  /// In ar, this message translates to:
  /// **'اكتبيها تاني'**
  String get dashNewPasswordAgain;

  /// No description provided for @dashPasswordRule.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر لازم ٨ حروف على الأقل.'**
  String get dashPasswordRule;

  /// No description provided for @dashPasswordMismatch.
  ///
  /// In ar, this message translates to:
  /// **'الكلمتين مش زي بعض.'**
  String get dashPasswordMismatch;

  /// No description provided for @dashTodayTitle.
  ///
  /// In ar, this message translates to:
  /// **'اليوم · {date}'**
  String dashTodayTitle(String date);

  /// No description provided for @dashCalendar.
  ///
  /// In ar, this message translates to:
  /// **'مواعيد اليوم'**
  String get dashCalendar;

  /// No description provided for @dashClosedToday.
  ///
  /// In ar, this message translates to:
  /// **'العيادة مقفولة النهارده.'**
  String get dashClosedToday;

  /// No description provided for @dashQueue.
  ///
  /// In ar, this message translates to:
  /// **'طابور الحضور'**
  String get dashQueue;

  /// No description provided for @dashQueueOrder.
  ///
  /// In ar, this message translates to:
  /// **'بالترتيب حسب وقت الوصول، من غير أولوية.'**
  String get dashQueueOrder;

  /// No description provided for @dashQueueEmpty.
  ///
  /// In ar, this message translates to:
  /// **'مفيش حد وصل لسه.'**
  String get dashQueueEmpty;

  /// No description provided for @dashWaiting.
  ///
  /// In ar, this message translates to:
  /// **'مستني'**
  String get dashWaiting;

  /// No description provided for @dashDoneUnpaid.
  ///
  /// In ar, this message translates to:
  /// **'تم · الدفع لسه متسجلش'**
  String get dashDoneUnpaid;

  /// No description provided for @dashPaid.
  ///
  /// In ar, this message translates to:
  /// **'تم · اتدفع {amount} جنيه'**
  String dashPaid(String amount);

  /// No description provided for @dashMarkArrived.
  ///
  /// In ar, this message translates to:
  /// **'وصل'**
  String get dashMarkArrived;

  /// No description provided for @dashMarkDone.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get dashMarkDone;

  /// No description provided for @dashUndo.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get dashUndo;

  /// No description provided for @dashWalkIn.
  ///
  /// In ar, this message translates to:
  /// **'بدون حجز'**
  String get dashWalkIn;

  /// No description provided for @dashStopWalkIns.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف الحالات بدون حجز'**
  String get dashStopWalkIns;

  /// No description provided for @dashAddWalkIn.
  ///
  /// In ar, this message translates to:
  /// **'إضافة حالة بدون حجز'**
  String get dashAddWalkIn;

  /// No description provided for @dashNoHoursLeft.
  ///
  /// In ar, this message translates to:
  /// **'مفيش ساعات فاضلة النهارده.'**
  String get dashNoHoursLeft;

  /// No description provided for @dashFamilyName.
  ///
  /// In ar, this message translates to:
  /// **'اسم ولي الأمر'**
  String get dashFamilyName;

  /// No description provided for @dashPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل'**
  String get dashPhone;

  /// No description provided for @dashChildrenNames.
  ///
  /// In ar, this message translates to:
  /// **'أسماء الأطفال'**
  String get dashChildrenNames;

  /// No description provided for @dashChildrenNamesHelp.
  ///
  /// In ar, this message translates to:
  /// **'افصلي بين الأسماء بفاصلة.'**
  String get dashChildrenNamesHelp;

  /// No description provided for @dashWalkInAdded.
  ///
  /// In ar, this message translates to:
  /// **'اتضافت الحالة للطابور.'**
  String get dashWalkInAdded;

  /// No description provided for @dashCancelForFamily.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الحجز للأسرة'**
  String get dashCancelForFamily;

  /// No description provided for @dashRecordPayment.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدفع'**
  String get dashRecordPayment;

  /// No description provided for @dashCashAmount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ كاش (جنيه)'**
  String get dashCashAmount;

  /// No description provided for @dashCoveredByPackage.
  ///
  /// In ar, this message translates to:
  /// **'الكشف مغطّى بالباقة'**
  String get dashCoveredByPackage;

  /// No description provided for @dashPaymentSaved.
  ///
  /// In ar, this message translates to:
  /// **'اتسجل الدفع.'**
  String get dashPaymentSaved;

  /// No description provided for @dashClose.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get dashClose;

  /// No description provided for @dashSaved.
  ///
  /// In ar, this message translates to:
  /// **'اتحفظ.'**
  String get dashSaved;

  /// No description provided for @dashAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get dashAdd;

  /// No description provided for @dashEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get dashEdit;

  /// No description provided for @dashRemove.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get dashRemove;

  /// No description provided for @dashSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'اسم الطفل أو رقم ولي الأمر'**
  String get dashSearchHint;

  /// No description provided for @dashSearch.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get dashSearch;

  /// No description provided for @dashNoResults.
  ///
  /// In ar, this message translates to:
  /// **'مفيش نتايج.'**
  String get dashNoResults;

  /// No description provided for @dashBasics.
  ///
  /// In ar, this message translates to:
  /// **'البيانات الأساسية'**
  String get dashBasics;

  /// No description provided for @dashEditBasics.
  ///
  /// In ar, this message translates to:
  /// **'تعديل البيانات'**
  String get dashEditBasics;

  /// No description provided for @dashGuardianPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم ولي الأمر: {phone}'**
  String dashGuardianPhone(String phone);

  /// No description provided for @dashSellPackage.
  ///
  /// In ar, this message translates to:
  /// **'بيع الباقة السنوية'**
  String get dashSellPackage;

  /// No description provided for @dashPackageSold.
  ///
  /// In ar, this message translates to:
  /// **'اتباعت الباقة.'**
  String get dashPackageSold;

  /// No description provided for @dashMeasurements.
  ///
  /// In ar, this message translates to:
  /// **'القياسات'**
  String get dashMeasurements;

  /// No description provided for @dashDoses.
  ///
  /// In ar, this message translates to:
  /// **'التطعيمات المتسجلة'**
  String get dashDoses;

  /// No description provided for @dashAddMeasurement.
  ///
  /// In ar, this message translates to:
  /// **'إضافة قياس'**
  String get dashAddMeasurement;

  /// No description provided for @dashAddDose.
  ///
  /// In ar, this message translates to:
  /// **'إضافة جرعة'**
  String get dashAddDose;

  /// No description provided for @dashCorrect.
  ///
  /// In ar, this message translates to:
  /// **'تصحيح (الدكتور)'**
  String get dashCorrect;

  /// No description provided for @dashDate.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get dashDate;

  /// No description provided for @dashDoseNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الجرعة'**
  String get dashDoseNumber;

  /// No description provided for @dashLot.
  ///
  /// In ar, this message translates to:
  /// **'رقم التشغيلة'**
  String get dashLot;

  /// No description provided for @dashNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة الدكتور'**
  String get dashNote;

  /// No description provided for @dashNoNote.
  ///
  /// In ar, this message translates to:
  /// **'مفيش ملاحظة.'**
  String get dashNoNote;

  /// No description provided for @dashNoteHelp.
  ///
  /// In ar, this message translates to:
  /// **'بيشوفها الدكتور بس.'**
  String get dashNoteHelp;

  /// No description provided for @dashContact.
  ///
  /// In ar, this message translates to:
  /// **'العنوان والتواصل'**
  String get dashContact;

  /// No description provided for @dashPrices.
  ///
  /// In ar, this message translates to:
  /// **'الأسعار'**
  String get dashPrices;

  /// No description provided for @dashVisitPrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر الكشف'**
  String get dashVisitPrice;

  /// No description provided for @dashPackagePrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر الباقة السنوية'**
  String get dashPackagePrice;

  /// No description provided for @dashPackageMonths.
  ///
  /// In ar, this message translates to:
  /// **'مدة الباقة (شهور)'**
  String get dashPackageMonths;

  /// No description provided for @dashSchedule.
  ///
  /// In ar, this message translates to:
  /// **'المواعيد'**
  String get dashSchedule;

  /// No description provided for @dashCapacity.
  ///
  /// In ar, this message translates to:
  /// **'السعة في الساعة'**
  String get dashCapacity;

  /// No description provided for @dashCancelWindow.
  ///
  /// In ar, this message translates to:
  /// **'مهلة الإلغاء (ساعات)'**
  String get dashCancelWindow;

  /// No description provided for @dashHolidays.
  ///
  /// In ar, this message translates to:
  /// **'الإجازات'**
  String get dashHolidays;

  /// No description provided for @dashHolidaysHelp.
  ///
  /// In ar, this message translates to:
  /// **'تواريخ YYYY-MM-DD بينها فاصلة.'**
  String get dashHolidaysHelp;

  /// No description provided for @dashWorkingHoursHelp.
  ///
  /// In ar, this message translates to:
  /// **'ساعات كل يوم بنظام ٢٤ ساعة، مثلًا 17-21 أو 10-14, 17-21. فاضي = مقفول.'**
  String get dashWorkingHoursHelp;

  /// No description provided for @dashVaccineDay.
  ///
  /// In ar, this message translates to:
  /// **'يوم تطعيم'**
  String get dashVaccineDay;

  /// No description provided for @dashVaccineOffers.
  ///
  /// In ar, this message translates to:
  /// **'التطعيمات المتاحة في العيادة وأسعارها'**
  String get dashVaccineOffers;

  /// No description provided for @dashPrice.
  ///
  /// In ar, this message translates to:
  /// **'السعر'**
  String get dashPrice;

  /// No description provided for @dashPriceShown.
  ///
  /// In ar, this message translates to:
  /// **'السعر ظاهر للأم'**
  String get dashPriceShown;

  /// No description provided for @dashVaccineList.
  ///
  /// In ar, this message translates to:
  /// **'قائمة التطعيمات'**
  String get dashVaccineList;

  /// No description provided for @dashScheduleSource.
  ///
  /// In ar, this message translates to:
  /// **'مصدر الجدول'**
  String get dashScheduleSource;

  /// No description provided for @dashApprove.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد'**
  String get dashApprove;

  /// No description provided for @dashApproved.
  ///
  /// In ar, this message translates to:
  /// **'اتعمد الجدول.'**
  String get dashApproved;

  /// No description provided for @dashDueMonths.
  ///
  /// In ar, this message translates to:
  /// **'عند {months} شهور'**
  String dashDueMonths(String months);

  /// No description provided for @dashNewItem.
  ///
  /// In ar, this message translates to:
  /// **'إضافة نصيحة أو فيديو'**
  String get dashNewItem;

  /// No description provided for @dashItemTitle.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get dashItemTitle;

  /// No description provided for @dashCategory.
  ///
  /// In ar, this message translates to:
  /// **'التصنيف'**
  String get dashCategory;

  /// No description provided for @dashAgeFrom.
  ///
  /// In ar, this message translates to:
  /// **'من سن (شهور)'**
  String get dashAgeFrom;

  /// No description provided for @dashAgeTo.
  ///
  /// In ar, this message translates to:
  /// **'لحد سن (شهور)'**
  String get dashAgeTo;

  /// No description provided for @dashLink.
  ///
  /// In ar, this message translates to:
  /// **'الرابط'**
  String get dashLink;

  /// No description provided for @dashBody.
  ///
  /// In ar, this message translates to:
  /// **'النص'**
  String get dashBody;

  /// No description provided for @dashDraftNote.
  ///
  /// In ar, this message translates to:
  /// **'المسودة مش بتظهر للأمهات لحد ما الدكتور ينشرها.'**
  String get dashDraftNote;

  /// No description provided for @dashCatFever.
  ///
  /// In ar, this message translates to:
  /// **'الحرارة'**
  String get dashCatFever;

  /// No description provided for @dashCatFeeding.
  ///
  /// In ar, this message translates to:
  /// **'الرضاعة والهضم'**
  String get dashCatFeeding;

  /// No description provided for @dashCatSleep.
  ///
  /// In ar, this message translates to:
  /// **'النوم'**
  String get dashCatSleep;

  /// No description provided for @dashCatAllergy.
  ///
  /// In ar, this message translates to:
  /// **'الحساسية'**
  String get dashCatAllergy;

  /// No description provided for @dashDraft.
  ///
  /// In ar, this message translates to:
  /// **'مسودة'**
  String get dashDraft;

  /// No description provided for @dashPublished.
  ///
  /// In ar, this message translates to:
  /// **'منشور'**
  String get dashPublished;

  /// No description provided for @dashArchived.
  ///
  /// In ar, this message translates to:
  /// **'مؤرشف'**
  String get dashArchived;

  /// No description provided for @dashPublish.
  ///
  /// In ar, this message translates to:
  /// **'نشر'**
  String get dashPublish;

  /// No description provided for @dashArchive.
  ///
  /// In ar, this message translates to:
  /// **'أرشفة'**
  String get dashArchive;

  /// No description provided for @dashNothingYet.
  ///
  /// In ar, this message translates to:
  /// **'مفيش حاجة لسه.'**
  String get dashNothingYet;

  /// No description provided for @dashSaveDraft.
  ///
  /// In ar, this message translates to:
  /// **'حفظ كمسودة'**
  String get dashSaveDraft;

  /// No description provided for @dashDraftSaved.
  ///
  /// In ar, this message translates to:
  /// **'اتحفظت المسودة.'**
  String get dashDraftSaved;

  /// No description provided for @dashOnePerLine.
  ///
  /// In ar, this message translates to:
  /// **'كل بند في سطر.'**
  String get dashOnePerLine;

  /// No description provided for @dashAddBand.
  ///
  /// In ar, this message translates to:
  /// **'إضافة قائمة سن'**
  String get dashAddBand;

  /// No description provided for @dashFrom.
  ///
  /// In ar, this message translates to:
  /// **'من'**
  String get dashFrom;

  /// No description provided for @dashTo.
  ///
  /// In ar, this message translates to:
  /// **'لحد'**
  String get dashTo;

  /// No description provided for @dashDaily.
  ///
  /// In ar, this message translates to:
  /// **'يومي'**
  String get dashDaily;

  /// No description provided for @dashMonthly.
  ///
  /// In ar, this message translates to:
  /// **'شهري'**
  String get dashMonthly;

  /// No description provided for @dashAllClinics.
  ///
  /// In ar, this message translates to:
  /// **'العيادتين'**
  String get dashAllClinics;

  /// No description provided for @dashShowReport.
  ///
  /// In ar, this message translates to:
  /// **'عرض'**
  String get dashShowReport;

  /// No description provided for @dashExportCsv.
  ///
  /// In ar, this message translates to:
  /// **'تصدير CSV'**
  String get dashExportCsv;

  /// No description provided for @dashTotal.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get dashTotal;

  /// No description provided for @dashRepBookings.
  ///
  /// In ar, this message translates to:
  /// **'الحجوزات'**
  String get dashRepBookings;

  /// No description provided for @dashRepArrivals.
  ///
  /// In ar, this message translates to:
  /// **'الحضور'**
  String get dashRepArrivals;

  /// No description provided for @dashRepNoShows.
  ///
  /// In ar, this message translates to:
  /// **'لم يحضر'**
  String get dashRepNoShows;

  /// No description provided for @dashRepWalkIns.
  ///
  /// In ar, this message translates to:
  /// **'بدون حجز'**
  String get dashRepWalkIns;

  /// No description provided for @dashRepCash.
  ///
  /// In ar, this message translates to:
  /// **'كاش الكشوفات'**
  String get dashRepCash;

  /// No description provided for @dashRepPackages.
  ///
  /// In ar, this message translates to:
  /// **'الباقات المباعة'**
  String get dashRepPackages;

  /// No description provided for @dashSetPolicy.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية والشروط'**
  String get dashSetPolicy;

  /// No description provided for @dashSetPolicyVersion.
  ///
  /// In ar, this message translates to:
  /// **'رقم النسخة (زيادته بتطلب موافقة جديدة)'**
  String get dashSetPolicyVersion;

  /// No description provided for @dashSetPrivacyText.
  ///
  /// In ar, this message translates to:
  /// **'نص سياسة الخصوصية'**
  String get dashSetPrivacyText;

  /// No description provided for @dashSetTermsText.
  ///
  /// In ar, this message translates to:
  /// **'نص الشروط'**
  String get dashSetTermsText;

  /// No description provided for @dashSetSignIn.
  ///
  /// In ar, this message translates to:
  /// **'الدخول'**
  String get dashSetSignIn;

  /// No description provided for @dashSetMaxCodeAttempts.
  ///
  /// In ar, this message translates to:
  /// **'عدد محاولات الكود'**
  String get dashSetMaxCodeAttempts;

  /// No description provided for @dashSetResendWait.
  ///
  /// In ar, this message translates to:
  /// **'انتظار إعادة الإرسال (ثواني)'**
  String get dashSetResendWait;

  /// No description provided for @dashSetReverifyDays.
  ///
  /// In ar, this message translates to:
  /// **'إعادة التحقق بعد (أيام)'**
  String get dashSetReverifyDays;

  /// No description provided for @dashSetBooking.
  ///
  /// In ar, this message translates to:
  /// **'الحجز'**
  String get dashSetBooking;

  /// No description provided for @dashSetHorizon.
  ///
  /// In ar, this message translates to:
  /// **'الحجز لحد كام يوم قدام'**
  String get dashSetHorizon;

  /// No description provided for @dashSetMaxUpcoming.
  ///
  /// In ar, this message translates to:
  /// **'أقصى حجوزات قادمة للعيلة'**
  String get dashSetMaxUpcoming;

  /// No description provided for @dashSetChild.
  ///
  /// In ar, this message translates to:
  /// **'ملف الطفل'**
  String get dashSetChild;

  /// No description provided for @dashSetFollowUpAge.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة لحد سن (شهور)'**
  String get dashSetFollowUpAge;

  /// No description provided for @dashSetLateDays.
  ///
  /// In ar, this message translates to:
  /// **'الجرعة متأخرة بعد (أيام)'**
  String get dashSetLateDays;

  /// No description provided for @dashNewStaff.
  ///
  /// In ar, this message translates to:
  /// **'إضافة موظف'**
  String get dashNewStaff;

  /// No description provided for @dashTempPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة سر مؤقتة'**
  String get dashTempPassword;

  /// No description provided for @dashRoleDoctor.
  ///
  /// In ar, this message translates to:
  /// **'دكتور'**
  String get dashRoleDoctor;

  /// No description provided for @dashRoleSecretary.
  ///
  /// In ar, this message translates to:
  /// **'سكرتيرة'**
  String get dashRoleSecretary;

  /// No description provided for @dashDisabled.
  ///
  /// In ar, this message translates to:
  /// **'متوقف'**
  String get dashDisabled;

  /// No description provided for @dashDisable.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get dashDisable;

  /// No description provided for @dashEnable.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل'**
  String get dashEnable;

  /// No description provided for @dashAction.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get dashAction;

  /// No description provided for @dashAllActions.
  ///
  /// In ar, this message translates to:
  /// **'كل الأنواع'**
  String get dashAllActions;

  /// No description provided for @dashAuditCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} سجل'**
  String dashAuditCount(String count);

  /// No description provided for @dashErrFull.
  ///
  /// In ar, this message translates to:
  /// **'الساعة دي مليانة.'**
  String get dashErrFull;

  /// No description provided for @dashErrWalkInsStopped.
  ///
  /// In ar, this message translates to:
  /// **'الحالات بدون حجز متوقفة النهارده.'**
  String get dashErrWalkInsStopped;

  /// No description provided for @dashErrHourNotOver.
  ///
  /// In ar, this message translates to:
  /// **'الساعة لسه مخلصتش.'**
  String get dashErrHourNotOver;

  /// No description provided for @dashErrWrongStatus.
  ///
  /// In ar, this message translates to:
  /// **'الحالة دي مش مناسبة للخطوة دي.'**
  String get dashErrWrongStatus;

  /// No description provided for @dashErrNotToday.
  ///
  /// In ar, this message translates to:
  /// **'دي مش حجوزات النهارده.'**
  String get dashErrNotToday;

  /// No description provided for @dashErrNoPackage.
  ///
  /// In ar, this message translates to:
  /// **'الأسرة مالهاش باقة سارية.'**
  String get dashErrNoPackage;

  /// No description provided for @dashErrHasPackage.
  ///
  /// In ar, this message translates to:
  /// **'الأسرة عندها باقة سارية بالفعل.'**
  String get dashErrHasPackage;

  /// No description provided for @dashErrDoctorOnly.
  ///
  /// In ar, this message translates to:
  /// **'الخطوة دي للدكتور بس.'**
  String get dashErrDoctorOnly;

  /// No description provided for @dashErrLastDoctor.
  ///
  /// In ar, this message translates to:
  /// **'لازم يفضل حساب دكتور واحد شغال على الأقل.'**
  String get dashErrLastDoctor;

  /// No description provided for @dashErrBookingsOutsideHours.
  ///
  /// In ar, this message translates to:
  /// **'فيه {count} حجوزات مؤكدة هتبقى برة المواعيد الجديدة. انقليها أو الغيها الأول.'**
  String dashErrBookingsOutsideHours(int count);

  /// No description provided for @dashErrOtherClinic.
  ///
  /// In ar, this message translates to:
  /// **'دي بيانات عيادة تانية.'**
  String get dashErrOtherClinic;

  /// No description provided for @dashErrHourClosed.
  ///
  /// In ar, this message translates to:
  /// **'الساعة دي مش متاحة.'**
  String get dashErrHourClosed;

  /// No description provided for @dashErrNotAllowed.
  ///
  /// In ar, this message translates to:
  /// **'مش مسموح.'**
  String get dashErrNotAllowed;

  /// No description provided for @dashErrAlreadyExists.
  ///
  /// In ar, this message translates to:
  /// **'موجود بالفعل.'**
  String get dashErrAlreadyExists;

  /// No description provided for @dashRepPackageRevenue.
  ///
  /// In ar, this message translates to:
  /// **'إيراد الباقات'**
  String get dashRepPackageRevenue;

  /// No description provided for @dashMoveForFamily.
  ///
  /// In ar, this message translates to:
  /// **'نقل الحجز لميعاد تاني'**
  String get dashMoveForFamily;

  /// No description provided for @dashBrand.
  ///
  /// In ar, this message translates to:
  /// **'دكتور النونو'**
  String get dashBrand;

  /// No description provided for @dashAdminSection.
  ///
  /// In ar, this message translates to:
  /// **'إدارة'**
  String get dashAdminSection;

  /// No description provided for @dashUnsaved.
  ///
  /// In ar, this message translates to:
  /// **'فيه تغييرات مش محفوظة'**
  String get dashUnsaved;

  /// No description provided for @dashAllSaved.
  ///
  /// In ar, this message translates to:
  /// **'كل التغييرات محفوظة'**
  String get dashAllSaved;

  /// No description provided for @dashDiscard.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get dashDiscard;

  /// No description provided for @dashSaveChanges.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التغييرات'**
  String get dashSaveChanges;

  /// No description provided for @dashPickRange.
  ///
  /// In ar, this message translates to:
  /// **'اختاري الفترة'**
  String get dashPickRange;

  /// No description provided for @dashEgp.
  ///
  /// In ar, this message translates to:
  /// **'جنيه'**
  String get dashEgp;

  /// No description provided for @dashKpiBookings.
  ///
  /// In ar, this message translates to:
  /// **'الحجوزات'**
  String get dashKpiBookings;

  /// No description provided for @dashKpiCapacity.
  ///
  /// In ar, this message translates to:
  /// **'من {count} مكان'**
  String dashKpiCapacity(String count);

  /// No description provided for @dashKpiArrived.
  ///
  /// In ar, this message translates to:
  /// **'وصلوا'**
  String get dashKpiArrived;

  /// No description provided for @dashKpiDone.
  ///
  /// In ar, this message translates to:
  /// **'تم الكشف'**
  String get dashKpiDone;

  /// No description provided for @dashKpiNoShow.
  ///
  /// In ar, this message translates to:
  /// **'لم يحضر'**
  String get dashKpiNoShow;

  /// No description provided for @dashKpiCash.
  ///
  /// In ar, this message translates to:
  /// **'كاش النهارده'**
  String get dashKpiCash;

  /// No description provided for @dashKpiCashNote.
  ///
  /// In ar, this message translates to:
  /// **'كشوفات بس، من غير الباقات'**
  String get dashKpiCashNote;

  /// No description provided for @dashHourOver.
  ///
  /// In ar, this message translates to:
  /// **'خلصت'**
  String get dashHourOver;

  /// No description provided for @dashHourNow.
  ///
  /// In ar, this message translates to:
  /// **'دلوقتي'**
  String get dashHourNow;

  /// No description provided for @dashTodayBookings.
  ///
  /// In ar, this message translates to:
  /// **'حجوزات النهارده'**
  String get dashTodayBookings;

  /// No description provided for @dashAllHours.
  ///
  /// In ar, this message translates to:
  /// **'كل الساعات'**
  String get dashAllHours;

  /// No description provided for @dashColNumber.
  ///
  /// In ar, this message translates to:
  /// **'#'**
  String get dashColNumber;

  /// No description provided for @dashColChild.
  ///
  /// In ar, this message translates to:
  /// **'الطفل'**
  String get dashColChild;

  /// No description provided for @dashColVisit.
  ///
  /// In ar, this message translates to:
  /// **'الزيارة'**
  String get dashColVisit;

  /// No description provided for @dashColStatus.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get dashColStatus;

  /// No description provided for @dashColPayment.
  ///
  /// In ar, this message translates to:
  /// **'الدفع'**
  String get dashColPayment;

  /// No description provided for @dashColAction.
  ///
  /// In ar, this message translates to:
  /// **'إجراء'**
  String get dashColAction;

  /// No description provided for @dashOpenFile.
  ///
  /// In ar, this message translates to:
  /// **'الملف'**
  String get dashOpenFile;

  /// No description provided for @dashPayPackage.
  ///
  /// In ar, this message translates to:
  /// **'باقة'**
  String get dashPayPackage;

  /// No description provided for @dashPayCash.
  ///
  /// In ar, this message translates to:
  /// **'{amount} ج'**
  String dashPayCash(String amount);

  /// No description provided for @dashClinicContact.
  ///
  /// In ar, this message translates to:
  /// **'بيانات العيادة والتواصل'**
  String get dashClinicContact;

  /// No description provided for @dashPricesBooking.
  ///
  /// In ar, this message translates to:
  /// **'الأسعار والحجز'**
  String get dashPricesBooking;

  /// No description provided for @dashHoursAndVaccineDays.
  ///
  /// In ar, this message translates to:
  /// **'مواعيد العمل وأيام التطعيم'**
  String get dashHoursAndVaccineDays;

  /// No description provided for @dashHoursHint.
  ///
  /// In ar, this message translates to:
  /// **'اختاري فترات كل يوم من القائمة. يوم من غير فترات = مقفول.'**
  String get dashHoursHint;

  /// No description provided for @dashAddRange.
  ///
  /// In ar, this message translates to:
  /// **'فترة'**
  String get dashAddRange;

  /// No description provided for @dashDayClosed.
  ///
  /// In ar, this message translates to:
  /// **'مقفول'**
  String get dashDayClosed;

  /// No description provided for @dashHolidayHint.
  ///
  /// In ar, this message translates to:
  /// **'الأيام دي العيادة مقفولة فيها ومش بتظهر في الحجز.'**
  String get dashHolidayHint;

  /// No description provided for @dashAddHoliday.
  ///
  /// In ar, this message translates to:
  /// **'إجازة'**
  String get dashAddHoliday;

  /// No description provided for @dashHolidayWarn.
  ///
  /// In ar, this message translates to:
  /// **'لو فيه حجوزات مؤكدة في يوم إجازة، الحفظ هيتوقف لحد ما تنقليها أو تلغيها.'**
  String get dashHolidayWarn;

  /// No description provided for @dashNoHolidays.
  ///
  /// In ar, this message translates to:
  /// **'مفيش إجازات جاية.'**
  String get dashNoHolidays;

  /// No description provided for @dashVaccinePricesClinic.
  ///
  /// In ar, this message translates to:
  /// **'أسعار التطعيمات في العيادة'**
  String get dashVaccinePricesClinic;

  /// No description provided for @dashOffered.
  ///
  /// In ar, this message translates to:
  /// **'متاح'**
  String get dashOffered;

  /// No description provided for @dashShownToGuardian.
  ///
  /// In ar, this message translates to:
  /// **'يظهر للأم'**
  String get dashShownToGuardian;

  /// No description provided for @dashPriceAtClinic.
  ///
  /// In ar, this message translates to:
  /// **'بالسعر في العيادة'**
  String get dashPriceAtClinic;

  /// No description provided for @dashUnitMonths.
  ///
  /// In ar, this message translates to:
  /// **'شهر'**
  String get dashUnitMonths;

  /// No description provided for @dashUnitHours.
  ///
  /// In ar, this message translates to:
  /// **'ساعة'**
  String get dashUnitHours;

  /// No description provided for @dashUnitPerHour.
  ///
  /// In ar, this message translates to:
  /// **'طفل/ساعة'**
  String get dashUnitPerHour;

  /// No description provided for @dashChildFileTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملف الطفل'**
  String get dashChildFileTitle;

  /// No description provided for @dashChildFileAudited.
  ///
  /// In ar, this message translates to:
  /// **'فتح الملف ده اتسجل في سجل التدقيق'**
  String get dashChildFileAudited;

  /// No description provided for @dashBack.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get dashBack;

  /// No description provided for @dashVisits.
  ///
  /// In ar, this message translates to:
  /// **'الزيارات'**
  String get dashVisits;

  /// No description provided for @dashDoctorNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات الدكتور'**
  String get dashDoctorNotes;

  /// No description provided for @dashDoctorOnly.
  ///
  /// In ar, this message translates to:
  /// **'للدكتور بس'**
  String get dashDoctorOnly;

  /// No description provided for @dashNewMeasurement.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل قياس جديد'**
  String get dashNewMeasurement;

  /// No description provided for @dashSaveMeasurement.
  ///
  /// In ar, this message translates to:
  /// **'حفظ القياس'**
  String get dashSaveMeasurement;

  /// No description provided for @dashMeasurementHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتبي قيمة واحدة على الأقل. التصحيح بعد الحفظ للدكتور بس.'**
  String get dashMeasurementHint;

  /// No description provided for @dashMeasurementHistory.
  ///
  /// In ar, this message translates to:
  /// **'القياسات المتسجلة'**
  String get dashMeasurementHistory;

  /// No description provided for @dashNumbersOnly.
  ///
  /// In ar, this message translates to:
  /// **'القياسات معروضة بالأرقام بس، من غير أي حكم طبي.'**
  String get dashNumbersOnly;

  /// No description provided for @dashColDate.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get dashColDate;

  /// No description provided for @dashColClinic.
  ///
  /// In ar, this message translates to:
  /// **'العيادة'**
  String get dashColClinic;

  /// No description provided for @dashColRecorder.
  ///
  /// In ar, this message translates to:
  /// **'سجّله'**
  String get dashColRecorder;

  /// No description provided for @dashColVaccine.
  ///
  /// In ar, this message translates to:
  /// **'التطعيم'**
  String get dashColVaccine;

  /// No description provided for @dashColDose.
  ///
  /// In ar, this message translates to:
  /// **'الجرعة'**
  String get dashColDose;

  /// No description provided for @dashColLot.
  ///
  /// In ar, this message translates to:
  /// **'التشغيلة'**
  String get dashColLot;

  /// No description provided for @dashColNote.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظة'**
  String get dashColNote;

  /// No description provided for @dashCorrectShort.
  ///
  /// In ar, this message translates to:
  /// **'تصحيح'**
  String get dashCorrectShort;

  /// No description provided for @dashCorrected.
  ///
  /// In ar, this message translates to:
  /// **'اتصحح'**
  String get dashCorrected;

  /// No description provided for @dashGuardian.
  ///
  /// In ar, this message translates to:
  /// **'ولي الأمر'**
  String get dashGuardian;

  /// No description provided for @dashClinicsVisited.
  ///
  /// In ar, this message translates to:
  /// **'زار: {clinics}'**
  String dashClinicsVisited(String clinics);

  /// No description provided for @dashNoPackage.
  ///
  /// In ar, this message translates to:
  /// **'من غير باقة'**
  String get dashNoPackage;

  /// No description provided for @dashResultsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} نتيجة'**
  String dashResultsCount(String count);

  /// No description provided for @dashReportFilters.
  ///
  /// In ar, this message translates to:
  /// **'الفترة والعيادة'**
  String get dashReportFilters;

  /// No description provided for @dashReportResult.
  ///
  /// In ar, this message translates to:
  /// **'النتيجة'**
  String get dashReportResult;

  /// No description provided for @dashStaffList.
  ///
  /// In ar, this message translates to:
  /// **'الحسابات'**
  String get dashStaffList;

  /// No description provided for @dashActive.
  ///
  /// In ar, this message translates to:
  /// **'شغال'**
  String get dashActive;

  /// No description provided for @dashAuditHint.
  ///
  /// In ar, this message translates to:
  /// **'كل فتح لملف طفل وكل تصحيح بيتسجل هنا. السجل للقراءة بس.'**
  String get dashAuditHint;

  /// No description provided for @dashContentList.
  ///
  /// In ar, this message translates to:
  /// **'النصايح والفيديوهات'**
  String get dashContentList;

  /// No description provided for @dashFollowUpBands.
  ///
  /// In ar, this message translates to:
  /// **'قوايم المتابعة حسب السن'**
  String get dashFollowUpBands;

  /// No description provided for @dashDangerSigns.
  ///
  /// In ar, this message translates to:
  /// **'علامات الخطر'**
  String get dashDangerSigns;

  /// No description provided for @dashCatalogue.
  ///
  /// In ar, this message translates to:
  /// **'التطعيمات في التطبيق'**
  String get dashCatalogue;

  /// No description provided for @dashSettingsHint.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات للعيلة كلها في العيادتين.'**
  String get dashSettingsHint;

  /// No description provided for @dashClinicArea.
  ///
  /// In ar, this message translates to:
  /// **'عيادة {area}'**
  String dashClinicArea(String area);

  /// No description provided for @dashRegisterFamily.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل أسرة'**
  String get dashRegisterFamily;

  /// No description provided for @dashRegisterFamilyHint.
  ///
  /// In ar, this message translates to:
  /// **'رقم ولي الأمر وبيانات الأطفال. ولي الأمر يربطهم بحسابه من التطبيق بعد التحقق.'**
  String get dashRegisterFamilyHint;

  /// No description provided for @dashRegisterWalkIn.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الأسرة'**
  String get dashRegisterWalkIn;

  /// No description provided for @dashChildN.
  ///
  /// In ar, this message translates to:
  /// **'الطفل {n}'**
  String dashChildN(String n);

  /// No description provided for @dashAddChild.
  ///
  /// In ar, this message translates to:
  /// **'طفل تاني'**
  String get dashAddChild;

  /// No description provided for @dashBirthWeight.
  ///
  /// In ar, this message translates to:
  /// **'وزن الولادة (اختياري)'**
  String get dashBirthWeight;

  /// No description provided for @dashAllergiesOptional.
  ///
  /// In ar, this message translates to:
  /// **'الحساسية (اختياري)'**
  String get dashAllergiesOptional;

  /// No description provided for @dashFamilyRegistered.
  ///
  /// In ar, this message translates to:
  /// **'اتسجلت الأسرة.'**
  String get dashFamilyRegistered;

  /// No description provided for @dashDuplicateTitle.
  ///
  /// In ar, this message translates to:
  /// **'الطفل ده متسجل قبل كده على نفس الرقم'**
  String get dashDuplicateTitle;

  /// No description provided for @dashDuplicateBody.
  ///
  /// In ar, this message translates to:
  /// **'مفيش حاجة اتسجلت. شيلي الطفل المكرر من القايمة واحفظي تاني، أو افتحي ملفه.'**
  String get dashDuplicateBody;

  /// No description provided for @dashOpenExisting.
  ///
  /// In ar, this message translates to:
  /// **'افتحي الملف'**
  String get dashOpenExisting;

  /// No description provided for @dashMergeFile.
  ///
  /// In ar, this message translates to:
  /// **'دمج ملف مكرر'**
  String get dashMergeFile;

  /// No description provided for @dashMergeHint.
  ///
  /// In ar, this message translates to:
  /// **'اختاري الملف التاني لنفس الطفل على نفس الرقم. القياسات والتطعيمات والزيارات بتتنقل للملف ده، والملف التاني بيتقفل.'**
  String get dashMergeHint;

  /// No description provided for @dashMergeKeep.
  ///
  /// In ar, this message translates to:
  /// **'الملف اللي هيفضل'**
  String get dashMergeKeep;

  /// No description provided for @dashMergeClose.
  ///
  /// In ar, this message translates to:
  /// **'الملف اللي هيتقفل'**
  String get dashMergeClose;

  /// No description provided for @dashMergeNoOthers.
  ///
  /// In ar, this message translates to:
  /// **'مفيش ملفات تانية مفتوحة على نفس الرقم.'**
  String get dashMergeNoOthers;

  /// No description provided for @dashMergeConfirm.
  ///
  /// In ar, this message translates to:
  /// **'دمج الملفين'**
  String get dashMergeConfirm;

  /// No description provided for @dashMerged.
  ///
  /// In ar, this message translates to:
  /// **'اتدمج الملفين.'**
  String get dashMerged;

  /// No description provided for @dashRecordCounts.
  ///
  /// In ar, this message translates to:
  /// **'{m} قياس · {d} جرعة · {v} زيارة'**
  String dashRecordCounts(String m, String d, String v);

  /// No description provided for @dashFileClosed.
  ///
  /// In ar, this message translates to:
  /// **'الملف ده اتقفل واتدمج في ملف تاني.'**
  String get dashFileClosed;

  /// No description provided for @dashOpenKept.
  ///
  /// In ar, this message translates to:
  /// **'افتحي الملف الأساسي'**
  String get dashOpenKept;

  /// No description provided for @dashLinkToAccount.
  ///
  /// In ar, this message translates to:
  /// **'ربط بحساب ولي الأمر'**
  String get dashLinkToAccount;

  /// No description provided for @dashLinkConfirm.
  ///
  /// In ar, this message translates to:
  /// **'اتأكدي من شخصية ولي الأمر الأول. كل الأطفال غير المربوطين على الرقم ده هيظهروا في حسابه.'**
  String get dashLinkConfirm;

  /// No description provided for @dashLinked.
  ///
  /// In ar, this message translates to:
  /// **'اتربط الأطفال بحساب ولي الأمر.'**
  String get dashLinked;

  /// No description provided for @dashNotLinked.
  ///
  /// In ar, this message translates to:
  /// **'مش مربوط بالتطبيق'**
  String get dashNotLinked;

  /// No description provided for @dashErrDuplicate.
  ///
  /// In ar, this message translates to:
  /// **'الطفل ده متسجل قبل كده على نفس الرقم.'**
  String get dashErrDuplicate;

  /// No description provided for @dashErrSameFile.
  ///
  /// In ar, this message translates to:
  /// **'لازم تختاري ملف تاني.'**
  String get dashErrSameFile;

  /// No description provided for @dashErrOtherNumber.
  ///
  /// In ar, this message translates to:
  /// **'الملفين على أرقام مختلفة.'**
  String get dashErrOtherNumber;

  /// No description provided for @dashErrClosed.
  ///
  /// In ar, this message translates to:
  /// **'الملف ده اتقفل قبل كده.'**
  String get dashErrClosed;

  /// No description provided for @dashErrBookedTogether.
  ///
  /// In ar, this message translates to:
  /// **'فيه حجز جاي فيه الطفلين مع بعض. عدّليه أو الغيه الأول.'**
  String get dashErrBookedTogether;

  /// No description provided for @dashErrTooLarge.
  ///
  /// In ar, this message translates to:
  /// **'الملف كبير على الدمج مرة واحدة. كلمي الدعم.'**
  String get dashErrTooLarge;

  /// No description provided for @dashErrNoAccount.
  ///
  /// In ar, this message translates to:
  /// **'مفيش حساب في التطبيق على الرقم ده لسه.'**
  String get dashErrNoAccount;

  /// No description provided for @dashErrAlreadyLinked.
  ///
  /// In ar, this message translates to:
  /// **'الطفل مربوط بالفعل.'**
  String get dashErrAlreadyLinked;

  /// No description provided for @dashUnlockReverify.
  ///
  /// In ar, this message translates to:
  /// **'فك قفل التحقق'**
  String get dashUnlockReverify;

  /// No description provided for @dashUnlockConfirm.
  ///
  /// In ar, this message translates to:
  /// **'اتأكدي من شخصية ولي الأمر الأول. بعد كده يقدر يتحقق من تاني في التطبيق.'**
  String get dashUnlockConfirm;

  /// No description provided for @dashUnlocked.
  ///
  /// In ar, this message translates to:
  /// **'اتفك القفل.'**
  String get dashUnlocked;

  /// No description provided for @dashErrNotLocked.
  ///
  /// In ar, this message translates to:
  /// **'الحساب مش مقفول.'**
  String get dashErrNotLocked;

  /// No description provided for @clinicWaitingRoom.
  ///
  /// In ar, this message translates to:
  /// **'مكان الانتظار في العيادة'**
  String get clinicWaitingRoom;

  /// No description provided for @welcomeWaitingRoom.
  ///
  /// In ar, this message translates to:
  /// **'مكان الانتظار في العيادة'**
  String get welcomeWaitingRoom;

  /// No description provided for @welcomeWaitingRoomCaption.
  ///
  /// In ar, this message translates to:
  /// **'مكان مريح للأطفال وأهاليهم'**
  String get welcomeWaitingRoomCaption;

  /// No description provided for @notifTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notifTitle;

  /// No description provided for @notifNew.
  ///
  /// In ar, this message translates to:
  /// **'الجديد'**
  String get notifNew;

  /// No description provided for @notifEarlier.
  ///
  /// In ar, this message translates to:
  /// **'قبل كده'**
  String get notifEarlier;

  /// No description provided for @notifMarkAllRead.
  ///
  /// In ar, this message translates to:
  /// **'تعليم الكل كمقروء'**
  String get notifMarkAllRead;

  /// No description provided for @notifEmpty.
  ///
  /// In ar, this message translates to:
  /// **'مفيش إشعارات لسه. هنفكرك بمواعيد الحجز والتطعيمات هنا.'**
  String get notifEmpty;

  /// No description provided for @notifSettings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الإشعارات'**
  String get notifSettings;

  /// No description provided for @notifBookingSwitch.
  ///
  /// In ar, this message translates to:
  /// **'تذكير الحجز'**
  String get notifBookingSwitch;

  /// No description provided for @notifBookingSwitchSub.
  ///
  /// In ar, this message translates to:
  /// **'قبل الميعاد بيوم وبساعة'**
  String get notifBookingSwitchSub;

  /// No description provided for @notifVaccineSwitch.
  ///
  /// In ar, this message translates to:
  /// **'ميعاد التطعيم'**
  String get notifVaccineSwitch;

  /// No description provided for @notifVaccineSwitchSub.
  ///
  /// In ar, this message translates to:
  /// **'قبلها بـ ٣ أيام وفي يومها'**
  String get notifVaccineSwitchSub;

  /// No description provided for @notifOffNote.
  ///
  /// In ar, this message translates to:
  /// **'لو قفلتي نوع، هتلاقي التذكير برضه هنا في الصفحة دي.'**
  String get notifOffNote;

  /// No description provided for @notifDenied.
  ///
  /// In ar, this message translates to:
  /// **'الموبايل مش سامح للتطبيق يعرض إشعارات، فالتذكيرات هتفضل هنا في الصفحة بس.'**
  String get notifDenied;

  /// No description provided for @notifOpenSettings.
  ///
  /// In ar, this message translates to:
  /// **'افتحي إعدادات الموبايل'**
  String get notifOpenSettings;

  /// No description provided for @notifAskBody.
  ///
  /// In ar, this message translates to:
  /// **'نفكرك قبل الميعاد بيوم وبساعة؟'**
  String get notifAskBody;

  /// No description provided for @notifAskButton.
  ///
  /// In ar, this message translates to:
  /// **'فعّلي التذكيرات'**
  String get notifAskButton;

  /// No description provided for @notifUnreadCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} إشعارات جديدة'**
  String notifUnreadCount(String count);

  /// No description provided for @remindBookingDay.
  ///
  /// In ar, this message translates to:
  /// **'ميعادك بكرة'**
  String get remindBookingDay;

  /// No description provided for @remindBookingHour.
  ///
  /// In ar, this message translates to:
  /// **'ميعادك بعد ساعة'**
  String get remindBookingHour;

  /// No description provided for @remindVaccineSoon.
  ///
  /// In ar, this message translates to:
  /// **'تطعيم {child} بعد ٣ أيام'**
  String remindVaccineSoon(String child);

  /// No description provided for @remindVaccineToday.
  ///
  /// In ar, this message translates to:
  /// **'تطعيم {child} النهارده'**
  String remindVaccineToday(String child);

  /// No description provided for @remindVaccineBody.
  ///
  /// In ar, this message translates to:
  /// **'{vaccine} · {date}'**
  String remindVaccineBody(String vaccine, String date);

  /// No description provided for @remindVaccineDose.
  ///
  /// In ar, this message translates to:
  /// **'{vaccine} · الجرعة {dose}'**
  String remindVaccineDose(String vaccine, String dose);

  /// No description provided for @eventBookingConfirmed.
  ///
  /// In ar, this message translates to:
  /// **'تم تأكيد حجزك'**
  String get eventBookingConfirmed;

  /// No description provided for @eventBookingCancelled.
  ///
  /// In ar, this message translates to:
  /// **'اتلغى حجزك'**
  String get eventBookingCancelled;

  /// No description provided for @notifYesterday.
  ///
  /// In ar, this message translates to:
  /// **'أمس'**
  String get notifYesterday;

  /// No description provided for @notifUnread.
  ///
  /// In ar, this message translates to:
  /// **'غير مقروء'**
  String get notifUnread;

  /// No description provided for @splashDoctorLine.
  ///
  /// In ar, this message translates to:
  /// **'د. أحمد العبد · طب الأطفال وحديثي الولادة'**
  String get splashDoctorLine;

  /// No description provided for @navMe.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get navMe;

  /// No description provided for @meTitle.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get meTitle;

  /// No description provided for @meEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get meEdit;

  /// No description provided for @meChildren.
  ///
  /// In ar, this message translates to:
  /// **'أطفالي'**
  String get meChildren;

  /// No description provided for @meAddChild.
  ///
  /// In ar, this message translates to:
  /// **'إضافة طفل'**
  String get meAddChild;

  /// No description provided for @mePackage.
  ///
  /// In ar, this message translates to:
  /// **'الباقة'**
  String get mePackage;

  /// No description provided for @meAppearance.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get meAppearance;

  /// No description provided for @meTheme.
  ///
  /// In ar, this message translates to:
  /// **'الوضع'**
  String get meTheme;

  /// No description provided for @themeLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In ar, this message translates to:
  /// **'زي الموبايل'**
  String get themeSystem;

  /// No description provided for @meTextSize.
  ///
  /// In ar, this message translates to:
  /// **'حجم الخط'**
  String get meTextSize;

  /// No description provided for @textSmall.
  ///
  /// In ar, this message translates to:
  /// **'صغير'**
  String get textSmall;

  /// No description provided for @textNormal.
  ///
  /// In ar, this message translates to:
  /// **'عادي'**
  String get textNormal;

  /// No description provided for @textLarge.
  ///
  /// In ar, this message translates to:
  /// **'كبير'**
  String get textLarge;

  /// No description provided for @meSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get meSettings;

  /// No description provided for @meLanguage.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get meLanguage;

  /// No description provided for @meLanguageArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get meLanguageArabic;

  /// No description provided for @meEnglishSoon.
  ///
  /// In ar, this message translates to:
  /// **'English قريبًا'**
  String get meEnglishSoon;

  /// No description provided for @meNotifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات والتذكيرات'**
  String get meNotifications;

  /// No description provided for @meNotificationsBoth.
  ///
  /// In ar, this message translates to:
  /// **'الحجز والتطعيمات شغالين'**
  String get meNotificationsBoth;

  /// No description provided for @meNotificationsBooking.
  ///
  /// In ar, this message translates to:
  /// **'الحجز بس شغال'**
  String get meNotificationsBooking;

  /// No description provided for @meNotificationsVaccine.
  ///
  /// In ar, this message translates to:
  /// **'التطعيمات بس شغالة'**
  String get meNotificationsVaccine;

  /// No description provided for @meNotificationsOff.
  ///
  /// In ar, this message translates to:
  /// **'مقفولين'**
  String get meNotificationsOff;

  /// No description provided for @mePreferredClinic.
  ///
  /// In ar, this message translates to:
  /// **'العيادة المفضلة'**
  String get mePreferredClinic;

  /// No description provided for @mePreferredClinicSub.
  ///
  /// In ar, this message translates to:
  /// **'بتظهر أول ما تحجزي'**
  String get mePreferredClinicSub;

  /// No description provided for @mePreferredNone.
  ///
  /// In ar, this message translates to:
  /// **'مش محددة'**
  String get mePreferredNone;

  /// No description provided for @meAbout.
  ///
  /// In ar, this message translates to:
  /// **'عن التطبيق'**
  String get meAbout;

  /// No description provided for @meWhatsApp.
  ///
  /// In ar, this message translates to:
  /// **'كلمي العيادة على واتساب'**
  String get meWhatsApp;

  /// No description provided for @mePrivacy.
  ///
  /// In ar, this message translates to:
  /// **'الخصوصية والشروط'**
  String get mePrivacy;

  /// No description provided for @meRate.
  ///
  /// In ar, this message translates to:
  /// **'قيّمي التطبيق'**
  String get meRate;

  /// No description provided for @meRateSoon.
  ///
  /// In ar, this message translates to:
  /// **'التقييم هيتفعّل لما التطبيق ينزل على المتجر.'**
  String get meRateSoon;

  /// No description provided for @meVersion.
  ///
  /// In ar, this message translates to:
  /// **'دكتور النونو · الإصدار {version}'**
  String meVersion(String version);

  /// No description provided for @meSignInPrompt.
  ///
  /// In ar, this message translates to:
  /// **'سجّلي دخول عشان تشوفي أطفالك وتعدّلي بياناتك.'**
  String get meSignInPrompt;

  /// No description provided for @meSignIn.
  ///
  /// In ar, this message translates to:
  /// **'سجّلي برقم موبايلك'**
  String get meSignIn;

  /// No description provided for @pkgTitle.
  ///
  /// In ar, this message translates to:
  /// **'الباقة السنوية'**
  String get pkgTitle;

  /// No description provided for @pkgSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'لكل الإخوة'**
  String get pkgSubtitle;

  /// No description provided for @pkgPerClinic.
  ///
  /// In ar, this message translates to:
  /// **'{price} جنيه · {months} شهر'**
  String pkgPerClinic(String price, String months);

  /// No description provided for @pkgRulesTitle.
  ///
  /// In ar, this message translates to:
  /// **'الباقة بتشمل إيه'**
  String get pkgRulesTitle;

  /// No description provided for @pkgRuleSiblings.
  ///
  /// In ar, this message translates to:
  /// **'باقة واحدة لكل الإخوة على حسابك، وأي أخ بيتضاف بعدين بيدخل فيها من غير رسوم.'**
  String get pkgRuleSiblings;

  /// No description provided for @pkgRuleVisits.
  ///
  /// In ar, this message translates to:
  /// **'كشوفات العيادة من غير حد أقصى طول مدة الباقة.'**
  String get pkgRuleVisits;

  /// No description provided for @pkgRuleVaccines.
  ///
  /// In ar, this message translates to:
  /// **'التطعيمات بتتحسب بسعرها المعتاد.'**
  String get pkgRuleVaccines;

  /// No description provided for @pkgRuleClinics.
  ///
  /// In ar, this message translates to:
  /// **'سارية في العيادتين.'**
  String get pkgRuleClinics;

  /// No description provided for @pkgRuleCash.
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك والتجديد بالدفع كاش في العيادة.'**
  String get pkgRuleCash;

  /// No description provided for @pkgRuleStart.
  ///
  /// In ar, this message translates to:
  /// **'المدة بتبدأ من يوم الاشتراك.'**
  String get pkgRuleStart;

  /// No description provided for @pkgActiveUntil.
  ///
  /// In ar, this message translates to:
  /// **'لحد {date} · في العيادتين'**
  String pkgActiveUntil(String date);

  /// No description provided for @pkgActive.
  ///
  /// In ar, this message translates to:
  /// **'سارية'**
  String get pkgActive;

  /// No description provided for @pkgEnded.
  ///
  /// In ar, this message translates to:
  /// **'خلصت'**
  String get pkgEnded;

  /// No description provided for @pkgEndedOn.
  ///
  /// In ar, this message translates to:
  /// **'خلصت في {date}'**
  String pkgEndedOn(String date);

  /// No description provided for @pkgRenewed.
  ///
  /// In ar, this message translates to:
  /// **'اتجددت لحد {date}'**
  String pkgRenewed(String date);

  /// No description provided for @pkgChildLine.
  ///
  /// In ar, this message translates to:
  /// **'باقة {name}'**
  String pkgChildLine(String name);

  /// No description provided for @pkgNone.
  ///
  /// In ar, this message translates to:
  /// **'اشتركي في الباقة السنوية'**
  String get pkgNone;

  /// No description provided for @pkgNoneSub.
  ///
  /// In ar, this message translates to:
  /// **'كشوفات من غير حد للإخوة كلهم'**
  String get pkgNoneSub;

  /// No description provided for @pkgYours.
  ///
  /// In ar, this message translates to:
  /// **'باقتك'**
  String get pkgYours;

  /// No description provided for @pkgBookingHint.
  ///
  /// In ar, this message translates to:
  /// **'عندك إخوة بيكشفوا كتير؟ شوفي الباقة السنوية'**
  String get pkgBookingHint;

  /// No description provided for @remindPackageTitle.
  ///
  /// In ar, this message translates to:
  /// **'باقتك هتخلص بعد ١٤ يوم'**
  String get remindPackageTitle;

  /// No description provided for @remindPackageBody.
  ///
  /// In ar, this message translates to:
  /// **'لحد {date} · جدّديها كاش في العيادة'**
  String remindPackageBody(String date);

  /// No description provided for @dashRenewPackage.
  ///
  /// In ar, this message translates to:
  /// **'تجديد الباقة'**
  String get dashRenewPackage;

  /// No description provided for @dashPackageRenewed.
  ///
  /// In ar, this message translates to:
  /// **'اتجددت الباقة.'**
  String get dashPackageRenewed;

  /// No description provided for @dashPackageNext.
  ///
  /// In ar, this message translates to:
  /// **'التجديد من {from} لحد {to}'**
  String dashPackageNext(String from, String to);

  /// No description provided for @dashErrTooEarly.
  ///
  /// In ar, this message translates to:
  /// **'التجديد بيبقى في آخر ١٤ يوم من الباقة.'**
  String get dashErrTooEarly;

  /// No description provided for @errTimeout.
  ///
  /// In ar, this message translates to:
  /// **'الرد اتأخر. اتأكدي من النت وجربي تاني.'**
  String get errTimeout;

  /// No description provided for @signInLoadError.
  ///
  /// In ar, this message translates to:
  /// **'اتسجل دخولك، بس مقدرناش نحمّل بياناتك.'**
  String get signInLoadError;

  /// No description provided for @signInRetry.
  ///
  /// In ar, this message translates to:
  /// **'حاولي تاني'**
  String get signInRetry;

  /// No description provided for @loadError.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نحمّل البيانات. اتأكدي من النت وجربي تاني.'**
  String get loadError;

  /// No description provided for @linkClinicChildren.
  ///
  /// In ar, this message translates to:
  /// **'ربط أطفال العيادة'**
  String get linkClinicChildren;

  /// No description provided for @contentTitle.
  ///
  /// In ar, this message translates to:
  /// **'نصايح الدكتور'**
  String get contentTitle;

  /// No description provided for @contentSearch.
  ///
  /// In ar, this message translates to:
  /// **'دوّري في العناوين'**
  String get contentSearch;

  /// No description provided for @contentAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get contentAll;

  /// No description provided for @contentForAge.
  ///
  /// In ar, this message translates to:
  /// **'مناسب لسن {name}'**
  String contentForAge(String name);

  /// No description provided for @contentAllItems.
  ///
  /// In ar, this message translates to:
  /// **'كل المحتوى'**
  String get contentAllItems;

  /// No description provided for @contentReviewed.
  ///
  /// In ar, this message translates to:
  /// **'كل المحتوى بيراجعه الدكتور قبل النشر.'**
  String get contentReviewed;

  /// No description provided for @contentEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش محتوى منشور.'**
  String get contentEmpty;

  /// No description provided for @contentNoResults.
  ///
  /// In ar, this message translates to:
  /// **'مفيش نتايج. جربي كلمة تانية أو تصنيف تاني.'**
  String get contentNoResults;

  /// No description provided for @contentVideo.
  ///
  /// In ar, this message translates to:
  /// **'فيديو'**
  String get contentVideo;

  /// No description provided for @contentTip.
  ///
  /// In ar, this message translates to:
  /// **'نصيحة مكتوبة'**
  String get contentTip;

  /// No description provided for @contentAgeRange.
  ///
  /// In ar, this message translates to:
  /// **'من {from} لـ {to} شهر'**
  String contentAgeRange(String from, String to);

  /// No description provided for @contentOpenYoutube.
  ///
  /// In ar, this message translates to:
  /// **'شوفي الفيديو على يوتيوب'**
  String get contentOpenYoutube;

  /// No description provided for @contentVideoUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'الفيديو ده مش متاح هنا.'**
  String get contentVideoUnavailable;

  /// No description provided for @contentVideoOffline.
  ///
  /// In ar, this message translates to:
  /// **'الفيديو محتاج إنترنت. اتأكدي من النت وجربي تاني.'**
  String get contentVideoOffline;

  /// No description provided for @contentNotFound.
  ///
  /// In ar, this message translates to:
  /// **'المحتوى ده مبقاش متاح.'**
  String get contentNotFound;

  /// No description provided for @contentHomeTitle.
  ///
  /// In ar, this message translates to:
  /// **'جديد من الدكتور'**
  String get contentHomeTitle;

  /// No description provided for @contentHomeAll.
  ///
  /// In ar, this message translates to:
  /// **'كل المحتوى'**
  String get contentHomeAll;

  /// No description provided for @dashContentImport.
  ///
  /// In ar, this message translates to:
  /// **'استيراد من القناة'**
  String get dashContentImport;

  /// No description provided for @dashContentCategories.
  ///
  /// In ar, this message translates to:
  /// **'التصنيفات'**
  String get dashContentCategories;

  /// No description provided for @dashContentAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get dashContentAll;

  /// No description provided for @dashContentType.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get dashContentType;

  /// No description provided for @dashTypeVideo.
  ///
  /// In ar, this message translates to:
  /// **'فيديو'**
  String get dashTypeVideo;

  /// No description provided for @dashTypeTip.
  ///
  /// In ar, this message translates to:
  /// **'نصيحة مكتوبة'**
  String get dashTypeTip;

  /// No description provided for @dashYoutubeLink.
  ///
  /// In ar, this message translates to:
  /// **'رابط الفيديو على يوتيوب'**
  String get dashYoutubeLink;

  /// No description provided for @dashYoutubeHint.
  ///
  /// In ar, this message translates to:
  /// **'الصقي رابط الفيديو من قناة الدكتور'**
  String get dashYoutubeHint;

  /// No description provided for @dashYoutubeInvalid.
  ///
  /// In ar, this message translates to:
  /// **'ده مش رابط فيديو يوتيوب.'**
  String get dashYoutubeInvalid;

  /// No description provided for @dashYoutubeId.
  ///
  /// In ar, this message translates to:
  /// **'رقم الفيديو: {id}'**
  String dashYoutubeId(String id);

  /// No description provided for @dashAgeLimited.
  ///
  /// In ar, this message translates to:
  /// **'لسن معين'**
  String get dashAgeLimited;

  /// No description provided for @dashOrder.
  ///
  /// In ar, this message translates to:
  /// **'الترتيب'**
  String get dashOrder;

  /// No description provided for @dashOrderNote.
  ///
  /// In ar, this message translates to:
  /// **'الرقم الأصغر يظهر الأول.'**
  String get dashOrderNote;

  /// No description provided for @dashPreview.
  ///
  /// In ar, this message translates to:
  /// **'معاينة'**
  String get dashPreview;

  /// No description provided for @dashPreviewTitle.
  ///
  /// In ar, this message translates to:
  /// **'زي ما الأم هتشوفه في التطبيق'**
  String get dashPreviewTitle;

  /// No description provided for @dashUnpublish.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء النشر'**
  String get dashUnpublish;

  /// No description provided for @dashUnpublished.
  ///
  /// In ar, this message translates to:
  /// **'اتلغى النشر ورجع مسودة.'**
  String get dashUnpublished;

  /// No description provided for @dashRestore.
  ///
  /// In ar, this message translates to:
  /// **'رجوع لمسودة'**
  String get dashRestore;

  /// No description provided for @dashRestored.
  ///
  /// In ar, this message translates to:
  /// **'رجع مسودة.'**
  String get dashRestored;

  /// No description provided for @dashImportAdded.
  ///
  /// In ar, this message translates to:
  /// **'متضاف'**
  String get dashImportAdded;

  /// No description provided for @dashImportError.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نقرا القناة دلوقتي. الصقي رابط الفيديو بنفسك.'**
  String get dashImportError;

  /// No description provided for @dashImportNote.
  ///
  /// In ar, this message translates to:
  /// **'عناوين الشورتس في القناة تواريخ؛ اكتبي العنوان بعد الإضافة.'**
  String get dashImportNote;

  /// No description provided for @dashCategoryAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة تصنيف'**
  String get dashCategoryAdd;

  /// No description provided for @dashCategoryName.
  ///
  /// In ar, this message translates to:
  /// **'اسم التصنيف'**
  String get dashCategoryName;

  /// No description provided for @dashMoveUp.
  ///
  /// In ar, this message translates to:
  /// **'لفوق'**
  String get dashMoveUp;

  /// No description provided for @dashMoveDown.
  ///
  /// In ar, this message translates to:
  /// **'لتحت'**
  String get dashMoveDown;

  /// No description provided for @dashErrInUse.
  ///
  /// In ar, this message translates to:
  /// **'التصنيف ده عليه محتوى، مينفعش يتشال.'**
  String get dashErrInUse;

  /// No description provided for @dashErrVideoDuplicate.
  ///
  /// In ar, this message translates to:
  /// **'الفيديو ده متضاف قبل كده.'**
  String get dashErrVideoDuplicate;

  /// No description provided for @dashErrInvalidTransition.
  ///
  /// In ar, this message translates to:
  /// **'حالة المحتوى اتغيرت. حدّثي الصفحة.'**
  String get dashErrInvalidTransition;

  /// No description provided for @dashBodyRequired.
  ///
  /// In ar, this message translates to:
  /// **'النصيحة محتاجة نص.'**
  String get dashBodyRequired;
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
