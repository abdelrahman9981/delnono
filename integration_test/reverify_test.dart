// Re-check after inactivity end to end (quickstart.md scenario 19; FR-010a, FR-010b).

import 'package:delnono/core/firebase/firebase_init.dart';
import 'package:delnono/core/widgets/birth_date_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

DateTime picked = DateTime(2023, 6, 1);
final pickerOverride = birthDatePickerProvider.overrideWithValue((context, {initial}) async => picked);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    expect(useEmulator, isTrue, reason: 'Run with --dart-define=USE_EMULATOR=true');
    await initFirebase();
    await deleteAllEmulatorUsers();
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('after 91 days without use, child data needs a birth date first', (tester) async {
    await startApp(tester, overrides: [pickerOverride]);
    await signInFromBooking(tester, '+201000000090');
    await registerGuardian(tester, 'أمل يسري');
    await settle(tester, () => shows(find.byKey(const Key('child-name'))));
    await tester.enterText(find.byKey(const Key('child-name')), 'جنى');
    await tapInList(tester, find.byKey(const Key('child-birth-date')));
    await tapInList(tester, find.text('بنت'));
    await tapInList(tester, find.text('حفظ'));
    await settle(tester, () => location(tester) == '/booking');

    await ageGuardian(FirebaseAuth.instance.currentUser!.uid, 91);
    await startApp(tester, overrides: [pickerOverride]);
    await tester.pump(const Duration(seconds: 2));

    // Opening child data asks for the re-check first.
    await tester.tap(find.text('طفلي'));
    await settle(tester, () => shows(find.byKey(const Key('reverify-birth-date'))));
    expect(location(tester), '/reverify?from=%2Fchildren');

    picked = DateTime(2019, 5, 5);
    await tapInList(tester, find.byKey(const Key('reverify-birth-date')));
    await tapInList(tester, find.text('تأكيد'));
    await settle(tester, () => shows(find.textContaining('فاضلك محاولتين')));
    expect(find.textContaining('فاضلك محاولتين'), findsOneWidget);

    picked = DateTime(2023, 6, 1);
    await tapInList(tester, find.byKey(const Key('reverify-birth-date')));
    await tapInList(tester, find.text('تأكيد'));
    await settle(tester, () => location(tester) == '/children' && shows(find.text('جنى')));
    expect(location(tester), '/children');
    expect(find.text('جنى'), findsOneWidget);
  });
}
