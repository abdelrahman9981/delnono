// End-to-end sign-in against the Firebase emulators (quickstart.md scenarios 2 and 7).
//
//   functions/node_modules/.bin/firebase emulators:start --only auth,firestore,functions \
//     --import=./emulator-seed
//   flutter test integration_test/sign_in_test.dart --dart-define=USE_EMULATOR=true -d <simulator>

import 'package:delnono/app/app.dart';
import 'package:delnono/app/splash_intro.dart';
import 'package:delnono/core/firebase/firebase_init.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

const testPhone = '+201000000099';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    expect(useEmulator, isTrue, reason: 'Run with --dart-define=USE_EMULATOR=true');
    await initFirebase();
    await deleteAllEmulatorUsers();
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('sign in with a code, then stay signed in after a restart (FR-003, FR-005, FR-010)',
      (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [splashEnabledProvider.overrideWithValue(false)], child: const App()));
    await tester.pumpAndSettle();
    await leaveWelcome(tester);

    // A protected tab sends a signed-out visitor to sign-in, remembering where they were going.
    await tester.tap(find.text('حجز'));
    await settle(tester, () => find.byKey(const Key('phone-field')).evaluate().isNotEmpty);
    expect(location(tester), '/sign-in?from=%2Fbooking');

    await tester.enterText(find.byKey(const Key('phone-field')), '010 0000 0099');
    await tester.tap(find.text('ابعتيلي الكود'));
    await settle(tester, () => find.byKey(const Key('otp-field')).evaluate().isNotEmpty);
    expect(location(tester), '/sign-in/code?from=%2Fbooking');

    await tester.enterText(find.byKey(const Key('otp-field')), await latestCodeFor(testPhone));
    await settle(tester, () => location(tester).startsWith('/register'));

    expect(FirebaseAuth.instance.currentUser?.phoneNumber, testPhone);
    // No guardian doc yet, so the guard continues to registration with `from` kept.
    expect(location(tester), '/register/guardian?from=%2Fbooking');

    // Restart the widget tree with a fresh provider container: the session persists (FR-010).
    await startApp(tester);
    expect(FirebaseAuth.instance.currentUser?.phoneNumber, testPhone);

    await tester.tap(find.text('حجز'));
    await settle(tester, () => location(tester).startsWith('/register'));
    expect(location(tester), '/register/guardian?from=%2Fbooking', reason: 'not sent back to sign-in');
  });

  testWidgets('a kept sign-in whose account no longer exists is signed out at start', (tester) async {
    expect(FirebaseAuth.instance.currentUser, isNotNull, reason: 'signed in by the previous test');
    // As after an emulator restart, or the account deleted on another phone.
    await deleteAllEmulatorUsers();

    await startApp(tester);
    await settle(tester, () => FirebaseAuth.instance.currentUser == null);
    expect(FirebaseAuth.instance.currentUser, isNull);

    await leaveWelcome(tester);
    await tester.tap(find.text('حجز'));
    await settle(tester, () => location(tester).startsWith('/sign-in'));
    expect(location(tester), '/sign-in?from=%2Fbooking');
  });
}
