// Link-first registration on the simulator (owner, 27 Oct 2026): a number with clinic-registered
// children is asked to link them right after consent, before any add-child step. Linked children
// count as the family's children; skipping or failing leads to add-child; linking stays available
// later from «حسابي» › أطفالي; a child added first and then linked again is flagged as a duplicate.

import 'package:delnono/core/firebase/firebase_init.dart';
import 'package:delnono/core/widgets/birth_date_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

DateTime picked = DateTime(2023, 5, 10);
final pickerOverride = birthDatePickerProvider.overrideWithValue((context, {initial}) async => picked);

const noChildGate = 'ضيفي طفل الأول عشان تحجزي.';
const notMine = 'دول مش أطفالي · ضيفي طفل جديد';

Future<void> confirmLink(WidgetTester tester, DateTime date) async {
  picked = date;
  await tapInList(tester, find.byKey(const Key('link-birth-date')));
  await tapInList(tester, find.text('تأكيد'));
}

Future<void> addFirstChild(WidgetTester tester, String name, DateTime birth) async {
  await settle(tester, () => shows(find.byKey(const Key('child-name'))));
  picked = birth;
  await tester.enterText(find.byKey(const Key('child-name')), name);
  await tapInList(tester, find.byKey(const Key('child-birth-date')));
  await tapInList(tester, find.text('ولد'));
  await tapInList(tester, find.text('حفظ'));
}

Future<void> openMe(WidgetTester tester) async {
  await tester.tap(find.text('حسابي'));
  await settle(tester, () => shows(find.byKey(const Key('me-add-child'))));
}

Future<void> expectChildren(WidgetTester tester, List<String> names) async {
  await tester.tap(find.text('طفلي'));
  await settle(tester, () => names.every((n) => shows(find.textContaining(n))));
  for (final n in names) {
    expect(find.textContaining(n), findsWidgets, reason: n);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    expect(useEmulator, isTrue, reason: 'Run with --dart-define=USE_EMULATOR=true');
    await initFirebase();
    await deleteAllEmulatorUsers();
    await seedClinicChild('+201000000083', 'it-yassin', 'ياسين', '2024-01-01');
    await seedClinicChild('+201000000084', 'it-adam', 'آدم', '2024-06-06');
  });

  setUp(() => FirebaseAuth.instance.signOut());

  testWidgets('link-first: details → consent → link (before add-child) → Booking, no add-child gate', (tester) async {
    await startApp(tester, overrides: [pickerOverride]);
    await signInFromBooking(tester, '+201000000003');
    await registerGuardian(tester, 'منى إبراهيم');
    await settle(tester, () => shows(find.byKey(const Key('link-birth-date'))) || shows(find.byKey(const Key('child-name'))));
    expect(find.byKey(const Key('link-birth-date')), findsOneWidget, reason: 'linking comes before add-child');
    expect(find.byKey(const Key('child-name')), findsNothing);

    await confirmLink(tester, DateTime(2023, 5, 10));
    await settle(tester, () => location(tester) == '/booking');
    expect(location(tester), '/booking', reason: 'linked children skip the add-child step');
    await settle(tester, () => shows(find.byKey(const Key('clinic-clinic-1'))));
    expect(find.text(noChildGate), findsNothing);
    await expectChildren(tester, ['عمر', 'نور']);
    await openMe(tester);
    expect(find.byKey(const Key('me-link-clinic')), findsNothing, reason: 'nothing left to link');
  });

  testWidgets('skip-link: add a child instead; link later from «حسابي» › أطفالي', (tester) async {
    await startApp(tester, overrides: [pickerOverride]);
    await signInFromBooking(tester, '+201000000083');
    await registerGuardian(tester, 'هدى سالم');
    await settle(tester, () => shows(find.byKey(const Key('link-birth-date'))));
    await tapInList(tester, find.text(notMine));
    await addFirstChild(tester, 'سارة', DateTime(2025, 3, 3));
    await settle(tester, () => location(tester) == '/booking');
    expect(find.text(noChildGate), findsNothing);

    await openMe(tester);
    await tapInList(tester, find.byKey(const Key('me-link-clinic')));
    await settle(tester, () => shows(find.byKey(const Key('link-birth-date'))));
    await confirmLink(tester, DateTime(2024, 1, 1));
    await settle(tester, () => location(tester) == '/me');
    expect(location(tester), '/me', reason: 'back to «حسابي» after linking');
    expect(find.byKey(const Key('me-link-clinic')), findsNothing);
    await expectChildren(tester, ['سارة', 'ياسين']);
  });

  testWidgets('add-then-link: the same child added and linked is flagged as a duplicate', (tester) async {
    await startApp(tester, overrides: [pickerOverride]);
    await signInFromBooking(tester, '+201000000084');
    await registerGuardian(tester, 'ريم فؤاد');
    await settle(tester, () => shows(find.byKey(const Key('link-birth-date'))));
    await tapInList(tester, find.text(notMine));
    await addFirstChild(tester, 'آدم', DateTime(2024, 6, 6));
    await settle(tester, () => location(tester) == '/booking');

    await openMe(tester);
    await tapInList(tester, find.byKey(const Key('me-link-clinic')));
    await settle(tester, () => shows(find.byKey(const Key('link-birth-date'))));
    await confirmLink(tester, DateTime(2024, 6, 6));
    await settle(tester, () => shows(find.textContaining('مرتين')));
    expect(find.textContaining('مرتين'), findsOneWidget, reason: 'duplicate-child warning (same name and birth date)');
  });
}
