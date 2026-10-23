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
