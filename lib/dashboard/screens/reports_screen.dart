import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/l10n/app_localizations.dart';
import '../../core/clock.dart';
import '../../core/format/arabic_digits.dart';
import '../../features/booking/domain/clinic_time.dart';
import '../../features/clinics/data/clinics_repository.dart';
import '../data/dashboard_api.dart';
import '../data/staff_session.dart';
import '../widgets/dash_page.dart';
import '../widgets/dash_ui.dart';

const reportColumns = ['bookings', 'arrivals', 'noShows', 'walkIns', 'cash', 'packagesSold', 'packageRevenue'];

/// The report as CSV: dates, clinic and the numbers only (visit cash and package revenue apart), no names, phones or medical data
/// (D-20, 005 FR-023).
String reportCsv(List<Map<String, dynamic>> rows, Map<String, dynamic> total, String clinic, List<String> headers) {
  final lines = <String>[
    ['date', 'clinic', ...reportColumns].join(','),
    for (final r in [...rows, total]) ['${r['key']}', clinic, for (final c in reportColumns) '${r[c] ?? 0}'].join(','),
  ];
  // The Arabic header line first, so the file reads well in a spreadsheet.
  return '﻿${headers.join(',')}\n${lines.join('\n')}\n';
}

/// Daily and monthly reports (005 US7, D-20).
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late final String _today = ClinicTime.dateOf(ref.read(clockProvider)());
  late String _from = '${_today.substring(0, 8)}01';
  late String _to = _today;
  bool _byMonth = false;
  bool _allClinics = false;
  Map<String, dynamic>? _result;

  Future<void> _run(String clinicId) => runAction(context, () async {
    final r = await ref.read(dashboardApiProvider).call('report', {
      'clinicId': _allClinics ? 'all' : clinicId,
      'from': _from,
      'to': _to,
      'groupBy': _byMonth ? 'month' : 'day',
    });
    setState(() => _result = r);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final clinicId = ref.watch(currentClinicIdProvider);
    final isDoctor = ref.watch(staffSessionProvider).value?.isDoctor ?? false;
    final clinic = clinicId == null ? null : ref.watch(clinicProvider(clinicId));
    final headers = [
      l10n.dashDate,
      l10n.labelClinic,
      l10n.dashRepBookings,
      l10n.dashRepArrivals,
      l10n.dashRepNoShows,
      l10n.dashRepWalkIns,
      l10n.dashRepCash,
      l10n.dashRepPackages,
      l10n.dashRepPackageRevenue,
    ];
    final rows = [for (final r in (_result?['rows'] as List? ?? const [])) Map<String, dynamic>.from(r as Map)];
    final total = _result == null ? null : Map<String, dynamic>.from(_result!['total'] as Map);
    final clinicLabel = _allClinics ? l10n.dashAllClinics : (clinic?.name ?? '');
    final today = ClinicTime.asDate(_today);
    String n(Map<String, dynamic> r, String k) => arabicDigits((r[k] as num?) ?? 0);

    return DashPage(
      title: l10n.dashNavReports,
      actions: [
        if (total != null)
          OutlinedButton.icon(
            key: const Key('report-csv'),
            onPressed: () => launchUrl(
              Uri.dataFromString(
                reportCsv(rows, total, clinicLabel, headers),
                mimeType: 'text/csv',
                encoding: const Utf8Codec(),
              ),
            ),
            icon: const Icon(Icons.download),
            label: Text(l10n.dashExportCsv),
          ),
      ],
      children: [
        DashCard(
          title: l10n.dashReportFilters,
          icon: Icons.filter_alt_outlined,
          child: Wrap(
            spacing: 16,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              SizedBox(
                width: 240,
                child: DashField(
                  label: l10n.dashFrom,
                  child: DateField(
                    key: const Key('report-from'),
                    value: _from,
                    first: DateTime(2025),
                    last: today,
                    onChanged: (d) => setState(() => _from = d),
                  ),
                ),
              ),
              SizedBox(
                width: 240,
                child: DashField(
                  label: l10n.dashTo,
                  child: DateField(
                    key: const Key('report-to'),
                    value: _to,
                    first: DateTime(2025),
                    last: today,
                    onChanged: (d) => setState(() => _to = d),
                  ),
                ),
              ),
              SegmentSwitch<bool>(
                key: const Key('report-group'),
                options: [(false, l10n.dashDaily), (true, l10n.dashMonthly)],
                value: _byMonth,
                onChanged: (v) => setState(() => _byMonth = v),
              ),
              if (isDoctor)
                FilterChip(
                  key: const Key('report-all'),
                  label: Text(l10n.dashAllClinics),
                  selected: _allClinics,
                  onSelected: (v) => setState(() => _allClinics = v),
                ),
              FilledButton(
                key: const Key('report-run'),
                onPressed: clinicId == null ? null : () => _run(clinicId),
                child: Text(l10n.dashShowReport),
              ),
            ],
          ),
        ),
        if (total != null) ...[
          const SizedBox(height: 16),
          TileGrid(
            columns: 6,
            minTileWidth: 150,
            children: [
              KpiTile(label: l10n.dashRepBookings, value: n(total, 'bookings')),
              KpiTile(label: l10n.dashRepArrivals, value: n(total, 'arrivals')),
              KpiTile(label: l10n.dashRepNoShows, value: n(total, 'noShows')),
              KpiTile(label: l10n.dashRepWalkIns, value: n(total, 'walkIns')),
              KpiTile(label: l10n.dashRepCash, value: n(total, 'cash'), unit: l10n.dashEgp),
              KpiTile(
                label: l10n.dashRepPackageRevenue,
                value: n(total, 'packageRevenue'),
                unit: l10n.dashEgp,
                note: '${l10n.dashRepPackages}: ${n(total, 'packagesSold')}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          DashCard(
            key: const Key('report-table'),
            title: l10n.dashReportResult,
            hint: clinicLabel,
            icon: Icons.bar_chart_outlined,
            padding: EdgeInsets.zero,
            child: DashTable(
              headers: [headers[0], ...headers.skip(2)],
              flex: const [3, 2, 2, 2, 2, 2, 2, 2],
              rows: [
                for (final r in [...rows, total])
                  DashRow(cells: [
                    Text(r == total ? l10n.dashTotal : '${r['key']}', style: r == total ? const TextStyle(fontWeight: FontWeight.w700) : null),
                    for (final c in reportColumns) Text(n(r, c), style: r == total ? const TextStyle(fontWeight: FontWeight.w700) : null),
                  ]),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
