// Changing the number end to end (quickstart.md scenarios 12 and 13; FR-025, FR-025a, FR-026),
// plus signing out and back in.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delnono/core/firebase/firebase_init.dart';
import 'package:delnono/core/widgets/birth_date_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

const first = '+201000000094';
const taken = '+201000000093';
const fresh = '+201000000092';

final pickerOverride =
    birthDatePickerProvider.overrideWithValue((context, {initial}) async => DateTime(2022, 2, 2));

Future<void> openAccount(WidgetTester tester) async {
  await tester.tap(find.text('الرئيسية').last);
  await settle(tester, () => shows(find.byKey(const Key('account-button'))));
  await tester.tap(find.byKey(const Key('account-button')));
  await settle(tester, () => shows(find.byKey(const Key('account-change-phone'))));
}

Future<void> changeTo(WidgetTester tester, String phone) async {
  await tapInList(tester, find.byKey(const Key('account-change-phone')));
  await settle(tester, () => shows(find.byKey(const Key('new-phone-field'))));
  await tester.enterText(find.byKey(const Key('new-phone-field')), phone.substring(3));
  await tapInList(tester, find.text('ابعتي الكود'));
  await settle(tester, () => shows(find.byKey(const Key('new-phone-otp-field'))));
  await tester.enterText(find.byKey(const Key('new-phone-otp-field')), await latestCodeFor(phone));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    expect(useEmulator, isTrue, reason: 'Run with --dart-define=USE_EMULATOR=true');
    await initFirebase();
    await deleteAllEmulatorUsers();
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('a taken number is refused; a free one moves the account; sign out and back in', (tester) async {
    // Another account already owns `taken`.
    await startApp(tester);
    await signInFromBooking(tester, taken);
    await FirebaseAuth.instance.signOut();

    await startApp(tester, overrides: [pickerOverride]);
    await signInFromBooking(tester, first);
    await registerGuardian(tester, 'دينا كمال');
    await settle(tester, () => shows(find.byKey(const Key('child-name'))));
    await tester.enterText(find.byKey(const Key('child-name')), 'نور');
    await tapInList(tester, find.byKey(const Key('child-birth-date')));
    await tapInList(tester, find.text('بنت'));
    await tapInList(tester, find.text('حفظ'));
    await settle(tester, () => location(tester) == '/booking');
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await openAccount(tester);

    // FR-025a: the number belongs to another account.
    await changeTo(tester, taken);
    await settle(tester, () => shows(find.text('الرقم ده عليه حساب تاني. كلمي العيادة عشان نساعدك.')));
    expect(find.text('الرقم ده عليه حساب تاني. كلمي العيادة عشان نساعدك.'), findsOneWidget);
    expect(FirebaseAuth.instance.currentUser!.phoneNumber, first);

    // FR-025, FR-026: a free number.
    await tester.tap(find.byType(BackButton));
    await settle(tester, () => shows(find.byKey(const Key('account-change-phone'))));
    await changeTo(tester, fresh);
    await settle(tester, () => location(tester) == '/account');
    expect(FirebaseAuth.instance.currentUser!.phoneNumber, fresh);
    final guardian = await FirebaseFirestore.instance.doc('guardians/$uid').get();
    expect(guardian.get('phone'), fresh);

    // Sign out clears the session and the offline cache; signing in with the new number works.
    await tapInList(tester, find.byKey(const Key('account-sign-out')));
    await settle(tester, () => location(tester) == '/welcome');
    expect(FirebaseAuth.instance.currentUser, isNull);

    await signInFromBooking(tester, fresh);
    expect(FirebaseAuth.instance.currentUser!.uid, uid, reason: 'same account, new number');
  });
}
