// Local reminders end to end on the simulator (007 quickstart): booking a visit schedules its
// reminders on the phone; the Home bell counts the confirmation; the page lists it and marks it
// read; turning booking reminders off removes them from the phone.

import 'package:delnono/core/firebase/firebase_init.dart';
import 'package:delnono/features/notifications/domain/reminders.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'booking_test.dart' show pickerOverride;
import 'helpers.dart';

/// Pumps frames for [seconds] (the app debounces rescheduling by 300 ms).
Future<void> wait(WidgetTester tester, int seconds) async {
  for (var i = 0; i < seconds * 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<Set<int>> pendingIds() async =>
    {for (final r in await FlutterLocalNotificationsPlugin().pendingNotificationRequests()) r.id};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    expect(useEmulator, isTrue, reason: 'Run with --dart-define=USE_EMULATOR=true');
    await initFirebase();
    await deleteAllEmulatorUsers();
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('a booking schedules reminders, shows on the bell and the page; switching off removes them', (tester) async {
    await startApp(tester, overrides: [pickerOverride]);
    await registerWithChild(tester, '+201000000088', 'هبة علي', 'سليم');

    await tester.tap(find.text('حجز'));
    await settle(tester, () => shows(find.byKey(const Key('clinic-clinic-2'))));
    await tapInList(tester, find.byKey(const Key('clinic-clinic-2')));
    await settle(tester, () => shows(keysStarting('day-')));
    // A later day, so both the day-before and the hour-before reminders are in the future.
    await tapInList(tester, keysStarting('day-').at(2));
    await settle(tester, () => shows(keysStarting('hour-')));
    await tapInList(tester, keysStarting('hour-').first);
    await tapInList(tester, keysStarting('child-').first);
    await tapInList(tester, find.byKey(const Key('confirm-booking')));
    await settle(tester, () => shows(find.byKey(const Key('booking-number'))));
    final bookingId = location(tester).split('/').last;

    // The phone now has this booking's two reminders (FR-001, FR-003).
    await wait(tester, 3);
    final pending = await pendingIds();
    expect(pending, containsAll([reminderId('booking:$bookingId:24h'), reminderId('booking:$bookingId:1h')]));

    // The bell counts the confirmation; the page lists it (FR-007, FR-008).
    await tester.tap(find.text('الرئيسية'));
    await settle(tester, () => shows(find.byKey(const Key('notifications-bell'))));
    await tester.tap(find.byKey(const Key('notifications-bell')));
    await settle(tester, () => shows(find.text('تم تأكيد حجزك')));
    expect(find.text('الجديد'), findsOneWidget);
    await tester.tap(find.byKey(const Key('notif-mark-all')));
    await settle(tester, () => shows(find.text('قبل كده')));

    // Booking reminders off: they leave the phone (FR-005).
    await tapInList(tester, find.byKey(const Key('notif-booking')));
    await wait(tester, 2);
    final after = await pendingIds();
    expect(after, isNot(contains(reminderId('booking:$bookingId:1h'))));
    expect(after, isNot(contains(reminderId('booking:$bookingId:24h'))));
  });
}
