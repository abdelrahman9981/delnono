// Deleting the account end to end (quickstart.md scenario 14; FR-027 to FR-030), then signing in
// again with the same number: the child the guardian added is unlinked and can be linked again.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delnono/core/firebase/firebase_init.dart';
import 'package:delnono/core/widgets/birth_date_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

const phone = '+201000000091';
final pickerOverride =
    birthDatePickerProvider.overrideWithValue((context, {initial}) async => DateTime(2021, 4, 4));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    expect(useEmulator, isTrue, reason: 'Run with --dart-define=USE_EMULATOR=true');
    await initFirebase();
    await deleteAllEmulatorUsers();
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('delete, then the same number starts over and links the child again', (tester) async {
    await startApp(tester, overrides: [pickerOverride]);
    await signInFromBooking(tester, phone);
    await registerGuardian(tester, 'سلوى عادل');
    await settle(tester, () => shows(find.byKey(const Key('child-name'))));
    await tester.enterText(find.byKey(const Key('child-name')), 'زين');
    await tapInList(tester, find.byKey(const Key('child-birth-date')));
    await tapInList(tester, find.text('ولد'));
    await tapInList(tester, find.text('حفظ'));
    await settle(tester, () => location(tester) == '/booking');
    final oldUid = FirebaseAuth.instance.currentUser!.uid;

    await tester.tap(find.text('الرئيسية').last);
    await settle(tester, () => shows(find.byKey(const Key('account-button'))));
    await tester.tap(find.byKey(const Key('account-button')));
    await settle(tester, () => shows(find.byKey(const Key('account-delete'))));
    await tapInList(tester, find.byKey(const Key('account-delete')));
    await settle(tester, () => shows(find.byKey(const Key('delete-confirm'))));
    await tapInList(tester, find.byKey(const Key('delete-confirm')));
    await tapInList(tester, find.byKey(const Key('delete-button')));
    await settle(tester, () => location(tester) == '/welcome');
    expect(location(tester), '/welcome');
    expect(FirebaseAuth.instance.currentUser, isNull);

    // Same number again: a new account; the earlier child is offered for linking (FR-021).
    await signInFromBooking(tester, phone);
    expect(FirebaseAuth.instance.currentUser!.uid, isNot(oldUid));
    await registerGuardian(tester, 'سلوى عادل');
    await settle(tester, () => shows(find.byKey(const Key('link-birth-date'))));
    await tapInList(tester, find.byKey(const Key('link-birth-date')));
    await tapInList(tester, find.text('تأكيد'));
    await settle(tester, () => location(tester) == '/booking');

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final children =
        await FirebaseFirestore.instance.collection('children').where('guardianUid', isEqualTo: uid).get();
    expect(children.docs.single.get('name'), 'زين');
  });
}
