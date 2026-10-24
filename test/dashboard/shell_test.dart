import 'package:delnono/dashboard/screens/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/clinic_fakes.dart';
import 'fakes.dart';
import 'harness.dart';

void main() {
  testWidgets('a secretary sees her clinic and no doctor-only screens (D-47)', (tester) async {
    await pumpDashboard(tester, const TodayScreen(), overrides: dashboardOverrides(api: FakeDashboardApi()));
    expect(find.byKey(const Key('dash-clinic-name')), findsOneWidget);
    expect(find.text(clinic1.name), findsWidgets);
    expect(find.byKey(const Key('dash-clinic-picker')), findsNothing);
    expect(find.text('الموظفين'), findsNothing);
    expect(find.text('سجل التدقيق'), findsNothing);
  });

  testWidgets('the doctor switches clinics and sees every screen', (tester) async {
    await pumpDashboard(tester, const TodayScreen(), overrides: dashboardOverrides(api: FakeDashboardApi(), session: doctorSession));
    expect(find.text('الموظفين'), findsOneWidget);
    expect(find.text('سجل التدقيق'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dash-clinic-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(clinic2.name).last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hour-row-10')), findsOneWidget, reason: "clinic 2's morning hours");
  });

  testWidgets('on a tablet the navigation is a drawer', (tester) async {
    await pumpDashboard(tester, const TodayScreen(), overrides: dashboardOverrides(api: FakeDashboardApi()), size: const Size(820, 1180));
    expect(find.byKey(const Key('dash-nav')), findsNothing);
    expect(find.byType(DrawerButton), findsOneWidget);
  });
}
