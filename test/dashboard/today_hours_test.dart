import 'package:delnono/dashboard/screens/today_screen.dart';
import 'package:delnono/features/booking/data/booking_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/booking/seeded_hours_test.dart' show moqattamHours;
import 'fakes.dart';
import 'harness.dart';

/// «اليوم» shows only the day's working ranges of the seeded Moqattam clinic, never 24 hours.
void main() {
  const moqattam = BookingSettings(workingHours: moqattamHours, holidays: ['2027-01-07']);

  Future<void> open(WidgetTester tester, DateTime clock) => pumpDashboard(
        tester,
        const TodayScreen(),
        overrides: dashboardOverrides(api: FakeDashboardApi(), clinic1Settings: moqattam, clock: clock),
      );

  Finder card(int h) => find.byKey(Key('hour-card-$h'));

  testWidgets('Tuesday: six one-hour blocks (1–3 pm, 6–10 pm) and 36 places', (tester) async {
    await open(tester, DateTime.utc(2026, 11, 10, 8)); // 10 am Cairo
    for (final h in [13, 14, 18, 19, 20, 21]) {
      expect(card(h), findsOneWidget, reason: '$h');
    }
    for (final h in [0, 12, 15, 17, 22, 23]) {
      expect(card(h), findsNothing, reason: '$h');
    }
    expect(find.text('من ٣٦ مكان'), findsOneWidget);
    expect(find.textContaining('١ م لـ ٣ م، ٦ م لـ ١٠ م'), findsOneWidget, reason: 'the header shows the break');
  });

  test('hour runs', () {
    expect(hourRuns([13, 14, 18, 19, 20, 21]), [(13, 15), (18, 22)]);
    expect(hourRuns([17]), [(17, 18)]);
    expect(hourRuns([]), isEmpty);
  });

  testWidgets('Friday: «العيادة مقفولة النهارده» and no blocks', (tester) async {
    await open(tester, DateTime.utc(2026, 11, 13, 8));
    expect(find.text('العيادة مقفولة النهارده.'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => '${w.key}'.contains('hour-card-')), findsNothing);
  });

  testWidgets('a holiday: closed, no blocks', (tester) async {
    await open(tester, DateTime.utc(2027, 1, 7, 8));
    expect(find.text('العيادة مقفولة النهارده.'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => '${w.key}'.contains('hour-card-')), findsNothing);
  });
}
