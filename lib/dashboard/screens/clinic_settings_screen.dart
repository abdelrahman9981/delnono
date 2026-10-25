import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/clock.dart';
import '../../core/settings/settings_repository.dart';
import '../../features/booking/data/booking_settings.dart';
import '../../features/booking/domain/clinic_time.dart';
import '../../features/booking/presentation/booking_format.dart';
import '../../features/child_profile/data/vaccine_schedule_repository.dart';
import '../data/dashboard_api.dart';
import '../data/staff_session.dart';
import '../widgets/dash_page.dart';
import '../widgets/dash_ui.dart';

/// The current clinic document as stored (contact fields the booking settings do not carry).
final clinicDocProvider = StreamProvider.family<Map<String, dynamic>, String>(
  (ref, id) => ref.watch(firestoreProvider).doc('clinics/$id').snapshots().map((s) => s.data() ?? const {}),
);

/// Adds [range] to a day's ranges, merging overlapping or touching ones, ascending.
List<(int, int)> addRange(List<(int, int)> ranges, (int, int) range) {
  final all = [...ranges, range]..sort((a, b) => a.$1.compareTo(b.$1));
  final out = <(int, int)>[];
  for (final r in all) {
    if (out.isNotEmpty && r.$1 <= out.last.$2) {
      final last = out.removeLast();
      out.add((last.$1, r.$2 > last.$2 ? r.$2 : last.$2));
    } else {
      out.add(r);
    }
  }
  return out;
}

/// The clinic's contact, prices, hours, holidays and vaccine offers (005 US5, D-44, D-45;
/// docs/design/dashboard/Clinic). Hours are picked as ranges and holidays from a date picker, never
/// typed; changes wait in the sticky save bar. The secretary edits her clinic; the doctor the clinic
/// picked in the top bar.
class ClinicSettingsScreen extends ConsumerStatefulWidget {
  const ClinicSettingsScreen({super.key});

  @override
  ConsumerState<ClinicSettingsScreen> createState() => _ClinicSettingsScreenState();
}

class _Offer {
  _Offer({required this.offered, required this.price, required this.shown});

  bool offered;
  final TextEditingController price;
  bool shown;
}

class _ClinicSettingsScreenState extends ConsumerState<ClinicSettingsScreen> {
  String? _loadedFor;
  final _c = <String, TextEditingController>{};
  var _hours = <int, List<(int, int)>>{};
  var _holidays = <String>[];
  var _vaccineDays = <int>{};
  final _offers = <String, _Offer>{};
  String _saved = '';
  bool _busy = false;

  TextEditingController _ctl(String k) => _c.putIfAbsent(k, () => TextEditingController()..addListener(_changed));

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [..._c.values, for (final o in _offers.values) o.price]) {
      c.dispose();
    }
    super.dispose();
  }

  void _load(String clinicId, Map<String, dynamic> doc, BookingSettings s, Map<String, VaccineInfo> catalogue) {
    if (_loadedFor == clinicId || doc.isEmpty) return;
    _loadedFor = clinicId;
    for (final k in ['address', 'phone', 'whatsapp']) {
      _ctl(k).text = '${doc[k] ?? ''}';
    }
    _ctl('visitPrice').text = '${s.visitPrice}';
    _ctl('packagePrice').text = '${doc['packagePrice'] ?? 0}';
    _ctl('packageMonths').text = '${doc['packageMonths'] ?? 12}';
    _ctl('capacityPerHour').text = '${s.capacityPerHour}';
    _ctl('cancelWindowHours').text = '${s.cancelWindowHours}';
    _holidays = [...s.holidays]..sort();
    _hours = {
      for (var d = 1; d <= 7; d++) d: [for (final r in s.workingHours[d] ?? const []) (r.from, r.to)],
    };
    _vaccineDays = {...s.vaccineWeekdays};
    for (final o in _offers.values) {
      o.price.dispose();
    }
    _offers.clear();
    for (final v in catalogue.values) {
      final o = s.vaccinePrices[v.id];
      _offers[v.id] = _Offer(
        offered: o?.offered ?? false,
        price: TextEditingController(text: '${o?.price ?? 0}')..addListener(_changed),
        shown: o?.shown ?? true,
      );
    }
    _saved = jsonEncode(_fields());
  }

  Map<String, Object> _fields() {
    int n(String k) => int.tryParse(_ctl(k).text.trim()) ?? 0;
    return {
      'address': _ctl('address').text.trim(),
      'phone': _ctl('phone').text.trim(),
      'whatsapp': _ctl('whatsapp').text.trim(),
      'visitPrice': n('visitPrice'),
      'packagePrice': n('packagePrice'),
      'packageMonths': n('packageMonths'),
      'capacityPerHour': n('capacityPerHour'),
      'cancelWindowHours': n('cancelWindowHours'),
      'holidays': [..._holidays],
      'workingHours': {
        for (final e in _hours.entries)
          '${e.key}': [for (final (from, to) in e.value) {'from': from, 'to': to}],
      },
      'vaccineWeekdays': _vaccineDays.toList()..sort(),
      'vaccinePrices': {
        for (final e in _offers.entries)
          e.key: {'offered': e.value.offered, 'price': int.tryParse(e.value.price.text.trim()) ?? 0, 'shown': e.value.shown},
      },
    };
  }

  Future<void> _save(String clinicId) async {
    final l10n = AppLocalizations.of(context);
    final fields = _fields();
    setState(() => _busy = true);
    final ok = await runAction(
      context,
      () => ref.read(dashboardApiProvider).call('updateClinic', {'clinicId': clinicId, 'fields': fields}),
      done: l10n.dashSaved,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _saved = jsonEncode(fields);
    });
  }

  void _discard() => setState(() => _loadedFor = null);

  Future<void> _addRange(int day) async {
    final last = _hours[day]?.lastOrNull;
    final from = last == null ? 17 : (last.$2 >= 23 ? 22 : last.$2 + 1);
    final range = await pickTimeRange(context, from: from, to: (from + 4).clamp(from + 1, 24));
    if (range != null) setState(() => _hours[day] = addRange(_hours[day] ?? const [], range));
  }

  Future<void> _editRange(int day, int index) async {
    final (from, to) = _hours[day]![index];
    final range = await pickTimeRange(context, from: from, to: to);
    if (range == null) return;
    setState(() {
      final rest = [..._hours[day]!]..removeAt(index);
      _hours[day] = addRange(rest, range);
    });
  }

  Future<void> _addHoliday() async {
    final today = ClinicTime.asDate(ClinicTime.dateOf(ref.read(clockProvider)()));
    final picked = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
      initialDate: today,
    );
    if (picked == null) return;
    final date = DateFormat('yyyy-MM-dd').format(picked);
    if (!_holidays.contains(date)) setState(() => _holidays = [..._holidays, date]..sort());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    final clinicId = ref.watch(currentClinicIdProvider);
    if (clinicId == null) return const Center(child: CircularProgressIndicator());
    final doc = ref.watch(clinicDocProvider(clinicId)).value ?? const <String, dynamic>{};
    final settings = ref.watch(bookingSettingsProvider(clinicId)).value;
    final catalogue = ref.watch(vaccineCatalogueProvider).value ?? const <String, VaccineInfo>{};
    if (settings == null || doc.isEmpty) return const Center(child: CircularProgressIndicator());
    _load(clinicId, doc, settings, catalogue);
    final dirty = jsonEncode(_fields()) != _saved;
    // ISO weekday names, week from Saturday (5 Jan 2026 is a Monday).
    String day(int iso) => DateFormat('EEEE', 'ar').format(DateTime(2026, 1, 4 + iso));

    Widget field(String k, String label, {bool number = false, bool ltr = false, String? unit, double width = 260}) => SizedBox(
      width: width,
      child: DashField(
        label: label,
        child: TextField(
          key: Key('clinic-$k'),
          controller: _ctl(k),
          keyboardType: number ? TextInputType.number : null,
          textDirection: ltr ? TextDirection.ltr : null,
          decoration: dashInput(context, unit: unit),
        ),
      ),
    );
    Widget fields(List<Widget> children) => Wrap(spacing: 16, runSpacing: 14, children: children);

    final dayRows = <Widget>[
      for (final d in const [6, 7, 1, 2, 3, 4, 5])
        Container(
          key: Key('hours-$d'),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
          child: Row(
            children: [
              SizedBox(width: 110, child: Text(day(d), style: const TextStyle(fontWeight: FontWeight.w600))),
              const SizedBox(width: 12),
              Expanded(child: Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                if ((_hours[d] ?? const []).isEmpty)
                  Text(l10n.dashDayClosed, key: Key('closed-$d'), style: TextStyle(color: c.muted)),
                for (final (i, (from, to)) in (_hours[d] ?? const <(int, int)>[]).indexed)
                  TimeChip(
                    key: Key('range-$d-$i'),
                    label: l10n.hourRange(hourLabel(l10n, from), hourLabel(l10n, to)),
                    onTap: () => _editRange(d, i),
                    onRemove: () => setState(() => _hours[d] = [..._hours[d]!]..removeAt(i)),
                  ),
                AddChip(key: Key('add-range-$d'), label: l10n.dashAddRange, onTap: () => _addRange(d)),
              ])),
              const SizedBox(width: 12),
              SizedBox(
                width: 150,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Switch(
                    key: Key('vaccine-day-$d'),
                    value: _vaccineDays.contains(d),
                    onChanged: (v) => setState(() => v ? _vaccineDays.add(d) : _vaccineDays.remove(d)),
                  ),
                  const SizedBox(width: 6),
                  Flexible(child: Text(l10n.dashVaccineDay, style: const TextStyle(fontSize: 13))),
                ]),
              ),
            ],
          ),
        ),
    ];

    final offers = <Widget>[
      for (final v in catalogue.values.where((v) => v.active))
        if (_offers[v.id] case final o?)
          Container(
            key: Key('offer-${v.id}'),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 240,
                  child: Row(children: [
                    Switch(
                      key: Key('offered-${v.id}'),
                      value: o.offered,
                      onChanged: (x) => setState(() => o.offered = x),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(v.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                  ]),
                ),
                SizedBox(
                  width: 150,
                  child: TextField(
                    key: Key('price-${v.id}'),
                    controller: o.price,
                    enabled: o.offered,
                    keyboardType: TextInputType.number,
                    decoration: dashInput(context, unit: l10n.dashEgp),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: Row(children: [
                    Switch(
                      key: Key('shown-${v.id}'),
                      value: o.shown,
                      onChanged: o.offered ? (x) => setState(() => o.shown = x) : null,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        o.shown ? l10n.dashShownToGuardian : '${l10n.dashShownToGuardian} · «${l10n.dashPriceAtClinic}»',
                        style: TextStyle(fontSize: 13, color: o.shown ? null : c.muted),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
    ];

    return DashPage(
      title: l10n.dashNavClinic,
      subtitle: '${doc['name'] ?? ''}',
      bottom: SaveBar(dirty: dirty, busy: _busy, onSave: () => _save(clinicId), onDiscard: _discard),
      children: [
        DashCard(
          title: l10n.dashClinicContact,
          icon: Icons.store_mall_directory_outlined,
          child: fields([
            field('address', l10n.labelAddress, width: 536),
            field('phone', l10n.dashPhone, ltr: true),
            field('whatsapp', l10n.whatsapp, ltr: true),
          ]),
        ),
        const SizedBox(height: 16),
        DashCard(
          title: l10n.dashPricesBooking,
          icon: Icons.payments_outlined,
          tone: Tone.green,
          child: fields([
            field('visitPrice', l10n.dashVisitPrice, number: true, unit: l10n.dashEgp, width: 200),
            field('packagePrice', l10n.dashPackagePrice, number: true, unit: l10n.dashEgp, width: 200),
            field('packageMonths', l10n.dashPackageMonths, number: true, unit: l10n.dashUnitMonths, width: 200),
            field('capacityPerHour', l10n.dashCapacity, number: true, unit: l10n.dashUnitPerHour, width: 200),
            field('cancelWindowHours', l10n.dashCancelWindow, number: true, unit: l10n.dashUnitHours, width: 200),
          ]),
        ),
        const SizedBox(height: 16),
        DashCard(
          title: l10n.dashHoursAndVaccineDays,
          hint: l10n.dashHoursHint,
          icon: Icons.schedule,
          tone: Tone.yellow,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: dayRows),
        ),
        const SizedBox(height: 16),
        DashCard(
          title: l10n.dashHolidays,
          hint: l10n.dashHolidayHint,
          icon: Icons.event_busy_outlined,
          tone: Tone.pink,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              if (_holidays.isEmpty) Text(l10n.dashNoHolidays, style: TextStyle(color: c.muted)),
              for (final h in _holidays)
                TimeChip(
                  key: Key('holiday-$h'),
                  label: dayLabel(h),
                  onRemove: () => setState(() => _holidays = [..._holidays]..remove(h)),
                ),
              AddChip(key: const Key('add-holiday'), label: l10n.dashAddHoliday, onTap: _addHoliday),
            ]),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline, size: 16, color: c.muted),
              const SizedBox(width: 6),
              Expanded(child: Text(l10n.dashHolidayWarn, style: TextStyle(fontSize: 12, color: c.muted))),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        DashCard(
          title: l10n.dashVaccinePricesClinic,
          icon: Icons.vaccines_outlined,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: offers),
        ),
      ],
    );
  }
}

