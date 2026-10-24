import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../core/settings/settings_repository.dart';
import '../../features/clinics/data/clinics_repository.dart';
import '../data/dashboard_api.dart';
import '../widgets/dash_page.dart';

final staffListProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) => ref
      .watch(firestoreProvider)
      .collection('staff')
      .snapshots()
      .map(
        (q) => [
          for (final d in q.docs) {'uid': d.id, ...d.data()},
        ]..sort((a, b) => '${a['name']}'.compareTo('${b['name']}')),
      ),
);

/// Staff accounts (005 US8, D-12): the doctor creates, edits and disables them.
class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final staff = ref.watch(staffListProvider).value ?? const <Map<String, dynamic>>[];
    final clinics = ref.watch(allClinicsProvider).value ?? const <Clinic>[];
    final api = ref.read(dashboardApiProvider);
    return DashPage(
      title: l10n.dashNavStaff,
      actions: [
        FilledButton.icon(
          key: const Key('staff-new'),
          onPressed: () => showDialog<void>(context: context, builder: (_) => const _StaffDialog()),
          icon: const Icon(Icons.person_add_alt),
          label: Text(l10n.dashNewStaff),
        ),
      ],
      children: [
        for (final s in staff)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ActionRow(
                key: Key('staff-${s['uid']}'),
                title: '${s['name']} · ${s['email']}',
                subtitle: [
                  s['role'] == 'doctor' ? l10n.dashRoleDoctor : l10n.dashRoleSecretary,
                  if (s['clinicId'] != null) clinics.where((c) => c.id == s['clinicId']).firstOrNull?.name ?? '',
                  if (s['active'] != true) l10n.dashDisabled,
                ].join(' · '),
                actions: [
                  IconButton(
                    tooltip: l10n.dashEdit,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => _StaffDialog(existing: s),
                    ),
                  ),
                  OutlinedButton(
                    key: Key('staff-toggle-${s['uid']}'),
                    onPressed: () => runAction(
                      context,
                      () => api.call('manageStaff', {
                        'action': s['active'] == true ? 'disable' : 'enable',
                        'uid': s['uid'],
                      }),
                      done: l10n.dashSaved,
                    ),
                    child: Text(s['active'] == true ? l10n.dashDisable : l10n.dashEnable),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StaffDialog extends ConsumerStatefulWidget {
  const _StaffDialog({this.existing});

  final Map<String, dynamic>? existing;

  @override
  ConsumerState<_StaffDialog> createState() => _StaffDialogState();
}

class _StaffDialogState extends ConsumerState<_StaffDialog> {
  late final _name = TextEditingController(text: '${widget.existing?['name'] ?? ''}');
  late final _email = TextEditingController(text: '${widget.existing?['email'] ?? ''}');
  final _password = TextEditingController();
  late String _role = '${widget.existing?['role'] ?? 'secretary'}';
  late String? _clinic = widget.existing?['clinicId'] as String?;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final clinics = ref.watch(allClinicsProvider).value ?? const <Clinic>[];
    final creating = widget.existing == null;
    return AlertDialog(
      title: Text(creating ? l10n.dashNewStaff : l10n.dashEdit),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('staff-name'),
              controller: _name,
              decoration: InputDecoration(labelText: l10n.guardianFullName),
            ),
            if (creating) ...[
              TextField(
                key: const Key('staff-email'),
                controller: _email,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(labelText: l10n.dashEmail),
              ),
              TextField(
                key: const Key('staff-password'),
                controller: _password,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(labelText: l10n.dashTempPassword),
              ),
            ],
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'secretary', label: Text(l10n.dashRoleSecretary)),
                ButtonSegment(value: 'doctor', label: Text(l10n.dashRoleDoctor)),
              ],
              selected: {_role},
              onSelectionChanged: (s) => setState(() => _role = s.first),
            ),
            if (_role == 'secretary')
              DropdownButtonFormField<String>(
                isExpanded: true,
                key: const Key('staff-clinic'),
                initialValue: _clinic,
                items: [for (final c in clinics) DropdownMenuItem(value: c.id, child: Text(c.name))],
                onChanged: (v) => setState(() => _clinic = v),
                decoration: InputDecoration(labelText: l10n.labelClinic),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.dashClose)),
        FilledButton(
          key: const Key('staff-save'),
          onPressed: () async {
            final ok = await runAction(
              context,
              () => ref.read(dashboardApiProvider).call('manageStaff', {
                'action': creating ? 'create' : 'update',
                if (!creating) 'uid': widget.existing!['uid'],
                'name': _name.text.trim(),
                if (creating) 'email': _email.text.trim(),
                if (creating) 'tempPassword': _password.text,
                'role': _role,
                'clinicId': _role == 'secretary' ? _clinic : null,
              }),
              done: l10n.dashSaved,
            );
            if (ok && context.mounted) Navigator.pop(context);
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
