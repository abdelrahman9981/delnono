import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/clock.dart';
import '../../core/format/arabic_digits.dart';
import '../../features/booking/data/booking_settings.dart';
import '../../features/booking/domain/booking.dart';
import '../../features/booking/domain/clinic_time.dart';
import '../../features/booking/domain/price_preview.dart' show VisitType;
import '../../features/booking/domain/schedule.dart';
import '../../features/booking/presentation/booking_format.dart';
import '../data/dashboard_api.dart';
import '../data/staff_session.dart';
import '../data/today_repository.dart';
import '../router.dart';
import '../widgets/dash_page.dart';
import '../widgets/dash_ui.dart';
import 'register_family_dialog.dart';

/// Today (005 US2, US3; docs/design/dashboard/Today): the day's numbers, the hour strip with places
/// left, every booking and walk-in with its status, and the arrival queue by arrival time with
/// payment per visit (D-06, D-07, FR-049, FR-058).
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  /// The hour the table shows; null for every hour.
  int? _hour;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final clinicId = ref.watch(currentClinicIdProvider);
    if (clinicId == null) return const Center(child: CircularProgressIndicator());
    final now = ref.watch(clockProvider)();
    final date = ClinicTime.dateOf(now);
    final day = (clinicId: clinicId, date: date);
    // Only the clinic's own hours: never the built-in defaults while its settings load.
    final loaded = ref.watch(bookingSettingsProvider(clinicId));
    if (!loaded.hasValue) return const Center(child: CircularProgressIndicator());
    final settings = loaded.value!;
    final bookings = ref.watch(dayBookingsProvider(day)).value ?? const <QueueBooking>[];
    final walkIns = ref.watch(dayWalkInsProvider(day)).value ?? const <WalkIn>[];
    final stopped = ref.watch(walkInsStoppedProvider(day)).value ?? false;
    final api = ref.read(dashboardApiProvider);

    final hours = hoursOf(settings, date);
    int taken(int h) => bookings.where((b) => b.booking.hour == h).length + walkIns.where((w) => w.hour == h).length;
    final hour = hours.contains(_hour) ? _hour : null;

    final queue = <_QueueEntry>[
      for (final b in bookings)
        if (b.arrivedAt != null && (b.statusRaw == 'arrived' || b.statusRaw == 'done')) _QueueEntry.booking(b),
      for (final w in walkIns)
        if (w.arrivedAt != null) _QueueEntry.walkIn(w),
    ]..sort((a, b) => a.arrivedAt.compareTo(b.arrivedAt));

    int count(String status) =>
        bookings.where((b) => b.statusRaw == status).length + walkIns.where((w) => w.status == status).length;
    num cash(Map<String, dynamic>? p) => (p?['cash'] as num?) ?? 0;
    final cashToday = [for (final b in bookings) cash(b.payment), for (final w in walkIns) cash(w.payment)].fold<num>(0, (a, b) => a + b);

    final kpis = TileGrid(
      key: const Key('today-kpis'),
      children: [
        KpiTile(
          label: l10n.dashKpiBookings,
          value: arabicDigits(bookings.length + walkIns.length),
          note: l10n.dashKpiCapacity(arabicDigits(hours.length * settings.capacityPerHour)),
        ),
        KpiTile(label: l10n.dashKpiArrived, value: arabicDigits(count('arrived')), color: toneColors(context, Tone.yellow).$2),
        KpiTile(label: l10n.dashKpiDone, value: arabicDigits(count('done')), color: toneColors(context, Tone.green).$2),
        KpiTile(label: l10n.dashKpiNoShow, value: arabicDigits(count('no_show')), color: Theme.of(context).extension<AppColors>()!.dangerText),
        KpiTile(label: l10n.dashKpiCash, value: arabicDigits(cashToday), unit: l10n.dashEgp, note: l10n.dashKpiCashNote),
      ],
    );

    final strip = KeyedSubtree(
      key: const Key('today-calendar'),
      child: hours.isEmpty
          ? DashCard(child: Text(l10n.dashClosedToday))
          : TileGrid(
              columns: hours.length.clamp(1, 6),
              minTileWidth: 150,
              gap: 10,
              children: [
                for (final h in hours)
                  _HourCard(
                    key: Key('hour-card-$h'),
                    hour: h,
                    taken: taken(h),
                    capacity: settings.capacityPerHour,
                    over: !ClinicTime.startsAt(date, h + 1).isAfter(now),
                    current: !ClinicTime.startsAt(date, h).isAfter(now) && ClinicTime.startsAt(date, h + 1).isAfter(now),
                    selected: hour == h,
                    onTap: () => setState(() => _hour = hour == h ? null : h),
                  ),
              ],
            ),
    );

    final rows = <DashRow>[
      for (final b in bookings)
        if (hour == null || b.booking.hour == hour) _bookingRow(context, b, now),
      for (final w in walkIns)
        if (hour == null || w.hour == hour) _walkInRow(context, w),
    ];
    final table = DashCard(
      key: const Key('today-bookings'),
      title: l10n.dashTodayBookings,
      icon: Icons.event_note_outlined,
      padding: EdgeInsets.zero,
      action: hours.isEmpty
          ? null
          : SegmentSwitch<int?>(
              key: const Key('hour-filter'),
              options: [(null, l10n.dashAllHours), for (final h in hours) (h, hourLabel(l10n, h))],
              value: hour,
              onChanged: (h) => setState(() => _hour = h),
            ),
      child: rows.isEmpty
          ? Padding(padding: const EdgeInsets.all(20), child: Text(l10n.dashNothingYet))
          : DashTable(
              headers: [l10n.dashColNumber, l10n.dashColChild, l10n.labelHour, l10n.dashColVisit, l10n.dashColStatus, l10n.dashColPayment, l10n.dashColAction],
              flex: const [2, 5, 4, 3, 3, 3, 6],
              rows: rows,
            ),
    );

    final queueCard = DashCard(
      key: const Key('today-queue'),
      title: l10n.dashQueue,
      hint: l10n.dashQueueOrder,
      icon: Icons.format_list_numbered_rtl,
      tone: Tone.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (queue.isEmpty) Text(l10n.dashQueueEmpty),
          for (final (i, e) in queue.indexed)
            ActionRow(
              key: Key('queue-${e.id}'),
              leading: InitialAvatar(arabicDigits(i + 1), tone: e.done ? Tone.green : Tone.yellow, size: 32),
              title: e.title(l10n),
              subtitle: e.done
                  ? (e.payment == null ? l10n.dashDoneUnpaid : l10n.dashPaid(arabicDigits((e.payment!['cash'] as num?) ?? 0)))
                  : l10n.dashWaiting,
              actions: [
                if (!e.done)
                  FilledButton(
                    key: Key('done-${e.id}'),
                    onPressed: () => runAction(context, () => api.call('queueAction', {'action': 'done', ...e.ref})),
                    child: Text(l10n.dashKpiDone),
                  ),
                OutlinedButton(
                  key: Key('pay-${e.id}'),
                  onPressed: () => showDialog<void>(context: context, builder: (_) => _PaymentDialog(entry: e)),
                  child: Text(l10n.dashRecordPayment),
                ),
              ],
            ),
        ],
      ),
    );

    return DashPage(
      title: l10n.dashNavToday,
      subtitle: [
        dayLabel(date),
        if (hours.isNotEmpty) l10n.hourRange(hourLabel(l10n, hours.first), hourLabel(l10n, hours.last + 1)),
      ].join(' · '),
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
        kpis,
        const SizedBox(height: 16),
        strip,
        const SizedBox(height: 16),
        table,
        const SizedBox(height: 16),
        queueCard,
      ],
    );
  }

  DashRow _bookingRow(BuildContext context, QueueBooking item, DateTime now) {
    final l10n = AppLocalizations.of(context);
    final b = item.booking;
    final api = ref.read(dashboardApiProvider);
    final isDoctor = ref.read(staffSessionProvider).value?.isDoctor ?? false;
    final hourOver = !ClinicTime.startsAt(b.date, b.hour + 1).isAfter(now);
    Future<void> act(String action) async {
      await runAction(context, () => api.call('queueAction', {'action': action, 'bookingId': b.id}));
    }

    final childId = b.children.firstOrNull?.childId;
    return DashRow(
      key: Key('booking-row-${b.id}'),
      cells: [
        Text(arabicDigits(b.number), style: const TextStyle(fontWeight: FontWeight.w700)),
        Row(children: [
          InitialAvatar(b.children.firstOrNull?.name ?? '', size: 32),
          const SizedBox(width: 8),
          Expanded(child: Text(b.children.map((c) => c.name).join(l10n.listSeparator), style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
        Text(hourRange(l10n, b.hour)),
        Text(_visitLabel(l10n, b)),
        _statusPill(l10n, item.statusRaw),
        _paymentCell(l10n, item.payment),
        Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          if (item.statusRaw == 'confirmed')
            FilledButton.tonal(key: Key('arrive-${b.id}'), onPressed: () => act('arrive'), child: Text(l10n.dashMarkArrived)),
          if (item.statusRaw == 'confirmed' && hourOver)
            OutlinedButton(key: Key('no-show-${b.id}'), onPressed: () => act('noShow'), child: Text(l10n.statusNoShow)),
          if (isDoctor && item.statusRaw != 'confirmed')
            TextButton(key: Key('undo-${b.id}'), onPressed: () => act('undo'), child: Text(l10n.dashUndo)),
          if (childId != null)
            TextButton(
              key: Key('file-${b.id}'),
              onPressed: () => context.go('${DashRoutes.children}/$childId'),
              child: Text(l10n.dashOpenFile),
            ),
          if (item.statusRaw == 'confirmed')
            PopupMenuButton<String>(
              key: Key('booking-menu-${b.id}'),
              icon: const Icon(Icons.more_horiz),
              onSelected: (v) async {
                if (v == 'move') {
                  await showDialog<void>(context: context, builder: (_) => MoveBookingDialog(booking: b));
                } else if (v == 'cancel') {
                  await runAction(
                    context,
                    () => api.call('staffBookingAction', {'action': 'cancel', 'bookingId': b.id}),
                    done: l10n.bookingCancelled,
                  );
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(key: Key('move-${b.id}'), value: 'move', child: Text(l10n.dashMoveForFamily)),
                PopupMenuItem(value: 'cancel', child: Text(l10n.dashCancelForFamily)),
              ],
            ),
        ]),
      ],
    );
  }

  DashRow _walkInRow(BuildContext context, WalkIn w) {
    final l10n = AppLocalizations.of(context);
    return DashRow(
      key: Key('walkin-${w.id}'),
      cells: [
        const Text('—'),
        Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(w.children.join(l10n.listSeparator), style: const TextStyle(fontWeight: FontWeight.w600)),
          StatusPill(l10n.dashWalkIn, PillKind.walkIn, dot: false),
        ]),
        Text(hourRange(l10n, w.hour)),
        Text(w.familyName),
        _statusPill(l10n, w.status),
        _paymentCell(l10n, w.payment),
        // A walk-in family without files can be registered here (009 FR-003).
        TextButton(
          key: Key('register-walkin-${w.id}'),
          onPressed: () => showDialog<List<String>>(
            context: context,
            builder: (_) => RegisterFamilyDialog(phone: w.phone, fullName: w.familyName, childNames: w.children),
          ),
          child: Text(l10n.dashRegisterWalkIn),
        ),
      ],
    );
  }
}

String _visitLabel(AppLocalizations l10n, Booking b) {
  if (b.visitType == VisitType.vaccineOnly) return l10n.visitTypeVaccine;
  return b.price.vaccines.isEmpty ? l10n.visitTypeVisit : '${l10n.visitTypeVisit} + ${l10n.visitTypeVaccine}';
}

Widget _statusPill(AppLocalizations l10n, String status) => switch (status) {
  'arrived' => StatusPill(l10n.statusArrived, PillKind.arrived),
  'done' => StatusPill(l10n.statusDone, PillKind.done),
  'no_show' => StatusPill(l10n.statusNoShow, PillKind.noShow),
  _ => StatusPill(l10n.statusConfirmed, PillKind.confirmed),
};

Widget _paymentCell(AppLocalizations l10n, Map<String, dynamic>? p) {
  if (p == null) return const Text('—');
  if (p['covered'] == true) return StatusPill(l10n.dashPayPackage, PillKind.ok, dot: false);
  return Text(l10n.dashPayCash(arabicDigits((p['cash'] as num?) ?? 0)));
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

/// One hour in the strip (`.hour`): its range, places left, a bar, "over" or "now".
class _HourCard extends StatelessWidget {
  const _HourCard({
    super.key,
    required this.hour,
    required this.taken,
    required this.capacity,
    required this.over,
    required this.current,
    required this.selected,
    required this.onTap,
  });

  final int hour;
  final int taken;
  final int capacity;
  final bool over;
  final bool current;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final left = (capacity - taken).clamp(0, capacity);
    return Material(
      color: selected ? c.blueSoft : c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: current ? c.blue : c.border, width: current ? 2 : 1),
      ),
      child: InkWell(
        key: Key('hour-row-$hour'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(hourRange(l10n, hour), style: const TextStyle(fontWeight: FontWeight.w700))),
              if (current)
                StatusPill(l10n.dashHourNow, PillKind.info, dot: false)
              else if (over)
                Text(l10n.dashHourOver, style: TextStyle(fontSize: 12, color: c.muted)),
            ]),
            const SizedBox(height: 8),
            Text(
              left == 0 ? l10n.hourFull : l10n.placesLeft(arabicDigits(left), arabicDigits(capacity)),
              style: TextStyle(fontSize: 12, color: left == 0 ? c.dangerText : c.muted),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: capacity == 0 ? 1 : (taken / capacity).clamp(0, 1),
                minHeight: 6,
                backgroundColor: dark ? c.border : Dash.barTrack,
                color: left == 0 ? c.pink : c.blue,
              ),
            ),
          ]),
        ),
      ),
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

/// Moves a booking to another day or hour of its clinic for the family (005 FR-009). Capacity, hours
/// and family limits apply on the server; the cancel window does not. Children, vaccines and fixed
/// prices stay as booked.
class MoveBookingDialog extends ConsumerStatefulWidget {
  const MoveBookingDialog({super.key, required this.booking});

  final Booking booking;

  @override
  ConsumerState<MoveBookingDialog> createState() => _MoveBookingDialogState();
}

class _MoveBookingDialogState extends ConsumerState<MoveBookingDialog> {
  String? _date;
  int? _hour;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final b = widget.booking;
    final clinicId = b.clinicId ?? ref.watch(currentClinicIdProvider) ?? '';
    final loaded = ref.watch(bookingSettingsProvider(clinicId));
    if (!loaded.hasValue) return const AlertDialog(content: SizedBox(height: 80, child: Center(child: CircularProgressIndicator())));
    final settings = loaded.value!;
    final now = ref.watch(clockProvider)();
    final needsVaccineDay = b.children.any((c) => c.vaccines.isNotEmpty);
    final days = bookableDays(settings, now, vaccines: needsVaccineDay);
    final date = _date ?? b.date;
    final hours = days.contains(date) ? openHours(settings, date, now) : const <int>[];
    final hour = hours.contains(_hour ?? b.hour) ? (_hour ?? b.hour) : hours.firstOrNull;

    return AlertDialog(
      title: Text(l10n.dashMoveForFamily),
      content: SizedBox(
        width: 400,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${l10n.bookingNumberValue(arabicDigits(b.number))} · ${b.children.map((c) => c.name).join(l10n.listSeparator)}'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            key: const Key('move-date'),
            initialValue: days.contains(date) ? date : null,
            items: [for (final d in days) DropdownMenuItem(value: d, child: Text(dayLabel(d)))],
            onChanged: (d) => setState(() {
              _date = d;
              _hour = null;
            }),
            decoration: InputDecoration(labelText: l10n.dashDate),
          ),
          DropdownButtonFormField<int>(
            isExpanded: true,
            key: ValueKey('move-hour-$date'),
            initialValue: hour,
            items: [for (final h in hours) DropdownMenuItem(value: h, child: Text(hourRange(l10n, h)))],
            onChanged: (h) => setState(() => _hour = h),
            decoration: InputDecoration(labelText: l10n.labelHour),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.dashClose)),
        FilledButton(
          key: const Key('move-save'),
          onPressed: hour == null || (date == b.date && hour == b.hour)
              ? null
              : () async {
                  final ok = await runAction(
                    context,
                    () => ref.read(dashboardApiProvider).call('staffBookingAction', {
                      'action': 'change',
                      'bookingId': b.id,
                      'selection': {
                        'visitType': b.visitType == VisitType.vaccineOnly ? 'vaccine_only' : 'visit',
                        'date': date,
                        'hour': hour,
                        'children': [for (final c in b.children) {'childId': c.childId, 'vaccines': c.vaccines}],
                      },
                    }),
                    done: l10n.bookingChanged,
                  );
                  if (ok && context.mounted) Navigator.pop(context);
                },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
