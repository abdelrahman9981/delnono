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

const reportColumns = ['bookings', 'arrivals', 'noShows', 'walkIns', 'cash', 'packagesSold'];

/// The report as CSV: dates, clinic and the six numbers only, no names, phones or medical data
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
  late final _from = TextEditingController(text: '${_today.substring(0, 8)}01');
  late final _to = TextEditingController(text: _today);
  bool _byMonth = false;
  bool _allClinics = false;
  Map<String, dynamic>? _result;

  Future<void> _run(String clinicId) => runAction(context, () async {
    final r = await ref.read(dashboardApiProvider).call('report', {
      'clinicId': _allClinics ? 'all' : clinicId,
      'from': _from.text.trim(),
      'to': _to.text.trim(),
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
    ];
    final rows = [for (final r in (_result?['rows'] as List? ?? const [])) Map<String, dynamic>.from(r as Map)];
    final total = _result == null ? null : Map<String, dynamic>.from(_result!['total'] as Map);
    final clinicLabel = _allClinics ? l10n.dashAllClinics : (clinic?.name ?? '');

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
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 160,
              child: TextField(
                key: const Key('report-from'),
                controller: _from,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(labelText: l10n.dashFrom),
              ),
            ),
            SizedBox(
              width: 160,
              child: TextField(
                key: const Key('report-to'),
                controller: _to,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(labelText: l10n.dashTo),
              ),
            ),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l10n.dashDaily)),
                ButtonSegment(value: true, label: Text(l10n.dashMonthly)),
              ],
              selected: {_byMonth},
              onSelectionChanged: (s) => setState(() => _byMonth = s.first),
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
        const SizedBox(height: 16),
        if (total != null)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              key: const Key('report-table'),
              columns: [
                for (final h in [headers[0], ...headers.skip(2)]) DataColumn(label: Text(h)),
              ],
              rows: [
                for (final r in [...rows, total])
                  DataRow(
                    cells: [
                      DataCell(Text(r == total ? l10n.dashTotal : '${r['key']}')),
                      for (final c in reportColumns) DataCell(Text(arabicDigits((r[c] as num?) ?? 0))),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
