import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/clock.dart';
import '../../core/format/age.dart';
import '../../core/format/arabic_digits.dart';
import '../../features/booking/domain/clinic_time.dart';
import '../../features/booking/presentation/booking_format.dart';
import '../../features/child_profile/data/vaccine_schedule_repository.dart';
import '../../features/child_profile/presentation/profile_format.dart';
import '../../features/clinics/data/clinics_repository.dart';
import '../data/dashboard_api.dart';
import '../data/staff_session.dart';
import '../router.dart';
import '../widgets/dash_page.dart';
import '../widgets/dash_ui.dart';
import 'merge_dialog.dart';

/// The child file, opened through `openChildFile` so the opening is logged (D-13, FR-028).
final childFileProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, childId) => ref.read(dashboardApiProvider).call('openChildFile', {'childId': childId}),
);

/// Child file (005 US4; docs/design/dashboard/ChildFile): a header card with the child, guardian,
/// package and clinics visited, then tabs for measurements, doses, visits and the doctor's notes.
/// Staff record at their clinic (D-29); only the doctor corrects (with a change log) and reads or
/// writes notes (D-11); the family package can be sold here (D-46).
class ChildFileScreen extends ConsumerStatefulWidget {
  const ChildFileScreen({super.key, required this.childId});

  final String childId;

  @override
  ConsumerState<ChildFileScreen> createState() => _ChildFileScreenState();
}

class _ChildFileScreenState extends ConsumerState<ChildFileScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final file = ref.watch(childFileProvider(widget.childId));
    return DashPage(
      title: l10n.dashChildFileTitle,
      subtitle: l10n.dashChildFileAudited,
      leading: IconButton(
        key: const Key('child-back'),
        tooltip: l10n.dashBack,
        // The platform back arrow follows the text direction: it points right (›, back) in RTL.
        icon: const BackButtonIcon(),
        onPressed: () => context.go(DashRoutes.children),
      ),
      children: [
        file.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Center(child: Text(dashErrorText(l10n, e))),
          data: (f) => f['merged'] is Map
              ? _ClosedFile(merged: Map<String, dynamic>.from(f['merged'] as Map))
              : _File(childId: widget.childId, file: f, tab: _tab, onTab: (i) => setState(() => _tab = i)),
        ),
      ],
    );
  }
}

class _File extends ConsumerWidget {
  const _File({required this.childId, required this.file, required this.tab, required this.onTab});

  final String childId;
  final Map<String, dynamic> file;
  final int tab;
  final ValueChanged<int> onTab;

  List<Map<String, dynamic>> _list(String key) => [
    for (final x in (file[key] as List? ?? const [])) Map<String, dynamic>.from(x as Map),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    final child = Map<String, dynamic>.from(file['child'] as Map);
    final isDoctor = ref.watch(staffSessionProvider).value?.isDoctor ?? false;
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
    final visited = {
      for (final r in [...measurements, ...doses, ...visits])
        if (clinicName(r['clinicId']).isNotEmpty) clinicName(r['clinicId']),
    };
    void reload() => ref.invalidate(childFileProvider(childId));
    Future<void> dialog(Widget d) async {
      if (await showDialog<bool>(context: context, builder: (_) => d) == true) reload();
    }

    Future<void> confirmThen(String title, String body, String callable, String done) async {
      final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: SizedBox(width: 420, child: Text(body)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.dashClose)),
            FilledButton(
              key: const Key('confirm-yes'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(title),
            ),
          ],
        ),
      );
      if (yes != true || !context.mounted) return;
      if (await runAction(
        context,
        () => ref.read(dashboardApiProvider).call(callable, {'childId': childId}),
        done: done,
      )) {
        reload();
      }
    }

    String value(Object? v, String unit) => v == null ? '—' : '${measureValue((v as num).toDouble())} $unit';
    Widget recorder(Map<String, dynamic> r) => Text('${r['recordedByName'] ?? '—'}', style: TextStyle(color: c.muted));
    Widget correction(Map<String, dynamic> r, String kind, Widget Function() editor) => Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (r['correctedBy'] != null) StatusPill(l10n.dashCorrected, PillKind.warn, dot: false),
        if (isDoctor)
          OutlinedButton.icon(
            key: Key('correct-$kind-${r['id']}'),
            onPressed: () => dialog(editor()),
            icon: const Icon(Icons.edit_note, size: 18),
            label: Text(l10n.dashCorrectShort),
          ),
      ],
    );

    final header = DashCard(
      key: const Key('child-header'),
      child: Wrap(
        spacing: 20,
        runSpacing: 14,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InitialAvatar('${child['name']}', tone: child['sex'] == 'female' ? Tone.pink : Tone.blue, size: 56),
              const SizedBox(width: 14),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${child['name']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    Text(
                      '${arabicAge('${child['birthDate']}', l10n)} · ${child['sex'] == 'female' ? l10n.sexFemale : l10n.sexMale} · ${child['birthDate']}',
                      style: TextStyle(color: c.muted),
                    ),
                    Text(
                      [
                        '${l10n.dashGuardian}: ${child['guardianPhone'] ?? ''}',
                        if (file['clinicGuardian'] case {'fullName': final String name}) name,
                      ].join(' · '),
                      style: TextStyle(color: c.muted),
                    ),
                    if (child['allergies'] != null && '${child['allergies']}'.isNotEmpty)
                      Text(l10n.detailsAllergies('${child['allergies']}'), style: TextStyle(color: c.dangerText)),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (package != null)
                StatusPill(
                  l10n.packageActiveUntil('${package['endsOn']}'),
                  PillKind.ok,
                  key: const Key('child-package'),
                )
              else ...[
                StatusPill(l10n.dashNoPackage, PillKind.info, dot: false),
                if (child['guardianUid'] != null && clinicId != null)
                  OutlinedButton(
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
              ],
              if (child['guardianUid'] == null)
                StatusPill(l10n.dashNotLinked, PillKind.warn, key: const Key('child-unlinked')),
              // Staff lift a guardian's lock after checking them in person (009 FR-008, FR-008a).
              if (child['guardianUid'] == null && file['accountOnNumber'] == true)
                OutlinedButton(
                  key: const Key('staff-link'),
                  onPressed: () =>
                      confirmThen(l10n.dashLinkToAccount, l10n.dashLinkConfirm, 'staffLinkChildren', l10n.dashLinked),
                  child: Text(l10n.dashLinkToAccount),
                ),
              if (file['reverifyLocked'] == true)
                OutlinedButton(
                  key: const Key('unlock-reverify'),
                  onPressed: () =>
                      confirmThen(l10n.dashUnlockReverify, l10n.dashUnlockConfirm, 'unlockReverify', l10n.dashUnlocked),
                  child: Text(l10n.dashUnlockReverify),
                ),
              if (visited.isNotEmpty)
                StatusPill(l10n.dashClinicsVisited(visited.join(l10n.listSeparator)), PillKind.info, dot: false),
              if (isDoctor)
                OutlinedButton.icon(
                  key: const Key('merge-file'),
                  onPressed: () async {
                    final keepId = await showDialog<String>(
                      context: context,
                      builder: (_) => MergeDialog(
                        child: {...child, 'id': childId},
                        counts: (measurements.length, doses.length, visits.length),
                      ),
                    );
                    if (keepId == null || !context.mounted) return;
                    if (keepId == childId) {
                      reload();
                    } else {
                      context.go('${DashRoutes.children}/$keepId');
                    }
                  },
                  icon: const Icon(Icons.merge_type, size: 18),
                  label: Text(l10n.dashMergeFile),
                ),
              OutlinedButton.icon(
                key: const Key('edit-basics'),
                onPressed: () => dialog(_BasicsDialog(childId: childId, child: child)),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(l10n.dashEditBasics),
              ),
            ],
          ),
        ],
      ),
    );

    final history = DashCard(
      title: l10n.dashMeasurementHistory,
      icon: Icons.straighten,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (measurements.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(l10n.noMeasurements, style: TextStyle(color: c.muted)),
            )
          else
            DashTable(
              headers: [
                l10n.dashColDate,
                l10n.measureWeight,
                l10n.measureLength,
                l10n.measureHead,
                l10n.dashColClinic,
                l10n.dashColRecorder,
                '',
              ],
              flex: const [3, 2, 2, 2, 2, 3, 4],
              rows: [
                for (final m in measurements)
                  DashRow(
                    key: Key('measurement-${m['id']}'),
                    cells: [
                      Text('${m['measuredOn']}'),
                      Text(value(m['weightKg'], l10n.unitKg), style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(value(m['lengthCm'], l10n.unitCm)),
                      Text(value(m['headCm'], l10n.unitCm)),
                      Text(clinicName(m['clinicId'])),
                      recorder(m),
                      correction(
                        m,
                        'measurement',
                        () => _MeasurementDialog(childId: childId, clinicId: clinicId, existing: m),
                      ),
                    ],
                  ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Text(l10n.dashNumbersOnly, style: TextStyle(fontSize: 12, color: c.muted)),
          ),
        ],
      ),
    );

    final measurementsTab = LayoutBuilder(
      builder: (context, box) {
        final form = _NewMeasurement(childId: childId, clinicId: clinicId, onSaved: reload);
        if (box.maxWidth < 900) return Column(children: [form, const SizedBox(height: 16), history]);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 320, child: form),
            const SizedBox(width: 16),
            Expanded(child: history),
          ],
        );
      },
    );

    final dosesTab = DashCard(
      title: l10n.dashDoses,
      icon: Icons.vaccines_outlined,
      tone: Tone.green,
      padding: EdgeInsets.zero,
      action: FilledButton.icon(
        key: const Key('add-dose'),
        onPressed: () => dialog(_DoseDialog(childId: childId, clinicId: clinicId)),
        icon: const Icon(Icons.add),
        label: Text(l10n.dashAddDose),
      ),
      child: doses.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Text(l10n.dashNothingYet, style: TextStyle(color: c.muted)),
            )
          : DashTable(
              headers: [
                l10n.dashColVaccine,
                l10n.dashColDose,
                l10n.dashColDate,
                l10n.dashColLot,
                l10n.dashColClinic,
                l10n.dashColRecorder,
                '',
              ],
              flex: const [4, 2, 3, 2, 2, 3, 4],
              rows: [
                for (final d in doses)
                  DashRow(
                    key: Key('dose-${d['id']}'),
                    cells: [
                      Text(
                        catalogue[d['vaccineId']]?.name ?? '${d['vaccineId']}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(arabicDigits(d['dose'] as num? ?? 1)),
                      Text('${d['givenOn']}'),
                      Text('${d['lot'] ?? '—'}', textDirection: TextDirection.ltr),
                      Text(clinicName(d['clinicId'])),
                      recorder(d),
                      correction(d, 'dose', () => _DoseDialog(childId: childId, clinicId: clinicId, existing: d)),
                    ],
                  ),
              ],
            ),
    );

    final visitsTab = DashCard(
      title: l10n.dashVisits,
      icon: Icons.event_available_outlined,
      padding: EdgeInsets.zero,
      child: visits.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Text(l10n.visitsEmpty, style: TextStyle(color: c.muted)),
            )
          : DashTable(
              headers: [l10n.dashColDate, l10n.dashColClinic],
              flex: const [1, 1],
              rows: [
                for (final v in visits)
                  DashRow(key: Key('visit-${v['id']}'), cells: [Text('${v['date']}'), Text(clinicName(v['clinicId']))]),
              ],
            ),
    );

    // The doctor's notes: sent to the doctor only (FR-016), so the tab is the doctor's only.
    final notesTab = DashCard(
      title: l10n.dashDoctorNotes,
      hint: l10n.dashNoteHelp,
      icon: Icons.lock_outline,
      tone: Tone.navy,
      padding: EdgeInsets.zero,
      child: visits.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Text(l10n.visitsEmpty, style: TextStyle(color: c.muted)),
            )
          : DashTable(
              headers: [l10n.dashColDate, l10n.dashColClinic, l10n.dashColNote, ''],
              flex: const [2, 2, 6, 2],
              rows: [
                for (final v in visits)
                  DashRow(
                    key: Key('note-row-${v['id']}'),
                    cells: [
                      Text('${v['date']}'),
                      Text(clinicName(v['clinicId'])),
                      Text((v['note'] as String?)?.isNotEmpty == true ? '${v['note']}' : l10n.dashNoNote),
                      IconButton(
                        key: Key('note-${v['id']}'),
                        tooltip: l10n.dashNote,
                        icon: const Icon(Icons.sticky_note_2_outlined),
                        onPressed: () => dialog(_NoteDialog(childId: childId, visit: v)),
                      ),
                    ],
                  ),
              ],
            ),
    );

    final tabs = [measurementsTab, dosesTab, visitsTab, if (isDoctor) notesTab];
    final index = tab.clamp(0, tabs.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 16),
        DashTabs(
          index: index,
          onChanged: onTab,
          tabs: [
            Text(l10n.dashMeasurements),
            Text(l10n.vaccinesTitle),
            Text(l10n.dashVisits),
            if (isDoctor)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.dashDoctorNotes),
                  const SizedBox(width: 6),
                  Icon(Icons.lock_outline, size: 14, color: Theme.of(context).extension<AppColors>()!.muted),
                  const SizedBox(width: 4),
                  StatusPill(l10n.dashDoctorOnly, PillKind.info, dot: false),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),
        tabs[index],
      ],
    );
  }
}

/// A closed file (009 FR-007): only where it was merged into.
class _ClosedFile extends StatelessWidget {
  const _ClosedFile({required this.merged});

  final Map<String, dynamic> merged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DashCard(
      key: const Key('child-closed'),
      title: l10n.dashFileClosed,
      icon: Icons.merge_type,
      tone: Tone.yellow,
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('${merged['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
          FilledButton(
            key: const Key('open-kept'),
            onPressed: () => context.go('${DashRoutes.children}/${merged['into']}'),
            child: Text(l10n.dashOpenKept),
          ),
        ],
      ),
    );
  }
}

/// "Record a new measurement" (`.side-form`): date from a picker, then at least one value.
class _NewMeasurement extends ConsumerStatefulWidget {
  const _NewMeasurement({required this.childId, required this.clinicId, required this.onSaved});

  final String childId;
  final String? clinicId;
  final VoidCallback onSaved;

  @override
  ConsumerState<_NewMeasurement> createState() => _NewMeasurementState();
}

class _NewMeasurementState extends ConsumerState<_NewMeasurement> {
  late String _date = ClinicTime.dateOf(ref.read(clockProvider)());
  final _weight = TextEditingController();
  final _length = TextEditingController();
  final _head = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _weight.dispose();
    _length.dispose();
    _head.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = ClinicTime.asDate(ClinicTime.dateOf(ref.read(clockProvider)()));
    final picked = await showDatePicker(
      context: context,
      firstDate: today.subtract(const Duration(days: 365 * 18)),
      lastDate: today,
      initialDate: ClinicTime.asDate(_date),
    );
    if (picked != null) setState(() => _date = DateFormat('yyyy-MM-dd').format(picked));
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final ok = await runAction(
      context,
      () => ref.read(dashboardApiProvider).call('saveMeasurement', {
        'childId': widget.childId,
        'clinicId': widget.clinicId,
        'measuredOn': _date,
        'weightKg': _num(_weight),
        'lengthCm': _num(_length),
        'headCm': _num(_head),
      }),
      done: l10n.dashSaved,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      for (final c in [_weight, _length, _head]) {
        c.clear();
      }
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    Widget value(String key, TextEditingController ctl, String label, String unit) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DashField(
        label: label,
        child: TextField(
          key: Key(key),
          controller: ctl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: dashInput(context, unit: unit),
        ),
      ),
    );
    return DashCard(
      key: const Key('new-measurement'),
      title: l10n.dashNewMeasurement,
      icon: Icons.add_chart,
      tone: Tone.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DashField(
              label: l10n.dashDate,
              child: InkWell(
                key: const Key('new-m-date'),
                borderRadius: BorderRadius.circular(12),
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: dashInput(context)
                      .copyWith(suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18)),
                  child: Text(dayLabel(_date)),
                ),
              ),
            ),
          ),
          value('new-m-weight', _weight, l10n.measureWeight, l10n.unitKg),
          value('new-m-length', _length, l10n.measureLength, l10n.unitCm),
          value('new-m-head', _head, l10n.measureHead, l10n.unitCm),
          FilledButton(
            key: const Key('add-measurement'),
            onPressed: _busy ? null : _save,
            child: Text(l10n.dashSaveMeasurement),
          ),
          const SizedBox(height: 10),
          Text(l10n.dashMeasurementHint, style: TextStyle(fontSize: 12, color: c.muted)),
        ],
      ),
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
