# Contract: LocalNotifier (app-internal)

```dart
abstract interface class LocalNotifier {
  Future<void> init({required void Function(String route) onTap}); // and launch details
  Future<bool> requestPermission();   // true if granted
  Future<bool> permissionGranted();
  Future<void> replaceAll(List<Reminder> reminders); // cancel all pending, schedule these
  Future<void> cancelAll();
}
```

Implementations: `PluginNotifier` (flutter_local_notifications), `NoopNotifier` (web and tests), `FakeNotifier` (tests: records the last list).
