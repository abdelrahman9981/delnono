// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'دكتور النونو';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navBooking => 'حجز';

  @override
  String get navMyChild => 'طفلي';

  @override
  String get navContent => 'محتوى';

  @override
  String get placeholderTag => 'مؤقت';

  @override
  String get placeholderBody => 'الشاشة دي لسه بتتعمل.';

  @override
  String get placeholderHome => 'الرئيسية';

  @override
  String get placeholderBooking => 'الحجز';

  @override
  String get placeholderContent => 'المحتوى';

  @override
  String get placeholderNotifications => 'الإشعارات';

  @override
  String get screenWelcome => 'أهلًا بيكي';

  @override
  String get screenSignIn => 'رقم الموبايل';

  @override
  String get screenOtp => 'كود التحقق';

  @override
  String get screenGuardian => 'بياناتك';

  @override
  String get screenConsent => 'الموافقة على الخصوصية';

  @override
  String get screenLinkChildren => 'أطفالك في العيادة';

  @override
  String get screenAddChild => 'إضافة طفل';

  @override
  String get screenChildren => 'أطفالي';

  @override
  String get screenChildProfile => 'ملف الطفل';

  @override
  String get screenReverify => 'تأكيد الحساب';

  @override
  String get screenAccount => 'حسابي';

  @override
  String get screenChangePhone => 'تغيير رقم الموبايل';

  @override
  String get screenDeleteAccount => 'حذف الحساب';

  @override
  String stepOf(String current, String total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get back => 'رجوع';

  @override
  String get signInTitle => 'تسجيل الدخول';

  @override
  String get phoneHeading => 'رقم موبايلك إيه؟';

  @override
  String get phoneIntro =>
      'هنبعتلك كود في رسالة عشان نتأكد إن الرقم بتاعك. الرقم ده هو حسابك في التطبيق.';

  @override
  String get phoneLabel => 'رقم الموبايل';

  @override
  String get phoneClinicHint =>
      'لو العيادة سجلت أطفالك قبل كده، استخدمي نفس الرقم.';

  @override
  String get phoneStaySignedIn =>
      'هتفضلي مسجلة دخول على الموبايل ده، ومش هنطلب كود تاني غير لو خرجتي من الحساب.';

  @override
  String get phoneSendCode => 'ابعتيلي الكود';

  @override
  String get phonePrivacyNote =>
      'بالمتابعة هتشوفي سياسة الخصوصية قبل ما نحفظ أي بيانات.';

  @override
  String get phoneInvalid => 'اكتبي رقم موبايل مصري صحيح، زي 010 1234 5678.';

  @override
  String get otpHeading => 'اكتبي الكود';

  @override
  String otpSentTo(String phone) {
    return 'بعتنا كود من ٦ أرقام على $phone';
  }

  @override
  String get otpChangeNumber => 'غيّري الرقم';

  @override
  String get otpCodeField => 'كود التحقق من ٦ أرقام';

  @override
  String otpValidFor(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'الكود صالح $countText دقيقة',
      few: 'الكود صالح $countText دقايق',
      two: 'الكود صالح دقيقتين',
      one: 'الكود صالح دقيقة واحدة',
    );
    return '$_temp0';
  }

  @override
  String otpResendIn(String time) {
    return 'إعادة الإرسال بعد $time';
  }

  @override
  String get otpResend => 'ابعتي الكود تاني';

  @override
  String get otpConfirm => 'تأكيد';

  @override
  String otpAttempts(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText محاولة',
      few: '$countText محاولات',
      two: 'محاولتين',
      one: 'محاولة واحدة',
    );
    return '$_temp0';
  }

  @override
  String otpWrongCode(String attempts) {
    return 'الكود مش صح. فاضلك $attempts، وبعدها اطلبي كود جديد.';
  }

  @override
  String get otpNoAttemptsLeft =>
      'الكود مش صح، والمحاولات خلصت. اطلبي كود جديد.';

  @override
  String get next => 'التالي';

  @override
  String get save => 'حفظ';

  @override
  String get guardianHeading => 'نتعرف عليكي';

  @override
  String get guardianIntro => 'البيانات دي بتظهر للعيادة مع كل حجز.';

  @override
  String get guardianFullName => 'الاسم بالكامل';

  @override
  String get guardianRelation => 'صلة القرابة بالطفل';

  @override
  String get relationMother => 'أم';

  @override
  String get relationFather => 'أب';

  @override
  String get relationOther => 'آخر';

  @override
  String get guardianEmail => 'الإيميل (اختياري)';

  @override
  String get guardianEmailHelp => 'بنستخدمه بس لو احتجنا نبعتلك حاجة مكتوبة.';

  @override
  String get guardianNothingSaved =>
      'مش هنحفظ أي بيانات غير بعد ما توافقي على سياسة الخصوصية في الخطوة الجاية.';

  @override
  String get errFullName => 'اكتبي اسمك بالكامل، من حرفين لحد ٨٠ حرف.';

  @override
  String get errRelation => 'اختاري صلة القرابة.';

  @override
  String get errEmail => 'الإيميل مش مكتوب صح.';

  @override
  String get consentTitle => 'الخصوصية';

  @override
  String get consentHeading => 'بيانات طفلك أمانة';

  @override
  String get consentIntro => 'قبل ما نحفظ أي حاجة، اعرفي هنعمل إيه بالبيانات.';

  @override
  String get consentUpdatedHeading => 'سياسة الخصوصية اتحدثت';

  @override
  String get consentUpdatedIntro =>
      'راجعي الإصدار الجديد ووافقي عليه عشان تكملي.';

  @override
  String get consentWhat =>
      'بنجمع إيه: بياناتك، وبيانات طفلك، وقياساته وتطعيماته وزياراته.';

  @override
  String get consentWho =>
      'مين يشوفها: انتي، والدكتور. السكرتارية تشوف المواعيد والقياسات بس.';

  @override
  String get consentDelete =>
      'الحذف: تقدري تمسحي حسابك في أي وقت. السجل الطبي بيفضل عند العيادة.';

  @override
  String get consentReadFull => 'اقري سياسة الخصوصية وشروط الاستخدام كاملة';

  @override
  String get consentPlaceholder => 'نص مؤقت · يراجعه المحامي قبل الإطلاق';

  @override
  String get consentPolicyCheck => 'موافقة على سياسة الخصوصية وشروط الاستخدام';

  @override
  String consentVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String consentVersionDated(String version, String date) {
    return 'الإصدار $version · $date';
  }

  @override
  String get consentChildDataCheck => 'موافقة على جمع بيانات طفلي الصحية';

  @override
  String get consentChildDataSub => 'عشان نسجل ملفه وتطعيماته ونفكرك بمواعيده';

  @override
  String get consentAccept => 'موافقة ومتابعة';

  @override
  String get consentBothRequired => 'لازم الموافقتين عشان تكملي.';

  @override
  String get policyPrivacyTitle => 'سياسة الخصوصية';

  @override
  String get policyTermsTitle => 'شروط الاستخدام';

  @override
  String get childName => 'اسم الطفل';

  @override
  String get childBirthDate => 'تاريخ الميلاد';

  @override
  String get childBirthDatePick => 'اختاري التاريخ';

  @override
  String get childSex => 'النوع';

  @override
  String get sexMale => 'ولد';

  @override
  String get sexFemale => 'بنت';

  @override
  String get childFixedFieldsNote =>
      'تاريخ الميلاد والنوع بيحددوا جدول التطعيمات، فتعديلهم بعد كده بيبقى من العيادة.';

  @override
  String get childBirthWeight => 'وزن الولادة (اختياري)';

  @override
  String get kg => 'كجم';

  @override
  String get childAllergies => 'الحساسية (اختياري)';

  @override
  String childDuplicateLinked(String name) {
    return '«$name» متسجل في حسابك بنفس تاريخ الميلاد، فمش هنضيفه تاني.';
  }

  @override
  String childDuplicateClinic(String name) {
    return 'فيه طفل اسمه «$name» بنفس تاريخ الميلاد مسجل على رقمك بالفعل، فمش هنضيفه تاني. لو ده غلط كلمي العيادة.';
  }

  @override
  String get errChildName => 'اكتبي اسم الطفل، من حرفين لحد ٦٠ حرف.';

  @override
  String get errBirthDate => 'اختاري تاريخ الميلاد.';

  @override
  String get errSex => 'اختاري النوع.';

  @override
  String get errBirthWeight => 'الوزن لازم يكون بين ٠٫٣ و٧ كجم.';

  @override
  String get errAllergies => 'اكتبي الحساسية في أقل من ٥٠٠ حرف.';

  @override
  String get welcomeClinic => 'دكتور النونو';

  @override
  String get welcomeDoctorName => 'د. أحمد العبد';

  @override
  String get welcomeDoctorTitle => 'استشاري طب الأطفال وحديثي الولادة · المقطم';

  @override
  String get welcomePhotoPlaceholder => 'صورة د. أحمد';

  @override
  String get welcomePhotoSoon => 'هنضيف الصورة الحقيقية قريب';

  @override
  String get welcomeHeading => 'أهلًا بيكي';

  @override
  String get welcomeIntro =>
      'احجزي ميعادك وتابعي نمو وتطعيمات طفلك من مكان واحد.';

  @override
  String get welcomeBookTitle => 'احجزي من التطبيق';

  @override
  String get welcomeBookBody => 'اختاري اليوم والساعة وشوفي الأماكن الفاضية';

  @override
  String get welcomeProfileTitle => 'ملف طفلك معاكي';

  @override
  String get welcomeProfileBody => 'القياسات والتطعيمات والزيارات';

  @override
  String get welcomeTipsTitle => 'نصايح من الدكتور';

  @override
  String get welcomeTipsBody => 'فيديوهات حسب سن طفلك';

  @override
  String get welcomeRegister => 'سجّلي برقم موبايلك';

  @override
  String get welcomeBrowse => 'اتفرجي على المحتوى الأول';

  @override
  String get welcomeDisclaimer =>
      'التطبيق للحجز والمتابعة بس، ومش بديل للكشف أو تشخيص الطبيب.';

  @override
  String get errInvalidCode => 'الكود مش صح.';

  @override
  String get errCodeExpired => 'الكود خلص وقته. اطلبي كود جديد.';

  @override
  String get errTooManyRequests => 'محاولات كتير. استني شوية وجربي تاني.';

  @override
  String get errNoConnection =>
      'محتاجة إنترنت عشان تكملي. اتأكدي من الاتصال وجربي تاني.';

  @override
  String get errNumberInUse =>
      'الرقم ده عليه حساب تاني. كلمي العيادة عشان نساعدك.';

  @override
  String get errSmsQuota => 'مش قادرين نبعت كود دلوقتي. جربي بعد شوية.';

  @override
  String get errUnauthenticated => 'سجلي دخول الأول.';

  @override
  String get errAlreadyExists => 'البيانات دي موجودة قبل كده.';

  @override
  String get errPolicyOutdated =>
      'سياسة الخصوصية اتحدثت. راجعيها ووافقي عليها الأول.';

  @override
  String get errInvalidInput => 'في بيانات مش صح. راجعيها وجربي تاني.';

  @override
  String get errNoClinicChildren => 'مفيش أطفال على رقمك في العيادة.';

  @override
  String get errBirthDateMismatch => 'التاريخ مش مطابق.';

  @override
  String get errLocked => 'وقفنا المحاولات. كلمي العيادة عشان نكمل.';

  @override
  String get errGeneric => 'حصلت مشكلة. جربي تاني.';
}
