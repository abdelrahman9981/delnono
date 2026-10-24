// Linking clinic-registered children end to end (quickstart.md scenarios 8 and 18; FR-021).
// Uses the seeded clinic number +201000000001 with Youssef (2024-03-15), Mariam (2022-07-02) and
// Salma (2026-01-20).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delnono/core/firebase/firebase_init.dart';
import 'package:delnono/core/widgets/birth_date_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

DateTime picked = DateTime(2024, 3, 15);
final pickerOverride = birthDatePickerProvider.overrideWithValue((context, {initial}) async => picked);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    expect(useEmulator, isTrue, reason: 'Run with --dart-define=USE_EMULATOR=true');
    await initFirebase();
    await deleteAllEmulatorUsers();
  });

  setUp(() => FirebaseAuth.instance.signOut());

  testWidgets('a wrong date counts down; the right date links both clinic children', (tester) async {
    await startApp(tester, overrides: [pickerOverride]);
    await signInFromBooking(tester, '+201000000001');
    await registerGuardian(tester, 'سارة محمود');
    await settle(tester, () => shows(find.byKey(const Key('link-birth-date'))));
    expect(location(tester), '/register/link?from=%2Fbooking');
    expect(find.textContaining('يوسف'), findsNothing, reason: 'no child data before the check');

    picked = DateTime(2019, 5, 5);
    await tapInList(tester, find.byKey(const Key('link-birth-date')));
    await tapInList(tester, find.text('تأكيد'));
    await settle(tester, () => shows(find.textContaining('فاضلك محاولتين')));
    expect(find.textContaining('فاضلك محاولتين'), findsOneWidget);

    picked = DateTime(2024, 3, 15);
    await tapInList(tester, find.byKey(const Key('link-birth-date')));
    await tapInList(tester, find.text('تأكيد'));
    await settle(tester, () => location(tester) == '/booking');
    expect(location(tester), '/booking', reason: 'children exist, so no first-child step');

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final children =
        await FirebaseFirestore.instance.collection('children').where('guardianUid', isEqualTo: uid).get();
    expect(children.docs.map((d) => d.get('name')).toSet(), {'يوسف', 'مريم', 'سلمى'});
  });
}
