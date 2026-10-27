import 'package:delnono/dashboard/screens/content_screen.dart';
import 'package:delnono/dashboard/screens/follow_up_editor_screen.dart';
import 'package:delnono/dashboard/screens/vaccines_admin_screen.dart';
import 'package:delnono/features/child_profile/data/follow_up_repository.dart';
import 'package:delnono/features/child_profile/data/vaccine_schedule_repository.dart';
import 'package:delnono/features/child_profile/domain/child_age.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'harness.dart';

/// Researched demo content shows «مقترح · يراجعه الدكتور» until the doctor approves it (launch checklist).
void main() {
  const badge = 'مقترح · يراجعه الدكتور';

  testWidgets('vaccines and schedule entries marked proposed show the badge; approved ones do not', (tester) async {
    await pumpDashboard(tester, const VaccinesAdminScreen(), path: '/vaccines', overrides: [
      ...dashboardOverrides(api: FakeDashboardApi(), session: doctorSession, catalogue: const {
        'v1': VaccineInfo(id: 'v1', name: 'شلل الأطفال بالفم', kind: VaccineKind.basic, proposed: true),
        'v3': VaccineInfo(id: 'v3', name: 'الروتا', kind: VaccineKind.additional),
      }),
      vaccineScheduleProvider.overrideWith((ref) => Stream.value(const [
            ScheduleEntry(id: 's04', vaccineId: 'v1', dose: 2, dueAge: AgeSpan(months: 2), ageLabel: 'الشهر التاني', order: 0, proposed: true),
          ])),
      vaccineSettingsProvider.overrideWith((ref) => Stream.value(const VaccineSettings(source: 'وزارة الصحة'))),
    ]);
    expect(find.byKey(const Key('proposed-vaccine-v1')), findsOneWidget);
    expect(find.byKey(const Key('proposed-vaccine-v3')), findsNothing);
    expect(find.byKey(const Key('proposed-schedule-s04')), findsOneWidget);
    expect(find.text(badge), findsNWidgets(2));
  });

  testWidgets('follow-up bands and danger signs: badges and the band\'s own signs are kept in the draft', (tester) async {
    final api = FakeDashboardApi();
    await pumpDashboard(tester, const FollowUpEditorScreen(), path: '/follow-up', overrides: [
      ...dashboardOverrides(api: api),
      followUpDraftsProvider.overrideWith((ref) => Stream.value(null)),
      followUpBandsProvider.overrideWith((ref) => Stream.value(const [
            FollowUpBand(fromMonths: 0, toMonths: 2, title: 'متابعة أول شهرين', items: ['بيبص في وشك'], dangerSigns: ['مش بيرضع كويس'], proposed: true),
          ])),
      followUpSettingsProvider.overrideWith((ref) => Stream.value(const FollowUpSettings(dangerSigns: ['جاله تشنجات'], proposed: true))),
    ]);
    expect(find.byKey(const Key('proposed-danger-signs')), findsOneWidget);
    expect(find.byKey(const Key('proposed-band-0')), findsOneWidget);
    await tester.tap(find.byKey(const Key('follow-up-save')));
    await tester.pumpAndSettle();
    final (_, data) = api.calls.single;
    expect(((data['bands']! as List).single as Map)['dangerSigns'], ['مش بيرضع كويس']);
  });

  testWidgets('a proposed tip shows the badge in the content list', (tester) async {
    await pumpDashboard(tester, const ContentScreen(), path: '/content', overrides: [
      ...dashboardOverrides(api: FakeDashboardApi(), session: doctorSession),
      contentItemsProvider.overrideWith((ref) => Stream.value([
            {'id': 'tip-sleep', 'type': 'tip', 'title': 'نوم الرضيع على ضهره', 'category': 'sleep', 'body': 'نص', 'status': 'published', 'reviewStatus': 'proposed'},
            {'id': 'tip-own', 'type': 'tip', 'title': 'نصيحة الدكتور', 'category': 'sleep', 'body': 'نص', 'status': 'published', 'reviewStatus': 'approved'},
          ])),
    ]);
    expect(find.byKey(const Key('proposed-tip-sleep')), findsOneWidget);
    expect(find.byKey(const Key('proposed-tip-own')), findsNothing);
  });
}
