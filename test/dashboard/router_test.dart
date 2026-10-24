import 'package:delnono/dashboard/data/staff_session.dart';
import 'package:delnono/dashboard/router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  group('dashboardRedirect (contracts/routes.md)', () {
    test('signed out or not staff: sign-in', () {
      expect(dashboardRedirect('/today', loading: false, signedIn: false), DashRoutes.signIn);
      expect(dashboardRedirect('/today', loading: false, signedIn: true), DashRoutes.signIn, reason: 'a guardian or disabled account');
      expect(dashboardRedirect(DashRoutes.signIn, loading: false, signedIn: false), isNull);
    });

    test('waits while loading', () => expect(dashboardRedirect('/today', loading: true, signedIn: false), isNull));

    test('a temporary password must be changed first (FR-001)', () {
      const s = StaffSession(uid: 'x', name: 'x', email: 'x', role: StaffRole.secretary, clinicId: 'clinic-1', mustChangePassword: true);
      expect(dashboardRedirect('/today', loading: false, signedIn: true, staff: s), DashRoutes.password);
      expect(dashboardRedirect(DashRoutes.password, loading: false, signedIn: true, staff: s), isNull);
    });

    test('doctor-only screens send a secretary to Today', () {
      for (final path in DashRoutes.doctorOnly) {
        expect(dashboardRedirect(path, loading: false, signedIn: true, staff: secretarySession), DashRoutes.today, reason: path);
        expect(dashboardRedirect(path, loading: false, signedIn: true, staff: doctorSession), isNull, reason: path);
      }
    });

    test('signed in on sign-in goes to Today', () {
      expect(dashboardRedirect(DashRoutes.signIn, loading: false, signedIn: true, staff: secretarySession), DashRoutes.today);
    });
  });
}
