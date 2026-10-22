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
