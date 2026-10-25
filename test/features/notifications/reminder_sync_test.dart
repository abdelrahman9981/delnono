import 'dart:async';

import 'package:delnono/core/clock.dart';
import 'package:delnono/features/auth/data/auth_repository.dart';
import 'package:delnono/features/booking/data/bookings_repository.dart';
import 'package:delnono/features/booking/domain/booking.dart';
import 'package:delnono/features/child_profile/data/doses_repository.dart';
import 'package:delnono/features/child_profile/data/vaccine_schedule_repository.dart';
import 'package:delnono/features/children/data/children_repository.dart';
import 'package:delnono/features/notifications/data/local_notifier.dart';
import 'package:delnono/features/notifications/data/notification_prefs.dart';
import 'package:delnono/features/notifications/data/reminder_sync.dart';
import 'package:delnono/features/notifications/domain/reminders.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'reminders_test.dart' show booking, fourMonths, catalogue, now, youssef;

class _User extends Mock implements User {}

/// Like a Firestore snapshot stream: the current value on subscribe, then each change.
Stream<T> latest<T>(ValueNotifier<T> n) {
  late final StreamController<T> c;
  void changed() => c.add(n.value);
  c = StreamController<T>(
    onListen: () {
      c.add(n.value);
      n.addListener(changed);
    },
    onCancel: () => n.removeListener(changed),
  );
  return c.stream;
}

/// Records what the app schedules.
class FakeNotifier implements LocalNotifier {
  List<String>? scheduled;
  var cleared = 0;

  @override
  Future<void> init({required void Function(String route) onTap}) async {}
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<bool> permissionGranted() async => true;
  @override
  Future<void> replaceAll(List<Reminder> reminders) async => scheduled = reminders.map((r) => r.key).toList();
  @override
  Future<void> cancelAll() async {
    cleared++;
    scheduled = const [];
  }

  @override
  bool get canOpenSettings => false;
  @override
  Future<void> openSettings() async {}
}

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  late FakeNotifier notifier;
  late ValueNotifier<User?> auth;
  late ValueNotifier<List<Booking>> bookings;
  late ValueNotifier<List<DoseRecord>> doses;
  late ProviderContainer c;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    notifier = FakeNotifier();
    auth = ValueNotifier(null);
    bookings = ValueNotifier(const []);
    doses = ValueNotifier(const []);
    c = ProviderContainer(overrides: [
      clockProvider.overrideWithValue(() => now),
      localNotifierProvider.overrideWithValue(notifier),
      authStateProvider.overrideWith((ref) => latest(auth)),
      myBookingsProvider.overrideWith((ref) => latest(bookings)),
      childrenProvider.overrideWith((ref) => Stream.value(const [youssef])),
      vaccineScheduleProvider.overrideWith((ref) => Stream.value(const [fourMonths])),
      vaccineCatalogueProvider.overrideWith((ref) => Stream.value(catalogue)),
      dosesProvider.overrideWith((ref, id) => latest(doses)),
    ]);
    c.listen(reminderSyncProvider, (_, _) {});
  });

  tearDown(() => c.dispose());

  Future<void> settle() => Future.delayed(const Duration(milliseconds: 450));

  Future<void> signedInWith(List<Booking> b, [List<DoseRecord> d = const []]) async {
    bookings.value = b;
    doses.value = d;
    auth.value = _User();
    // The first load of the device preferences can take a moment.
    for (var i = 0; i < 30 && notifier.scheduled == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    await settle();
  }

  test('a booking and a due dose are scheduled; moving the booking moves its reminders (FR-001–FR-003)', () async {
    await signedInWith([booking('b', '2026-11-17', 18)]);
    expect(notifier.scheduled, ['booking:b:24h', 'vaccine:c1:s4:3d', 'booking:b:1h', 'vaccine:c1:s4:day']);
    bookings.value = [booking('b', '2026-11-18', 10)];
    await settle();
    expect(notifier.scheduled, ['vaccine:c1:s4:3d', 'booking:b:24h', 'booking:b:1h', 'vaccine:c1:s4:day']);
  });

  test('a cancelled booking and a recorded dose leave nothing behind (FR-004)', () async {
    await signedInWith([booking('b', '2026-11-17', 18)]);
    bookings.value = [booking('b', '2026-11-17', 18, status: BookingStatus.cancelled)];
    doses.value = [const DoseRecord(id: 'd', scheduleId: 's4', vaccineId: 'v1', dose: 1, givenOn: '2026-11-15')];
    await settle();
    expect(notifier.scheduled, isEmpty);
  });

  test('a type turned off is not scheduled; on again it is (FR-005)', () async {
    await signedInWith([booking('b', '2026-11-17', 18)]);
    await c.read(notificationPrefsProvider.future);
    await c.read(notificationPrefsProvider.notifier).setVaccine(false);
    await settle();
    expect(notifier.scheduled, ['booking:b:24h', 'booking:b:1h']);
    await c.read(notificationPrefsProvider.notifier).setVaccine(true);
    await settle();
    expect(notifier.scheduled, hasLength(4));
  });

  test('signing out clears every reminder (FR-010)', () async {
    await signedInWith([booking('b', '2026-11-17', 18)]);
    auth.value = null;
    await settle();
    expect(notifier.cleared, greaterThan(0));
    expect(notifier.scheduled, isEmpty);
  });
}
