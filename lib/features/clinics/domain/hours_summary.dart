import 'package:intl/intl.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/format/arabic_digits.dart';
import 'clinic_hours.dart';

/// Egypt's week starts on Saturday (ISO 6).
const _weekOrder = [6, 7, 1, 2, 3, 4, 5];

int _h12(int h) => h % 12 == 0 ? 12 : h % 12;

/// "١٠ ص لـ ٢ م": a range of opening hours.
String openRange(AppLocalizations l10n, HourRange r) {
  String at(int h) => '${arabicDigits(_h12(h))} ${h < 12 || h == 24 ? l10n.periodAm : l10n.periodPm}';
  return l10n.hourRange(at(r.from), at(r.to));
}

/// One line per group of weekdays with the same hours, in week order, e.g.
/// "السبت، الأحد، الاثنين، الثلاثاء، الأربعاء، الخميس · ٥ م لـ ٩ م". Closed days are left out.
List<String> hoursSummary(AppLocalizations l10n, Map<int, List<HourRange>> workingHours) {
  // 5 Jan 2026 is a Monday, so ISO weekday d falls on 4 + d January.
  String dayName(int iso) => DateFormat('EEEE', 'ar').format(DateTime(2026, 1, 4 + iso));
  String key(List<HourRange> ranges) => ranges.map((r) => '${r.from}-${r.to}').join(',');
  final groups = <String, (List<int>, List<HourRange>)>{};
  for (final day in _weekOrder) {
    final ranges = workingHours[day] ?? const <HourRange>[];
    if (ranges.isEmpty) continue;
    groups.putIfAbsent(key(ranges), () => (<int>[], ranges)).$1.add(day);
  }
  return [
    for (final (days, ranges) in groups.values)
      '${days.map(dayName).join(l10n.listSeparator)} · ${ranges.map((r) => openRange(l10n, r)).join(l10n.listSeparator)}',
  ];
}
