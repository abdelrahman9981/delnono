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

  @override
  String get dashTitle => 'لوحة العيادة';

  @override
  String get dashNavToday => 'اليوم';

  @override
  String get dashNavChildren => 'ملفات الأطفال';

  @override
  String get dashNavClinic => 'العيادة';

  @override
  String get dashNavContent => 'المحتوى';

  @override
  String get dashNavFollowUp => 'قوائم المتابعة';

  @override
  String get dashNavReports => 'التقارير';

  @override
  String get dashNavVaccines => 'التطعيمات';

  @override
  String get dashNavSettings => 'الإعدادات';

  @override
  String get dashNavStaff => 'الموظفين';

  @override
  String get dashNavAudit => 'سجل التدقيق';

  @override
  String get dashSwitchClinic => 'تغيير العيادة';

  @override
  String get dashSignInTitle => 'دخول الموظفين';

  @override
  String get dashEmail => 'الإيميل';

  @override
  String get dashPassword => 'كلمة السر';

  @override
  String get dashSignIn => 'دخول';

  @override
  String get dashErrSignIn => 'الإيميل أو كلمة السر مش صح.';

  @override
  String get dashErrDisabled => 'الحساب ده متوقف. كلمي الدكتور.';

  @override
  String get dashNotStaff =>
      'الحساب ده مش حساب موظف شغال. اخرجي وادخلي بحساب الموظف.';

  @override
  String get dashPasswordTitle => 'غيّري كلمة السر';

  @override
  String get dashPasswordIntro =>
      'دي أول مرة تدخلي. اختاري كلمة سر خاصة بيكي بدل المؤقتة.';

  @override
  String get dashNewPassword => 'كلمة السر الجديدة';

  @override
  String get dashNewPasswordAgain => 'اكتبيها تاني';

  @override
  String get dashPasswordRule => 'كلمة السر لازم ٨ حروف على الأقل.';

  @override
  String get dashPasswordMismatch => 'الكلمتين مش زي بعض.';

  @override
  String dashTodayTitle(String date) {
    return 'اليوم · $date';
  }

  @override
  String get dashCalendar => 'مواعيد اليوم';

  @override
  String get dashClosedToday => 'العيادة مقفولة النهارده.';

  @override
  String get dashQueue => 'طابور الحضور';

  @override
  String get dashQueueOrder => 'بالترتيب حسب وقت الوصول، من غير أولوية.';

  @override
  String get dashQueueEmpty => 'مفيش حد وصل لسه.';

  @override
  String get dashWaiting => 'مستني';

  @override
  String get dashDoneUnpaid => 'تم · الدفع لسه متسجلش';

  @override
  String dashPaid(String amount) {
    return 'تم · اتدفع $amount جنيه';
  }

  @override
  String get dashMarkArrived => 'وصل';

  @override
  String get dashMarkDone => 'تم';

  @override
  String get dashUndo => 'تراجع';

  @override
  String get dashWalkIn => 'بدون حجز';

  @override
  String get dashStopWalkIns => 'إيقاف الحالات بدون حجز';

  @override
  String get dashAddWalkIn => 'إضافة حالة بدون حجز';

  @override
  String get dashNoHoursLeft => 'مفيش ساعات فاضلة النهارده.';

  @override
  String get dashFamilyName => 'اسم ولي الأمر';

  @override
  String get dashPhone => 'رقم الموبايل';

  @override
  String get dashChildrenNames => 'أسماء الأطفال';

  @override
  String get dashChildrenNamesHelp => 'افصلي بين الأسماء بفاصلة.';

  @override
  String get dashWalkInAdded => 'اتضافت الحالة للطابور.';

  @override
  String get dashCancelForFamily => 'إلغاء الحجز للأسرة';

  @override
  String get dashRecordPayment => 'تسجيل الدفع';

  @override
  String get dashCashAmount => 'المبلغ كاش (جنيه)';

  @override
  String get dashCoveredByPackage => 'الكشف مغطّى بالباقة';

  @override
  String get dashPaymentSaved => 'اتسجل الدفع.';

  @override
  String get dashClose => 'إغلاق';

  @override
  String get dashSaved => 'اتحفظ.';

  @override
  String get dashAdd => 'إضافة';

  @override
  String get dashEdit => 'تعديل';

  @override
  String get dashRemove => 'حذف';

  @override
  String get dashSearchHint => 'اسم الطفل أو رقم ولي الأمر';

  @override
  String get dashSearch => 'بحث';

  @override
  String get dashNoResults => 'مفيش نتايج.';

  @override
  String get dashBasics => 'البيانات الأساسية';

  @override
  String get dashEditBasics => 'تعديل البيانات';

  @override
  String dashGuardianPhone(String phone) {
    return 'رقم ولي الأمر: $phone';
  }

  @override
  String get dashSellPackage => 'بيع الباقة السنوية';

  @override
  String get dashPackageSold => 'اتباعت الباقة.';

  @override
  String get dashMeasurements => 'القياسات';

  @override
  String get dashDoses => 'التطعيمات المتسجلة';

  @override
  String get dashAddMeasurement => 'إضافة قياس';

  @override
  String get dashAddDose => 'إضافة جرعة';

  @override
  String get dashCorrect => 'تصحيح (الدكتور)';

  @override
  String get dashDate => 'التاريخ';

  @override
  String get dashDoseNumber => 'رقم الجرعة';

  @override
  String get dashLot => 'رقم التشغيلة';

  @override
  String get dashNote => 'ملاحظة الدكتور';

  @override
  String get dashNoNote => 'مفيش ملاحظة.';

  @override
  String get dashNoteHelp => 'بيشوفها الدكتور بس.';

  @override
  String get dashContact => 'العنوان والتواصل';

  @override
  String get dashPrices => 'الأسعار';

  @override
  String get dashVisitPrice => 'سعر الكشف';

  @override
  String get dashPackagePrice => 'سعر الباقة السنوية';

  @override
  String get dashPackageMonths => 'مدة الباقة (شهور)';

  @override
  String get dashSchedule => 'المواعيد';

  @override
  String get dashCapacity => 'السعة في الساعة';

  @override
  String get dashCancelWindow => 'مهلة الإلغاء (ساعات)';

  @override
  String get dashHolidays => 'الإجازات';

  @override
  String get dashHolidaysHelp => 'تواريخ YYYY-MM-DD بينها فاصلة.';

  @override
  String get dashWorkingHoursHelp =>
      'ساعات كل يوم بنظام ٢٤ ساعة، مثلًا 17-21 أو 10-14, 17-21. فاضي = مقفول.';

  @override
  String get dashVaccineDay => 'يوم تطعيم';

  @override
  String get dashVaccineOffers => 'التطعيمات المتاحة في العيادة وأسعارها';

  @override
  String get dashPrice => 'السعر';

  @override
  String get dashPriceShown => 'السعر ظاهر للأم';

  @override
  String get dashVaccineList => 'قائمة التطعيمات';

  @override
  String get dashScheduleSource => 'مصدر الجدول';

  @override
  String get dashApprove => 'اعتماد';

  @override
  String get dashApproved => 'اتعمد الجدول.';

  @override
  String dashDueMonths(String months) {
    return 'عند $months شهور';
  }

  @override
  String get dashNewItem => 'إضافة نصيحة أو فيديو';

  @override
  String get dashItemTitle => 'العنوان';

  @override
  String get dashCategory => 'التصنيف';

  @override
  String get dashAgeFrom => 'من سن (شهور)';

  @override
  String get dashAgeTo => 'لحد سن (شهور)';

  @override
  String get dashLink => 'الرابط';

  @override
  String get dashBody => 'النص';

  @override
  String get dashDraftNote => 'المسودة مش بتظهر للأمهات لحد ما الدكتور ينشرها.';

  @override
  String get dashCatFever => 'الحرارة';

  @override
  String get dashCatFeeding => 'الرضاعة والهضم';

  @override
  String get dashCatSleep => 'النوم';

  @override
  String get dashCatAllergy => 'الحساسية';

  @override
  String get dashDraft => 'مسودة';

  @override
  String get dashPublished => 'منشور';

  @override
  String get dashArchived => 'مؤرشف';

  @override
  String get dashPublish => 'نشر';

  @override
  String get dashArchive => 'أرشفة';

  @override
  String get dashNothingYet => 'مفيش حاجة لسه.';

  @override
  String get dashSaveDraft => 'حفظ كمسودة';

  @override
  String get dashDraftSaved => 'اتحفظت المسودة.';

  @override
  String get dashOnePerLine => 'كل بند في سطر.';

  @override
  String get dashAddBand => 'إضافة قائمة سن';

  @override
  String get dashFrom => 'من';

  @override
  String get dashTo => 'لحد';

  @override
  String get dashDaily => 'يومي';

  @override
  String get dashMonthly => 'شهري';

  @override
  String get dashAllClinics => 'العيادتين';

  @override
  String get dashShowReport => 'عرض';

  @override
  String get dashExportCsv => 'تصدير CSV';

  @override
  String get dashTotal => 'الإجمالي';

  @override
  String get dashRepBookings => 'الحجوزات';

  @override
  String get dashRepArrivals => 'الحضور';

  @override
  String get dashRepNoShows => 'لم يحضر';

  @override
  String get dashRepWalkIns => 'بدون حجز';

  @override
  String get dashRepCash => 'كاش الكشوفات';

  @override
  String get dashRepPackages => 'الباقات المباعة';

  @override
  String get dashSetPolicy => 'سياسة الخصوصية والشروط';

  @override
  String get dashSetPolicyVersion => 'رقم النسخة (زيادته بتطلب موافقة جديدة)';

  @override
  String get dashSetPrivacyText => 'نص سياسة الخصوصية';

  @override
  String get dashSetTermsText => 'نص الشروط';

  @override
  String get dashSetSignIn => 'الدخول';

  @override
  String get dashSetMaxCodeAttempts => 'عدد محاولات الكود';

  @override
  String get dashSetResendWait => 'انتظار إعادة الإرسال (ثواني)';

  @override
  String get dashSetReverifyDays => 'إعادة التحقق بعد (أيام)';

  @override
  String get dashSetBooking => 'الحجز';

  @override
  String get dashSetHorizon => 'الحجز لحد كام يوم قدام';

  @override
  String get dashSetMaxUpcoming => 'أقصى حجوزات قادمة للعيلة';

  @override
  String get dashSetChild => 'ملف الطفل';

  @override
  String get dashSetFollowUpAge => 'المتابعة لحد سن (شهور)';

  @override
  String get dashSetLateDays => 'الجرعة متأخرة بعد (أيام)';

  @override
  String get dashNewStaff => 'إضافة موظف';

  @override
  String get dashTempPassword => 'كلمة سر مؤقتة';

  @override
  String get dashRoleDoctor => 'دكتور';

  @override
  String get dashRoleSecretary => 'سكرتيرة';

  @override
  String get dashDisabled => 'متوقف';

  @override
  String get dashDisable => 'إيقاف';

  @override
  String get dashEnable => 'تشغيل';

  @override
  String get dashAction => 'النوع';

  @override
  String get dashAllActions => 'كل الأنواع';

  @override
  String dashAuditCount(String count) {
    return '$count سجل';
  }

  @override
  String get dashErrFull => 'الساعة دي مليانة.';

  @override
  String get dashErrWalkInsStopped => 'الحالات بدون حجز متوقفة النهارده.';

  @override
  String get dashErrHourNotOver => 'الساعة لسه مخلصتش.';

  @override
  String get dashErrWrongStatus => 'الحالة دي مش مناسبة للخطوة دي.';

  @override
  String get dashErrNotToday => 'دي مش حجوزات النهارده.';

  @override
  String get dashErrNoPackage => 'الأسرة مالهاش باقة سارية.';

  @override
  String get dashErrHasPackage => 'الأسرة عندها باقة سارية بالفعل.';

  @override
  String get dashErrDoctorOnly => 'الخطوة دي للدكتور بس.';

  @override
  String get dashErrLastDoctor => 'لازم يفضل حساب دكتور واحد شغال على الأقل.';

  @override
  String dashErrBookingsOutsideHours(int count) {
    return 'فيه $count حجوزات مؤكدة هتبقى برة المواعيد الجديدة. انقليها أو الغيها الأول.';
  }

  @override
  String get dashErrOtherClinic => 'دي بيانات عيادة تانية.';

  @override
  String get dashErrHourClosed => 'الساعة دي مش متاحة.';

  @override
  String get dashErrNotAllowed => 'مش مسموح.';

  @override
  String get dashErrAlreadyExists => 'موجود بالفعل.';

  @override
  String get dashRepPackageRevenue => 'إيراد الباقات';

  @override
  String get dashMoveForFamily => 'نقل الحجز لميعاد تاني';

  @override
  String get dashBrand => 'دكتور النونو';

  @override
  String get dashAdminSection => 'إدارة';

  @override
  String get dashUnsaved => 'فيه تغييرات مش محفوظة';

  @override
  String get dashAllSaved => 'كل التغييرات محفوظة';

  @override
  String get dashDiscard => 'تراجع';

  @override
  String get dashSaveChanges => 'حفظ التغييرات';

  @override
  String get dashPickRange => 'اختاري الفترة';

  @override
  String get dashEgp => 'جنيه';

  @override
  String get dashKpiBookings => 'الحجوزات';

  @override
  String dashKpiCapacity(String count) {
    return 'من $count مكان';
  }

  @override
  String get dashKpiArrived => 'وصلوا';

  @override
  String get dashKpiDone => 'تم الكشف';

  @override
  String get dashKpiNoShow => 'لم يحضر';

  @override
  String get dashKpiCash => 'كاش النهارده';

  @override
  String get dashKpiCashNote => 'كشوفات بس، من غير الباقات';

  @override
  String get dashHourOver => 'خلصت';

  @override
  String get dashHourNow => 'دلوقتي';

  @override
  String get dashTodayBookings => 'حجوزات النهارده';

  @override
  String get dashAllHours => 'كل الساعات';

  @override
  String get dashColNumber => '#';

  @override
  String get dashColChild => 'الطفل';

  @override
  String get dashColVisit => 'الزيارة';

  @override
  String get dashColStatus => 'الحالة';

  @override
  String get dashColPayment => 'الدفع';

  @override
  String get dashColAction => 'إجراء';

  @override
  String get dashOpenFile => 'الملف';

  @override
  String get dashPayPackage => 'باقة';

  @override
  String dashPayCash(String amount) {
    return '$amount ج';
  }

  @override
  String get dashClinicContact => 'بيانات العيادة والتواصل';

  @override
  String get dashPricesBooking => 'الأسعار والحجز';

  @override
  String get dashHoursAndVaccineDays => 'مواعيد العمل وأيام التطعيم';

  @override
  String get dashHoursHint =>
      'اختاري فترات كل يوم من القائمة. يوم من غير فترات = مقفول.';

  @override
  String get dashAddRange => 'فترة';

  @override
  String get dashDayClosed => 'مقفول';

  @override
  String get dashHolidayHint =>
      'الأيام دي العيادة مقفولة فيها ومش بتظهر في الحجز.';

  @override
  String get dashAddHoliday => 'إجازة';

  @override
  String get dashHolidayWarn =>
      'لو فيه حجوزات مؤكدة في يوم إجازة، الحفظ هيتوقف لحد ما تنقليها أو تلغيها.';

  @override
  String get dashNoHolidays => 'مفيش إجازات جاية.';

  @override
  String get dashVaccinePricesClinic => 'أسعار التطعيمات في العيادة';

  @override
  String get dashOffered => 'متاح';

  @override
  String get dashShownToGuardian => 'يظهر للأم';

  @override
  String get dashPriceAtClinic => 'بالسعر في العيادة';

  @override
  String get dashUnitMonths => 'شهر';

  @override
  String get dashUnitHours => 'ساعة';

  @override
  String get dashUnitPerHour => 'طفل/ساعة';

  @override
  String get dashChildFileTitle => 'ملف الطفل';

  @override
  String get dashChildFileAudited => 'فتح الملف ده اتسجل في سجل التدقيق';

  @override
  String get dashBack => 'رجوع';

  @override
  String get dashVisits => 'الزيارات';

  @override
  String get dashDoctorNotes => 'ملاحظات الدكتور';

  @override
  String get dashDoctorOnly => 'للدكتور بس';

  @override
  String get dashNewMeasurement => 'تسجيل قياس جديد';

  @override
  String get dashSaveMeasurement => 'حفظ القياس';

  @override
  String get dashMeasurementHint =>
      'اكتبي قيمة واحدة على الأقل. التصحيح بعد الحفظ للدكتور بس.';

  @override
  String get dashMeasurementHistory => 'القياسات المتسجلة';

  @override
  String get dashNumbersOnly =>
      'القياسات معروضة بالأرقام بس، من غير أي حكم طبي.';

  @override
  String get dashColDate => 'التاريخ';

  @override
  String get dashColClinic => 'العيادة';

  @override
  String get dashColRecorder => 'سجّله';

  @override
  String get dashColVaccine => 'التطعيم';

  @override
  String get dashColDose => 'الجرعة';

  @override
  String get dashColLot => 'التشغيلة';

  @override
  String get dashColNote => 'الملاحظة';

  @override
  String get dashCorrectShort => 'تصحيح';

  @override
  String get dashCorrected => 'اتصحح';

  @override
  String get dashGuardian => 'ولي الأمر';

  @override
  String dashClinicsVisited(String clinics) {
    return 'زار: $clinics';
  }

  @override
  String get dashNoPackage => 'من غير باقة';

  @override
  String dashResultsCount(String count) {
    return '$count نتيجة';
  }

  @override
  String get dashReportFilters => 'الفترة والعيادة';

  @override
  String get dashReportResult => 'النتيجة';

  @override
  String get dashStaffList => 'الحسابات';

  @override
  String get dashActive => 'شغال';

  @override
  String get dashAuditHint =>
      'كل فتح لملف طفل وكل تصحيح بيتسجل هنا. السجل للقراءة بس.';

  @override
  String get dashContentList => 'النصايح والفيديوهات';

  @override
  String get dashFollowUpBands => 'قوايم المتابعة حسب السن';

  @override
  String get dashDangerSigns => 'علامات الخطر';

  @override
  String get dashCatalogue => 'التطعيمات في التطبيق';

  @override
  String get dashSettingsHint => 'إعدادات للعيلة كلها في العيادتين.';

  @override
  String dashClinicArea(String area) {
    return 'عيادة $area';
  }

  @override
  String get dashRegisterFamily => 'تسجيل أسرة';

  @override
  String get dashRegisterFamilyHint =>
      'رقم ولي الأمر وبيانات الأطفال. ولي الأمر يربطهم بحسابه من التطبيق بعد التحقق.';

  @override
  String get dashRegisterWalkIn => 'تسجيل الأسرة';

  @override
  String dashChildN(String n) {
    return 'الطفل $n';
  }

  @override
  String get dashAddChild => 'طفل تاني';

  @override
  String get dashBirthWeight => 'وزن الولادة (اختياري)';

  @override
  String get dashAllergiesOptional => 'الحساسية (اختياري)';

  @override
  String get dashFamilyRegistered => 'اتسجلت الأسرة.';

  @override
  String get dashDuplicateTitle => 'الطفل ده متسجل قبل كده على نفس الرقم';

  @override
  String get dashDuplicateBody =>
      'مفيش حاجة اتسجلت. شيلي الطفل المكرر من القايمة واحفظي تاني، أو افتحي ملفه.';

  @override
  String get dashOpenExisting => 'افتحي الملف';

  @override
  String get dashMergeFile => 'دمج ملف مكرر';

  @override
  String get dashMergeHint =>
      'اختاري الملف التاني لنفس الطفل على نفس الرقم. القياسات والتطعيمات والزيارات بتتنقل للملف ده، والملف التاني بيتقفل.';

  @override
  String get dashMergeKeep => 'الملف اللي هيفضل';

  @override
  String get dashMergeClose => 'الملف اللي هيتقفل';

  @override
  String get dashMergeNoOthers => 'مفيش ملفات تانية مفتوحة على نفس الرقم.';

  @override
  String get dashMergeConfirm => 'دمج الملفين';

  @override
  String get dashMerged => 'اتدمج الملفين.';

  @override
  String dashRecordCounts(String m, String d, String v) {
    return '$m قياس · $d جرعة · $v زيارة';
  }

  @override
  String get dashFileClosed => 'الملف ده اتقفل واتدمج في ملف تاني.';

  @override
  String get dashOpenKept => 'افتحي الملف الأساسي';

  @override
  String get dashLinkToAccount => 'ربط بحساب ولي الأمر';

  @override
  String get dashLinkConfirm =>
      'اتأكدي من شخصية ولي الأمر الأول. كل الأطفال غير المربوطين على الرقم ده هيظهروا في حسابه.';

  @override
  String get dashLinked => 'اتربط الأطفال بحساب ولي الأمر.';

  @override
  String get dashNotLinked => 'مش مربوط بالتطبيق';

  @override
  String get dashErrDuplicate => 'الطفل ده متسجل قبل كده على نفس الرقم.';

  @override
  String get dashErrSameFile => 'لازم تختاري ملف تاني.';

  @override
  String get dashErrOtherNumber => 'الملفين على أرقام مختلفة.';

  @override
  String get dashErrClosed => 'الملف ده اتقفل قبل كده.';

  @override
  String get dashErrBookedTogether =>
      'فيه حجز جاي فيه الطفلين مع بعض. عدّليه أو الغيه الأول.';

  @override
  String get dashErrTooLarge => 'الملف كبير على الدمج مرة واحدة. كلمي الدعم.';

  @override
  String get dashErrNoAccount => 'مفيش حساب في التطبيق على الرقم ده لسه.';

  @override
  String get dashErrAlreadyLinked => 'الطفل مربوط بالفعل.';

  @override
  String get dashUnlockReverify => 'فك قفل التحقق';

  @override
  String get dashUnlockConfirm =>
      'اتأكدي من شخصية ولي الأمر الأول. بعد كده يقدر يتحقق من تاني في التطبيق.';

  @override
  String get dashUnlocked => 'اتفك القفل.';

  @override
  String get dashErrNotLocked => 'الحساب مش مقفول.';

  @override
  String get clinicWaitingRoom => 'مكان الانتظار في العيادة';

  @override
  String get welcomeWaitingRoom => 'مكان الانتظار في العيادة';

  @override
  String get welcomeWaitingRoomCaption => 'مكان مريح للأطفال وأهاليهم';

  @override
  String get notifTitle => 'الإشعارات';

  @override
  String get notifNew => 'الجديد';

  @override
  String get notifEarlier => 'قبل كده';

  @override
  String get notifMarkAllRead => 'تعليم الكل كمقروء';

  @override
  String get notifEmpty =>
      'مفيش إشعارات لسه. هنفكرك بمواعيد الحجز والتطعيمات هنا.';

  @override
  String get notifSettings => 'إعدادات الإشعارات';

  @override
  String get notifBookingSwitch => 'تذكير الحجز';

  @override
  String get notifBookingSwitchSub => 'قبل الميعاد بيوم وبساعة';

  @override
  String get notifVaccineSwitch => 'ميعاد التطعيم';

  @override
  String get notifVaccineSwitchSub => 'قبلها بـ ٣ أيام وفي يومها';

  @override
  String get notifOffNote =>
      'لو قفلتي نوع، هتلاقي التذكير برضه هنا في الصفحة دي.';

  @override
  String get notifDenied =>
      'الموبايل مش سامح للتطبيق يعرض إشعارات، فالتذكيرات هتفضل هنا في الصفحة بس.';

  @override
  String get notifOpenSettings => 'افتحي إعدادات الموبايل';

  @override
  String get notifAskBody => 'نفكرك قبل الميعاد بيوم وبساعة؟';

  @override
  String get notifAskButton => 'فعّلي التذكيرات';

  @override
  String notifUnreadCount(String count) {
    return '$count إشعارات جديدة';
  }

  @override
  String get remindBookingDay => 'ميعادك بكرة';

  @override
  String get remindBookingHour => 'ميعادك بعد ساعة';

  @override
  String remindVaccineSoon(String child) {
    return 'تطعيم $child بعد ٣ أيام';
  }

  @override
  String remindVaccineToday(String child) {
    return 'تطعيم $child النهارده';
  }

  @override
  String remindVaccineBody(String vaccine, String date) {
    return '$vaccine · $date';
  }

  @override
  String remindVaccineDose(String vaccine, String dose) {
    return '$vaccine · الجرعة $dose';
  }

  @override
  String get eventBookingConfirmed => 'تم تأكيد حجزك';

  @override
  String get eventBookingCancelled => 'اتلغى حجزك';

  @override
  String get notifYesterday => 'أمس';

  @override
  String get notifUnread => 'غير مقروء';

  @override
  String get splashDoctorLine => 'د. أحمد العبد · طب الأطفال وحديثي الولادة';

  @override
  String get navMe => 'حسابي';

  @override
  String get meTitle => 'حسابي';

  @override
  String get meEdit => 'تعديل';

  @override
  String get meChildren => 'أطفالي';

  @override
  String get meAddChild => 'إضافة طفل';

  @override
  String get mePackage => 'الباقة';

  @override
  String get meAppearance => 'المظهر';

  @override
  String get meTheme => 'الوضع';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeSystem => 'زي الموبايل';

  @override
  String get meTextSize => 'حجم الخط';

  @override
  String get textSmall => 'صغير';

  @override
  String get textNormal => 'عادي';

  @override
  String get textLarge => 'كبير';

  @override
  String get meSettings => 'الإعدادات';

  @override
  String get meLanguage => 'اللغة';

  @override
  String get meLanguageArabic => 'العربية';

  @override
  String get meEnglishSoon => 'English قريبًا';

  @override
  String get meNotifications => 'الإشعارات والتذكيرات';

  @override
  String get meNotificationsBoth => 'الحجز والتطعيمات شغالين';

  @override
  String get meNotificationsBooking => 'الحجز بس شغال';

  @override
  String get meNotificationsVaccine => 'التطعيمات بس شغالة';

  @override
  String get meNotificationsOff => 'مقفولين';

  @override
  String get mePreferredClinic => 'العيادة المفضلة';

  @override
  String get mePreferredClinicSub => 'بتظهر أول ما تحجزي';

  @override
  String get mePreferredNone => 'مش محددة';

  @override
  String get meAbout => 'عن التطبيق';

  @override
  String get meWhatsApp => 'كلمي العيادة على واتساب';

  @override
  String get mePrivacy => 'الخصوصية والشروط';

  @override
  String get meRate => 'قيّمي التطبيق';

  @override
  String get meRateSoon => 'التقييم هيتفعّل لما التطبيق ينزل على المتجر.';

  @override
  String meVersion(String version) {
    return 'دكتور النونو · الإصدار $version';
  }

  @override
  String get meSignInPrompt => 'سجّلي دخول عشان تشوفي أطفالك وتعدّلي بياناتك.';

  @override
  String get meSignIn => 'سجّلي برقم موبايلك';

  @override
  String get pkgTitle => 'الباقة السنوية';

  @override
  String get pkgSubtitle => 'لكل الإخوة';

  @override
  String pkgPerClinic(String price, String months) {
    return '$price جنيه · $months شهر';
  }

  @override
  String get pkgRulesTitle => 'الباقة بتشمل إيه';

  @override
  String get pkgRuleSiblings =>
      'باقة واحدة لكل الإخوة على حسابك، وأي أخ بيتضاف بعدين بيدخل فيها من غير رسوم.';

  @override
  String get pkgRuleVisits => 'كشوفات العيادة من غير حد أقصى طول مدة الباقة.';

  @override
  String get pkgRuleVaccines => 'التطعيمات بتتحسب بسعرها المعتاد.';

  @override
  String get pkgRuleClinics => 'سارية في العيادتين.';

  @override
  String get pkgRuleCash => 'الاشتراك والتجديد بالدفع كاش في العيادة.';

  @override
  String get pkgRuleStart => 'المدة بتبدأ من يوم الاشتراك.';

  @override
  String pkgActiveUntil(String date) {
    return 'لحد $date · في العيادتين';
  }

  @override
  String get pkgActive => 'سارية';

  @override
  String get pkgEnded => 'خلصت';

  @override
  String pkgEndedOn(String date) {
    return 'خلصت في $date';
  }

  @override
  String pkgRenewed(String date) {
    return 'اتجددت لحد $date';
  }

  @override
  String pkgChildLine(String name) {
    return 'باقة $name';
  }

  @override
  String get pkgNone => 'اشتركي في الباقة السنوية';

  @override
  String get pkgNoneSub => 'كشوفات من غير حد للإخوة كلهم';

  @override
  String get pkgYours => 'باقتك';

  @override
  String get pkgBookingHint => 'عندك إخوة بيكشفوا كتير؟ شوفي الباقة السنوية';

  @override
  String get remindPackageTitle => 'باقتك هتخلص بعد ١٤ يوم';

  @override
  String remindPackageBody(String date) {
    return 'لحد $date · جدّديها كاش في العيادة';
  }

  @override
  String get dashRenewPackage => 'تجديد الباقة';

  @override
  String get dashPackageRenewed => 'اتجددت الباقة.';

  @override
  String dashPackageNext(String from, String to) {
    return 'التجديد من $from لحد $to';
  }

  @override
  String get dashErrTooEarly => 'التجديد بيبقى في آخر ١٤ يوم من الباقة.';

  @override
  String get errTimeout => 'الرد اتأخر. اتأكدي من النت وجربي تاني.';

  @override
  String get signInLoadError => 'اتسجل دخولك، بس مقدرناش نحمّل بياناتك.';

  @override
  String get signInRetry => 'حاولي تاني';

  @override
  String get loadError => 'مقدرناش نحمّل البيانات. اتأكدي من النت وجربي تاني.';

  @override
  String get linkClinicChildren => 'ربط أطفال العيادة';

  @override
  String get contentTitle => 'نصايح الدكتور';

  @override
  String get contentSearch => 'دوّري في العناوين';

  @override
  String get contentAll => 'الكل';

  @override
  String contentForAge(String name) {
    return 'مناسب لسن $name';
  }

  @override
  String get contentAllItems => 'كل المحتوى';

  @override
  String get contentReviewed => 'كل المحتوى بيراجعه الدكتور قبل النشر.';

  @override
  String get contentEmpty => 'لسه مفيش محتوى منشور.';

  @override
  String get contentNoResults => 'مفيش نتايج. جربي كلمة تانية أو تصنيف تاني.';

  @override
  String get contentVideo => 'فيديو';

  @override
  String get contentTip => 'نصيحة مكتوبة';

  @override
  String contentAgeRange(String from, String to) {
    return 'من $from لـ $to شهر';
  }

  @override
  String get contentOpenYoutube => 'شوفي الفيديو على يوتيوب';

  @override
  String get contentVideoUnavailable => 'الفيديو ده مش متاح هنا.';

  @override
  String get contentVideoOffline =>
      'الفيديو محتاج إنترنت. اتأكدي من النت وجربي تاني.';

  @override
  String get contentNotFound => 'المحتوى ده مبقاش متاح.';

  @override
  String get contentHomeTitle => 'جديد من الدكتور';

  @override
  String get contentHomeAll => 'كل المحتوى';

  @override
  String get dashContentImport => 'استيراد من القناة';

  @override
  String get dashContentCategories => 'التصنيفات';

  @override
  String get dashContentAll => 'الكل';

  @override
  String get dashContentType => 'النوع';

  @override
  String get dashTypeVideo => 'فيديو';

  @override
  String get dashTypeTip => 'نصيحة مكتوبة';

  @override
  String get dashYoutubeLink => 'رابط الفيديو على يوتيوب';

  @override
  String get dashYoutubeHint => 'الصقي رابط الفيديو من قناة الدكتور';

  @override
  String get dashYoutubeInvalid => 'ده مش رابط فيديو يوتيوب.';

  @override
  String dashYoutubeId(String id) {
    return 'رقم الفيديو: $id';
  }

  @override
  String get dashAgeLimited => 'لسن معين';

  @override
  String get dashOrder => 'الترتيب';

  @override
  String get dashOrderNote => 'الرقم الأصغر يظهر الأول.';

  @override
  String get dashPreview => 'معاينة';

  @override
  String get dashPreviewTitle => 'زي ما الأم هتشوفه في التطبيق';

  @override
  String get dashUnpublish => 'إلغاء النشر';

  @override
  String get dashUnpublished => 'اتلغى النشر ورجع مسودة.';

  @override
  String get dashRestore => 'رجوع لمسودة';

  @override
  String get dashRestored => 'رجع مسودة.';

  @override
  String get dashImportAdded => 'متضاف';

  @override
  String get dashImportError =>
      'مقدرناش نقرا القناة دلوقتي. الصقي رابط الفيديو بنفسك.';

  @override
  String get dashImportNote =>
      'عناوين الشورتس في القناة تواريخ؛ اكتبي العنوان بعد الإضافة.';

  @override
  String get dashCategoryAdd => 'إضافة تصنيف';

  @override
  String get dashCategoryName => 'اسم التصنيف';

  @override
  String get dashMoveUp => 'لفوق';

  @override
  String get dashMoveDown => 'لتحت';

  @override
  String get dashErrInUse => 'التصنيف ده عليه محتوى، مينفعش يتشال.';

  @override
  String get dashErrVideoDuplicate => 'الفيديو ده متضاف قبل كده.';

  @override
  String get dashErrInvalidTransition => 'حالة المحتوى اتغيرت. حدّثي الصفحة.';

  @override
  String get dashBodyRequired => 'النصيحة محتاجة نص.';
}
