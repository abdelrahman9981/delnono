// The child profile end to end (003 quickstart scenarios 1, 4, 5, 7, 8 and 10): link the seeded clinic
// children, read measurements, vaccines, visits and follow-up, then read them again offline.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delnono/core/firebase/firebase_init.dart';
import 'package:delnono/core/widgets/birth_date_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

final pickerOverride = birthDatePickerProvider.overrideWithValue((context, {initial}) async => DateTime(2024, 3, 15));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    expect(useEmulator, isTrue, reason: 'Run with --dart-define=USE_EMULATOR=true');
    await initFirebase();
    await deleteAllEmulatorUsers();
    await FirebaseAuth.instance.signOut();
  });

  tearDownAll(() => FirebaseFirestore.instance.enableNetwork());

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  }

  Future<void> openMyChild(WidgetTester tester, String childId) async {
    // The location can change a frame before the tabs are drawn.
    await settle(tester, () => shows(find.text('طفلي')));
    await tester.tap(find.text('طفلي'));
    // The list may be scrolled down from an earlier step; the switcher is at its top.
    await settle(tester, () => shows(find.byType(ListView)));
    final list = find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.byKey(const Key('child-switcher')), -300, scrollable: list);
    await settle(tester, () => shows(find.byKey(Key('child-chip-$childId'))));
    // Three chips do not fit across the screen; the switcher scrolls sideways.
    await tester.ensureVisible(find.byKey(Key('child-chip-$childId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('child-chip-$childId')));
    await tester.pumpAndSettle();
  }

  testWidgets('the seeded family\'s child record, online and offline', (tester) async {
    await startApp(tester, overrides: [pickerOverride]);
    // +201000000001 is the registered seeded family: no registration, straight in.
    await signInFromBooking(tester, seededFamilyPhone, registered: true);
    expect(location(tester), '/booking');

    // Measurements and chart (FR-003, FR-004).
    await openMyChild(tester, 'seed-youssef');
    await settle(tester, () => shows(find.text('١٢٫٩')));
    expect(find.text('آخر قياسات يوسف'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('measure-weight')), matching: find.text('١٢٫٩')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('measure-head')), matching: find.text('اتقاس ١٥ مارس ٢٠٢٦')), findsOneWidget);
    await tapInList(tester, find.byKey(const Key('growth-chart')));

    // Vaccines (FR-007, FR-009, FR-011).
    await tapInList(tester, find.byKey(const Key('entry-vaccines')));
    await settle(tester, () => shows(find.byKey(const Key('dose-s01'))));
    expect(find.descendant(of: find.byKey(const Key('dose-s01')), matching: find.text('اتاخدت')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('dose-s01')), matching: find.text('رقم التشغيلة: LOT-1001')), findsOneWidget);
    expect(find.byKey(const Key('schedule-source')), findsOneWidget);
    await back(tester);

    // Visits, newest first, with what was recorded (FR-013); no prescription photos (D-39).
    await tapInList(tester, find.byKey(const Key('entry-visits')));
    await settle(tester, () => shows(find.byKey(const Key('visit-seed-youssef-v8'))));
    expect(find.descendant(of: find.byKey(const Key('visit-seed-youssef-v8')), matching: find.textContaining('الوزن ١٢٫٩ كجم')),
        findsOneWidget);
    expect(find.textContaining('روشت'), findsNothing);
    await back(tester);

    // Follow-up for the 9-month-old; the 4-year-old has danger signs only (FR-016 to FR-018).
    await openMyChild(tester, 'seed-salma');
    await tapInList(tester, find.byKey(const Key('entry-follow-up')));
    await settle(tester, () => shows(find.byKey(const Key('when-to-call'))));
    expect(find.byKey(const Key('follow-up-band')), findsOneWidget);
    expect(find.byKey(const Key('call-clinic-clinic-1')), findsOneWidget);
    expect(find.byKey(const Key('call-ambulance')), findsOneWidget);
    await back(tester);
    await openMyChild(tester, 'seed-mariam');
    await tapInList(tester, find.byKey(const Key('entry-follow-up')));
    await settle(tester, () => shows(find.byKey(const Key('when-to-call'))));
    expect(find.byKey(const Key('follow-up-band')), findsNothing);
    expect(find.byKey(const Key('follow-up-over-age')), findsOneWidget);
    await back(tester);

    // Offline: restart the app tree with the network off; everything loaded is still readable (FR-022).
    await FirebaseFirestore.instance.disableNetwork();
    await startApp(tester, overrides: [pickerOverride]);
    await openMyChild(tester, 'seed-youssef');
    await settle(tester, () => shows(find.text('١٢٫٩')));
    expect(find.text('آخر قياسات يوسف'), findsOneWidget);
    await tapInList(tester, find.byKey(const Key('entry-visits')));
    await settle(tester, () => shows(find.byKey(const Key('visit-seed-youssef-v8'))));
    expect(find.byKey(const Key('visit-seed-youssef-v8')), findsOneWidget);
    await back(tester);
    await tapInList(tester, find.byKey(const Key('entry-vaccines')));
    await settle(tester, () => shows(find.byKey(const Key('dose-s01'))));
    expect(find.byKey(const Key('offline-note')), findsOneWidget);
    await FirebaseFirestore.instance.enableNetwork();
  });
}
