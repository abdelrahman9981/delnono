// Changing and cancelling a booking end to end (002 quickstart scenarios 10–11; FR-020 to FR-022).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delnono/core/firebase/firebase_init.dart';
import 'package:delnono/core/widgets/birth_date_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

final pickerOverride =
    birthDatePickerProvider.overrideWithValue((context, {initial}) async => DateTime(2022, 4, 4));

Future<int> taken(String date, int hour) async {
  final q = await FirebaseFirestore.instance
      .collection('slots')
      .where('clinicId', isEqualTo: 'clinic-1')
      .where('date', isEqualTo: date)
      .where('hour', isEqualTo: hour)
      .get();
  return q.docs.isEmpty ? 0 : q.docs.single.get('taken') as int;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    expect(useEmulator, isTrue, reason: 'Run with --dart-define=USE_EMULATOR=true');
    await initFirebase();
    await deleteAllEmulatorUsers();
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('change keeps the number and moves the place; cancel frees it', (tester) async {
    await startApp(tester, overrides: [pickerOverride]);
    await registerWithChild(tester, '+201000000086', 'دعاء نبيل', 'سليم');

    // At the main clinic (004), book the first open day at its first hour (a day after today, so
    // outside the cancel window).
    await settle(tester, () => shows(find.byKey(const Key('clinic-clinic-1'))));
    await tapInList(tester, find.byKey(const Key('clinic-clinic-1')));
    await settle(tester, () => shows(keysStarting('day-')));
    await tapInList(tester, keysStarting('day-').at(1));
    await settle(tester, () => shows(keysStarting('hour-')));
    await tapInList(tester, keysStarting('hour-').first);
    await tapInList(tester, keysStarting('child-').first);
    await tapInList(tester, find.byKey(const Key('confirm-booking')));
    await settle(tester, () => shows(find.byKey(const Key('booking-number'))));

    final uid = FirebaseAuth.instance.currentUser!.uid;
    Future<QueryDocumentSnapshot<Map<String, dynamic>>> mine() async =>
        (await FirebaseFirestore.instance.collection('bookings').where('guardianUid', isEqualTo: uid).get()).docs.single;
    final before = await mine();
    final date = before.get('date') as String;
    final hour = before.get('hour') as int;

    // Change to the next hour.
    await tapInList(tester, find.byKey(const Key('view-my-bookings')));
    await settle(tester, () => shows(find.byKey(Key('change-${before.id}'))));
    await tapInList(tester, find.byKey(Key('change-${before.id}')));
    await settle(tester, () => shows(find.byKey(Key('hour-${hour + 1}'))));
    await tapInList(tester, find.byKey(Key('hour-${hour + 1}')));
    await tapInList(tester, find.byKey(const Key('confirm-booking')));
    await settle(tester, () => location(tester) == '/booking/mine');

    final after = await mine();
    expect(after.get('number'), before.get('number'), reason: 'same booking number');
    expect(after.get('hour'), hour + 1);
    expect(await taken(date, hour), 0);
    expect(await taken(date, hour + 1), 1);

    // Cancel.
    await settle(tester, () => shows(find.byKey(Key('cancel-${after.id}'))));
    await tapInList(tester, find.byKey(Key('cancel-${after.id}')));
    await settle(tester, () => shows(find.byKey(const Key('confirm-cancel'))));
    await tester.tap(find.byKey(const Key('confirm-cancel')));
    await settle(tester, () => shows(find.text('اتلغى الحجز.')));
    expect((await mine()).get('status'), 'cancelled');
    expect(await taken(date, hour + 1), 0, reason: 'place freed at once');
  });
}
