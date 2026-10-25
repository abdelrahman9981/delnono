import 'package:delnono/dashboard/screens/clinic_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'harness.dart';

Future<void> show(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
}

void main() {
  test('ranges merge when they overlap or touch, and stay sorted', () {
    expect(addRange(const [(17, 21)], (10, 14)), [(10, 14), (17, 21)]);
    expect(addRange(const [(10, 14)], (13, 18)), [(10, 18)]);
    expect(addRange(const [(10, 14), (17, 21)], (14, 17)), [(10, 21)]);
  });

  group('clinic settings (US5, docs/design/dashboard/Clinic)', () {
    late FakeDashboardApi api;

    Future<void> open(WidgetTester tester) async {
      api = FakeDashboardApi();
      await pumpDashboard(tester, const ClinicSettingsScreen(), path: '/clinic', overrides: [
        ...dashboardOverrides(api: api),
        clinicDocProvider.overrideWith((ref, id) => Stream.value({'name': '[عيادة المقطم · بيانات مؤقتة]', 'address': '[عنوان]', 'packagePrice': 1500, 'packageMonths': 12})),
      ]);
    }

    Map<String, dynamic> saved() => api.calls.single.$2['fields']! as Map<String, dynamic>;

    Future<void> save(WidgetTester tester) async {
      await show(tester, find.byKey(const Key('save-changes')));
      await tester.tap(find.byKey(const Key('save-changes')));
      await tester.pumpAndSettle();
    }

    testWidgets('nothing to save until something changes; a closed day shows "closed"', (tester) async {
      await open(tester);
      expect(tester.widget<FilledButton>(find.byKey(const Key('save-changes'))).onPressed, isNull);
      expect(find.byKey(const Key('unsaved-note')), findsNothing);
      expect(find.byKey(const Key('closed-5')), findsOneWidget, reason: 'Friday has no hours');
      expect(find.byType(TextField).evaluate().where((e) => (e.widget.key as ValueKey?)?.value == 'hours-5'), isEmpty,
          reason: 'hours are never typed');
    });

    testWidgets('a time range is picked from lists and saved; the bar shows unsaved changes', (tester) async {
      await open(tester);
      await show(tester, find.byKey(const Key('add-range-5')));
      await tester.tap(find.byKey(const Key('add-range-5')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('range-from')), findsOneWidget);
      await tester.tap(find.byKey(const Key('range-ok')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('range-5-0')), findsOneWidget);
      expect(find.byKey(const Key('unsaved-note')), findsOneWidget);
      await save(tester);
      expect(api.calls.single.$1, 'updateClinic');
      expect((saved()['workingHours'] as Map)['5'], [{'from': 17, 'to': 21}]);
      expect(find.byKey(const Key('unsaved-note')), findsNothing, reason: 'saved');
    });

    testWidgets('removing a range and discarding brings the saved hours back', (tester) async {
      await open(tester);
      await show(tester, find.byKey(const Key('range-6-0')));
      await tester.tap(find.descendant(of: find.byKey(const Key('range-6-0')), matching: find.byIcon(Icons.close)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('closed-6')), findsOneWidget);
      await tester.tap(find.byKey(const Key('discard')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('range-6-0')), findsOneWidget);
      expect(find.byKey(const Key('unsaved-note')), findsNothing);
    });

    testWidgets('a holiday comes from the date picker and shows as a chip', (tester) async {
      await open(tester);
      await show(tester, find.byKey(const Key('add-holiday')));
      await tester.tap(find.byKey(const Key('add-holiday')));
      await tester.pumpAndSettle();
      final ok = MaterialLocalizations.of(tester.element(find.byType(DatePickerDialog))).okButtonLabel;
      await tester.tap(find.text(ok));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('holiday-2026-11-15')), findsOneWidget);
      await save(tester);
      expect(saved()['holidays'], ['2026-11-15']);
    });

    testWidgets('each vaccine has one "shown to the guardian" switch; off shows the price at the clinic', (tester) async {
      await open(tester);
      await show(tester, find.byKey(const Key('offer-v1')));
      expect(find.byKey(const Key('shown-v1')), findsOneWidget);
      await tester.tap(find.byKey(const Key('offered-v1')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('price-v1')), '450');
      await tester.tap(find.byKey(const Key('shown-v1')));
      await tester.pumpAndSettle();
      expect(find.textContaining('بالسعر في العيادة'), findsOneWidget);
      await save(tester);
      expect((saved()['vaccinePrices'] as Map)['v1'], {'offered': true, 'price': 450, 'shown': false});
    });
  });
}
