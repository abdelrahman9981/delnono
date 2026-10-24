// T024: every dashboard screen at desktop (1440) and tablet (820) width, light and dark, normal and
// large text, lays out without overflow (005 FR-026).

import 'package:delnono/dashboard/screens/audit_screen.dart';
import 'package:delnono/dashboard/screens/child_file_screen.dart';
import 'package:delnono/dashboard/screens/children_search_screen.dart';
import 'package:delnono/dashboard/screens/clinic_settings_screen.dart';
import 'package:delnono/dashboard/screens/content_screen.dart';
import 'package:delnono/dashboard/screens/follow_up_editor_screen.dart';
import 'package:delnono/dashboard/screens/password_screen.dart';
import 'package:delnono/dashboard/screens/reports_screen.dart';
import 'package:delnono/dashboard/screens/settings_screen.dart';
import 'package:delnono/dashboard/screens/sign_in_screen.dart';
import 'package:delnono/dashboard/screens/staff_screen.dart';
import 'package:delnono/dashboard/screens/today_screen.dart';
import 'package:delnono/dashboard/screens/vaccines_admin_screen.dart';
import 'package:delnono/features/auth/data/auth_repository.dart';
import 'package:delnono/features/child_profile/data/follow_up_repository.dart';
import 'package:delnono/features/child_profile/data/vaccine_schedule_repository.dart';
import 'package:delnono/features/child_profile/domain/child_age.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/rtl_icons.dart';
import 'fakes.dart';
import 'harness.dart';
import 'screens_test.dart' show file;

final screens = <String, Widget Function()>{
  'today': () => const TodayScreen(),
  'children': () => const ChildrenSearchScreen(),
  'child file': () => const ChildFileScreen(childId: 'kid'),
  'clinic': () => const ClinicSettingsScreen(),
  'vaccines': () => const VaccinesAdminScreen(),
  'content': () => const ContentScreen(),
  'follow-up': () => const FollowUpEditorScreen(),
  'reports': () => const ReportsScreen(),
  'settings': () => const SettingsScreen(),
  'staff': () => const StaffScreen(),
  'audit': () => const AuditScreen(),
  'sign-in': () => const SignInScreen(),
  'password': () => const PasswordScreen(),
};

void main() {
  for (final size in const [Size(1440, 900), Size(820, 1180)]) {
    for (final brightness in Brightness.values) {
      for (final scale in [1.0, 1.5]) {
        for (final MapEntry(key: name, value: build) in screens.entries) {
          testWidgets('$name · ${size.width.toInt()} · ${brightness.name} · text ×$scale', (tester) async {
            final api = FakeDashboardApi()..responses['openChildFile'] = file;
            await pumpDashboard(
              tester,
              build(),
              size: size,
              brightness: brightness,
              textScale: scale,
              overrides: [
                ...dashboardOverrides(
                  api: api,
                  session: doctorSession,
                  bookings: [queueBooking('a', 18), queueBooking('b', 19, status: 'arrived', arrivedAt: now)],
                ),
                authStateProvider.overrideWith((ref) => Stream.value(null)),
                clinicDocProvider.overrideWith((ref, id) => Stream.value({'name': '[عيادة المقطم · بيانات مؤقتة]', 'address': '[عنوان]', 'packagePrice': 1500, 'packageMonths': 12})),
                settingsDocProvider.overrideWith((ref, id) => Stream.value({'currentVersion': 1, 'privacyPolicyText': '[نص]'})),
                contentItemsProvider.overrideWith((ref) => Stream.value([{'id': 'x', 'title': '[نصيحة عن الحرارة]', 'category': 'fever', 'status': 'draft'}])),
                staffListProvider.overrideWith((ref) => Stream.value([{'uid': 'sec1', 'name': '[سكرتيرة المقطم]', 'email': 'sec1@demo.delnono', 'role': 'secretary', 'clinicId': 'clinic-1', 'active': true}])),
                auditProvider.overrideWith((ref) => Stream.value([{'id': 'a', 'action': 'child.opened', 'actorUid': 'sec1'}])),
                followUpDraftsProvider.overrideWith((ref) => Stream.value(null)),
                followUpBandsProvider.overrideWith((ref) => Stream.value(const [FollowUpBand(fromMonths: 0, toMonths: 2, title: '[أول شهرين]', items: ['[بند]'])])),
                followUpSettingsProvider.overrideWith((ref) => Stream.value(const FollowUpSettings(dangerSigns: ['[خطر]']))),
                vaccineScheduleProvider.overrideWith((ref) => Stream.value(const [
                      ScheduleEntry(id: 's1', vaccineId: 'v1', dose: 1, dueAge: AgeSpan(months: 2), ageLabel: 'الشهر الثاني', order: 0),
                    ])),
                vaccineSettingsProvider.overrideWith((ref) => Stream.value(const VaccineSettings(source: '[مصدر]', reviewedOn: '2026-10-01'))),
              ],
            );
            expect(tester.takeException(), isNull);
            expect(wrongWayIcons(tester), isEmpty, reason: 'chevrons and back icons must follow RTL');
            final lists = find.byType(Scrollable);
            if (lists.evaluate().isNotEmpty) {
              await tester.drag(lists.first, const Offset(0, -2000), warnIfMissed: false);
              await tester.pump(const Duration(milliseconds: 300));
              expect(tester.takeException(), isNull);
            }
          });
        }
      }
    }
  }
}
