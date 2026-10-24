/// Ages and due dates from a birth date (`YYYY-MM-DD`, Cairo calendar dates). Pure Dart.
library;

/// A child's age or a schedule age: whole calendar months plus days.
class AgeSpan {
  const AgeSpan({this.months = 0, this.days = 0});

  factory AgeSpan.fromMap(Object? m) {
    if (m is! Map) return const AgeSpan();
    return AgeSpan(months: (m['months'] as num?)?.toInt() ?? 0, days: (m['days'] as num?)?.toInt() ?? 0);
  }

  final int months;
  final int days;

  @override
  bool operator ==(Object other) => other is AgeSpan && other.months == months && other.days == days;

  @override
  int get hashCode => Object.hash(months, days);

  @override
  String toString() => 'AgeSpan($months m, $days d)';
}

DateTime _parse(String date) {
  final p = date.split('-').map(int.parse).toList();
  return DateTime.utc(p[0], p[1], p[2]);
}

String _format(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// [date] plus [span]: calendar months first, clamped to the last day of the month (31 Jan + 1 month
/// = 28 or 29 Feb), then days.
String addAge(String date, AgeSpan span) {
  final d = _parse(date);
  final monthIndex = d.month - 1 + span.months;
  final year = d.year + (monthIndex ~/ 12);
  final month = monthIndex % 12 + 1;
  final lastDay = DateTime.utc(year, month + 1, 0).day;
  final day = d.day > lastDay ? lastDay : d.day;
  return _format(DateTime.utc(year, month, day + span.days));
}

/// Whole calendar months from [birthDate] to [today] (a month is complete on the same day of the
/// month, or on the month's last day when it is shorter).
int ageInMonths(String birthDate, String today) {
  final b = _parse(birthDate);
  final t = _parse(today);
  var months = (t.year - b.year) * 12 + t.month - b.month;
  if (months > 0 && compareDates(addAge(birthDate, AgeSpan(months: months)), today) > 0) months--;
  return months < 0 ? 0 : months;
}

/// Age in fractional months, for the growth chart's x axis.
double ageInMonthsExact(String birthDate, String date) {
  final whole = ageInMonths(birthDate, date);
  final from = _parse(addAge(birthDate, AgeSpan(months: whole)));
  final to = _parse(addAge(birthDate, AgeSpan(months: whole + 1)));
  final into = _parse(date).difference(from).inDays;
  return whole + into / to.difference(from).inDays;
}

/// Negative when [a] is before [b] (both `YYYY-MM-DD`).
int compareDates(String a, String b) => a.compareTo(b);

/// Days from [from] to [to] (positive when [to] is later).
int daysBetween(String from, String to) => _parse(to).difference(_parse(from)).inDays;
