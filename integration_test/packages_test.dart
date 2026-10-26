// The annual package in the app on the simulator (008 quickstart): signed out, Home → the package
// page with each clinic's price from the seed; a family with a package sees it per child in
// «حسابي» and first on the package page.

import 'package:delnono/core/firebase/firebase_init.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'booking_test.dart' show pickerOverride;
import 'helpers.dart';

String isoDate(DateTime d) => d.toIso8601String().substring(0, 10);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    expect(useEmulator, isTrue, reason: 'Run with --dart-define=USE_EMULATOR=true');
    await initFirebase();
    await deleteAllEmulatorUsers();
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('package page from Home; «الباقة» per child with its end date', (tester) async {
    await startApp(tester, overrides: [pickerOverride]);
    await leaveWelcome(tester);
    await settle(tester, () => shows(find.byKey(const Key('home-package'))));
    await tapInList(tester, find.byKey(const Key('home-package')));
    await settle(tester, () => shows(find.text('سارية في العيادتين.')));
    expect(find.textContaining('جنيه ·'), findsWidgets, reason: "the clinics' package prices from the seed");
    await tester.pageBack();
    await settle(tester, () => shows(find.byKey(const Key('home-package'))));

    await registerWithChild(tester, '+201000000089', 'منى حسن', 'آدم');
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final today = DateTime.now();
    await adminSetFields('packages/night-$uid', {
      'guardianUid': {'stringValue': uid},
      'active': {'booleanValue': true},
      'startsOn': {'stringValue': isoDate(today.subtract(const Duration(days: 30)))},
      'endsOn': {'stringValue': isoDate(today.add(const Duration(days: 300)))},
      'soldAtClinicId': {'stringValue': 'clinic-1'},
    });

    await tester.tap(find.text('حسابي').last);
    await settle(tester, () => shows(find.textContaining('في العيادتين')));
    expect(find.text('باقة آدم'), findsOneWidget);
    expect(find.text('سارية'), findsOneWidget);
    await tapInList(tester, find.text('باقة آدم'));
    await settle(tester, () => shows(find.byKey(const Key('pkg-status'))));
    expect(find.descendant(of: find.byKey(const Key('pkg-status')), matching: find.text('سارية')), findsOneWidget);
  });
}
