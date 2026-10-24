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
  String get confirm => 'تأكيد';

  @override
  String get linkHeading => 'فيه ملفات أطفال على رقمك';

  @override
  String get linkIntro =>
      'العيادة سجلت قبل كده أطفال على الرقم ده. عشان نتأكد إنهم أطفالك، جاوبي على سؤال واحد.';

  @override
  String get linkBirthDateLabel =>
      'تاريخ ميلاد واحد من أطفالك المسجلين في العيادة';

  @override
  String get linkPrivacyNote => 'مش هنعرض أي بيانات غير لما الإجابة تبقى صح.';

  @override
  String linkWrongDate(String attempts) {
    return 'التاريخ مش مطابق. فاضلك $attempts. بعدها هنوقف الربط وتقدري تكلمي العيادة.';
  }

  @override
  String get linkLocked =>
      'وقفنا الربط بعد المحاولات دي. كلمي العيادة عشان تربط أطفالك بحسابك.';

  @override
  String linkSuccess(String names) {
    return 'اتضاف $names لحسابك.';
  }

  @override
  String get linkNotMine => 'دول مش أطفالي · ضيفي طفل جديد';

  @override
  String get childrenEmpty => 'لسه مفيش أطفال في حسابك.';

  @override
  String get childrenAdd => 'إضافة طفل';

  @override
  String ageYears(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText سنة',
      few: '$countText سنين',
      two: 'سنتين',
      one: 'سنة',
    );
    return '$_temp0';
  }

  @override
  String ageMonths(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText شهر',
      few: '$countText شهور',
      two: 'شهرين',
      one: 'شهر',
    );
    return '$_temp0';
  }

  @override
  String get ageNewborn => 'أقل من شهر';

  @override
  String ageAnd(String years, String months) {
    return '$years و$months';
  }

  @override
  String get childFixedFieldsLocked =>
      'تاريخ الميلاد والنوع بيصححهم الدكتور أو السكرتارية بس، لأنهم بيحددوا جدول التطعيمات. لو فيهم غلط كلمي العيادة.';

  @override
  String get childSaved => 'اتحفظت التعديلات.';

  @override
  String get childNotFound => 'الطفل ده مش موجود في حسابك.';

  @override
  String get accountChildren => 'أطفالي';

  @override
  String get accountChangePhone => 'تغيير رقم الموبايل';

  @override
  String get accountChangePhoneSub => 'بكود على الرقم الجديد';

  @override
  String get accountNotifications => 'الإشعارات';

  @override
  String get accountPrivacy => 'الخصوصية والشروط';

  @override
  String accountPrivacySub(String version) {
    return 'وافقتي على الإصدار $version';
  }

  @override
  String get accountWhatsApp => 'كلمي العيادة على واتساب';

  @override
  String get accountWhatsAppSub => 'للاستفسار والدعم، مش للحجز';

  @override
  String get accountWhatsAppUnavailable => 'رقم واتساب العيادة لسه مش متاح.';

  @override
  String get accountSignOut => 'تسجيل الخروج';

  @override
  String get accountDeleteTitle => 'حذف الحساب';

  @override
  String get accountDeleteBody =>
      'هنمسح حسابك وبياناتك من التطبيق. ملفات أطفالك الطبية بتفضل عند العيادة للمدة اللي يحددها القانون.';

  @override
  String get accountDeleteButton => 'حذف حسابي';

  @override
  String get changePhoneHeading => 'رقمك الجديد';

  @override
  String get changePhoneIntro =>
      'هنبعت كود على الرقم الجديد. أطفالك وبياناتك بيفضلوا زي ما هما.';

  @override
  String get changePhoneSend => 'ابعتي الكود';

  @override
  String get changePhoneSame => 'ده نفس رقمك الحالي.';

  @override
  String changePhoneDone(String phone) {
    return 'اتغير رقمك لـ $phone.';
  }

  @override
  String get deleteHeading => 'قبل ما تمسحي حسابك';

  @override
  String get deleteRemovedTitle => 'هنمسح من التطبيق';

  @override
  String get deleteRemoved =>
      'حسابك ورقمك واسمك وإعداداتك. هتخرجي من التطبيق على الموبايل ده.';

  @override
  String get deleteKeptTitle => 'هيفضل عند العيادة';

  @override
  String get deleteKept =>
      'ملفات أطفالك الطبية وسجل موافقتك، للمدة اللي يحددها القانون.';

  @override
  String get deleteComeBack =>
      'لو سجلتي تاني بنفس الرقم، هتبدأي من الأول وتقدري تربطي أطفالك تاني.';

  @override
  String get deleteConfirmCheck => 'فاهمة، وعايزة أمسح حسابي';

  @override
  String get deleteButton => 'حذف حسابي نهائيًا';

  @override
  String get deleteDone => 'اتمسح حسابك.';

  @override
  String get reverifyHeading => 'تأكيد إنك صاحبة الحساب';

  @override
  String get reverifyIntro =>
      'بقالك فترة مدخلتيش التطبيق. عشان نحمي بيانات أطفالك، اكتبي تاريخ ميلاد واحد منهم.';

  @override
  String get reverifyBirthDateLabel => 'تاريخ ميلاد واحد من أطفالك';

  @override
  String reverifyWrongDate(String attempts) {
    return 'التاريخ مش مطابق. فاضلك $attempts. بعدها هنقفل بيانات الأطفال لحد ما تكلمي العيادة.';
  }

  @override
  String get reverifyLocked =>
      'قفلنا بيانات الأطفال بعد المحاولات دي. كلمي العيادة عشان نفتحها تاني.';

  @override
  String get nameListSeparator => ' و';

  @override
  String get bookingTitle => 'احجزي زيارة';

  @override
  String get visitTypeVisit => 'كشف أطفال';

  @override
  String get visitTypeVaccine => 'تطعيم';

  @override
  String get visitTypeVaccineSub => 'حسب الجرعة';

  @override
  String priceEgp(String amount) {
    return '$amount جنيه';
  }

  @override
  String get chooseDay => 'اختاري اليوم';

  @override
  String get chooseHour => 'اختاري الساعة';

  @override
  String get arrivalOrder => 'الدخول بالأسبقية';

  @override
  String hourRange(String from, String to) {
    return '$from لـ $to';
  }

  @override
  String get periodAm => 'ص';

  @override
  String get periodPm => 'م';

  @override
  String placesLeft(String left, String capacity) {
    return 'فاضل $left من $capacity';
  }

  @override
  String get hourFull => 'مكتمل';

  @override
  String get noHoursThatDay => 'مفيش ساعات متاحة في اليوم ده.';

  @override
  String get whoIsComing => 'مين هييجي؟';

  @override
  String get chooseMoreThanOne => 'اختاري أكتر من طفل';

  @override
  String vaccinesFor(String name) {
    return 'تطعيمات $name';
  }

  @override
  String get noVaccine => 'من غير تطعيم';

  @override
  String get summaryTotal => 'إجمالي الزيارة';

  @override
  String get coveredByPackage => 'مغطّى بالباقة';

  @override
  String get activePackage => 'باقة نشطة';

  @override
  String get summaryWhen => 'المعاد';

  @override
  String get summaryChildren => 'الأطفال';

  @override
  String get summaryPayment => 'الدفع';

  @override
  String get cashAtClinic => 'كاش في العيادة';

  @override
  String get summaryVisit => 'الكشف';

  @override
  String get priceAtClinic => 'بالسعر في العيادة';

  @override
  String get totalExcludesHidden =>
      'الإجمالي من غير التطعيمات اللي سعرها في العيادة.';

  @override
  String hoursCount(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText ساعة',
      few: '$countText ساعات',
      two: 'ساعتين',
      one: 'ساعة',
    );
    return '$_temp0';
  }

  @override
  String cancelUntil(String hours) {
    return 'تقدري تلغي لحد $hours قبل الميعاد';
  }

  @override
  String get confirmBooking => 'تأكيد الحجز';

  @override
  String get myBookings => 'حجوزاتي';

  @override
  String get noChildrenToBook => 'ضيفي طفل الأول عشان تحجزي.';

  @override
  String get bookingFull => 'الميعاد اتحجز. اختاري ساعة تانية.';

  @override
  String priceChanged(String total) {
    return 'السعر اتغير. الإجمالي دلوقتي $total جنيه، أكدي تاني.';
  }

  @override
  String get bookingClosedDay => 'العيادة مقفولة في اليوم ده.';

  @override
  String get bookingStarted => 'الساعة دي بدأت خلاص. اختاري ساعة تانية.';

  @override
  String get bookingBeyondHorizon =>
      'الحجز متاح للأيام الجاية بس، مش أبعد من كده.';

  @override
  String get bookingNotVaccineDay => 'التطعيمات في أيام التطعيم بس.';

  @override
  String get bookingAlreadyThatDay =>
      'عندك حجز في اليوم ده بالفعل. عدّليه لو عايزة تضيفي طفل.';

  @override
  String get bookingTooMany =>
      'عندك أقصى عدد من الحجوزات الجاية. استني لما واحد يخلص أو الغيه.';

  @override
  String get bookingVaccineRequired => 'اختاري تطعيم واحد على الأقل.';

  @override
  String get successTag => 'تم الحجز بنجاح';

  @override
  String successTitle(String name) {
    return 'ميعادكم اتأكد يا $name';
  }

  @override
  String successWaiting(String children) {
    return 'مستنيين $children في العيادة';
  }

  @override
  String get bookingNumber => 'رقم الحجز';

  @override
  String bookingNumberValue(String number) {
    return '# نونو $number';
  }

  @override
  String get statusConfirmed => 'مؤكد';

  @override
  String get statusArrived => 'وصل';

  @override
  String get statusDone => 'تم';

  @override
  String get statusCancelled => 'ملغي';

  @override
  String get statusNoShow => 'لم يحضر';

  @override
  String get statusSoon => 'قريب';

  @override
  String get labelDay => 'اليوم';

  @override
  String get labelHour => 'الساعة';

  @override
  String get labelVisit => 'الزيارة';

  @override
  String get payAtClinic => 'الدفع في العيادة';

  @override
  String get arrivalOrderInHour => 'الدخول بالأسبقية جوه الساعة المحجوزة';

  @override
  String get viewMyBookings => 'عرض حجوزاتي';

  @override
  String get backHome => 'الرجوع للرئيسية';

  @override
  String get tabUpcoming => 'القادمة';

  @override
  String get tabPast => 'السابقة';

  @override
  String get dueAtClinic => 'المطلوب في العيادة';

  @override
  String get canChange => 'لسه ينفع تعدلي أو تلغي';

  @override
  String canChangeSub(String hours) {
    return 'متبقي أكتر من $hours على الميعاد';
  }

  @override
  String lessThan(String hours) {
    return 'فاضل أقل من $hours';
  }

  @override
  String get lessThanSub => 'التعديل والإلغاء عن طريق العيادة';

  @override
  String get changeBooking => 'تعديل';

  @override
  String get cancelBooking => 'إلغاء الحجز';

  @override
  String get callClinic => 'كلمي العيادة';

  @override
  String get newBooking => 'احجزي ميعاد جديد';

  @override
  String get noBookings => 'لسه مفيش حجوزات.';

  @override
  String get cancelConfirmTitle => 'تلغي الحجز؟';

  @override
  String cancelConfirmBody(String when) {
    return 'هيتلغى حجز $when والمكان هيرجع متاح لغيرك.';
  }

  @override
  String get keepBooking => 'لأ، خليه';

  @override
  String get bookingCancelled => 'اتلغى الحجز.';

  @override
  String titleVisit(String names) {
    return 'كشف $names';
  }

  @override
  String titleVaccine(String names) {
    return 'تطعيم $names';
  }

  @override
  String titleVisitAndVaccine(String names) {
    return 'كشف وتطعيم $names';
  }

  @override
  String get changeTitle => 'تعديل الحجز';

  @override
  String get confirmChange => 'تأكيد التعديل';

  @override
  String get bookingChanged => 'اتعدل الحجز.';

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

  @override
  String get childProfileTitle => 'ملف طفلي';

  @override
  String latestMeasurements(String name) {
    return 'آخر قياسات $name';
  }

  @override
  String measurementsUpdated(String date) {
    return 'اتحدثت $date';
  }

  @override
  String measuredOn(String date) {
    return 'اتقاس $date';
  }

  @override
  String get measureWeight => 'الوزن';

  @override
  String get measureLength => 'الطول';

  @override
  String get measureHead => 'محيط الرأس';

  @override
  String get unitKg => 'كجم';

  @override
  String get unitCm => 'سم';

  @override
  String get notRecordedYet => 'لسه متسجلش';

  @override
  String get noMeasurements =>
      'لسه مفيش قياسات متسجلة. القياسات بتتسجل في العيادة وقت الكشف.';

  @override
  String get growthChart => 'منحنى النمو';

  @override
  String growthChartSubtitle(String metric) {
    return '$metric بالنسبة للعمر';
  }

  @override
  String get chartBirth => 'الولادة';

  @override
  String get chartBirthWeight => 'وزن الولادة';

  @override
  String chartMonthsAxis(String months) {
    return '$months شهور';
  }

  @override
  String get doctorReviewsMeasurements =>
      'الدكتور هيراجع القياسات معاكي في الكشف';

  @override
  String get entryVaccines => 'التطعيمات';

  @override
  String get entryVisits => 'سجل الزيارات';

  @override
  String get entryFollowUp => 'المتابعة حسب العمر';

  @override
  String get entryDetails => 'بيانات الطفل';

  @override
  String detailsAllergies(String allergies) {
    return 'حساسية: $allergies';
  }

  @override
  String get detailsNoAllergies => 'مفيش حساسية متسجلة';

  @override
  String get vaccinesTitle => 'التطعيمات';

  @override
  String vaccinesSource(String source) {
    return 'المصدر: $source';
  }

  @override
  String vaccinesReviewed(String date) {
    return 'آخر مراجعة: $date';
  }

  @override
  String get vaccinesBasic => 'التطعيمات الأساسية';

  @override
  String get vaccinesAdditional => 'تطعيمات إضافية';

  @override
  String get additionalBadge => 'إضافي';

  @override
  String get additionalChoice =>
      'التطعيمات الإضافية اختيارية، والقرار ليكي بعد ما تتكلمي مع الدكتور.';

  @override
  String doseNumber(String number) {
    return 'الجرعة $number';
  }

  @override
  String doseDueOn(String date) {
    return 'ميعادها $date';
  }

  @override
  String doseGivenOn(String date) {
    return 'اتاخدت $date';
  }

  @override
  String doseLot(String lot) {
    return 'رقم التشغيلة: $lot';
  }

  @override
  String get doseScheduled => 'مجدولة';

  @override
  String get doseDue => 'مستحقة';

  @override
  String get doseGiven => 'اتاخدت';

  @override
  String get doseLate => 'متأخرة';

  @override
  String get doseMissed => 'فائتة';

  @override
  String additionalSuggestedAge(String age) {
    return 'العمر المناسب: $age';
  }

  @override
  String additionalDoses(String count) {
    return 'عدد الجرعات: $count';
  }

  @override
  String additionalInterval(String weeks) {
    return 'الفاصل بين الجرعات: $weeks أسابيع';
  }

  @override
  String get vaccinesEmpty => 'جدول التطعيمات لسه مش متاح.';

  @override
  String get visitsTitle => 'سجل الزيارات';

  @override
  String get visitsEmpty => 'لسه مفيش زيارات متسجلة.';

  @override
  String get visitClinic => 'كشف';

  @override
  String get visitVaccine => 'تطعيم';

  @override
  String get visitWalkIn => 'كشف بدون حجز';

  @override
  String visitMeasurements(String values) {
    return 'القياسات: $values';
  }

  @override
  String visitDoses(String names) {
    return 'التطعيمات: $names';
  }

  @override
  String get followUpTitle => 'المتابعة حسب العمر';

  @override
  String get followUpPlaceholder => 'أمثلة مؤقتة · يعتمدها الدكتور';

  @override
  String get whenToCall => 'متى تتصلين بالدكتور';

  @override
  String get whenToCallIntro => 'لو لاحظتي أي علامة من دول، كلمي العيادة فورًا';

  @override
  String get callClinicPhone => 'اتصلي بالعيادة';

  @override
  String get callAmbulance => 'الإسعاف ١٢٣';

  @override
  String get followUpDisclaimer =>
      'القوايم دي للمتابعة بس، ومش بتشخّص حالة طفلك.';

  @override
  String followUpOverAge(String years) {
    return 'المتابعة حسب العمر بتغطي لحد $years سنين.';
  }

  @override
  String get followUpNoBand => 'مفيش قائمة متابعة للسن ده لسه.';

  @override
  String get packageTitle => 'الباقة السنوية للعيلة';

  @override
  String packageActiveUntil(String date) {
    return 'نشطة لحد $date';
  }

  @override
  String packageEndedOn(String date) {
    return 'خلصت في $date';
  }

  @override
  String get packageActive => 'نشطة';

  @override
  String get packageEnded => 'خلصت';

  @override
  String packageMonthsLeft(String months) {
    return 'متبقي $months';
  }

  @override
  String get offlineBanner => 'إنتي أوفلاين · دي آخر بيانات اتحملت';

  @override
  String get needsConnectionFirstTime =>
      'محتاجين إنترنت أول مرة عشان نحمّل البيانات.';

  @override
  String get chooseClinic => 'اختاري العيادة';

  @override
  String get noClinics => 'مفيش عيادات متاحة للحجز دلوقتي.';

  @override
  String get changeClinic => 'تغيير';

  @override
  String get bookingClinicInactive =>
      'العيادة دي مش بتستقبل حجوزات دلوقتي. اختاري عيادة تانية.';

  @override
  String get labelClinic => 'العيادة';

  @override
  String get labelAddress => 'العنوان';

  @override
  String get listSeparator => '، ';

  @override
  String get homeWelcome => 'أهلًا بيكي';

  @override
  String homeGreeting(String name) {
    return 'أهلًا يا $name';
  }

  @override
  String get homeClinics => 'عياداتنا';

  @override
  String get doctorName => 'د. أحمد العبد';

  @override
  String get doctorTitle => 'استشاري طب الأطفال وحديثي الولادة';

  @override
  String get doctorTagline => 'موجودين عشان نطمنك';

  @override
  String get doctorPhotoPlaceholder =>
      '[صورة د. أحمد · هنضيف الصورة الحقيقية قريب]';

  @override
  String get bookHere => 'احجزي هنا';

  @override
  String get callClinicShort => 'اتصلي';

  @override
  String get whatsapp => 'واتساب';

  @override
  String callClinicAt(String area) {
    return 'اتصلي بعيادة $area';
  }

  @override
  String additionalPriceAt(String area, String price) {
    return 'السعر في $area: $price جنيه';
  }

  @override
  String visitAtClinic(String clinic) {
    return 'في $clinic';
  }
}
