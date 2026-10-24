// Browsing without an account, end to end against the Firebase emulators
// (quickstart.md scenarios 1 and 2; FR-001 to FR-003).
//
//   functions/node_modules/.bin/firebase emulators:start --only auth,firestore,functions \
//     --import=./emulator-seed
//   flutter test integration_test/browse_test.dart --dart-define=USE_EMULATOR=true -d <simulator>

import 'package:delnono/core/firebase/firebase_init.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    expect(useEmulator, isTrue, reason: 'Run with --dart-define=USE_EMULATOR=true');
    await initFirebase();
    await deleteAllEmulatorUsers();
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('signed out: Welcome, then Home and Content without an account; Booking needs sign-in '
      'and returns to Booking after registration', (tester) async {
    await startApp(tester);

    // Fresh start shows Welcome (US3).
    expect(location(tester), '/welcome');
    expect(find.text('سجّلي برقم موبايلك'), findsOneWidget);

    // Content and Home open without signing in (FR-001).
    await tester.tap(find.text('اتفرجي على المحتوى الأول'));
    await settle(tester, () => location(tester) == '/content' && shows(find.text('حجز')));
    expect(location(tester), '/content');
    await tester.tap(find.text('الرئيسية').last);
    await settle(tester, () => location(tester) == '/' && shows(find.text('حجز')));
    expect(location(tester), '/');
    expect(FirebaseAuth.instance.currentUser, isNull);
    // Home shows both clinics to anyone (004 FR-013).
    await settle(tester, () => shows(find.byKey(const Key('clinic-card-clinic-1'))));
    expect(find.byKey(const Key('clinic-card-clinic-1')), findsOneWidget);

    // "احجزي هنا" on clinic 2 asks for sign-in, remembering the booking and the clinic (FR-002,
    // FR-003; 004 FR-013).
    await tapInList(tester, find.byKey(const Key('book-at-clinic-2')));
    await settle(tester, () => shows(find.byKey(const Key('phone-field'))));
    expect(location(tester), '/sign-in?from=%2Fbooking%3Fclinic%3Dclinic-2');

    // Sign in and register; the visitor ends up on Booking.
    const phone = '+201000000096';
    await tester.enterText(find.byKey(const Key('phone-field')), phone.substring(3));
    await tester.tap(find.text('ابعتيلي الكود'));
    await settle(tester, () => shows(find.byKey(const Key('otp-field'))));
    await tester.enterText(find.byKey(const Key('otp-field')), await latestCodeFor(phone));
    await settle(tester, () => shows(find.byKey(const Key('guardian-name'))));

    await tester.enterText(find.byKey(const Key('guardian-name')), 'هبة سامي');
    await tapInList(tester, find.text('أم'));
    await tapInList(tester, find.text('التالي'));
    await settle(tester, () => shows(find.byKey(const Key('consent-policy'))));
    await tapInList(tester, find.byKey(const Key('consent-policy')));
    await tapInList(tester, find.byKey(const Key('consent-child-data')));
    await tapInList(tester, find.text('موافقة ومتابعة'));
    await settle(tester, () => shows(find.byKey(const Key('child-name'))));

    await tester.enterText(find.byKey(const Key('child-name')), 'ليلى');
    await tapInList(tester, find.byKey(const Key('child-birth-date')));
    await settle(tester, () => shows(find.byType(DatePickerDialog)));
    await tester.tap(find.text(MaterialLocalizations.of(tester.element(find.byType(DatePickerDialog))).okButtonLabel));
    await tester.pump(const Duration(milliseconds: 500));
    await tapInList(tester, find.text('بنت'));
    await tapInList(tester, find.text('حفظ'));
    await settle(tester, () => location(tester) == '/booking?clinic=clinic-2');
    expect(location(tester), '/booking?clinic=clinic-2');
    await settle(tester, () => shows(find.byKey(const Key('chosen-clinic'))));
    expect(find.descendant(of: find.byKey(const Key('chosen-clinic')), matching: find.textContaining('عيادة مدينة نصر')), findsOneWidget);

    // Restarting signed in skips Welcome and opens home.
    await startApp(tester);
    await settle(tester, () => location(tester) == '/');
    expect(location(tester), '/');
  });
}
