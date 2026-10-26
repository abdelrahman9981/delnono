import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:timezone/timezone.dart' as tz;

import '../../../app/l10n/app_localizations.dart';
import '../../../app/theme.dart';
import '../../../core/clock.dart';
import '../../../core/format/arabic_digits.dart';
import '../../../core/widgets/notice.dart';
import '../../booking/domain/clinic_time.dart';
import '../data/local_notifier.dart';
import '../data/notification_prefs.dart';
import '../data/reminder_sync.dart';
import '../domain/reminders.dart';

/// Whether the phone lets the app show notifications; refreshed when the screen asks.
final notificationPermissionProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(localNotifierProvider).permissionGranted(),
);

/// Turns a reminder type on or off; turning one on asks for the phone's permission in context
/// (007 FR-006).
Future<void> setReminderType(WidgetRef ref, {required bool vaccine, required bool on}) async {
  final prefs = ref.read(notificationPrefsProvider.notifier);
  if (vaccine) {
    await prefs.setVaccine(on);
  } else {
    await prefs.setBooking(on);
  }
  if (on && !await ref.read(localNotifierProvider).permissionGranted()) {
    await ref.read(localNotifierProvider).requestPermission();
    await prefs.setAskedPermission();
    ref.invalidate(notificationPermissionProvider);
  }
}

/// The notifications page (design screen 10, docs/design/screens/Notifications.dc.html; 007 US3,
/// US4): new and earlier items, mark all as read, and the two reminder switches.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final feed = ref.watch(feedProvider);
    final prefs = ref.watch(notificationPrefsProvider).value ?? const NotificationPrefs();
    final granted = ref.watch(notificationPermissionProvider).value ?? true;
    final notifier = ref.read(localNotifierProvider);
    final unread = [for (final f in feed) if (!prefs.read.contains(f.key)) f];
    final earlier = [for (final f in feed) if (prefs.read.contains(f.key)) f];

    Widget heading(String title, {Widget? action}) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      // Wraps at large text sizes, so the action never pushes the title out.
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [Text(title, style: text.titleMedium), ?action],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notifTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
          children: [
            if (feed.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Text(l10n.notifEmpty, key: const Key('notif-empty'), style: text.bodyMedium?.copyWith(color: c.muted)),
              ),
            if (unread.isNotEmpty) ...[
              heading(
                l10n.notifNew,
                action: TextButton(
                  key: const Key('notif-mark-all'),
                  onPressed: () => ref.read(notificationPrefsProvider.notifier).markRead(unread.map((f) => f.key)),
                  child: Text(l10n.notifMarkAllRead, style: const TextStyle(fontSize: 12)),
                ),
              ),
              for (final f in unread) _ItemCard(item: f, unread: true),
            ],
            if (earlier.isNotEmpty) ...[
              heading(l10n.notifEarlier),
              for (final f in earlier) _ItemCard(item: f, unread: false),
            ],
            heading(l10n.notifSettings),
            if (!granted) ...[
              Notice(l10n.notifDenied, key: const Key('notif-denied'), kind: NoticeKind.warn),
              if (notifier.canOpenSettings)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(onPressed: notifier.openSettings, child: Text(l10n.notifOpenSettings)),
                ),
              const SizedBox(height: 8),
            ],
            Card(
              margin: EdgeInsets.zero,
              child: Column(children: [
                SwitchListTile(
                  key: const Key('notif-booking'),
                  value: prefs.booking,
                  onChanged: (on) => setReminderType(ref, vaccine: false, on: on),
                  title: Text(l10n.notifBookingSwitch, style: text.titleSmall),
                  subtitle: Text(l10n.notifBookingSwitchSub, style: text.bodySmall),
                ),
                Divider(height: 1, indent: 12, endIndent: 12, color: c.border),
                SwitchListTile(
                  key: const Key('notif-vaccine'),
                  value: prefs.vaccine,
                  onChanged: (on) => setReminderType(ref, vaccine: true, on: on),
                  title: Text(l10n.notifVaccineSwitch, style: text.titleSmall),
                  subtitle: Text(l10n.notifVaccineSwitchSub, style: text.bodySmall),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Text(l10n.notifOffNote, style: text.bodySmall?.copyWith(color: c.muted, height: 1.6)),
          ],
        ),
      ),
    );
  }
}

class _ItemCard extends ConsumerWidget {
  const _ItemCard({required this.item, required this.unread});

  final FeedItem item;
  final bool unread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final (icon, bg, fg) = switch (item.kind) {
      FeedKind.bookingReminder => (Icons.calendar_today_outlined, c.blueSoft, c.blue),
      FeedKind.vaccineReminder => (Icons.vaccines_outlined, c.pinkSoft, c.pink),
      FeedKind.packageReminder => (Icons.card_giftcard, c.yellowSoft, c.yellow),
      FeedKind.confirmed => (Icons.check, c.greenSoft, c.green),
      FeedKind.cancelled => (Icons.event_busy_outlined, c.dangerBg, c.dangerText),
    };
    final now = ref.watch(clockProvider)();
    final today = ClinicTime.dateOf(now);
    final day = ClinicTime.dateOf(item.at);
    final when = day == today
        ? arabicDigits(DateFormat('h a', 'ar').format(tz.TZDateTime.from(item.at, ClinicTime.cairo)))
        : day == ClinicTime.addDays(today, -1)
            ? l10n.notifYesterday
            : arabicDigits(DateFormat('d MMMM', 'ar').format(ClinicTime.asDate(day)));

    return Opacity(
      opacity: unread ? 1 : .8,
      child: Card(
        key: Key('notif-${item.key}'),
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            ref.read(notificationPrefsProvider.notifier).markRead([item.key]);
            context.push(item.route);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: fg),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.title, style: text.titleSmall),
                  const SizedBox(height: 2),
                  Text(item.body, style: text.bodySmall?.copyWith(color: c.muted)),
                ]),
              ),
              const SizedBox(width: 8),
              Text(when, style: text.bodySmall?.copyWith(color: c.muted, fontSize: 11)),
              if (unread) ...[
                const SizedBox(width: 6),
                Semantics(
                  label: l10n.notifUnread,
                  child: Container(width: 8, height: 8, decoration: BoxDecoration(color: c.pink, shape: BoxShape.circle)),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
