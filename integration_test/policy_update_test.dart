// A new privacy policy version needs consent before any child data (quickstart.md scenario 15;
// FR-017).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delnono/core/firebase/firebase_init.dart';
import 'package:delnono/core/widgets/birth_date_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

final pickerOverride =
    birthDatePickerProvider.overrideWithValue((context, {initial}) async => DateTime(2022, 9, 9));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    expect(useEmulator, isTrue, reason: 'Run with --dart-define=USE_EMULATOR=true');
    await initFirebase();
    await deleteAllEmulatorUsers();
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('policy version 2: consent again before child data, then continue', (tester) async {
    await startApp(tester, overrides: [pickerOverride]);
    await signInFromBooking(tester, '+201000000089');
    await registerGuardian(tester, 'هالة فريد');
    await settle(tester, () => shows(find.byKey(const Key('child-name'))));
    await tester.enterText(find.byKey(const Key('child-name')), 'عمر');
    await tapInList(tester, find.byKey(const Key('child-birth-date')));
    await tapInList(tester, find.text('ولد'));
    await tapInList(tester, find.text('حفظ'));
    await settle(tester, () => location(tester) == '/booking');

    await adminSetFields('settings/policy', {'currentVersion': {'integerValue': '2'}});
    await startApp(tester, overrides: [pickerOverride]);

    await tester.tap(find.text('طفلي'));
    await settle(tester, () => shows(find.text('سياسة الخصوصية اتحدثت')));
    expect(location(tester), '/register/consent?from=%2Fchildren');

    await tapInList(tester, find.byKey(const Key('consent-policy')));
    await tapInList(tester, find.byKey(const Key('consent-child-data')));
    await tapInList(tester, find.text('موافقة ومتابعة'));
    await settle(tester, () => location(tester) == '/children' && shows(find.text('عمر')));
    expect(find.text('عمر'), findsOneWidget);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final guardian = await FirebaseFirestore.instance.doc('guardians/$uid').get();
    expect(guardian.get('consentVersion'), 2);
    final consents = await FirebaseFirestore.instance.collection('guardians/$uid/consents').get();
    expect(consents.size, 2, reason: 'one consent per version');
  });
}
