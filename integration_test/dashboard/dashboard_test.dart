// The clinic dashboard end to end in a browser against the emulators (005 quickstart scenarios 1, 2,
// 5 and 6): a secretary signs in and sees only her clinic, marks a booking arrived and done, records a
// measurement from the child file's form; the doctor signs in and corrects it. Run with
// scripts/dashboard_e2e.sh.

import 'package:delnono/core/firebase/firebase_init.dart';
import 'package:delnono/dashboard/app.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Pumps frames until [done] holds (real time, so network calls can finish).
Future<void> settle(WidgetTester tester, bool Function() done, {int seconds = 30}) async {
  for (var i = 0; i < seconds * 5 && !done(); i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

bool shows(Finder f) => f.evaluate().isNotEmpty;

Future<void> tapAndSettle(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(f);
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> signIn(WidgetTester tester, String email) async {
  await settle(tester, () => shows(find.byKey(const Key('dash-email'))));
  await tester.enterText(find.byKey(const Key('dash-email')), email);
  await tester.enterText(find.byKey(const Key('dash-password')), 'Delnono-2026');
  await tapAndSettle(tester, find.byKey(const Key('dash-sign-in')));
  await settle(tester, () => shows(find.byKey(const Key('today-calendar'))));
}

Future<void> openYoussef(WidgetTester tester) async {
  await tapAndSettle(tester, find.text('ملفات الأطفال').first);
  await settle(tester, () => shows(find.byKey(const Key('child-search'))));
  await tester.enterText(find.byKey(const Key('child-search')), 'يوسف');
  await tapAndSettle(tester, find.byKey(const Key('child-search-go')));
  await settle(tester, () => shows(find.byKey(const Key('child-result-seed-youssef'))));
  await tapAndSettle(tester, find.byKey(const Key('child-result-seed-youssef')));
  await settle(tester, () => shows(find.byKey(const Key('add-measurement'))));
}

/// `--dart-define=SCREENSHOTS=true` with test_driver/screenshot_driver.dart saves build/screenshots/.
const screenshots = bool.fromEnvironment('SCREENSHOTS');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shot(WidgetTester tester, String name) async {
    if (!screenshots) return;
    await tester.pump(const Duration(milliseconds: 1500));
    await binding.takeScreenshot('dashboard-$name');
  }

  setUpAll(() async {
    expect(useEmulator, isTrue, reason: 'Run with --dart-define=USE_EMULATOR=true');
    await initFirebase(persistence: false);
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('secretary: her clinic only, arrived and done, a measurement; doctor: corrects it', (tester) async {
    // Keep each Flutter error in full for build/integration_response_data.json: the driver's report
    // only counts them.
    final errors = <String>[];
    final report = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details.toString());
      binding.reportData = {'errors': errors};
      report?.call(details);
    };
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(const ProviderScope(child: DashboardApp()));

    // A secretary sees only her clinic (D-47).
    await signIn(tester, 'sec1@demo.delnono');
    await settle(tester, () => shows(find.byKey(const Key('dash-clinic-name'))));
    expect(find.byKey(const Key('dash-clinic-name')), findsOneWidget);
    expect(find.byKey(const Key('dash-clinic-picker')), findsNothing);
    await settle(tester, () => shows(find.byKey(const Key('booking-row-e2e-clinic1'))));
    expect(find.byKey(const Key('booking-row-e2e-clinic1')), findsOneWidget);
    expect(find.byKey(const Key('booking-row-e2e-clinic2')), findsNothing, reason: "clinic 2's booking");
    expect(find.text('الموظفين'), findsNothing, reason: 'doctor-only screens');
    await shot(tester, '1-today-secretary');

    // Arrived, then done (D-06, FR-010).
    await tapAndSettle(tester, find.byKey(const Key('arrive-e2e-clinic1')));
    await settle(tester, () => shows(find.byKey(const Key('done-e2e-clinic1'))));
    expect(find.byKey(const Key('queue-e2e-clinic1')), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('done-e2e-clinic1')));
    await settle(tester, () => !shows(find.byKey(const Key('done-e2e-clinic1'))));
    expect(find.byKey(const Key('done-e2e-clinic1')), findsNothing);

    // A measurement at her clinic from the file's form (D-29); she cannot correct it.
    await openYoussef(tester);
    await tester.enterText(find.byKey(const Key('new-m-weight')), '13.4');
    await tapAndSettle(tester, find.byKey(const Key('add-measurement')));
    await settle(tester, () => shows(find.text('١٣٫٤ كجم')));
    expect(find.text('١٣٫٤ كجم'), findsOneWidget);
    expect(find.byIcon(Icons.edit_note), findsNothing, reason: 'only the doctor corrects');
    await shot(tester, '2-child-file');

    // The doctor signs in and corrects it (FR-015); the row is tagged corrected.
    // The "saved" message sits over the side bar's foot, where sign-out is; let it go first.
    await settle(tester, () => !shows(find.byType(SnackBar)));
    await tapAndSettle(tester, find.byKey(const Key('dash-sign-out')));
    await signIn(tester, 'doctor@demo.delnono');
    await settle(tester, () => shows(find.byKey(const Key('dash-clinic-picker'))));
    expect(find.byKey(const Key('dash-clinic-picker')), findsOneWidget);
    await openYoussef(tester);
    await settle(tester, () => shows(find.text('١٣٫٤ كجم')));
    final row = find.ancestor(of: find.text('١٣٫٤ كجم'), matching: find.byWidgetPredicate((w) => '${w.key}'.contains("'measurement-")));
    await tapAndSettle(tester, find.descendant(of: row.first, matching: find.byIcon(Icons.edit_note)));
    await settle(tester, () => shows(find.byKey(const Key('m-weight'))));
    await tester.enterText(find.byKey(const Key('m-weight')), '13.6');
    await tapAndSettle(tester, find.byKey(const Key('dialog-save')));
    await settle(tester, () => shows(find.text('١٣٫٦ كجم')));
    expect(find.text('١٣٫٦ كجم'), findsOneWidget);
    expect(find.text('١٣٫٤ كجم'), findsNothing);
    final corrected = find.ancestor(of: find.text('١٣٫٦ كجم'), matching: find.byWidgetPredicate((w) => '${w.key}'.contains("'measurement-")));
    expect(find.descendant(of: corrected.first, matching: find.text('اتصحح')), findsOneWidget);

    // The doctor publishes a seeded draft video (006); it can then be unpublished.
    await settle(tester, () => !shows(find.byType(SnackBar)));
    await tapAndSettle(tester, find.text('المحتوى').first);
    await settle(tester, () => shows(find.byKey(const Key('publish-yt-skgdeAOm374'))));
    expect(find.byKey(const Key('proposed-tip-fever')), findsOneWidget, reason: 'researched tips are marked proposed');
    await shot(tester, '3-content');
    await tapAndSettle(tester, find.byKey(const Key('publish-yt-skgdeAOm374')));
    await settle(tester, () => shows(find.byKey(const Key('unpublish-yt-skgdeAOm374'))));
    expect(find.byKey(const Key('unpublish-yt-skgdeAOm374')), findsOneWidget);
  });
}
