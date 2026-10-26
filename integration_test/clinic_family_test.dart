// Bug 0003 on the simulator (26 Oct 2026): the seeded clinic family +201000000003 registers slowly
// (longer than Riverpod's retry window for a denied query), adds a child before linking, then links
// عمر and نور with the birth date. «طفلي» and Booking must show all three, never a blank screen or
// "add a child first".

import 'package:delnono/core/firebase/firebase_init.dart';
import 'package:delnono/core/widgets/birth_date_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

DateTime picked = DateTime(2025, 2, 2);
final pickerOverride = birthDatePickerProvider.overrideWithValue((context, {initial}) async => picked);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    expect(useEmulator, isTrue, reason: 'Run with --dart-define=USE_EMULATOR=true');
    await initFirebase();
    await deleteAllEmulatorUsers();
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('slow registration, a child added before linking, then the clinic children linked', (tester) async {
    await startApp(tester, overrides: [pickerOverride]);
    await signInFromBooking(tester, '+201000000003');
    expect(location(tester), startsWith('/register/guardian'));

    // A guardian who takes their time on the details screen (over 40 s): the old app's children
    // query, denied before registration, had given up by now and never came back.
    for (var i = 0; i < 225; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    await registerGuardian(tester, 'محمد عبدالرحمن');
    await settle(tester, () => shows(find.byKey(const Key('link-birth-date'))));

    // "These aren't mine": add a child first.
    await tapInList(tester, find.text('دول مش أطفالي · ضيفي طفل جديد'));
    await settle(tester, () => shows(find.byKey(const Key('child-name'))));
    await tester.enterText(find.byKey(const Key('child-name')), 'سليم');
    await tapInList(tester, find.byKey(const Key('child-birth-date')));
    await tapInList(tester, find.text('ولد'));
    await tapInList(tester, find.text('حفظ'));
    await settle(tester, () => location(tester) == '/booking');

    // Booking is not gated, and «طفلي» is not blank.
    expect(find.text('ضيفي طفل الأول عشان تحجزي.'), findsNothing);
    await tester.tap(find.text('طفلي'));
    await settle(tester, () => shows(find.textContaining('سليم')));
    expect(find.textContaining('سليم'), findsWidgets);
    expect(find.byKey(const Key('load-error')), findsNothing);

    // Next start: the clinic's children are still waiting. The app opens on Home (public); entering
    // Booking asks for the link. Link them with عمر's birth date.
    await startApp(tester, overrides: [pickerOverride]);
    await settle(tester, () => shows(find.text('حجز')));
    await tester.tap(find.text('حجز'));
    await settle(tester, () => shows(find.byKey(const Key('link-birth-date'))));
    picked = DateTime(2023, 5, 10);
    await tapInList(tester, find.byKey(const Key('link-birth-date')));
    await tapInList(tester, find.text('تأكيد'));
    await settle(tester, () => !location(tester).startsWith('/register'));

    await tester.tap(find.text('طفلي'));
    await settle(tester, () => shows(find.textContaining('نور')));
    for (final name in ['سليم', 'عمر', 'نور']) {
      expect(find.textContaining(name), findsWidgets, reason: name);
    }
    await tester.tap(find.text('حجز'));
    await settle(tester, () => shows(find.byKey(const Key('clinic-clinic-1'))));
    expect(find.text('ضيفي طفل الأول عشان تحجزي.'), findsNothing);
  });
}
