import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/route_guard.dart';
import '../../../app/theme.dart';
import '../../../core/format/arabic_digits.dart';
import '../../registration/data/guardian_repository.dart';
import '../data/bookings_repository.dart';
import '../domain/booking.dart';
import 'booking_format.dart';

/// Booking success (`/booking/done/:id`, docs/design/figma/booking-success.jpg).
class BookingSuccessScreen extends ConsumerWidget {
  const BookingSuccessScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final booking = ref.watch(bookingByIdProvider(bookingId));
    final guardian = ref.watch(guardianProvider).value;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final green = dark ? const Color(0xFF79D8BC) : const Color(0xFF1F7A61);

    if (booking == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final firstName = guardian?.fullName.split(' ').first ?? '';
    final names = joinNames(l10n, booking.children.map((ch) => ch.name));

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(label, style: text.bodyMedium?.copyWith(color: c.muted))),
              const SizedBox(width: 8),
              Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
            ],
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 32, 18, 28),
          children: [
            Center(
              child: Container(
                width: 136,
                height: 136,
                decoration: BoxDecoration(shape: BoxShape.circle, color: c.greenSoft),
                alignment: Alignment.center,
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: c.green,
                  child: const Icon(Icons.check, color: Colors.white, size: 36),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.successTag, textAlign: TextAlign.center, style: TextStyle(color: c.blue, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(l10n.successTitle(firstName), textAlign: TextAlign.center, style: text.headlineMedium),
            const SizedBox(height: 4),
            Text(l10n.successWaiting(names), textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: c.muted)),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: c.blueSoft, borderRadius: BorderRadius.circular(14)),
                          child: Icon(Icons.calendar_today_outlined, color: c.blue, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.bookingNumber, style: text.bodySmall),
                              Text(
                                l10n.bookingNumberValue(arabicDigits(booking.number)),
                                key: const Key('booking-number'),
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        _Pill(text: l10n.statusConfirmed, color: green, background: c.greenSoft),
                      ],
                    ),
                    const Divider(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [Text(l10n.labelDay, style: text.bodySmall), Text(dayLabel(booking.date), style: const TextStyle(fontWeight: FontWeight.w700))],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [Text(l10n.labelHour, style: text.bodySmall), Text(hourRange(l10n, booking.hour), style: const TextStyle(fontWeight: FontWeight.w700))],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    row(l10n.labelVisit, bookingTitle(l10n, booking)),
                    row(l10n.summaryChildren, names),
                    row(l10n.payAtClinic, amountDue(l10n, booking.price)),
                    if (booking.price.hasHiddenPrices) Text(l10n.totalExcludesHidden, style: text.bodySmall),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: c.blueSoft, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 18, color: c.blue),
                          const SizedBox(width: 8),
                          Expanded(child: Text(l10n.arrivalOrderInHour, style: TextStyle(fontSize: 12, color: c.blue))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const Key('view-my-bookings'),
              onPressed: () => context.go('${Routes.booking}/mine'),
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(l10n.viewMyBookings),
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => context.go(Routes.home), child: Text(l10n.backHome)),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color, required this.background});

  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      );
}

/// Status pill text and colours, shared with My bookings.
({String text, Color color, Color background}) statusStyle(BuildContext context, BookingStatus s, {bool soon = false}) {
  final l10n = AppLocalizations.of(context);
  final c = Theme.of(context).extension<AppColors>()!;
  final dark = Theme.of(context).brightness == Brightness.dark;
  final green = dark ? const Color(0xFF79D8BC) : const Color(0xFF1F7A61);
  final pink = dark ? const Color(0xFFFFB4C6) : const Color(0xFFB04A65);
  return switch (s) {
    BookingStatus.confirmed when soon => (text: l10n.statusSoon, color: pink, background: c.pinkSoft),
    BookingStatus.confirmed => (text: l10n.statusConfirmed, color: green, background: c.greenSoft),
    BookingStatus.arrived => (text: l10n.statusArrived, color: c.blueDeep, background: c.blueSoft),
    BookingStatus.done => (text: l10n.statusDone, color: c.muted, background: c.border),
    BookingStatus.cancelled => (text: l10n.statusCancelled, color: c.dangerText, background: c.dangerBg),
    BookingStatus.noShow => (text: l10n.statusNoShow, color: c.muted, background: c.border),
  };
}
