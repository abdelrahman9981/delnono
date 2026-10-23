import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/theme.dart';
import '../../../core/errors/arabic_errors.dart';
import '../../../core/format/age.dart';
import '../../../core/format/arabic_digits.dart';
import '../../../core/validation/registration_rules.dart';
import '../../../core/widgets/notice.dart';
import '../../auth/data/auth_repository.dart';
import '../data/children_repository.dart';

/// A child's basic details (`/children/:id`). The guardian edits name and allergies only; birth
/// date and sex are shown read-only because they drive the vaccine schedule (FR-023, FR-024).
class ChildProfileScreen extends ConsumerStatefulWidget {
  const ChildProfileScreen({super.key, required this.childId});

  final String childId;

  @override
  ConsumerState<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends ConsumerState<ChildProfileScreen> {
  final _name = TextEditingController();
  final _allergies = TextEditingController();
  String? _loadedFor;
  bool _submitted = false;
  bool _saving = false;
  bool _saved = false;
  Object? _error;

  @override
  void dispose() {
    _name.dispose();
    _allergies.dispose();
    super.dispose();
  }

  void _load(Child child) {
    if (_loadedFor == child.id) return;
    _loadedFor = child.id;
    _name.text = child.name;
    _allergies.text = child.allergies ?? '';
  }

  Future<void> _save() async {
    setState(() {
      _submitted = true;
      _saved = false;
      _error = null;
    });
    if (!validChildName(_name.text) || !validAllergies(_allergies.text)) return;
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      final allergies = _allergies.text.trim();
      await ref.read(childrenRepositoryProvider).updateDetails(
            widget.childId,
            uid: uid,
            name: _name.text.trim(),
            allergies: allergies.isEmpty ? null : allergies,
          );
      if (mounted) setState(() => _saved = true);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    // Watched so the signed-in uid is ready when saving (rules require it as updatedBy).
    ref.watch(authStateProvider);
    final child = ref.watch(childProvider(widget.childId));
    final loading = ref.watch(childrenProvider).isLoading;

    if (child == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.screenChildProfile)),
        body: Center(child: loading ? const CircularProgressIndicator() : Text(l10n.childNotFound)),
      );
    }
    _load(child);

    Widget readOnly(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(child: Text(label, style: text.bodyMedium?.copyWith(color: c.muted))),
              Text(value, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(child.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            TextField(
              key: const Key('profile-name'),
              controller: _name,
              decoration: InputDecoration(
                labelText: l10n.childName,
                errorText: _submitted && !validChildName(_name.text) ? l10n.errChildName : null,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('profile-allergies'),
              controller: _allergies,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.childAllergies,
                errorText: _submitted && !validAllergies(_allergies.text) ? l10n.errAllergies : null,
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                child: Column(
                  children: [
                    readOnly(
                      l10n.childBirthDate,
                      arabicDigits(DateFormat.yMMMMd('ar').format(DateTime.parse(child.birthDate))),
                    ),
                    readOnly('', arabicAge(child.birthDate, l10n)),
                    readOnly(l10n.childSex, child.sex == Sex.female ? l10n.sexFemale : l10n.sexMale),
                    if (child.birthWeightKg != null)
                      readOnly(l10n.childBirthWeight, '${arabicDigits(child.birthWeightKg!.toString().replaceAll('.', '٫'))} ${l10n.kg}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Notice(l10n.childFixedFieldsLocked, icon: Icons.lock_outline),
            if (_saved) ...[const SizedBox(height: 12), Notice(l10n.childSaved, icon: Icons.check_circle_outline)],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Notice(arabicErrorMessage(_error!, l10n), kind: NoticeKind.danger),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
