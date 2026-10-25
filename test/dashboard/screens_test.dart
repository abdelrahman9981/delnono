import 'package:delnono/dashboard/screens/child_file_screen.dart';
import 'package:delnono/dashboard/screens/content_screen.dart';
import 'package:delnono/dashboard/screens/follow_up_editor_screen.dart';
import 'package:delnono/dashboard/screens/reports_screen.dart';
import 'package:delnono/dashboard/screens/staff_screen.dart';
import 'package:delnono/features/child_profile/data/follow_up_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'harness.dart';

final file = {
  'child': {'id': 'kid', 'name': 'يوسف', 'birthDate': '2024-03-15', 'sex': 'male', 'guardianPhone': '+201000000001', 'guardianUid': 'g1'},
  'measurements': [
    {'id': 'm1', 'measuredOn': '2026-10-01', 'weightKg': 12.9, 'clinicId': 'clinic-1'},
  ],
  'doses': [
    {'id': 'd1', 'vaccineId': 'v1', 'dose': 1, 'givenOn': '2024-03-16', 'lot': 'L-1', 'clinicId': 'clinic-2'},
  ],
  'visits': [
    {'id': 'v1', 'date': '2026-10-01', 'clinicId': 'clinic-1'},
  ],
  'packages': [],
};

void main() {
  group('child file (US4)', () {
    Future<FakeDashboardApi> open(WidgetTester tester, {bool doctor = false}) async {
      final api = FakeDashboardApi()
        ..responses['openChildFile'] = {
          ...file,
          if (doctor) 'visits': [{'id': 'v1', 'date': '2026-10-01', 'clinicId': 'clinic-1', 'note': '[ملاحظة]'}],
        };
      await pumpDashboard(tester, const ChildFileScreen(childId: 'kid'),
          path: '/children/kid', overrides: dashboardOverrides(api: api, session: doctor ? doctorSession : secretarySession));
      return api;
    }

    Future<void> tab(WidgetTester tester, int i) async {
      await tester.tap(find.byKey(Key('tab-$i')));
      await tester.pumpAndSettle();
    }

    testWidgets('opens through openChildFile (audited) and shows records with their clinic in tabs', (tester) async {
      final api = await open(tester);
      expect(api.calls.first.$1, 'openChildFile');
      expect(find.byKey(const Key('child-header')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('measurement-m1')), matching: find.text('١٢٫٩ كجم')), findsOneWidget);
      expect(find.text('القياسات معروضة بالأرقام بس، من غير أي حكم طبي.'), findsOneWidget);
      await tab(tester, 1);
      expect(find.descendant(of: find.byKey(const Key('dose-d1')), matching: find.text('L-1')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('dose-d1')), matching: find.text('مدينة نصر')), findsOneWidget);
    });

    testWidgets('the secretary adds but cannot correct, and sees no notes (D-29, FR-016)', (tester) async {
      await open(tester);
      expect(find.byKey(const Key('add-measurement')), findsOneWidget);
      expect(find.byKey(const Key('correct-measurement-m1')), findsNothing);
      expect(find.byKey(const Key('tab-3')), findsNothing, reason: 'no notes tab');
      for (final i in [1, 2]) {
        await tab(tester, i);
        expect(find.byKey(const Key('note-v1')), findsNothing);
        expect(find.text('[ملاحظة]'), findsNothing);
      }
    });

    testWidgets('the doctor corrects and reads and writes notes', (tester) async {
      await open(tester, doctor: true);
      expect(find.byKey(const Key('correct-measurement-m1')), findsOneWidget);
      await tab(tester, 1);
      expect(find.byKey(const Key('correct-dose-d1')), findsOneWidget);
      await tab(tester, 3);
      expect(find.text('[ملاحظة]'), findsOneWidget);
      expect(find.byKey(const Key('note-v1')), findsOneWidget);
    });

    testWidgets('the new-measurement form sends it at the current clinic', (tester) async {
      final api = await open(tester);
      await tester.enterText(find.byKey(const Key('new-m-weight')), '13.1');
      await tester.tap(find.byKey(const Key('add-measurement')));
      await tester.pumpAndSettle();
      final (name, data) = api.calls.firstWhere((c) => c.$1 == 'saveMeasurement');
      expect(name, 'saveMeasurement');
      expect(data['clinicId'], 'clinic-1');
      expect(data['measuredOn'], '2026-11-15');
      expect(data['weightKg'], 13.1);
      expect(data.containsKey('id'), isFalse);
    });

    testWidgets('a corrected record is tagged and shows who recorded it', (tester) async {
      final api = FakeDashboardApi()
        ..responses['openChildFile'] = {
          ...file,
          'measurements': [
            {'id': 'm1', 'measuredOn': '2026-10-01', 'weightKg': 12.9, 'clinicId': 'clinic-1', 'recordedByName': '[منى]', 'correctedBy': 'doc'},
          ],
        };
      await pumpDashboard(tester, const ChildFileScreen(childId: 'kid'), path: '/children/kid', overrides: dashboardOverrides(api: api));
      final row = find.byKey(const Key('measurement-m1'));
      expect(find.descendant(of: row, matching: find.text('[منى]')), findsOneWidget);
      expect(find.descendant(of: row, matching: find.text('اتصحح')), findsOneWidget);
    });

    testWidgets('a family without a package can buy one at this clinic (FR-012)', (tester) async {
      final api = await open(tester);
      await tester.tap(find.byKey(const Key('sell-package')));
      await tester.pumpAndSettle();
      final call = api.calls.firstWhere((c) => c.$1 == 'sellPackage');
      expect(call.$2, {'clinicId': 'clinic-1', 'guardianUid': 'g1'});
    });
  });

  group('reports (US7)', () {
    test('CSV holds dates, clinic and the six numbers only (FR-023)', () {
      final csv = reportCsv(
        [{'key': '2026-11-15', 'bookings': 3, 'arrivals': 1, 'noShows': 1, 'walkIns': 1, 'cash': 450, 'packagesSold': 1, 'packageRevenue': 1500}],
        {'key': 'total', 'bookings': 3, 'arrivals': 1, 'noShows': 1, 'walkIns': 1, 'cash': 450, 'packagesSold': 1, 'packageRevenue': 1500},
        '[عيادة]',
        const ['التاريخ', 'العيادة'],
      );
      final lines = csv.trim().split('\n');
      expect(lines[1], 'date,clinic,bookings,arrivals,noShows,walkIns,cash,packagesSold,packageRevenue');
      expect(lines[2], '2026-11-15,[عيادة],3,1,1,1,450,1,1500');
      expect(lines.last, startsWith('total,'));
    });

    testWidgets('the doctor can report both clinics; the secretary cannot', (tester) async {
      final api = FakeDashboardApi()..responses['report'] = {'rows': [], 'total': {'key': 'total'}};
      await pumpDashboard(tester, const ReportsScreen(), path: '/reports', overrides: dashboardOverrides(api: api));
      expect(find.byKey(const Key('report-all')), findsNothing);
      await tester.tap(find.byKey(const Key('report-run')));
      await tester.pumpAndSettle();
      expect(api.calls.single.$2['clinicId'], 'clinic-1');
      expect(find.byKey(const Key('report-table')), findsOneWidget);
    });
  });

  group('content and follow-up (US6)', () {
    testWidgets('a secretary has no publish button', (tester) async {
      final items = [{'id': 'x', 'title': '[حرارة]', 'category': 'fever', 'status': 'draft'}];
      await pumpDashboard(tester, const ContentScreen(), path: '/content',
          overrides: [...dashboardOverrides(api: FakeDashboardApi()), contentItemsProvider.overrideWith((ref) => Stream.value(items))]);
      expect(find.byKey(const Key('publish-x')), findsNothing);
    });

    testWidgets('the doctor publishes', (tester) async {
      final items = [{'id': 'x', 'title': '[حرارة]', 'category': 'fever', 'status': 'draft'}];
      await pumpDashboard(tester, const ContentScreen(), path: '/content', overrides: [
        ...dashboardOverrides(api: FakeDashboardApi(), session: doctorSession),
        contentItemsProvider.overrideWith((ref) => Stream.value(items)),
      ]);
      expect(find.byKey(const Key('publish-x')), findsOneWidget);
    });

    testWidgets('a secretary saves follow-up drafts; she has no publish button', (tester) async {
      final api = FakeDashboardApi();
      await pumpDashboard(tester, const FollowUpEditorScreen(), path: '/follow-up', overrides: [
        ...dashboardOverrides(api: api),
        followUpDraftsProvider.overrideWith((ref) => Stream.value(null)),
        followUpBandsProvider.overrideWith((ref) => Stream.value(const [FollowUpBand(fromMonths: 0, toMonths: 2, title: '[أول شهرين]', items: ['[بند]'])])),
        followUpSettingsProvider.overrideWith((ref) => Stream.value(const FollowUpSettings(dangerSigns: ['[خطر]']))),
      ]);
      expect(find.byKey(const Key('follow-up-publish')), findsNothing);
      await tester.tap(find.byKey(const Key('follow-up-save')));
      await tester.pumpAndSettle();
      final (name, data) = api.calls.single;
      expect(name, 'saveFollowUpDraft');
      expect(data['dangerSigns'], ['[خطر]']);
      expect((data['bands'] as List).single, {'title': '[أول شهرين]', 'fromMonths': 0, 'toMonths': 2, 'items': ['[بند]']});
    });
  });

  testWidgets('staff: the doctor creates a secretary for a clinic (US1)', (tester) async {
    final api = FakeDashboardApi();
    await pumpDashboard(tester, const StaffScreen(), path: '/staff', overrides: [
      ...dashboardOverrides(api: api, session: doctorSession),
      staffListProvider.overrideWith((ref) => Stream.value(const [])),
    ]);
    await tester.tap(find.byKey(const Key('staff-new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('staff-name')), '[منى]');
    await tester.enterText(find.byKey(const Key('staff-email')), 'mona@demo.delnono');
    await tester.enterText(find.byKey(const Key('staff-password')), 'Temp-1234');
    await tester.tap(find.byKey(const Key('staff-clinic')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('[عيادة مدينة نصر · بيانات مؤقتة]').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('staff-save')));
    await tester.pumpAndSettle();
    final (name, data) = api.calls.single;
    expect(name, 'manageStaff');
    expect(data, {'action': 'create', 'name': '[منى]', 'email': 'mona@demo.delnono', 'tempPassword': 'Temp-1234', 'role': 'secretary', 'clinicId': 'clinic-2'});
  });
}
