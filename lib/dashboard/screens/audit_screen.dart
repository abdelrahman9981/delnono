import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../app/l10n/app_localizations.dart';
import '../../core/format/arabic_digits.dart';
import '../../core/settings/settings_repository.dart';
import '../widgets/dash_page.dart';

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
  final _date = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final all = ref.watch(auditProvider).value ?? const <Map<String, dynamic>>[];
    final actions = {for (final e in all) '${e['action']}'}.toList()..sort();
    String day(Object? at) => at is Timestamp ? DateFormat('yyyy-MM-dd').format(at.toDate()) : '';
    final shown = all
        .where(
          (e) =>
              (_action == null || e['action'] == _action) &&
              (_date.text.trim().isEmpty || day(e['at']) == _date.text.trim()),
        )
        .toList();

    return DashPage(
      title: l10n.dashNavAudit,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<String?>(
                isExpanded: true,
                key: const Key('audit-action'),
                initialValue: _action,
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.dashAllActions)),
                  for (final a in actions) DropdownMenuItem(value: a, child: Text(a)),
                ],
                onChanged: (v) => setState(() => _action = v),
                decoration: InputDecoration(labelText: l10n.dashAction),
              ),
            ),
            SizedBox(
              width: 180,
              child: TextField(
                key: const Key('audit-date'),
                controller: _date,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(labelText: l10n.dashDate, helperText: 'YYYY-MM-DD'),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(l10n.dashAuditCount(arabicDigits(shown.length))),
        for (final e in shown)
          ListTile(
            key: Key('audit-${e['id']}'),
            dense: true,
            title: Text('${e['action']}'),
            subtitle: Text(
              [
                if (e['at'] is Timestamp) DateFormat('yyyy-MM-dd HH:mm').format((e['at'] as Timestamp).toDate()),
                '${e['actorUid']}',
                if (e['subjectPhone'] != null) '${e['subjectPhone']}',
                if (e['childIds'] != null) (e['childIds'] as List).join(', '),
              ].join(' · '),
            ),
          ),
      ],
    );
  }
}
