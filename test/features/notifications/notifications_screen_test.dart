import 'package:delnono/core/clock.dart';
import 'package:delnono/features/auth/data/auth_repository.dart';
import 'package:delnono/features/notifications/data/local_notifier.dart';
import 'package:delnono/features/notifications/data/notification_prefs.dart';
import 'package:delnono/features/notifications/data/reminder_sync.dart';
import 'package:delnono/features/notifications/domain/reminders.dart';
import 'package:delnono/features/notifications/presentation/notifications_bell.dart';
import 'package:delnono/features/notifications/presentation/notifications_screen.dart';
import 'package:delnono/features/notifications/presentation/reminder_offer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../helpers/screen_harness.dart';
import 'reminder_sync_test.dart' show FakeNotifier;

class _User extends Mock implements User {}

/// Sunday 15 Nov 2026, 12:00 Cairo.
final now = DateTime.utc(2026, 11, 15, 10);

final items = [
  FeedItem(key: 'r1', kind: FeedKind.bookingReminder, at: DateTime.utc(2026, 11, 15, 7), title: 'ميعادك بكرة', body: 'كشف يوسف', route: '/booking/mine'),
  FeedItem(key: 'r2', kind: FeedKind.vaccineReminder, at: DateTime.utc(2026, 11, 14, 7), title: 'تطعيم يوسف بعد ٣ أيام', body: '[الخماسي]', route: '/children/c1/vaccines'),
  FeedItem(key: 'r3', kind: FeedKind.confirmed, at: DateTime.utc(2026, 11, 3, 7), title: 'تم تأكيد حجزك', body: 'كشف مريم', route: '/booking/mine'),
];

class _PermissionNotifier extends FakeNotifier {
  _PermissionNotifier(this.granted);

  bool granted;
  var asked = 0;

  @override
  Future<bool> permissionGranted() async => granted;

  @override
  Future<bool> requestPermission() async {
    asked++;
    return granted;
  }
}

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  Future<ScreenHarness> open(WidgetTester tester, Widget screen, {bool granted = true, bool signedIn = true, LocalNotifier? notifier}) async {
    final h = ScreenHarness(
      initial: '/',
      routes: [GoRoute(path: '/', builder: (_, _) => screen)],
      overrides: [
        clockProvider.overrideWithValue(() => now),
        authStateProvider.overrideWith((ref) => Stream.value(signedIn ? _User() : null)),
        feedProvider.overrideWithValue(items),
        localNotifierProvider.overrideWithValue(notifier ?? _PermissionNotifier(granted)),
      ],
    );
    await h.pump(tester);
    return h;
  }

  testWidgets('new items, then earlier ones after "mark all as read" (US3, FR-007)', (tester) async {
    final h = await open(tester, const NotificationsScreen());
    expect(find.text('الجديد'), findsOneWidget);
    expect(find.text('قبل كده'), findsNothing);
    expect(find.text('٩ ص'), findsOneWidget, reason: "today's item shows its Cairo time");
    expect(find.text('أمس'), findsOneWidget);
    expect(find.text('٣ نوفمبر'), findsOneWidget);
    await tester.tap(find.byKey(const Key('notif-mark-all')));
    await tester.pumpAndSettle();
    expect(find.text('الجديد'), findsNothing);
    expect(find.text('قبل كده'), findsOneWidget);
    expect(h.container.read(notificationPrefsProvider).value!.read, {'r1', 'r2', 'r3'});
  });

  testWidgets('opening an item marks it read and goes to its screen (FR-009)', (tester) async {
    final h = await open(tester, const NotificationsScreen());
    await tester.tap(find.byKey(const Key('notif-r2')));
    await tester.pumpAndSettle();
    expect(h.location, '/children/c1/vaccines');
    expect(h.container.read(notificationPrefsProvider).value!.read, {'r2'});
  });

  testWidgets('each type has its switch; turning one on asks for permission if needed (US4, FR-005, FR-006)', (tester) async {
    final notifier = _PermissionNotifier(false);
    final h = await open(tester, const NotificationsScreen(), notifier: notifier);
    expect(find.byKey(const Key('notif-denied')), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('notif-vaccine')), 100, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('notif-vaccine')));
    await tester.pumpAndSettle();
    expect(h.container.read(notificationPrefsProvider).value!.vaccine, isFalse);
    expect(notifier.asked, 0, reason: 'turning off asks nothing');
    await tester.tap(find.byKey(const Key('notif-vaccine')));
    await tester.pumpAndSettle();
    expect(h.container.read(notificationPrefsProvider).value!.vaccine, isTrue);
    expect(notifier.asked, 1);
  });

  testWidgets('the bell shows the unread count; none signed out (FR-008)', (tester) async {
    await open(tester, const Scaffold(body: Center(child: NotificationsBell())));
    expect(find.descendant(of: find.byKey(const Key('notifications-badge')), matching: find.text('٣')), findsOneWidget);
    await tester.tap(find.byKey(const Key('notifications-bell')));
    await tester.pumpAndSettle();
  });

  testWidgets('no bell for a signed-out visitor', (tester) async {
    await open(tester, const Scaffold(body: Center(child: NotificationsBell())), signedIn: false);
    expect(find.byKey(const Key('notifications-bell')), findsNothing);
  });

  testWidgets('booking success offers reminders once, and only if not allowed yet', (tester) async {
    final notifier = _PermissionNotifier(false);
    await open(tester, const Scaffold(body: ReminderOffer()), notifier: notifier);
    expect(find.byKey(const Key('reminder-offer')), findsOneWidget);
    await tester.tap(find.byKey(const Key('reminder-offer-yes')));
    await tester.pumpAndSettle();
    expect(notifier.asked, 1);
    expect(find.byKey(const Key('reminder-offer')), findsNothing, reason: 'asked once');
  });
}
