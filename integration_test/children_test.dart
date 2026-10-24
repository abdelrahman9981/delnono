// Managing children end to end (quickstart.md scenario 11; FR-023, FR-024): edit name and allergies
// through Security Rules, and the onChildUpdated trigger records history.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delnono/core/firebase/firebase_init.dart';
import 'package:delnono/core/widgets/birth_date_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

final pickerOverride =
    birthDatePickerProvider.overrideWithValue((context, {initial}) async => DateTime(2023, 6, 1));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    expect(useEmulator, isTrue, reason: 'Run with --dart-define=USE_EMULATOR=true');
    await initFirebase();
    await deleteAllEmulatorUsers();
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('add a child, then edit allergies; history is recorded', (tester) async {
    await startApp(tester, overrides: [pickerOverride]);
    await signInFromBooking(tester, '+201000000095');
    await registerGuardian(tester, 'رنا حسن');
    await settle(tester, () => shows(find.byKey(const Key('child-name'))));
    await tester.enterText(find.byKey(const Key('child-name')), 'آدم');
    await tapInList(tester, find.byKey(const Key('child-birth-date')));
    await tapInList(tester, find.text('ولد'));
    await tapInList(tester, find.text('حفظ'));
    await settle(tester, () => location(tester) == '/booking');

    await tester.tap(find.text('طفلي'));
    await settle(tester, () => shows(find.text('آدم')));
    await tapInList(tester, find.byKey(const Key('entry-details')));
    await settle(tester, () => shows(find.byKey(const Key('profile-allergies'))));
    expect(find.byType(TextField), findsNWidgets(2), reason: 'birth date and sex are read-only');

    await tester.enterText(find.byKey(const Key('profile-allergies')), 'حساسية لبن');
    await tapInList(tester, find.text('حفظ'));
    await settle(tester, () => shows(find.text('اتحفظت التعديلات.')));
    expect(find.text('اتحفظت التعديلات.'), findsOneWidget);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final child = (await FirebaseFirestore.instance.collection('children').where('guardianUid', isEqualTo: uid).get())
        .docs
        .single;
    expect(child.get('allergies'), 'حساسية لبن');

    QuerySnapshot<Map<String, dynamic>>? history;
    for (var i = 0; i < 40 && (history?.size ?? 0) == 0; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      history = await child.reference.collection('history').get();
    }
    expect(history!.size, 1);
    expect(history.docs.single.get('changedBy'), uid);
  });
}
