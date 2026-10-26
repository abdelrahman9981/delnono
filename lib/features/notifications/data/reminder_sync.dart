import 'dart:async';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/clock.dart';
import '../../auth/data/auth_repository.dart';
import '../../booking/data/bookings_repository.dart';
import '../../child_profile/data/doses_repository.dart';
import '../../child_profile/data/vaccine_schedule_repository.dart';
import '../../children/data/children_repository.dart';
import '../../packages/data/packages_repository.dart';
import '../domain/reminders.dart';
import 'local_notifier.dart';
import 'notification_prefs.dart';

/// Texts outside a widget: the app is Arabic only (constitution Principle IV).
final _l10n = lookupAppLocalizations(const Locale('ar'));

/// Every reminder the signed-in family's data calls for (past and future); null while loading.
final plannedRemindersProvider = Provider<List<Reminder>?>((ref) {
  if (ref.watch(authStateProvider).value == null) return const [];
  final bookings = ref.watch(myBookingsProvider).value;
  final children = ref.watch(childrenProvider).value;
  final schedule = ref.watch(vaccineScheduleProvider).value;
  final catalogue = ref.watch(vaccineCatalogueProvider).value;
  if (bookings == null || children == null || schedule == null || catalogue == null) return null;
  final doses = <String, List<DoseRecord>>{};
  for (final c in children) {
    final d = ref.watch(dosesProvider(c.id)).value;
    if (d == null) return null;
    doses[c.id] = d;
  }
  final packages = ref.watch(familyPackageListProvider).value;
  if (packages == null) return null;
  return planReminders(
    ReminderInputs(
      bookings: bookings,
      children: children,
      schedule: schedule,
      catalogue: catalogue,
      doses: doses,
      packages: packages,
    ),
    _l10n,
  );
});

/// The notifications page: reminders whose time came, confirmations and cancellations.
final feedProvider = Provider<List<FeedItem>>((ref) {
  final planned = ref.watch(plannedRemindersProvider) ?? const [];
  final bookings = ref.watch(myBookingsProvider).value ?? const [];
  return feedItems(planned, bookings, _l10n, now: ref.watch(clockProvider)());
});

/// Unread items on the page, for the Home bell.
final unreadCountProvider = Provider<int>((ref) {
  final read = ref.watch(notificationPrefsProvider).value?.read ?? const <String>{};
  return ref.watch(feedProvider).where((f) => !read.contains(f.key)).length;
});

/// Keeps the phone's scheduled reminders equal to the plan (FR-003, FR-004): whenever the data,
/// the switches or the session change, the latest plan replaces what is scheduled; signing out
/// clears everything (FR-010). Watched by the app root.
final reminderSyncProvider = Provider<void>((ref) {
  final notifier = ref.watch(localNotifierProvider);
  Timer? pending;

  void apply() {
    pending?.cancel();
    // Coalesce bursts of stream updates into one rebuild of the schedule.
    pending = Timer(const Duration(milliseconds: 300), () async {
      if (ref.read(authStateProvider).value == null) {
        await notifier.cancelAll();
        return;
      }
      final planned = ref.read(plannedRemindersProvider);
      final prefs = ref.read(notificationPrefsProvider).value;
      if (planned == null || prefs == null) return;
      await notifier.replaceAll(
        toSchedule(planned, now: ref.read(clockProvider)(), booking: prefs.booking, vaccine: prefs.vaccine),
      );
    });
  }

  ref.listen(plannedRemindersProvider, (_, _) => apply(), fireImmediately: true);
  ref.listen(notificationPrefsProvider, (_, _) => apply());
  ref.listen(authStateProvider, (_, _) => apply());
  ref.onDispose(() => pending?.cancel());
});
