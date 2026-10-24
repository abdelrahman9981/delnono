import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/clock.dart';
import '../../core/format/age.dart';
import '../../core/format/arabic_digits.dart';
import '../../features/booking/domain/clinic_time.dart';
import '../../features/child_profile/data/vaccine_schedule_repository.dart';
import '../../features/child_profile/presentation/profile_format.dart';
import '../../features/clinics/data/clinics_repository.dart';
import '../data/dashboard_api.dart';
import '../data/staff_session.dart';
import '../widgets/dash_page.dart';

/// The child file, opened through `openChildFile` so the opening is logged (D-13, FR-028).
final childFileProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, childId) => ref.read(dashboardApiProvider).call('openChildFile', {'childId': childId}),
);

/// Child file (005 US4): basic data, measurements and doses recorded at the clinic (D-29), the
/// doctor's corrections and notes (D-11), the family package (D-46).
class ChildFileScreen extends ConsumerWidget {
  const ChildFileScreen({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final file = ref.watch(childFileProvider(childId));
    return file.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(dashErrorText(l10n, e))),
      data: (f) => _File(childId: childId, file: f),
    );
  }
}

class _File extends ConsumerWidget {
  const _File({required this.childId, required this.file});

  final String childId;
  final Map<String, dynamic> file;

  List<Map<String, dynamic>> _list(String key) => [
    for (final x in (file[key] as List? ?? const [])) Map<String, dynamic>.from(x as Map),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final child = Map<String, dynamic>.from(file['child'] as Map);
    final staff = ref.watch(staffSessionProvider).value;
    final isDoctor = staff?.isDoctor ?? false;
    final clinicId = ref.watch(currentClinicIdProvider);
    final clinics = ref.watch(allClinicsProvider).value ?? const <Clinic>[];
    String clinicName(Object? id) => clinics.where((x) => x.id == id).firstOrNull?.area ?? '';
    final catalogue = ref.watch(vaccineCatalogueProvider).value ?? const <String, VaccineInfo>{};
    final measurements = _list('measurements')..sort((a, b) => '${b['measuredOn']}'.compareTo('${a['measuredOn']}'));
    final doses = _list('doses')..sort((a, b) => '${b['givenOn']}'.compareTo('${a['givenOn']}'));
    final visits = _list('visits')..sort((a, b) => '${b['date']}'.compareTo('${a['date']}'));
    final today = ClinicTime.dateOf(ref.watch(clockProvider)());
    final package = _list('packages')
        .where(
          (p) =>
              p['active'] == true && '${p['startsOn']}'.compareTo(today) <= 0 && today.compareTo('${p['endsOn']}') <= 0,
        )
        .firstOrNull;
    void reload() => ref.invalidate(childFileProvider(childId));

    Widget section(String title, List<Widget> children, {Widget? action}) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: text.titleMedium)),
                ?action,
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );

    return DashPage(
      title: '${child['name']}',
      actions: [
        OutlinedButton.icon(
          key: const Key('edit-basics'),
          onPressed: () async {
            if (await showDialog<bool>(
                  context: context,
                  builder: (_) => _BasicsDialog(childId: childId, child: child),
                ) ==
                true) {
              reload();
              }
          },
          icon: const Icon(Icons.edit_outlined),
          label: Text(l10n.dashEditBasics),
        ),
      ],
      children: [
        section(l10n.dashBasics, [
          Text(
            '${arabicAge('${child['birthDate']}', l10n)} · ${child['sex'] == 'female' ? l10n.sexFemale : l10n.sexMale} · ${child['birthDate']}',
          ),
          Text(l10n.dashGuardianPhone('${child['guardianPhone'] ?? ''}')),
          if (child['allergies'] != null) Text(l10n.detailsAllergies('${child['allergies']}')),
          const SizedBox(height: 8),
          if (package != null)
            Text(l10n.packageActiveUntil('${package['endsOn']}'), key: const Key('child-package'))
          else if (child['guardianUid'] != null && clinicId != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton(
                key: const Key('sell-package'),
                onPressed: () async {
                  final ok = await runAction(
                    context,
                    () => ref.read(dashboardApiProvider).call('sellPackage', {
                      'clinicId': clinicId,
                      'guardianUid': child['guardianUid'],
                    }),
                    done: l10n.dashPackageSold,
                  );
                  if (ok) reload();
                },
                child: Text(l10n.dashSellPackage),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        section(
          l10n.dashMeasurements,
          [
            if (measurements.isEmpty) Text(l10n.noMeasurements, style: TextStyle(color: c.muted)),
            for (final m in measurements)
              ListTile(
                key: Key('measurement-${m['id']}'),
                dense: true,
                title: Text(
                  [
                    if (m['weightKg'] != null)
                      '${l10n.measureWeight} ${measureValue((m['weightKg'] as num).toDouble())} ${l10n.unitKg}',
                    if (m['lengthCm'] != null)
                      '${l10n.measureLength} ${measureValue((m['lengthCm'] as num).toDouble())} ${l10n.unitCm}',
                    if (m['headCm'] != null)
                      '${l10n.measureHead} ${measureValue((m['headCm'] as num).toDouble())} ${l10n.unitCm}',
                  ].join(' · '),
                ),
                subtitle: Text('${m['measuredOn']} · ${clinicName(m['clinicId'])}'),
                trailing: isDoctor
                    ? IconButton(
                        key: Key('correct-measurement-${m['id']}'),
                        tooltip: l10n.dashCorrect,
                        icon: const Icon(Icons.edit_note),
                        onPressed: () async {
                          if (await showDialog<bool>(
                                context: context,
                                builder: (_) => _MeasurementDialog(childId: childId, clinicId: clinicId, existing: m),
                              ) ==
                              true) {
                            reload();
                          }
                        },
                      )
                    : null,
              ),
          ],
          action: TextButton.icon(
            key: const Key('add-measurement'),
            onPressed: () async {
              if (await showDialog<bool>(
                    context: context,
                    builder: (_) => _MeasurementDialog(childId: childId, clinicId: clinicId),
                  ) ==
                  true) {
                reload();
                }
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.dashAdd),
          ),
        ),
        const SizedBox(height: 12),
        section(
          l10n.dashDoses,
          [
            for (final d in doses)
              ListTile(
                key: Key('dose-${d['id']}'),
                dense: true,
                title: Text(
                  '${catalogue[d['vaccineId']]?.name ?? d['vaccineId']} · ${l10n.doseNumber(arabicDigits(d['dose'] as num? ?? 1))}',
                ),
                subtitle: Text(
                  [
                    '${d['givenOn']}',
                    if (d['lot'] != null) l10n.doseLot('${d['lot']}'),
                    clinicName(d['clinicId']),
                  ].join(' · '),
                ),
                trailing: isDoctor
                    ? IconButton(
                        key: Key('correct-dose-${d['id']}'),
                        tooltip: l10n.dashCorrect,
                        icon: const Icon(Icons.edit_note),
                        onPressed: () async {
                          if (await showDialog<bool>(
                                context: context,
                                builder: (_) => _DoseDialog(childId: childId, clinicId: clinicId, existing: d),
                              ) ==
                              true) {
                            reload();
                            }
                        },
                      )
                    : null,
              ),
          ],
          action: TextButton.icon(
            key: const Key('add-dose'),
            onPressed: () async {
              if (await showDialog<bool>(
                    context: context,
                    builder: (_) => _DoseDialog(childId: childId, clinicId: clinicId),
                  ) ==
                  true) {
                reload();
                }
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.dashAdd),
          ),
        ),
        const SizedBox(height: 12),
        section(l10n.visitsTitle, [
          if (visits.isEmpty) Text(l10n.visitsEmpty, style: TextStyle(color: c.muted)),
          for (final v in visits)
            ListTile(
              key: Key('visit-${v['id']}'),
              dense: true,
              title: Text('${v['date']} · ${clinicName(v['clinicId'])}'),
              // The doctor's note: sent to the doctor only (FR-016).
              subtitle: isDoctor
                  ? Text((v['note'] as String?)?.isNotEmpty == true ? '${v['note']}' : l10n.dashNoNote)
                  : null,
              trailing: isDoctor
                  ? IconButton(
                      key: Key('note-${v['id']}'),
                      tooltip: l10n.dashNote,
                      icon: const Icon(Icons.sticky_note_2_outlined),
                      onPressed: () async {
                        if (await showDialog<bool>(
                              context: context,
                              builder: (_) => _NoteDialog(childId: childId, visit: v),
                            ) ==
                            true) {
                          reload();
                          }
                      },
                    )
                  : null,
            ),
        ]),
      ],
    );
  }
}

/// A small form dialog that saves through a callable and returns true on success.
class _FormDialog extends StatelessWidget {
  const _FormDialog({required this.title, required this.fields, required this.onSave});

  final String title;
  final List<Widget> fields;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 400,
        child: Column(mainAxisSize: MainAxisSize.min, children: fields),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.dashClose)),
        FilledButton(
          key: const Key('dialog-save'),
          onPressed: () async {
            final ok = await runAction(context, onSave, done: l10n.dashSaved);
            if (ok && context.mounted) Navigator.pop(context, true);
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

TextField _field(String key, TextEditingController c, String label, {bool number = false, bool ltr = false}) =>
    TextField(
      key: Key(key),
      controller: c,
      keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : null,
      textDirection: ltr ? TextDirection.ltr : null,
      decoration: InputDecoration(labelText: label),
    );

num? _num(TextEditingController c) => num.tryParse(c.text.trim().replaceAll('٫', '.'));

class _MeasurementDialog extends ConsumerStatefulWidget {
  const _MeasurementDialog({required this.childId, required this.clinicId, this.existing});

  final String childId;
  final String? clinicId;
  final Map<String, dynamic>? existing;

  @override
  ConsumerState<_MeasurementDialog> createState() => _MeasurementDialogState();
}

class _MeasurementDialogState extends ConsumerState<_MeasurementDialog> {
  late final _date = TextEditingController(
    text: '${widget.existing?['measuredOn'] ?? ClinicTime.dateOf(ref.read(clockProvider)())}',
  );
  late final _weight = TextEditingController(text: '${widget.existing?['weightKg'] ?? ''}');
  late final _length = TextEditingController(text: '${widget.existing?['lengthCm'] ?? ''}');
  late final _head = TextEditingController(text: '${widget.existing?['headCm'] ?? ''}');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _FormDialog(
      title: widget.existing == null ? l10n.dashAddMeasurement : l10n.dashCorrect,
      fields: [
        _field('m-date', _date, l10n.dashDate, ltr: true),
        _field('m-weight', _weight, '${l10n.measureWeight} (${l10n.unitKg})', number: true),
        _field('m-length', _length, '${l10n.measureLength} (${l10n.unitCm})', number: true),
        _field('m-head', _head, '${l10n.measureHead} (${l10n.unitCm})', number: true),
      ],
      onSave: () => ref.read(dashboardApiProvider).call('saveMeasurement', {
        'childId': widget.childId,
        if (widget.existing != null) 'id': widget.existing!['id'],
        'clinicId': widget.clinicId,
        'measuredOn': _date.text.trim(),
        'weightKg': _num(_weight),
        'lengthCm': _num(_length),
        'headCm': _num(_head),
      }),
    );
  }
}

class _DoseDialog extends ConsumerStatefulWidget {
  const _DoseDialog({required this.childId, required this.clinicId, this.existing});

  final String childId;
  final String? clinicId;
  final Map<String, dynamic>? existing;

  @override
  ConsumerState<_DoseDialog> createState() => _DoseDialogState();
}

class _DoseDialogState extends ConsumerState<_DoseDialog> {
  late String? _vaccine = widget.existing?['vaccineId'] as String?;
  late final _dose = TextEditingController(text: '${widget.existing?['dose'] ?? 1}');
  late final _date = TextEditingController(
    text: '${widget.existing?['givenOn'] ?? ClinicTime.dateOf(ref.read(clockProvider)())}',
  );
  late final _lot = TextEditingController(text: '${widget.existing?['lot'] ?? ''}');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalogue = ref.watch(vaccineCatalogueProvider).value ?? const <String, VaccineInfo>{};
    return _FormDialog(
      title: widget.existing == null ? l10n.dashAddDose : l10n.dashCorrect,
      fields: [
        DropdownButtonFormField<String>(
          isExpanded: true,
          key: const Key('d-vaccine'),
          initialValue: _vaccine,
          items: [for (final v in catalogue.values) DropdownMenuItem(value: v.id, child: Text(v.name))],
          onChanged: (v) => setState(() => _vaccine = v),
          decoration: InputDecoration(labelText: l10n.vaccinesTitle),
        ),
        _field('d-dose', _dose, l10n.dashDoseNumber, number: true),
        _field('d-date', _date, l10n.dashDate, ltr: true),
        _field('d-lot', _lot, l10n.dashLot, ltr: true),
      ],
      onSave: () => ref.read(dashboardApiProvider).call('saveDose', {
        'childId': widget.childId,
        if (widget.existing != null) 'id': widget.existing!['id'],
        'clinicId': widget.clinicId,
        'vaccineId': _vaccine,
        'dose': int.tryParse(_dose.text.trim()) ?? 1,
        'givenOn': _date.text.trim(),
        'lot': _lot.text.trim(),
      }),
    );
  }
}

class _NoteDialog extends ConsumerStatefulWidget {
  const _NoteDialog({required this.childId, required this.visit});

  final String childId;
  final Map<String, dynamic> visit;

  @override
  ConsumerState<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends ConsumerState<_NoteDialog> {
  late final _text = TextEditingController(text: '${widget.visit['note'] ?? ''}');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _FormDialog(
      title: l10n.dashNote,
      fields: [
        TextField(
          key: const Key('note-text'),
          controller: _text,
          maxLines: 6,
          decoration: InputDecoration(helperText: l10n.dashNoteHelp),
        ),
      ],
      onSave: () => ref.read(dashboardApiProvider).call('saveVisitNote', {
        'childId': widget.childId,
        'visitId': widget.visit['id'],
        'text': _text.text,
      }),
    );
  }
}

class _BasicsDialog extends ConsumerStatefulWidget {
  const _BasicsDialog({required this.childId, required this.child});

  final String childId;
  final Map<String, dynamic> child;

  @override
  ConsumerState<_BasicsDialog> createState() => _BasicsDialogState();
}

class _BasicsDialogState extends ConsumerState<_BasicsDialog> {
  late final _name = TextEditingController(text: '${widget.child['name']}');
  late final _birth = TextEditingController(text: '${widget.child['birthDate']}');
  late final _allergies = TextEditingController(text: '${widget.child['allergies'] ?? ''}');
  late String _sex = '${widget.child['sex']}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _FormDialog(
      title: l10n.dashEditBasics,
      fields: [
        _field('b-name', _name, l10n.childName),
        _field('b-birth', _birth, l10n.childBirthDate, ltr: true),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'male', label: Text(l10n.sexMale)),
            ButtonSegment(value: 'female', label: Text(l10n.sexFemale)),
          ],
          selected: {_sex},
          onSelectionChanged: (s) => setState(() => _sex = s.first),
        ),
        _field('b-allergies', _allergies, l10n.childAllergies),
      ],
      onSave: () => ref.read(dashboardApiProvider).call('updateChildBasics', {
        'childId': widget.childId,
        'name': _name.text.trim(),
        'birthDate': _birth.text.trim(),
        'sex': _sex,
        'allergies': _allergies.text.trim(),
      }),
    );
  }
}
