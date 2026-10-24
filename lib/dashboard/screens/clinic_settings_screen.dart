import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../app/l10n/app_localizations.dart';
import '../../core/settings/settings_repository.dart';
import '../../features/booking/data/booking_settings.dart';
import '../../features/child_profile/data/vaccine_schedule_repository.dart';
import '../data/dashboard_api.dart';
import '../data/staff_session.dart';
import '../widgets/dash_page.dart';

/// The current clinic document as stored (contact fields the booking settings do not carry).
final clinicDocProvider = StreamProvider.family<Map<String, dynamic>, String>(
  (ref, id) => ref.watch(firestoreProvider).doc('clinics/$id').snapshots().map((s) => s.data() ?? const {}),
);

/// "17-21" or "10-14, 17-21" ↔ hour ranges.
String rangesText(List<HourRange> ranges) => ranges.map((r) => '${r.from}-${r.to}').join(', ');

List<Map<String, int>>? parseRanges(String text) {
  final out = <Map<String, int>>[];
  for (final part in text.split(RegExp('[،,]')).map((s) => s.trim()).where((s) => s.isNotEmpty)) {
    final m = RegExp(r'^(\d{1,2})\s*-\s*(\d{1,2})$').firstMatch(part);
    if (m == null) return null;
    final from = int.parse(m[1]!), to = int.parse(m[2]!);
    if (from >= to || to > 24) return null;
    out.add({'from': from, 'to': to});
  }
  return out;
}

/// The clinic's schedule, prices, contact and vaccine offers (005 US5, D-44, D-45). The secretary
/// edits her clinic; the doctor the clinic picked in the top bar.
class ClinicSettingsScreen extends ConsumerStatefulWidget {
  const ClinicSettingsScreen({super.key});

  @override
  ConsumerState<ClinicSettingsScreen> createState() => _ClinicSettingsScreenState();
}

class _ClinicSettingsScreenState extends ConsumerState<ClinicSettingsScreen> {
  String? _loadedFor;
  final _c = <String, TextEditingController>{};
  final _hours = <int, TextEditingController>{};
  Set<int> _vaccineDays = {};
  final _offers = <String, ({bool offered, TextEditingController price, bool shown})>{};

  TextEditingController _ctl(String k) => _c.putIfAbsent(k, TextEditingController.new);

  @override
  void dispose() {
    for (final c in [..._c.values, ..._hours.values, for (final o in _offers.values) o.price]) {
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
    _ctl('holidays').text = s.holidays.join(', ');
    for (var d = 1; d <= 7; d++) {
      _hours.putIfAbsent(d, TextEditingController.new).text = rangesText(s.workingHours[d] ?? const []);
    }
    _vaccineDays = {...s.vaccineWeekdays};
    for (final v in catalogue.values) {
      final o = s.vaccinePrices[v.id];
      _offers[v.id] = (
        offered: o?.offered ?? false,
        price: TextEditingController(text: '${o?.price ?? 0}'),
        shown: o?.shown ?? true,
      );
    }
  }

  Future<void> _save(String clinicId) async {
    final l10n = AppLocalizations.of(context);
    final hours = <String, Object>{};
    for (final e in _hours.entries) {
      final r = parseRanges(e.value.text);
      if (r == null) {
        await runAction(context, () async => throw const StaffActionRefused('invalid-argument', 'workingHours'));
        return;
      }
      hours['${e.key}'] = r;
    }
    int n(String k) => int.tryParse(_ctl(k).text.trim()) ?? 0;
    await runAction(
      context,
      () => ref.read(dashboardApiProvider).call('updateClinic', {
        'clinicId': clinicId,
        'fields': {
          'address': _ctl('address').text.trim(),
          'phone': _ctl('phone').text.trim(),
          'whatsapp': _ctl('whatsapp').text.trim(),
          'visitPrice': n('visitPrice'),
          'packagePrice': n('packagePrice'),
          'packageMonths': n('packageMonths'),
          'capacityPerHour': n('capacityPerHour'),
          'cancelWindowHours': n('cancelWindowHours'),
          'holidays': _ctl('holidays').text
              .split(RegExp('[،,]'))
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
          'workingHours': hours,
          'vaccineWeekdays': _vaccineDays.toList()..sort(),
          'vaccinePrices': {
            for (final e in _offers.entries)
              e.key: {
                'offered': e.value.offered,
                'price': int.tryParse(e.value.price.text.trim()) ?? 0,
                'shown': e.value.shown,
              },
          },
        },
      }),
      done: l10n.dashSaved,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final clinicId = ref.watch(currentClinicIdProvider);
    if (clinicId == null) return const Center(child: CircularProgressIndicator());
    final doc = ref.watch(clinicDocProvider(clinicId)).value ?? const <String, dynamic>{};
    final settings = ref.watch(bookingSettingsProvider(clinicId)).value;
    final catalogue = ref.watch(vaccineCatalogueProvider).value ?? const <String, VaccineInfo>{};
    if (settings == null || doc.isEmpty) return const Center(child: CircularProgressIndicator());
    _load(clinicId, doc, settings, catalogue);
    // ISO weekday names, week from Saturday (5 Jan 2026 is a Monday).
    String day(int iso) => DateFormat('EEEE', 'ar').format(DateTime(2026, 1, 4 + iso));
    Widget field(String k, String label, {bool number = false, bool ltr = false}) => SizedBox(
      width: 260,
      child: TextField(
        key: Key('clinic-$k'),
        controller: _ctl(k),
        keyboardType: number ? TextInputType.number : null,
        textDirection: ltr ? TextDirection.ltr : null,
        decoration: InputDecoration(labelText: label),
      ),
    );

    return DashPage(
      title: '${l10n.dashNavClinic} · ${doc['name'] ?? ''}',
      actions: [FilledButton(key: const Key('clinic-save'), onPressed: () => _save(clinicId), child: Text(l10n.save))],
      children: [
        Text(l10n.dashContact, style: Theme.of(context).textTheme.titleMedium),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            field('address', l10n.labelAddress),
            field('phone', l10n.dashPhone, ltr: true),
            field('whatsapp', l10n.whatsapp, ltr: true),
          ],
        ),
        const SizedBox(height: 20),
        Text(l10n.dashPrices, style: Theme.of(context).textTheme.titleMedium),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            field('visitPrice', l10n.dashVisitPrice, number: true),
            field('packagePrice', l10n.dashPackagePrice, number: true),
            field('packageMonths', l10n.dashPackageMonths, number: true),
          ],
        ),
        const SizedBox(height: 20),
        Text(l10n.dashSchedule, style: Theme.of(context).textTheme.titleMedium),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            field('capacityPerHour', l10n.dashCapacity, number: true),
            field('cancelWindowHours', l10n.dashCancelWindow, number: true),
            SizedBox(
              width: 532,
              child: TextField(
                key: const Key('clinic-holidays'),
                controller: _ctl('holidays'),
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(labelText: l10n.dashHolidays, helperText: l10n.dashHolidaysHelp),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(l10n.dashWorkingHoursHelp, style: Theme.of(context).textTheme.bodySmall),
        for (final d in const [6, 7, 1, 2, 3, 4, 5])
          Row(
            children: [
              SizedBox(width: 110, child: Text(day(d))),
              SizedBox(
                width: 200,
                child: TextField(key: Key('hours-$d'), controller: _hours[d], textDirection: TextDirection.ltr),
              ),
              const SizedBox(width: 12),
              FilterChip(
                key: Key('vaccine-day-$d'),
                label: Text(l10n.dashVaccineDay),
                selected: _vaccineDays.contains(d),
                onSelected: (v) => setState(() => v ? _vaccineDays.add(d) : _vaccineDays.remove(d)),
              ),
            ],
          ),
        const SizedBox(height: 20),
        Text(l10n.dashVaccineOffers, style: Theme.of(context).textTheme.titleMedium),
        for (final v in catalogue.values.where((v) => v.active))
          if (_offers[v.id] case final o?)
            Row(
              key: Key('offer-${v.id}'),
              children: [
                Expanded(child: Text(v.name)),
                Switch(
                  value: o.offered,
                  onChanged: (x) => setState(() => _offers[v.id] = (offered: x, price: o.price, shown: o.shown)),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: o.price,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.dashPrice),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l10n.dashPriceShown),
                  selected: o.shown,
                  onSelected: (x) => setState(() => _offers[v.id] = (offered: o.offered, price: o.price, shown: x)),
                ),
              ],
            ),
      ],
    );
  }
}
