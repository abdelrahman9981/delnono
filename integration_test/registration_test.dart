// First-run registration end to end against the Firebase emulators (quickstart.md scenarios 6, 7).
//
//   functions/node_modules/.bin/firebase emulators:start --only auth,firestore,functions \
//     --import=./emulator-seed
//   flutter test integration_test/registration_test.dart --dart-define=USE_EMULATOR=true -d <simulator>

import 'package:cloud_firestore/cloud_firestore.dart';
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
  });

  setUp(() => FirebaseAuth.instance.signOut());

  testWidgets('full first run: details → consent → first child → back to booking (FR-003, FR-012)',
      (tester) async {
    const phone = '+201000000098';
    await startApp(tester);
    await signInFromBooking(tester, phone);
    expect(location(tester), '/register/guardian?from=%2Fbooking');

    await tester.enterText(find.byKey(const Key('guardian-name')), 'سارة محمود');
    await tapInList(tester, find.text('أم'));
    await tapInList(tester, find.text('التالي'));
    await settle(tester, () => location(tester).startsWith('/register/consent'));
    expect(location(tester), '/register/consent?from=%2Fbooking');

    await tapInList(tester, find.byKey(const Key('consent-policy')));
    await tapInList(tester, find.byKey(const Key('consent-child-data')));
    await tapInList(tester, find.text('موافقة ومتابعة'));
    await settle(tester, () => location(tester).startsWith('/register/child'));
    expect(location(tester), '/register/child?from=%2Fbooking');

    await tester.enterText(find.byKey(const Key('child-name')), 'يوسف');
    await tapInList(tester, find.byKey(const Key('child-birth-date')));
    await settle(tester, () => shows(find.byType(DatePickerDialog)));
    final ok = MaterialLocalizations.of(tester.element(find.byType(DatePickerDialog))).okButtonLabel;
    await tester.tap(find.text(ok));
    await tester.pump(const Duration(milliseconds: 500));
    await tapInList(tester, find.text('ولد'));
    await tapInList(tester, find.text('حفظ'));
    await settle(tester, () => location(tester) == '/booking');
    expect(location(tester), '/booking');

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final guardian = await FirebaseFirestore.instance.doc('guardians/$uid').get();
    expect(guardian.get('fullName'), 'سارة محمود');
    expect(guardian.get('consentVersion'), 1);
    final consents = await FirebaseFirestore.instance.collection('guardians/$uid/consents').get();
    expect(consents.size, 1);
    final children =
        await FirebaseFirestore.instance.collection('children').where('guardianUid', isEqualTo: uid).get();
    expect(children.docs.single.get('name'), 'يوسف');
  });

  testWidgets('stopping at consent stores nothing; after a restart it starts at guardian details (FR-015)',
      (tester) async {
    const phone = '+201000000097';
    await startApp(tester);
    await signInFromBooking(tester, phone);

    await tester.enterText(find.byKey(const Key('guardian-name')), 'منى علي');
    await tapInList(tester, find.text('أم'));
    await tapInList(tester, find.text('التالي'));
    await settle(tester, () => location(tester).startsWith('/register/consent'));

    // Leave without consenting: the app restarts and the typed details are gone.
    await startApp(tester);
    await tester.tap(find.text('حجز'));
    await settle(tester, () => location(tester).startsWith('/register'));
    expect(location(tester), '/register/guardian?from=%2Fbooking');

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final guardian = await FirebaseFirestore.instance.doc('guardians/$uid').get();
    expect(guardian.exists, isFalse, reason: 'no guardian data before consent');
  });
}
