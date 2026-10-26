// The owner's sign-in path on the simulator, with the development code (BRD D-51): Welcome →
// "سجّلي برقم موبايلك" → number → 123456. The seeded family (+201000000001, uid seed-guardian-1)
// goes straight to Home; a new number goes to guardian details. Neither may hang.

import 'package:delnono/core/firebase/firebase_init.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

Future<void> signInWithDevCode(WidgetTester tester, String phone) async {
  await startApp(tester);
  await settle(tester, () => shows(find.text('سجّلي برقم موبايلك')));
  await tester.tap(find.text('سجّلي برقم موبايلك'));
  await settle(tester, () => shows(find.byKey(const Key('phone-field'))));
  await tester.enterText(find.byKey(const Key('phone-field')), phone.substring(3));
  await tester.tap(find.text('ابعتيلي الكود'));
  await settle(tester, () => shows(find.byKey(const Key('otp-field'))));
  await tester.enterText(find.byKey(const Key('otp-field')), '123456');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    expect(useEmulator, isTrue, reason: 'Run with --dart-define=USE_EMULATOR=true');
    await initFirebase();
    await deleteAllEmulatorUsers();
  });

  setUp(() => FirebaseAuth.instance.signOut());

  testWidgets('the seeded family signs in with 123456 to Home, as uid seed-guardian-1', (tester) async {
    await signInWithDevCode(tester, seededFamilyPhone);
    await settle(tester, () => location(tester) == '/');
    expect(location(tester), '/');
    expect(FirebaseAuth.instance.currentUser?.uid, seededFamilyUid);
    await tester.tap(find.text('طفلي'));
    await settle(tester, () => shows(find.textContaining('يوسف')));
    expect(find.textContaining('يوسف'), findsWidgets, reason: 'the seeded children are linked');
  });

  testWidgets('a new number signs in with 123456 to guardian details', (tester) async {
    await signInWithDevCode(tester, '+201000000099');
    await settle(tester, () => location(tester) == '/register/guardian');
    expect(location(tester), '/register/guardian');
  });
}
