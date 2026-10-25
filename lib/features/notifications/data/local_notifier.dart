import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminders.dart';

/// The phone's scheduled reminders (contracts/local-notifier.md).
abstract interface class LocalNotifier {
  /// Sets up the plugin; [onTap] gets the route of a tapped reminder, including the one that
  /// launched the app.
  Future<void> init({required void Function(String route) onTap});
  Future<bool> requestPermission();
  Future<bool> permissionGranted();

  /// Cancels every pending reminder and schedules [reminders] (research R1).
  Future<void> replaceAll(List<Reminder> reminders);
  Future<void> cancelAll();
}

/// Web (the demo) and tests: nothing on the phone; the page still works.
class NoopNotifier implements LocalNotifier {
  const NoopNotifier();

  @override
  Future<void> init({required void Function(String route) onTap}) async {}
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<bool> permissionGranted() async => false;
  @override
  Future<void> replaceAll(List<Reminder> reminders) async {}
  @override
  Future<void> cancelAll() async {}
}

/// flutter_local_notifications: times in Cairo (research R3), inexact on Android (no exact-alarm
/// permission), the route as payload (research R6).
class PluginNotifier implements LocalNotifier {
  final _plugin = FlutterLocalNotificationsPlugin();
  late final tz.Location _cairo;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails('reminders', 'التذكيرات', importance: Importance.high, priority: Priority.high),
    iOS: DarwinNotificationDetails(),
  );

  /// False where the platform plugin is missing (widget tests): every call is then a no-op.
  bool _ready = false;

  @override
  Future<void> init({required void Function(String route) onTap}) async {
    try {
      await _init(onTap);
      _ready = true;
    } on MissingPluginException {
      debugPrint('local notifications: no platform plugin here; reminders stay in the page only');
    }
  }

  Future<void> _init(void Function(String route) onTap) async {
    tzdata.initializeTimeZones();
    _cairo = tz.getLocation('Africa/Cairo');
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is asked in context, never at start (FR-006).
        iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
      ),
      onDidReceiveNotificationResponse: (r) {
        if (r.payload case final route? when route.isNotEmpty) onTap(route);
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      if (launch!.notificationResponse?.payload case final route? when route.isNotEmpty) onTap(route);
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        false;
  }

  @override
  Future<bool> permissionGranted() async {
    if (!_ready) return false;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final o = await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.checkPermissions();
      return o?.isEnabled ?? false;
    }
    return await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.areNotificationsEnabled() ??
        false;
  }

  @override
  Future<void> replaceAll(List<Reminder> reminders) async {
    if (!_ready) return;
    await _plugin.cancelAll();
    for (final r in reminders) {
      await _plugin.zonedSchedule(
        id: r.id,
        scheduledDate: tz.TZDateTime.from(r.at, _cairo),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: r.title,
        body: r.body,
        payload: r.route,
      );
    }
    if (kDebugMode) debugPrint('reminders scheduled: ${reminders.map((r) => '${r.key}@${r.at.toIso8601String()}').join(', ')}');
  }

  @override
  Future<void> cancelAll() async {
    if (_ready) await _plugin.cancelAll();
  }
}

/// The app's notifier: the plugin on phones, nothing on the web. Tests override it.
final localNotifierProvider = Provider<LocalNotifier>((ref) => kIsWeb ? const NoopNotifier() : PluginNotifier());
