import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/clock.dart';
import '../../core/format/arabic_digits.dart';
import '../../features/booking/data/booking_settings.dart';
import '../../features/booking/domain/clinic_time.dart';
import '../../features/booking/domain/schedule.dart';
import '../../features/booking/presentation/booking_format.dart';
import '../data/dashboard_api.dart';
import '../data/staff_session.dart';
import '../data/today_repository.dart';
import '../widgets/dash_page.dart';

/// Today (005 US2, US3): the hour calendar with places left, the arrival queue by arrival time,
/// walk-ins, stopping walk-ins, payment per visit and package sales (D-06, D-07, FR-049, FR-058).
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final clinicId = ref.watch(currentClinicIdProvider);
    if (clinicId == null) return const Center(child: CircularProgressIndicator());
    final now = ref.watch(clockProvider)();
    final date = ClinicTime.dateOf(now);
    final day = (clinicId: clinicId, date: date);
    final settings = ref.watch(bookingSettingsProvider(clinicId)).value ?? const BookingSettings();
    final bookings = ref.watch(dayBookingsProvider(day)).value ?? const <QueueBooking>[];
    final walkIns = ref.watch(dayWalkInsProvider(day)).value ?? const <WalkIn>[];
    final stopped = ref.watch(walkInsStoppedProvider(day)).value ?? false;
    final api = ref.read(dashboardApiProvider);

    final hours = hoursOf(settings, date);
    int taken(int h) => bookings.where((b) => b.booking.hour == h).length + walkIns.where((w) => w.hour == h).length;

    final queue = <_QueueEntry>[
      for (final b in bookings)
        if (b.arrivedAt != null && (b.statusRaw == 'arrived' || b.statusRaw == 'done')) _QueueEntry.booking(b),
      for (final w in walkIns)
        if (w.arrivedAt != null) _QueueEntry.walkIn(w),
    ]..sort((a, b) => a.arrivedAt.compareTo(b.arrivedAt));

    final calendar = Card(
      key: const Key('today-calendar'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.dashCalendar, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (hours.isEmpty) Text(l10n.dashClosedToday),
            for (final h in hours) ...[
              _HourHeader(hour: h, taken: taken(h), capacity: settings.capacityPerHour),
              for (final b in bookings.where((b) => b.booking.hour == h)) _BookingRow(item: b, now: now),
              for (final w in walkIns.where((w) => w.hour == h))
                ListTile(
                  dense: true,
                  key: Key('walkin-${w.id}'),
                  leading: const Icon(Icons.directions_walk),
                  title: Text('${w.familyName} · ${w.children.join(l10n.listSeparator)}'),
                  subtitle: Text(l10n.dashWalkIn),
                ),
              const Divider(),
            ],
          ],
        ),
      ),
    );

    final queueCard = Card(
      key: const Key('today-queue'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.dashQueue, style: Theme.of(context).textTheme.titleMedium),
            Text(l10n.dashQueueOrder, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            if (queue.isEmpty) Text(l10n.dashQueueEmpty),
            for (final (i, e) in queue.indexed)
              ActionRow(
                key: Key('queue-${e.id}'),
                leading: CircleAvatar(child: Text(arabicDigits(i + 1))),
                title: e.title(l10n),
                subtitle: e.done
                    ? (e.payment == null
                          ? l10n.dashDoneUnpaid
                          : l10n.dashPaid(arabicDigits((e.payment!['cash'] as num?) ?? 0)))
                    : l10n.dashWaiting,
                actions: [
                  if (!e.done)
                    FilledButton(
                      key: Key('done-${e.id}'),
                      onPressed: () => runAction(context, () => api.call('queueAction', {'action': 'done', ...e.ref})),
                      child: Text(l10n.dashMarkDone),
                    ),
                  OutlinedButton(
                    key: Key('pay-${e.id}'),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => _PaymentDialog(entry: e),
                    ),
                    child: Text(l10n.dashRecordPayment),
                  ),
                ],
              ),
          ],
        ),
      ),
    );

    return DashPage(
      title: l10n.dashTodayTitle(dayLabel(date)),
      actions: [
        FilterChip(
          key: const Key('stop-walk-ins'),
          label: Text(l10n.dashStopWalkIns),
          selected: stopped,
          onSelected: (v) => runAction(
            context,
            () => api.call('setWalkInsStopped', {'clinicId': clinicId, 'date': date, 'stopped': v}),
          ),
        ),
        FilledButton.icon(
          key: const Key('add-walk-in'),
          onPressed: stopped
              ? null
              : () => showDialog<void>(
                  context: context,
                  builder: (_) => _WalkInDialog(clinicId: clinicId, hours: openHoursNow(settings, date, now)),
                ),
          icon: const Icon(Icons.person_add_alt),
          label: Text(l10n.dashAddWalkIn),
        ),
      ],
      children: [
        LayoutBuilder(
          builder: (context, box) {
            if (box.maxWidth < 900) return Column(children: [queueCard, const SizedBox(height: 12), calendar]);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: calendar),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: queueCard),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Hours of today a walk-in can still join: working hours that have not ended.
List<int> openHoursNow(BookingSettings s, String date, DateTime now) =>
    hoursOf(s, date).where((h) => ClinicTime.startsAt(date, h + 1).isAfter(now)).toList();

class _QueueEntry {
  _QueueEntry.booking(QueueBooking b)
    : id = b.booking.id,
      ref = {'bookingId': b.booking.id},
      arrivedAt = b.arrivedAt!,
      done = b.statusRaw == 'done',
      payment = b.payment,
      names = b.booking.children.map((c) => c.name).toList(),
      number = b.booking.number,
      total = b.booking.price.total,
      guardianUid = null;

  _QueueEntry.walkIn(WalkIn w)
    : id = w.id,
      ref = {'walkInId': w.id},
      arrivedAt = w.arrivedAt!,
      done = w.status == 'done',
      payment = w.payment,
      names = w.children,
      number = null,
      total = null,
      guardianUid = null;

  final String id;
  final Map<String, Object> ref;
  final DateTime arrivedAt;
  final bool done;
  final Map<String, dynamic>? payment;
  final List<String> names;
  final int? number;
  final int? total;
  final String? guardianUid;

  String title(AppLocalizations l10n) => [
    if (number != null) l10n.bookingNumberValue(arabicDigits(number!)) else l10n.dashWalkIn,
    names.join(l10n.listSeparator),
  ].join(' · ');
}

class _HourHeader extends StatelessWidget {
  const _HourHeader({required this.hour, required this.taken, required this.capacity});

  final int hour;
  final int taken;
  final int capacity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    final left = (capacity - taken).clamp(0, capacity);
    return Padding(
      key: Key('hour-row-$hour'),
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(hourRange(l10n, hour), style: Theme.of(context).textTheme.titleSmall)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: left == 0 ? c.dangerBg : c.blueSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              left == 0 ? l10n.hourFull : l10n.placesLeft(arabicDigits(left), arabicDigits(capacity)),
              style: TextStyle(fontSize: 12, color: left == 0 ? c.dangerText : c.blue),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingRow extends ConsumerWidget {
  const _BookingRow({required this.item, required this.now});

  final QueueBooking item;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final b = item.booking;
    final api = ref.read(dashboardApiProvider);
    final staff = ref.watch(staffSessionProvider).value;
    final hourOver = !ClinicTime.startsAt(b.date, b.hour + 1).isAfter(now);
    final status = switch (item.statusRaw) {
      'arrived' => l10n.statusArrived,
      'done' => l10n.statusDone,
      'no_show' => l10n.statusNoShow,
      _ => l10n.statusConfirmed,
    };
    Future<void> act(String action) async {
      await runAction(context, () => api.call('queueAction', {'action': action, 'bookingId': b.id}));
    }

    return ActionRow(
      key: Key('booking-row-${b.id}'),
      title:
          '${l10n.bookingNumberValue(arabicDigits(b.number))} · ${b.children.map((c) => c.name).join(l10n.listSeparator)}',
      subtitle: '${bookingTitle(l10n, b)} · $status',
      actions: [
        if (item.statusRaw == 'confirmed')
          FilledButton.tonal(
            key: Key('arrive-${b.id}'),
            onPressed: () => act('arrive'),
            child: Text(l10n.dashMarkArrived),
          ),
        if (item.statusRaw == 'confirmed' && hourOver)
          OutlinedButton(key: Key('no-show-${b.id}'), onPressed: () => act('noShow'), child: Text(l10n.statusNoShow)),
        if (staff?.isDoctor == true && item.statusRaw != 'confirmed')
          TextButton(key: Key('undo-${b.id}'), onPressed: () => act('undo'), child: Text(l10n.dashUndo)),
        if (item.statusRaw == 'confirmed')
          PopupMenuButton<String>(
            key: Key('booking-menu-${b.id}'),
            onSelected: (v) async {
              if (v == 'cancel') {
                await runAction(
                  context,
                  () => api.call('staffBookingAction', {'action': 'cancel', 'bookingId': b.id}),
                  done: l10n.bookingCancelled,
                );
              }
            },
            itemBuilder: (_) => [PopupMenuItem(value: 'cancel', child: Text(l10n.dashCancelForFamily))],
          ),
      ],
    );
  }
}

class _PaymentDialog extends ConsumerStatefulWidget {
  const _PaymentDialog({required this.entry});

  final _QueueEntry entry;

  @override
  ConsumerState<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<_PaymentDialog> {
  late final _cash = TextEditingController(
    text: '${(widget.entry.payment?['cash'] as num?) ?? widget.entry.total ?? 0}',
  );
  late bool _covered = widget.entry.payment?['covered'] == true;

  @override
  void dispose() {
    _cash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.dashRecordPayment),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('payment-cash'),
            controller: _cash,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.dashCashAmount),
          ),
          CheckboxListTile(
            key: const Key('payment-covered'),
            value: _covered,
            onChanged: (v) => setState(() => _covered = v ?? false),
            title: Text(l10n.dashCoveredByPackage),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.dashClose)),
        FilledButton(
          key: const Key('payment-save'),
          onPressed: () async {
            final ok = await runAction(
              context,
              () => ref.read(dashboardApiProvider).call('recordPayment', {
                ...widget.entry.ref,
                'cash': int.tryParse(_cash.text.trim()) ?? 0,
                'covered': _covered,
              }),
              done: l10n.dashPaymentSaved,
            );
            if (ok && context.mounted) Navigator.pop(context);
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _WalkInDialog extends ConsumerStatefulWidget {
  const _WalkInDialog({required this.clinicId, required this.hours});

  final String clinicId;
  final List<int> hours;

  @override
  ConsumerState<_WalkInDialog> createState() => _WalkInDialogState();
}

class _WalkInDialogState extends ConsumerState<_WalkInDialog> {
  final _family = TextEditingController();
  final _phone = TextEditingController();
  final _children = TextEditingController();
  late int? _hour = widget.hours.firstOrNull;
  bool _vaccineOnly = false;

  @override
  void dispose() {
    _family.dispose();
    _phone.dispose();
    _children.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.dashAddWalkIn),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.hours.isEmpty) Text(l10n.dashNoHoursLeft),
            DropdownButtonFormField<int>(
              isExpanded: true,
              key: const Key('walk-in-hour'),
              initialValue: _hour,
              items: [for (final h in widget.hours) DropdownMenuItem(value: h, child: Text(hourRange(l10n, h)))],
              onChanged: (h) => setState(() => _hour = h),
              decoration: InputDecoration(labelText: l10n.labelHour),
            ),
            TextField(
              key: const Key('walk-in-family'),
              controller: _family,
              decoration: InputDecoration(labelText: l10n.dashFamilyName),
            ),
            TextField(
              key: const Key('walk-in-phone'),
              controller: _phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: l10n.dashPhone),
            ),
            TextField(
              key: const Key('walk-in-children'),
              controller: _children,
              decoration: InputDecoration(labelText: l10n.dashChildrenNames, helperText: l10n.dashChildrenNamesHelp),
            ),
            SwitchListTile(
              value: _vaccineOnly,
              onChanged: (v) => setState(() => _vaccineOnly = v),
              title: Text(l10n.visitTypeVaccine),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.dashClose)),
        FilledButton(
          key: const Key('walk-in-save'),
          onPressed: _hour == null
              ? null
              : () async {
                  final names = _children.text.split(RegExp('[،,]')).map((s) => s.trim()).where((s) => s.isNotEmpty);
                  final ok = await runAction(
                    context,
                    () => ref.read(dashboardApiProvider).call('addWalkIn', {
                      'clinicId': widget.clinicId,
                      'hour': _hour,
                      'familyName': _family.text.trim(),
                      'phone': _phone.text.trim(),
                      'children': [
                        for (final n in names) {'name': n},
                      ],
                      'visitType': _vaccineOnly ? 'vaccine_only' : 'visit',
                    }),
                    done: l10n.dashWalkInAdded,
                  );
                  if (ok && context.mounted) Navigator.pop(context);
                },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
