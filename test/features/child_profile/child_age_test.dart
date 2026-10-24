import 'package:delnono/features/child_profile/domain/child_age.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('addAge', () {
    test('adds calendar months, then days', () {
      expect(addAge('2026-01-20', const AgeSpan(months: 9)), '2026-10-20');
      expect(addAge('2024-03-15', const AgeSpan(months: 18)), '2025-09-15');
      expect(addAge('2026-01-20', const AgeSpan(days: 45)), '2026-03-06');
      expect(addAge('2026-01-20', const AgeSpan(months: 1, days: 3)), '2026-02-23');
    });

    test('clamps to the end of a shorter month', () {
      expect(addAge('2026-01-31', const AgeSpan(months: 1)), '2026-02-28');
      expect(addAge('2024-01-31', const AgeSpan(months: 1)), '2024-02-29');
      expect(addAge('2026-08-31', const AgeSpan(months: 1)), '2026-09-30');
    });

    test('a leap-day birth reaches its first birthday on 28 February', () {
      expect(addAge('2024-02-29', const AgeSpan(months: 12)), '2025-02-28');
    });
  });

  group('ageInMonths', () {
    test('a month is complete on the same day of the month', () {
      expect(ageInMonths('2026-01-20', '2026-10-19'), 8);
      expect(ageInMonths('2026-01-20', '2026-10-20'), 9);
      expect(ageInMonths('2022-07-02', '2026-10-24'), 51);
    });

    test('month-end births complete on the shorter month\'s last day', () {
      expect(ageInMonths('2026-01-31', '2026-02-28'), 1);
      expect(ageInMonths('2026-01-31', '2026-02-27'), 0);
    });

    test('never negative', () => expect(ageInMonths('2026-10-24', '2026-10-01'), 0));
  });

  test('ageInMonthsExact is fractional within the month', () {
    expect(ageInMonthsExact('2026-01-20', '2026-01-20'), 0);
    expect(ageInMonthsExact('2026-01-20', '2026-03-20'), 2);
    expect(ageInMonthsExact('2026-01-20', '2026-02-05'), closeTo(0.52, 0.01));
  });

  test('daysBetween', () {
    expect(daysBetween('2026-10-20', '2026-10-27'), 7);
    expect(daysBetween('2026-10-27', '2026-10-20'), -7);
  });
}
