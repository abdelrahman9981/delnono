import 'package:intl/intl.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/format/arabic_digits.dart';
import '../../booking/domain/clinic_time.dart';
import '../domain/child_age.dart';

/// "١٢ نوفمبر ٢٠٢٦".
String shortDate(String date) => arabicDigits(DateFormat('d MMMM y', 'ar').format(ClinicTime.asDate(date)));

/// "٨٫٧" with one decimal, or "٧١" for whole values.
String measureValue(double v) {
  final rounded = (v * 10).round() / 10;
  return rounded == rounded.roundToDouble() ? arabicDigits(rounded.toInt()) : arabicDecimal(rounded);
}

/// "٩ شهور", "سنة و٦ شهور", "عند الولادة" for an age span.
String ageSpanLabel(AppLocalizations l10n, AgeSpan span) {
  if (span.months == 0 && span.days == 0) return l10n.chartBirth;
  final y = span.months ~/ 12;
  final m = span.months % 12;
  final years = y > 0 ? l10n.ageYears(y, arabicDigits(y)) : null;
  final months = m > 0 ? l10n.ageMonths(m, arabicDigits(m)) : null;
  if (years != null && months != null) return l10n.ageAnd(years, months);
  return years ?? months ?? l10n.ageNewborn;
}
