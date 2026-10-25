import 'package:delnono/dashboard/data/dashboard_api.dart';
import 'package:delnono/dashboard/data/today_repository.dart';
import 'package:delnono/dashboard/screens/children_search_screen.dart';
import 'package:delnono/dashboard/screens/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'harness.dart';

Future<void> pickDate(WidgetTester tester, Key key) async {
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.text(MaterialLocalizations.of(tester.element(find.byType(DatePickerDialog))).okButtonLabel));
  await tester.pumpAndSettle();
}

void main() {
  group('desk registration (009 US1, US2)', () {
    testWidgets('registers a number, the guardian and a child, then opens the new file', (tester) async {
      final api = FakeDashboardApi()..responses['registerFamily'] = {'childIds': ['new1']};
      final router = await pumpDashboard(tester, const ChildrenSearchScreen(), path: '/children', overrides: dashboardOverrides(api: api));
      await tester.tap(find.byKey(const Key('register-family')));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(find.byKey(const Key('family-save'))).onPressed, isNull, reason: 'incomplete');
      await tester.enterText(find.byKey(const Key('family-phone')), '01000000077');
      await tester.enterText(find.byKey(const Key('family-name')), '[أم يوسف]');
      await tester.enterText(find.byKey(const Key('family-child-name-0')), 'يوسف');
      await pickDate(tester, const Key('family-child-birth-0'));
      await tester.enterText(find.byKey(const Key('family-child-weight-0')), '3.2');
      await tester.tap(find.byKey(const Key('family-save')));
      await tester.pumpAndSettle();
      final (name, data) = api.calls.single;
      expect(name, 'registerFamily');
      expect(data, {
        'clinicId': 'clinic-1',
        'phone': '01000000077',
        'fullName': '[أم يوسف]',
        'relation': 'mother',
        'children': [{'name': 'يوسف', 'birthDate': '2026-11-15', 'sex': 'male', 'birthWeightKg': 3.2}],
      });
      expect(router.state.uri.path, '/children/new1');
    });

    testWidgets('a second child can be added and removed', (tester) async {
      await pumpDashboard(tester, const ChildrenSearchScreen(), path: '/children', overrides: dashboardOverrides(api: FakeDashboardApi()));
      await tester.tap(find.byKey(const Key('register-family')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('family-add-child')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('family-child-name-1')), findsOneWidget);
      await tester.tap(find.byKey(const Key('family-remove-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('family-child-name-1')), findsNothing);
    });

    testWidgets("a walk-in's family opens the form with its number, name and children", (tester) async {
      await pumpDashboard(tester, const TodayScreen(), overrides: dashboardOverrides(
        api: FakeDashboardApi(),
        walkIns: [WalkIn(id: 'w', hour: 18, familyName: 'أم سما', phone: '01000000055', children: const ['سما', 'علي'], status: 'arrived', arrivedAt: now)],
      ));
      await tester.tap(find.byKey(const Key('register-walkin-w')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '01000000055'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'أم سما'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'سما'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'علي'), findsOneWidget);
    });

    testWidgets('a duplicate keeps the form and links to the existing file (FR-65)', (tester) async {
      final api = FakeDashboardApi()
        ..error = const StaffActionRefused('already-exists', 'duplicate', {
          'duplicates': [{'index': 0, 'childId': 'kid', 'name': 'يُوسف'}],
        });
      final router = await pumpDashboard(tester, const ChildrenSearchScreen(), path: '/children', overrides: dashboardOverrides(api: api));
      await tester.tap(find.byKey(const Key('register-family')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('family-phone')), '01000000077');
      await tester.enterText(find.byKey(const Key('family-name')), '[أم يوسف]');
      await tester.enterText(find.byKey(const Key('family-child-name-0')), 'يوسف');
      await pickDate(tester, const Key('family-child-birth-0'));
      await tester.tap(find.byKey(const Key('family-save')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('family-duplicates')), findsOneWidget);
      expect(find.textContaining('يُوسف'), findsOneWidget);
      await tester.tap(find.byKey(const Key('open-duplicate-kid')));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/children/kid');
    });
  });
}
