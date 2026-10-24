import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/data/auth_repository.dart';
import 'data/staff_session.dart';
import 'screens/audit_screen.dart';
import 'screens/child_file_screen.dart';
import 'screens/children_search_screen.dart';
import 'screens/clinic_settings_screen.dart';
import 'screens/content_screen.dart';
import 'screens/follow_up_editor_screen.dart';
import 'screens/password_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/staff_screen.dart';
import 'screens/today_screen.dart';
import 'screens/vaccines_admin_screen.dart';
import 'shell.dart';

abstract final class DashRoutes {
  static const signIn = '/sign-in';
  static const password = '/password';
  static const today = '/today';
  static const children = '/children';
  static const clinic = '/clinic';
  static const vaccines = '/vaccines';
  static const content = '/content';
  static const followUp = '/follow-up';
  static const reports = '/reports';
  static const settings = '/settings';
  static const staff = '/staff';
  static const audit = '/audit';

  /// Screens for the doctor only (contracts/routes.md).
  static const doctorOnly = {vaccines, settings, staff, audit};
}

/// Where a request should go instead, or null (contracts/routes.md). [loading] waits; signed-out
/// or non-staff accounts go to sign-in; a temporary password must be changed first.
String? dashboardRedirect(String path, {required bool loading, required bool signedIn, StaffSession? staff}) {
  if (loading) return null;
  if (!signedIn || staff == null) return path == DashRoutes.signIn ? null : DashRoutes.signIn;
  if (staff.mustChangePassword) return path == DashRoutes.password ? null : DashRoutes.password;
  if (path == DashRoutes.signIn || path == DashRoutes.password || path == '/') return DashRoutes.today;
  if (!staff.isDoctor && DashRoutes.doctorOnly.contains(path)) return DashRoutes.today;
  return null;
}

final dashboardRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.listen(staffSessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  GoRoute page(String path, Widget Function(GoRouterState s) build) => GoRoute(path: path, builder: (_, s) => build(s));

  return GoRouter(
    initialLocation: DashRoutes.today,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final staff = ref.read(staffSessionProvider);
      final signedIn = auth.value != null;
      return dashboardRedirect(
        state.uri.path,
        loading: !auth.hasValue || (signedIn && !staff.hasValue),
        signedIn: signedIn,
        staff: staff.value,
      );
    },
    routes: [
      page(DashRoutes.signIn, (_) => const SignInScreen()),
      page(DashRoutes.password, (_) => const PasswordScreen()),
      ShellRoute(
        builder: (context, state, child) => DashboardShell(location: state.uri.path, child: child),
        routes: [
          page(DashRoutes.today, (_) => const TodayScreen()),
          page(DashRoutes.children, (_) => const ChildrenSearchScreen()),
          page('${DashRoutes.children}/:id', (s) => ChildFileScreen(childId: s.pathParameters['id']!)),
          page(DashRoutes.clinic, (_) => const ClinicSettingsScreen()),
          page(DashRoutes.vaccines, (_) => const VaccinesAdminScreen()),
          page(DashRoutes.content, (_) => const ContentScreen()),
          page(DashRoutes.followUp, (_) => const FollowUpEditorScreen()),
          page(DashRoutes.reports, (_) => const ReportsScreen()),
          page(DashRoutes.settings, (_) => const SettingsScreen()),
          page(DashRoutes.staff, (_) => const StaffScreen()),
          page(DashRoutes.audit, (_) => const AuditScreen()),
        ],
      ),
    ],
  );
});
