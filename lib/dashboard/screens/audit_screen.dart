import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/format/arabic_digits.dart';
import '../../core/settings/settings_repository.dart';
import '../widgets/dash_page.dart';
import '../widgets/dash_ui.dart';

/// The latest audit entries (D-13), doctor only (rules).
final auditProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) => ref
      .watch(firestoreProvider)
      .collection('auditLog')
      .orderBy('at', descending: true)
      .limit(300)
      .snapshots()
      .map(
        (q) => [
          for (final d in q.docs) {'id': d.id, ...d.data()},
        ],
      ),
);

/// The audit log (005 US8, FR-025): who did what and when, filtered by action and date.
class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key});

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
  String? _action;
  String? _date;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    final all = ref.watch(auditProvider).value ?? const <Map<String, dynamic>>[];
    final actions = {for (final e in all) '${e['action']}'}.toList()..sort();
    String day(Object? at) => at is Timestamp ? DateFormat('yyyy-MM-dd').format(at.toDate()) : '';
    final shown = all.where((e) => (_action == null || e['action'] == _action) && (_date == null || day(e['at']) == _date)).toList();

    return DashPage(
      title: l10n.dashNavAudit,
      subtitle: l10n.dashAuditHint,
      showClinic: false,
      children: [
        DashCard(
          title: l10n.dashReportFilters,
          icon: Icons.filter_alt_outlined,
          tone: Tone.navy,
          child: Wrap(
            spacing: 16,
            runSpacing: 14,
            children: [
              SizedBox(
                width: 260,
                child: DashField(
                  label: l10n.dashAction,
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    key: const Key('audit-action'),
                    initialValue: _action,
                    items: [
                      DropdownMenuItem(value: null, child: Text(l10n.dashAllActions)),
                      for (final a in actions) DropdownMenuItem(value: a, child: Text(a)),
                    ],
                    onChanged: (v) => setState(() => _action = v),
                    decoration: dashInput(context),
                  ),
                ),
              ),
              SizedBox(
                width: 260,
                child: DashField(
                  label: l10n.dashDate,
                  child: DateField(
                    key: const Key('audit-date'),
                    value: _date,
                    hint: l10n.dashAllActions,
                    first: DateTime(2025),
                    last: DateTime.now(),
                    onChanged: (d) => setState(() => _date = d),
                    onClear: () => setState(() => _date = null),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DashCard(
          title: l10n.dashNavAudit,
          hint: l10n.dashAuditCount(arabicDigits(shown.length)),
          icon: Icons.history,
          tone: Tone.navy,
          padding: EdgeInsets.zero,
          child: shown.isEmpty
              ? Padding(padding: const EdgeInsets.all(20), child: Text(l10n.dashNothingYet, style: TextStyle(color: c.muted)))
              : DashTable(
                  headers: [l10n.dashColDate, l10n.dashAction, l10n.dashColRecorder, l10n.dashGuardian],
                  flex: const [3, 3, 3, 4],
                  rows: [
                    for (final e in shown)
                      DashRow(key: Key('audit-${e['id']}'), cells: [
                        Text(e['at'] is Timestamp ? DateFormat('yyyy-MM-dd HH:mm').format((e['at'] as Timestamp).toDate()) : '—'),
                        StatusPill('${e['action']}', PillKind.info, dot: false),
                        Text('${e['actorUid']}', style: TextStyle(color: c.muted)),
                        Text(
                          [
                            if (e['subjectPhone'] != null) '${e['subjectPhone']}',
                            if (e['childIds'] != null) (e['childIds'] as List).join(', '),
                          ].join(' · '),
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.end,
                        ),
                      ]),
                  ],
                ),
        ),
      ],
    );
  }
}
