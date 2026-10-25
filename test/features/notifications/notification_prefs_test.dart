import 'package:delnono/features/notifications/data/notification_prefs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('both types on by default; choices and read markers persist (FR-005)', () async {
    var c = ProviderContainer();
    var prefs = await c.read(notificationPrefsProvider.future);
    expect(prefs.booking, isTrue);
    expect(prefs.vaccine, isTrue);
    await c.read(notificationPrefsProvider.notifier).setVaccine(false);
    await c.read(notificationPrefsProvider.notifier).markRead(['a', 'b']);
    c.dispose();

    c = ProviderContainer();
    prefs = await c.read(notificationPrefsProvider.future);
    expect(prefs.vaccine, isFalse);
    expect(prefs.booking, isTrue);
    expect(prefs.read, {'a', 'b'});
    c.dispose();
  });

  test('read markers keep the newest $maxReadMarkers', () async {
    final c = ProviderContainer();
    await c.read(notificationPrefsProvider.future);
    await c.read(notificationPrefsProvider.notifier).markRead([for (var i = 0; i < maxReadMarkers + 5; i++) 'k$i']);
    final read = c.read(notificationPrefsProvider).value!.read;
    expect(read.length, maxReadMarkers);
    expect(read, isNot(contains('k0')));
    expect(read, contains('k${maxReadMarkers + 4}'));
    c.dispose();
  });
}
