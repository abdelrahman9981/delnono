import 'dart:io';

import 'package:delnono/features/booking/data/booking_settings.dart';
import 'package:delnono/features/booking/domain/schedule.dart';
import 'package:flutter_test/flutter_test.dart';

/// The seeded clinics' hours (functions/scripts/seed.ts): Moqattam Sat–Thu 1–3 pm and 6–10 pm; Nasr
/// City Sun/Tue/Wed 11 am–2 pm and 5–8 pm, Mon/Thu 5–9 pm; ISO weekdays, 1 = Monday.
const moqattamHours = <int, List<HourRange>>{
  1: [HourRange(13, 15), HourRange(18, 22)],
  2: [HourRange(13, 15), HourRange(18, 22)],
  3: [HourRange(13, 15), HourRange(18, 22)],
  4: [HourRange(13, 15), HourRange(18, 22)],
  5: [],
  6: [HourRange(13, 15), HourRange(18, 22)],
  7: [HourRange(13, 15), HourRange(18, 22)],
};
const nasrCityHours = <int, List<HourRange>>{
  1: [HourRange(17, 21)],
  2: [HourRange(11, 14), HourRange(17, 20)],
  3: [HourRange(11, 14), HourRange(17, 20)],
  4: [HourRange(17, 21)],
  5: [],
  6: [],
  7: [HourRange(11, 14), HourRange(17, 20)],
};

void main() {
  const moqattam = BookingSettings(workingHours: moqattamHours, holidays: ['2027-01-07']);
  const nasrCity = BookingSettings(capacityPerHour: 5, workingHours: nasrCityHours);
  const both = [13, 14, 18, 19, 20, 21];
  const long = [11, 12, 13, 17, 18, 19];
  const evening = [17, 18, 19, 20];

  test('the ranges match the seed', () {
    final seed = File('functions/scripts/seed.ts').readAsStringSync();
    expect(seed, contains('const c1Hours = [{ from: 13, to: 15 }, { from: 18, to: 22 }];'));
    expect(seed, contains('const c2Long = [{ from: 11, to: 14 }, { from: 17, to: 20 }];'));
    expect(seed, contains('const c2Evening = [{ from: 17, to: 21 }];'));
    expect(seed, contains('workingHours: { "1": c1Hours, "2": c1Hours, "3": c1Hours, "4": c1Hours, "5": [], "6": c1Hours, "7": c1Hours }'));
    expect(seed, contains('workingHours: { "1": c2Evening, "2": c2Long, "3": c2Long, "4": c2Evening, "5": [], "6": [], "7": c2Long }'));
  });

  // 7–13 Nov 2026: Saturday to Friday.
  final week = {
    '2026-11-07': ('Saturday', both, const <int>[]),
    '2026-11-08': ('Sunday', both, long),
    '2026-11-09': ('Monday', both, evening),
    '2026-11-10': ('Tuesday', both, long),
    '2026-11-11': ('Wednesday', both, long),
    '2026-11-12': ('Thursday', both, evening),
    '2026-11-13': ('Friday', const <int>[], const <int>[]),
  };
  for (final MapEntry(key: date, value: (day, m, n)) in week.entries) {
    test('$day $date: only the working ranges, at both clinics', () {
      expect(hoursOf(moqattam, date), m, reason: 'Moqattam');
      expect(hoursOf(nasrCity, date), n, reason: 'Nasr City');
      expect(isOpenDay(moqattam, date), m.isNotEmpty);
    });
  }

  test('a holiday has no hours (Coptic Christmas, Thursday 7 Jan 2027)', () {
    expect(hoursOf(moqattam, '2027-01-07'), isEmpty);
    expect(isOpenDay(moqattam, '2027-01-07'), isFalse);
  });

  test('booking offers only hours that have not started, inside the ranges', () {
    // Tuesday 10 Nov 2026, 2:30 pm Cairo (12:30 UTC): 1 pm and 2 pm have started.
    expect(openHours(moqattam, '2026-11-10', DateTime.utc(2026, 11, 10, 12, 30)), [18, 19, 20, 21]);
  });
}
