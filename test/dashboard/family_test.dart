import 'package:delnono/dashboard/data/dashboard_api.dart';
import 'package:delnono/dashboard/data/today_repository.dart';
import 'package:delnono/dashboard/screens/child_file_screen.dart';
import 'package:delnono/dashboard/screens/children_search_screen.dart';
import 'package:delnono/dashboard/screens/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'harness.dart';
import 'screens_test.dart' show file;

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

  group('merging files (009 US3)', () {
    FakeDashboardApi api0() => FakeDashboardApi()
      ..responses['openChildFile'] = file
      ..responses['searchChildren'] = {
        'children': [
          {'id': 'kid', 'name': 'يوسف', 'birthDate': '2024-03-15', 'sex': 'male', 'guardianPhone': '+201000000001'},
          {'id': 'dup', 'name': 'يوسف ا', 'birthDate': '2024-03-15', 'sex': 'male', 'guardianPhone': '+201000000001'},
        ],
      };

    testWidgets('a secretary has no merge action', (tester) async {
      await pumpDashboard(tester, const ChildFileScreen(childId: 'kid'), path: '/children/kid', overrides: dashboardOverrides(api: api0()));
      expect(find.byKey(const Key('merge-file')), findsNothing);
    });

    testWidgets('the doctor picks the other file on the number and merges it into this one', (tester) async {
      final api = api0();
      await pumpDashboard(tester, const ChildFileScreen(childId: 'kid'), path: '/children/kid',
          overrides: dashboardOverrides(api: api, session: doctorSession));
      await tester.tap(find.byKey(const Key('merge-file')));
      await tester.pumpAndSettle();
      expect(api.calls.last.$1, 'searchChildren');
      expect(api.calls.last.$2, {'query': '+201000000001'});
      expect(find.byKey(const Key('merge-pick-kid')), findsNothing, reason: 'not itself');
      expect(tester.widget<FilledButton>(find.byKey(const Key('merge-confirm'))).onPressed, isNull);
      await tester.tap(find.byKey(const Key('merge-pick-dup')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('merge-side-kid')), findsOneWidget);
      expect(find.byKey(const Key('merge-side-dup')), findsOneWidget);
      await tester.tap(find.byKey(const Key('merge-confirm')));
      await tester.pumpAndSettle();
      expect(api.calls.where((c) => c.$1 == 'mergeChildren').single.$2, {'keepId': 'kid', 'closeId': 'dup'});
    });

    testWidgets('keeping the other file closes this one and opens the kept file', (tester) async {
      final api = api0();
      final router = await pumpDashboard(tester, const ChildFileScreen(childId: 'kid'), path: '/children/kid',
          overrides: dashboardOverrides(api: api, session: doctorSession));
      await tester.tap(find.byKey(const Key('merge-file')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('merge-pick-dup')));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byKey(const Key('merge-keep')), matching: find.text('يوسف ا')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('merge-confirm')));
      await tester.pumpAndSettle();
      expect(api.calls.where((c) => c.$1 == 'mergeChildren').single.$2, {'keepId': 'dup', 'closeId': 'kid'});
      expect(router.state.uri.path, '/children/dup');
    });

    testWidgets('a closed file says where it went', (tester) async {
      final api = FakeDashboardApi()..responses['openChildFile'] = {'merged': {'into': 'kept', 'name': 'يوسف أحمد'}};
      final router = await pumpDashboard(tester, const ChildFileScreen(childId: 'old'), path: '/children/old', overrides: dashboardOverrides(api: api));
      expect(find.byKey(const Key('child-closed')), findsOneWidget);
      expect(find.text('يوسف أحمد'), findsOneWidget);
      await tester.tap(find.byKey(const Key('open-kept')));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/children/kept');
    });
  });

  group('staff lift a lock (009 US4)', () {
    final unlinked = {
      ...file,
      'child': {...file['child']! as Map, 'guardianUid': null},
      'accountOnNumber': true,
      'clinicGuardian': {'fullName': '[أم يوسف]', 'relation': 'mother'},
    };

    testWidgets('an unlinked child with an account on the number can be linked, after confirming', (tester) async {
      final api = FakeDashboardApi()..responses['openChildFile'] = unlinked;
      await pumpDashboard(tester, const ChildFileScreen(childId: 'kid'), path: '/children/kid', overrides: dashboardOverrides(api: api));
      expect(find.byKey(const Key('child-unlinked')), findsOneWidget);
      expect(find.textContaining('[أم يوسف]'), findsOneWidget);
      await tester.tap(find.byKey(const Key('staff-link')));
      await tester.pumpAndSettle();
      expect(api.calls.where((c) => c.$1 == 'staffLinkChildren'), isEmpty, reason: 'asks first');
      await tester.tap(find.byKey(const Key('confirm-yes')));
      await tester.pumpAndSettle();
      expect(api.calls.where((c) => c.$1 == 'staffLinkChildren').single.$2, {'childId': 'kid'});
    });

    testWidgets('no link without an account; unlock only when locked', (tester) async {
      final api = FakeDashboardApi()..responses['openChildFile'] = {...unlinked, 'accountOnNumber': false};
      await pumpDashboard(tester, const ChildFileScreen(childId: 'kid'), path: '/children/kid', overrides: dashboardOverrides(api: api));
      expect(find.byKey(const Key('staff-link')), findsNothing);
      expect(find.byKey(const Key('unlock-reverify')), findsNothing);
    });

    testWidgets('a locked guardian is unlocked after confirming', (tester) async {
      final api = FakeDashboardApi()..responses['openChildFile'] = {...file, 'reverifyLocked': true};
      await pumpDashboard(tester, const ChildFileScreen(childId: 'kid'), path: '/children/kid', overrides: dashboardOverrides(api: api));
      await tester.tap(find.byKey(const Key('unlock-reverify')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-yes')));
      await tester.pumpAndSettle();
      expect(api.calls.where((c) => c.$1 == 'unlockReverify').single.$2, {'childId': 'kid'});
    });
  });

  // T016: the new dialogs and states lay out at desktop and tablet width, light and dark, normal and
  // large text (FR-010).
  group('layout', () {
    for (final size in const [Size(1440, 900), Size(820, 1180)]) {
      for (final b in Brightness.values) {
        for (final scale in [1.0, 1.5]) {
          final label = '${size.width.toInt()} · ${b.name} · ×$scale';
          testWidgets('registration and merge dialogs, unlinked file · $label', (tester) async {
            final api = FakeDashboardApi()
              ..responses['openChildFile'] = {
                ...file,
                'child': {...file['child']! as Map, 'guardianUid': null},
                'accountOnNumber': true,
                'reverifyLocked': true,
                'clinicGuardian': {'fullName': '[اسم ولي أمر طويل شوية للتجربة]', 'relation': 'mother'},
              }
              ..responses['searchChildren'] = {
                'children': [
                  {'id': 'kid', 'name': 'يوسف', 'birthDate': '2024-03-15', 'sex': 'male', 'guardianPhone': '+201000000001'},
                  {'id': 'dup', 'name': 'يوسف أحمد محمود عبد الرحمن', 'birthDate': '2024-03-15', 'sex': 'male', 'guardianPhone': '+201000000001'},
                ],
              };
            await pumpDashboard(tester, const ChildFileScreen(childId: 'kid'), path: '/children/kid', size: size, brightness: b, textScale: scale,
                overrides: dashboardOverrides(api: api, session: doctorSession));
            expect(tester.takeException(), isNull);
            await tester.tap(find.byKey(const Key('merge-file')));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const Key('merge-pick-dup')));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.tap(find.text(MaterialLocalizations.of(tester.element(find.byType(AlertDialog))).closeButtonLabel).evaluate().isEmpty
                ? find.text('إغلاق')
                : find.text(MaterialLocalizations.of(tester.element(find.byType(AlertDialog))).closeButtonLabel));
            await tester.pumpAndSettle();
          });

          testWidgets('registration dialog with two children and a duplicate · $label', (tester) async {
            final api = FakeDashboardApi()
              ..error = const StaffActionRefused('already-exists', 'duplicate', {
                'duplicates': [{'index': 1, 'childId': 'kid', 'name': 'يوسف أحمد محمود'}],
              });
            await pumpDashboard(tester, const ChildrenSearchScreen(), path: '/children', size: size, brightness: b, textScale: scale,
                overrides: dashboardOverrides(api: api));
            await tester.tap(find.byKey(const Key('register-family')));
            await tester.pumpAndSettle();
            await tester.ensureVisible(find.byKey(const Key('family-add-child')));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const Key('family-add-child')));
            await tester.pumpAndSettle();
            await tester.enterText(find.byKey(const Key('family-phone')), '01000000077');
            await tester.enterText(find.byKey(const Key('family-name')), '[أم يوسف]');
            for (final i in [0, 1]) {
              await tester.ensureVisible(find.byKey(Key('family-child-name-$i')));
              await tester.pumpAndSettle();
              await tester.enterText(find.byKey(Key('family-child-name-$i')), 'يوسف');
              await tester.ensureVisible(find.byKey(Key('family-child-birth-$i')));
              await tester.pumpAndSettle();
              await pickDate(tester, Key('family-child-birth-$i'));
            }
            await tester.ensureVisible(find.byKey(const Key('family-save')));
            await tester.tap(find.byKey(const Key('family-save')));
            await tester.pumpAndSettle();
            expect(find.byKey(const Key('family-duplicates')), findsOneWidget);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });
}
