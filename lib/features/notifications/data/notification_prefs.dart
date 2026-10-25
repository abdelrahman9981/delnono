import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The guardian's reminder switches and read markers, on this device (data-model.md): local
/// reminders are per device, so their settings are too.
class NotificationPrefs {
  const NotificationPrefs({this.booking = true, this.vaccine = true, this.read = const {}, this.askedPermission = false});

  final bool booking;
  final bool vaccine;
  final Set<String> read;
  final bool askedPermission;

  NotificationPrefs copyWith({bool? booking, bool? vaccine, Set<String>? read, bool? askedPermission}) => NotificationPrefs(
    booking: booking ?? this.booking,
    vaccine: vaccine ?? this.vaccine,
    read: read ?? this.read,
    askedPermission: askedPermission ?? this.askedPermission,
  );
}

/// Read markers kept, newest last; older ones drop off.
const maxReadMarkers = 300;

class NotificationPrefsNotifier extends AsyncNotifier<NotificationPrefs> {
  static const _booking = 'notif.booking';
  static const _vaccine = 'notif.vaccine';
  static const _read = 'notif.read';
  static const _asked = 'notif.askedPermission';

  late SharedPreferencesAsync _store;

  @override
  Future<NotificationPrefs> build() async {
    _store = SharedPreferencesAsync();
    return NotificationPrefs(
      booking: await _store.getBool(_booking) ?? true,
      vaccine: await _store.getBool(_vaccine) ?? true,
      read: {...?await _store.getStringList(_read)},
      askedPermission: await _store.getBool(_asked) ?? false,
    );
  }

  NotificationPrefs get _now => state.value ?? const NotificationPrefs();

  Future<void> setBooking(bool on) async {
    state = AsyncData(_now.copyWith(booking: on));
    await _store.setBool(_booking, on);
  }

  Future<void> setVaccine(bool on) async {
    state = AsyncData(_now.copyWith(vaccine: on));
    await _store.setBool(_vaccine, on);
  }

  Future<void> markRead(Iterable<String> keys) async {
    final list = [..._now.read.where((k) => !keys.contains(k)), ...keys];
    final kept = list.length > maxReadMarkers ? list.sublist(list.length - maxReadMarkers) : list;
    state = AsyncData(_now.copyWith(read: kept.toSet()));
    await _store.setStringList(_read, kept);
  }

  Future<void> setAskedPermission() async {
    state = AsyncData(_now.copyWith(askedPermission: true));
    await _store.setBool(_asked, true);
  }
}

final notificationPrefsProvider = AsyncNotifierProvider<NotificationPrefsNotifier, NotificationPrefs>(NotificationPrefsNotifier.new);
