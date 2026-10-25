// Local reminders end to end on the simulator (007 quickstart): booking a visit schedules its
// reminders on the phone; the Home bell counts the confirmation; the page lists it and marks it
// read; turning booking reminders off removes them from the phone.

import 'package:delnono/core/firebase/firebase_init.dart';
import 'package:delnono/features/notifications/data/local_notifier.dart';
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

/// The real plugin, recording what the app asks it to schedule. iOS keeps scheduled requests only
/// after the guardian allows notifications, and a test cannot answer that system prompt (simctl
/// cannot grant it), so the phone's own queue is checked only when permission exists.
class RecordingNotifier implements LocalNotifier {
  final real = PluginNotifier();
  var scheduled = <String>[];

  @override
  Future<void> init({required void Function(String route) onTap}) => real.init(onTap: onTap);
  @override
  Future<bool> requestPermission() => real.requestPermission();
  @override
  Future<bool> permissionGranted() => real.permissionGranted();
  @override
  Future<void> replaceAll(List<Reminder> reminders) {
    scheduled = [for (final r in reminders) r.key];
    return real.replaceAll(reminders);
  }

  @override
  Future<void> cancelAll() {
    scheduled = [];
    return real.cancelAll();
  }

  @override
  bool get canOpenSettings => real.canOpenSettings;
  @override
  Future<void> openSettings() => real.openSettings();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    expect(useEmulator, isTrue, reason: 'Run with --dart-define=USE_EMULATOR=true');
    await initFirebase();
    await deleteAllEmulatorUsers();
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('a booking schedules reminders, shows on the bell and the page; switching off removes them', (tester) async {
    final phone = RecordingNotifier();
    await startApp(tester, overrides: [pickerOverride, localNotifierProvider.overrideWithValue(phone)]);
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

    // The app scheduled this booking's two reminders on the phone (FR-001, FR-003).
    await wait(tester, 3);
    expect(phone.scheduled, containsAll(['booking:$bookingId:24h', 'booking:$bookingId:1h']));
    if (await phone.permissionGranted()) {
      expect(await pendingIds(), containsAll([reminderId('booking:$bookingId:24h'), reminderId('booking:$bookingId:1h')]));
    }

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
    expect(phone.scheduled, isNot(contains('booking:$bookingId:1h')));
    expect(phone.scheduled, isNot(contains('booking:$bookingId:24h')));
    expect((await pendingIds()).intersection({reminderId('booking:$bookingId:1h'), reminderId('booking:$bookingId:24h')}), isEmpty);
  });
}
