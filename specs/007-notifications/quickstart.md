# Quickstart: Notifications

1. Run emulators with the seed and the app on the iOS simulator; sign in with a test number; book a visit for tomorrow → on the success screen allow notifications.
2. In the simulator: Settings → Notifications shows the app; `xcrun simctl` cannot list pending ones, so check with the in-app debug log (debug builds print the scheduled keys).
3. Move the booking from the dashboard → reopen the app → the log shows the new times; cancel → none.
4. Home bell: a booking confirmation shows count 1; open the page → «الجديد»; "mark all read" → count gone.
5. Turn vaccine reminders off → the log shows only booking reminders.

Automated: `flutter test test/features/notifications`, integration `integration_test/notifications_test.dart` on the simulator.
