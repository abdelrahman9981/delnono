import '../../app/l10n/app_localizations.dart';
import 'arabic_digits.dart';

/// Age in years and months, in Arabic ("سنتين و٣ شهور"). [birthDate] is `YYYY-MM-DD`.
String arabicAge(String birthDate, AppLocalizations l10n, {DateTime? today}) {
  final b = DateTime.parse(birthDate);
  final t = today ?? DateTime.now();
  var months = (t.year - b.year) * 12 + t.month - b.month;
  if (t.day < b.day) months--;
  if (months < 1) return l10n.ageNewborn;
  final y = months ~/ 12;
  final m = months % 12;
  final years = y > 0 ? l10n.ageYears(y, arabicDigits(y)) : null;
  final mos = m > 0 ? l10n.ageMonths(m, arabicDigits(m)) : null;
  if (years != null && mos != null) return l10n.ageAnd(years, mos);
  return years ?? mos!;
}
