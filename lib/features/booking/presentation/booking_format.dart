import 'package:intl/intl.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/format/arabic_digits.dart';
import '../domain/booking.dart';
import '../domain/clinic_time.dart';
import '../domain/price_preview.dart';

int _h12(int h) => h % 12 == 0 ? 12 : h % 12;

/// "٦ لـ ٧ م" for hour 18 (the period of the hour's end).
String hourRange(AppLocalizations l10n, int hour) {
  final end = hour + 1;
  final period = end <= 11 || end == 24 ? l10n.periodAm : l10n.periodPm;
  return '${l10n.hourRange(arabicDigits(_h12(hour)), arabicDigits(_h12(end)))} $period';
}

/// "الأحد، ١٥ نوفمبر ٢٠٢٦".
String dayLabel(String date) => arabicDigits(DateFormat('EEEE، d MMMM y', 'ar').format(ClinicTime.asDate(date)));

/// "الأحد".
String weekdayName(String date) => DateFormat('EEEE', 'ar').format(ClinicTime.asDate(date));

/// "نوفمبر ٢٠٢٦".
String monthYear(String date) => arabicDigits(DateFormat('MMMM y', 'ar').format(ClinicTime.asDate(date)));

/// "نوفمبر".
String monthName(String date) => DateFormat('MMMM', 'ar').format(ClinicTime.asDate(date));

String dayNumber(String date) => arabicDigits(int.parse(date.substring(8)));

String egp(AppLocalizations l10n, int amount) => l10n.priceEgp(arabicDigits(amount));

String joinNames(AppLocalizations l10n, Iterable<String> names) => names.join(l10n.nameListSeparator);

/// "كشف يوسف", "تطعيم مريم" or "كشف وتطعيم يوسف ومريم".
String bookingTitle(AppLocalizations l10n, Booking b) {
  final names = joinNames(l10n, b.children.map((c) => c.name));
  if (b.visitType == VisitType.vaccineOnly) return l10n.titleVaccine(names);
  return b.price.vaccines.isEmpty ? l10n.titleVisit(names) : l10n.titleVisitAndVaccine(names);
}

/// What the clinic will ask for: the shown total, or "covered by package" for a covered visit alone.
String amountDue(AppLocalizations l10n, PriceSnapshot p) =>
    p.visitCovered && p.total == 0 && !p.hasHiddenPrices ? l10n.coveredByPackage : egp(l10n, p.total);
