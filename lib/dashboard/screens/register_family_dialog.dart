import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/messenger.dart';
import '../../app/theme.dart';
import '../../core/clock.dart';
import '../../features/booking/domain/clinic_time.dart';
import '../data/dashboard_api.dart';
import '../data/staff_session.dart';
import '../router.dart';
import '../widgets/dash_page.dart';
import '../widgets/dash_ui.dart';

class _ChildRow {
  _ChildRow([String name = '']) : name = TextEditingController(text: name);

  final TextEditingController name;
  final weight = TextEditingController();
  final allergies = TextEditingController();
  String? birthDate;
  String sex = 'male';

  void dispose() {
    for (final c in [name, weight, allergies]) {
      c.dispose();
    }
  }
}

/// Registers a family at the desk (009 US1, BRD FR-64): the guardian's number, name and relation
/// (for staff only) and each child's basic data. A child already on the number comes back as a
/// duplicate (FR-65): nothing is saved and its file can be opened instead. Returns the new child ids.
class RegisterFamilyDialog extends ConsumerStatefulWidget {
  const RegisterFamilyDialog({super.key, this.phone = '', this.fullName = '', this.childNames = const []});

  /// Prefill from a walk-in.
  final String phone;
  final String fullName;
  final List<String> childNames;

  @override
  ConsumerState<RegisterFamilyDialog> createState() => _RegisterFamilyDialogState();
}

class _RegisterFamilyDialogState extends ConsumerState<RegisterFamilyDialog> {
  late final _phone = TextEditingController(text: widget.phone);
  late final _fullName = TextEditingController(text: widget.fullName);
  String _relation = 'mother';
  late final _children = [
    for (final n in widget.childNames) _ChildRow(n),
    if (widget.childNames.isEmpty) _ChildRow(),
  ];
  List<Map<String, dynamic>> _duplicates = const [];
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    _fullName.dispose();
    for (final c in _children) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final clinicId = ref.read(currentClinicIdProvider);
    setState(() {
      _busy = true;
      _duplicates = const [];
    });
    try {
      final r = await ref.read(dashboardApiProvider).call('registerFamily', {
        'clinicId': clinicId,
        'phone': _phone.text.trim(),
        'fullName': _fullName.text.trim(),
        'relation': _relation,
        'children': [
          for (final c in _children)
            {
              'name': c.name.text.trim(),
              'birthDate': c.birthDate,
              'sex': c.sex,
              'birthWeightKg': ?double.tryParse(c.weight.text.trim().replaceAll('٫', '.')),
              if (c.allergies.text.trim().isNotEmpty) 'allergies': c.allergies.text.trim(),
            },
        ],
      });
      showAppMessage(l10n.dashFamilyRegistered);
      if (mounted) Navigator.pop(context, [for (final id in (r['childIds'] as List? ?? const [])) '$id']);
    } on StaffActionRefused catch (e) {
      if (e.reason == 'duplicate') {
        setState(() => _duplicates = [for (final d in (e.details['duplicates'] as List? ?? const [])) Map<String, dynamic>.from(d as Map)]);
      } else {
        showAppMessage(dashErrorText(l10n, e));
      }
    } catch (e) {
      showAppMessage(dashErrorText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    final today = ClinicTime.asDate(ClinicTime.dateOf(ref.watch(clockProvider)()));
    final complete = _phone.text.trim().isNotEmpty &&
        _fullName.text.trim().isNotEmpty &&
        _children.every((ch) => ch.name.text.trim().isNotEmpty && ch.birthDate != null);

    Widget field(String label, Widget child, {double width = 240}) => SizedBox(width: width, child: DashField(label: label, child: child));

    return AlertDialog(
      title: Text(l10n.dashRegisterFamily),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            Text(l10n.dashRegisterFamilyHint, style: TextStyle(fontSize: 13, color: c.muted)),
            const SizedBox(height: 16),
            if (_duplicates.isNotEmpty) ...[
              Container(
                key: const Key('family-duplicates'),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: c.yellowSoft, borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l10n.dashDuplicateTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(l10n.dashDuplicateBody, style: const TextStyle(fontSize: 13)),
                  for (final d in _duplicates)
                    Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      Text('${l10n.dashChildN('${(d['index'] as num) + 1}')} · ${d['name']}'),
                      if ('${d['childId'] ?? ''}'.isNotEmpty)
                        TextButton(
                          key: Key('open-duplicate-${d['childId']}'),
                          onPressed: () {
                            Navigator.pop(context);
                            context.go('${DashRoutes.children}/${d['childId']}');
                          },
                          child: Text(l10n.dashOpenExisting),
                        ),
                    ]),
                ]),
              ),
              const SizedBox(height: 16),
            ],
            Wrap(spacing: 16, runSpacing: 14, children: [
              field(
                l10n.dashPhone,
                TextField(
                  key: const Key('family-phone'),
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  onChanged: (_) => setState(() {}),
                  decoration: dashInput(context, hint: '01xxxxxxxxx'),
                ),
              ),
              field(
                l10n.guardianFullName,
                TextField(
                  key: const Key('family-name'),
                  controller: _fullName,
                  onChanged: (_) => setState(() {}),
                  decoration: dashInput(context),
                ),
              ),
              SegmentSwitch<String>(
                key: const Key('family-relation'),
                options: [('mother', l10n.relationMother), ('father', l10n.relationFather), ('other', l10n.relationOther)],
                value: _relation,
                onChanged: (v) => setState(() => _relation = v),
              ),
            ]),
            for (final (i, ch) in _children.indexed) ...[
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: Text(l10n.dashChildN('${i + 1}'), style: const TextStyle(fontWeight: FontWeight.w700))),
                if (_children.length > 1)
                  IconButton(
                    key: Key('family-remove-$i'),
                    tooltip: l10n.dashRemove,
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _children.removeAt(i).dispose()),
                  ),
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 16, runSpacing: 14, crossAxisAlignment: WrapCrossAlignment.end, children: [
                field(
                  l10n.childName,
                  TextField(
                    key: Key('family-child-name-$i'),
                    controller: ch.name,
                    onChanged: (_) => setState(() {}),
                    decoration: dashInput(context),
                  ),
                ),
                field(
                  l10n.childBirthDate,
                  DateField(
                    key: Key('family-child-birth-$i'),
                    value: ch.birthDate,
                    hint: l10n.childBirthDatePick,
                    first: DateTime(today.year - 18),
                    last: today,
                    onChanged: (d) => setState(() => ch.birthDate = d),
                  ),
                ),
                SegmentSwitch<String>(
                  key: Key('family-child-sex-$i'),
                  options: [('male', l10n.sexMale), ('female', l10n.sexFemale)],
                  value: ch.sex,
                  onChanged: (v) => setState(() => ch.sex = v),
                ),
                field(
                  l10n.dashBirthWeight,
                  TextField(
                    key: Key('family-child-weight-$i'),
                    controller: ch.weight,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: dashInput(context, unit: l10n.unitKg),
                  ),
                  width: 160,
                ),
                field(
                  l10n.dashAllergiesOptional,
                  TextField(key: Key('family-child-allergies-$i'), controller: ch.allergies, decoration: dashInput(context)),
                ),
              ]),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AddChip(key: const Key('family-add-child'), label: l10n.dashAddChild, onTap: () => setState(() => _children.add(_ChildRow()))),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.dashClose)),
        FilledButton(key: const Key('family-save'), onPressed: complete && !_busy ? _save : null, child: Text(l10n.save)),
      ],
    );
  }
}
