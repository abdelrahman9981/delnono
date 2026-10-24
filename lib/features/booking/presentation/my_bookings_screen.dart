import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/messenger.dart';
import '../../../app/route_guard.dart';
import '../../../app/theme.dart';
import '../../../core/clock.dart';
import '../../../core/errors/arabic_errors.dart';
import '../../../core/format/arabic_digits.dart';
import '../../../core/launch/external_links.dart';
import '../../../core/settings/settings_repository.dart';
import '../data/booking_api.dart';
import '../data/booking_settings.dart';
import '../data/bookings_repository.dart';
import '../domain/booking.dart';
import '../domain/clinic_time.dart';
import '../domain/schedule.dart';
import 'booking_format.dart';
import 'booking_success_screen.dart' show statusStyle;

/// Upcoming: confirmed bookings whose hour has not ended, and arrived ones on their day (FR-018).
bool isUpcoming(Booking b, DateTime now) => switch (b.status) {
  BookingStatus.confirmed =>
    b.startsAt.add(const Duration(hours: 1)).isAfter(now),
  BookingStatus.arrived => b.date == ClinicTime.dateOf(now),
  _ => false,
};

/// My bookings (`/booking/mine`, docs/design/figma/my-bookings.jpg; FR-018 to FR-022).
class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  bool _past = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final now = ref.watch(clockProvider)();
    final all = ref.watch(myBookingsProvider);
    final settings =
        ref.watch(bookingSettingsProvider).value ?? const BookingSettings();

    final bookings = all.value ?? const <Booking>[];
    final upcoming = bookings.where((b) => isUpcoming(b, now)).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final past = bookings.where((b) => !isUpcoming(b, now)).toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    final shown = _past ? past : upcoming;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myBookings)),
      body: SafeArea(
        child: !all.hasValue
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                children: [
                  _Tabs(
                    past: _past,
                    upcomingCount: upcoming.length,
                    pastCount: past.length,
                    onChanged: (p) => setState(() => _past = p),
                  ),
                  const SizedBox(height: 16),
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        l10n.noBookings,
                        textAlign: TextAlign.center,
                        style: text.bodyLarge?.copyWith(color: c.muted),
                      ),
                    ),
                  for (final b in shown) ...[
                    _BookingCard(
                      booking: b,
                      settings: settings,
                      now: now,
                      upcoming: !_past,
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    key: const Key('new-booking'),
                    onPressed: () => context.go(Routes.booking),
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(l10n.newBooking),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.past,
    required this.upcomingCount,
    required this.pastCount,
    required this.onChanged,
  });

  final bool past;
  final int upcomingCount;
  final int pastCount;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).extension<AppColors>()!;

    Widget tab(
      Key key,
      String label,
      int count,
      bool selected,
      VoidCallback onTap,
    ) => Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          key: key,
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? c.blueSoft : null,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected ? c.blue : c.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                CircleAvatar(
                  radius: 11,
                  backgroundColor: selected ? c.blue : c.border,
                  child: Text(
                    arabicDigits(count),
                    style: TextStyle(
                      fontSize: 11,
                      color: selected ? Colors.white : c.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          tab(
            const Key('tab-upcoming'),
            l10n.tabUpcoming,
            upcomingCount,
            !past,
            () => onChanged(false),
          ),
          const SizedBox(width: 6),
          tab(
            const Key('tab-past'),
            l10n.tabPast,
            pastCount,
            past,
            () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  const _BookingCard({
    required this.booking,
    required this.settings,
    required this.now,
    required this.upcoming,
  });

  final Booking booking;
  final BookingSettings settings;
  final DateTime now;
  final bool upcoming;

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final when = '${dayLabel(booking.date)} · ${hourRange(l10n, booking.hour)}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelConfirmTitle),
        content: Text(l10n.cancelConfirmBody(when)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.keepBooking),
          ),
          TextButton(
            key: const Key('confirm-cancel'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.cancelBooking),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(bookingApiProvider).cancel(booking.id);
      showAppMessage(l10n.bookingCancelled);
    } on BookingRefusedException catch (e) {
      final hours = l10n.hoursCount(
        settings.cancelWindowHours,
        arabicDigits(settings.cancelWindowHours),
      );
      showAppMessage(
        e.reason == 'inside_window'
            ? '${l10n.lessThan(hours)}. ${l10n.lessThanSub}'
            : l10n.errGeneric,
      );
    } catch (e) {
      showAppMessage(arabicErrorMessage(e, l10n));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final soon =
        booking.status == BookingStatus.confirmed &&
        insideCancelWindow(settings, booking.startsAt, now);
    final status = statusStyle(context, booking.status, soon: soon);
    final hours = l10n.hoursCount(
      settings.cancelWindowHours,
      arabicDigits(settings.cancelWindowHours),
    );
    final whatsapp = ref.watch(clinicSettingsProvider).value?.whatsappNumber;
    final canChange =
        upcoming && booking.status == BookingStatus.confirmed && !soon;

    return Card(
      key: Key('booking-${booking.id}'),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Blue accent on upcoming bookings, as in the design.
          if (upcoming && !soon) Container(height: 4, color: c.blue),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: soon ? c.pinkSoft : c.blueSoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          FittedBox(
                            child: Text(
                              dayNumber(booking.date),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: soon ? c.pink : c.blue,
                              ),
                            ),
                          ),
                          FittedBox(
                            child: Text(
                              monthName(booking.date),
                              style: TextStyle(
                                fontSize: 11,
                                color: soon ? c.pink : c.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: status.background,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.text,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: status.color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            bookingTitle(l10n, booking),
                            style: text.titleSmall?.copyWith(fontSize: 16),
                          ),
                          Text(
                            '${weekdayName(booking.date)} ${hourRange(l10n, booking.hour)}',
                            style: text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.bookingNumber, style: text.bodySmall),
                          Text(
                            l10n.bookingNumberValue(
                              arabicDigits(booking.number),
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.dueAtClinic, style: text.bodySmall),
                          Text(
                            amountDue(l10n, booking.price),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (upcoming && booking.status == BookingStatus.confirmed) ...[
                  const Divider(height: 24),
                  if (canChange) ...[
                    _WindowNote(
                      icon: Icons.schedule,
                      title: l10n.canChange,
                      body: l10n.canChangeSub(hours),
                      background: c.greenSoft,
                      color: dark
                          ? const Color(0xFF79D8BC)
                          : const Color(0xFF1F7A61),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            key: Key('change-${booking.id}'),
                            style: FilledButton.styleFrom(
                              backgroundColor: c.blueSoft,
                              foregroundColor: c.blue,
                            ),
                            onPressed: () => context.push(
                              '${Routes.booking}/change/${booking.id}',
                            ),
                            child: Text(l10n.changeBooking),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            key: Key('cancel-${booking.id}'),
                            style: FilledButton.styleFrom(
                              backgroundColor: c.dangerBg,
                              foregroundColor: c.dangerText,
                            ),
                            onPressed: () => _cancel(context, ref, l10n),
                            child: Text(l10n.cancelBooking),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    _WindowNote(
                      icon: Icons.info_outline,
                      title: l10n.lessThan(hours),
                      body: l10n.lessThanSub,
                      background: c.yellowSoft,
                      color: dark
                          ? const Color(0xFFFFD46D)
                          : const Color(0xFF7D5800),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      key: Key('call-clinic-${booking.id}'),
                      onPressed: whatsapp == null
                          ? null
                          : () => ref
                                .read(externalLinksProvider)
                                .openWhatsApp(whatsapp),
                      icon: const Icon(Icons.chat_outlined),
                      label: Text(l10n.callClinic),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowNote extends StatelessWidget {
  const _WindowNote({
    required this.icon,
    required this.title,
    required this.body,
    required this.background,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(body, style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
        ),
      ],
    ),
  );
}
