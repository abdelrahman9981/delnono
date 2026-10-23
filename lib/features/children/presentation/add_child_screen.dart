import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/route_guard.dart';
import '../../../app/theme.dart';
import '../../../core/errors/arabic_errors.dart';
import '../../../core/format/arabic_digits.dart';
import '../../../core/validation/registration_rules.dart';
import '../../../core/widgets/notice.dart';
import '../../../core/widgets/segmented.dart';
import '../../../core/widgets/step_indicator.dart';
import '../../registration/application/registration_controller.dart';
import '../data/children_repository.dart';

/// Add a child (design screen 6, docs/design/screens/AddChild.dc.html). Used as the last step of
/// first-run registration (`/register/child`) and from the children list (`/children/add`).
class AddChildScreen extends ConsumerStatefulWidget {
  const AddChildScreen({super.key, this.registration = false, this.from});

  final bool registration;
  final String? from;

  @override
  ConsumerState<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends ConsumerState<AddChildScreen> {
  final _name = TextEditingController();
  final _weight = TextEditingController();
  final _allergies = TextEditingController();
  DateTime? _birthDate;
  Sex? _sex;
  bool _submitted = false;
  bool _saving = false;
  String? _duplicateMessage;
  Object? _error;

  @override
  void dispose() {
    _name.dispose();
    _weight.dispose();
    _allergies.dispose();
    super.dispose();
  }

  bool get _nameOk => validChildName(_name.text);
  double? get _weightKg => parseDecimal(_weight.text);
  bool get _weightOk => validBirthWeight(_weightKg);
  bool get _allergiesOk => validAllergies(_allergies.text);

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? today,
      firstDate: DateTime(today.year - 18, today.month, today.day),
      lastDate: today,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save(AppLocalizations l10n) async {
    setState(() {
      _submitted = true;
      _duplicateMessage = null;
      _error = null;
    });
    if (!_nameOk || _birthDate == null || _sex == null || !_weightOk || !_allergiesOk) return;

    setState(() => _saving = true);
    final name = _name.text.trim();
    try {
      await ref.read(childrenRepositoryProvider).createChild(NewChild(
            name: name,
            birthDate: isoDate(_birthDate!),
            sex: _sex!,
            birthWeightKg: _weightKg,
            allergies: _allergies.text.trim().isEmpty ? null : _allergies.text.trim(),
          ));
      if (!mounted) return;
      if (widget.registration) {
        // Ends first-run registration; the guard continues to `from`.
        ref.read(registrationControllerProvider.notifier).finish();
      } else {
        context.go(Routes.children);
      }
    } on DuplicateChildException catch (e) {
      setState(() => _duplicateMessage =
          e.existingLinked ? l10n.childDuplicateLinked(name) : l10n.childDuplicateClinic(name));
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    String? fieldError(bool ok, String message) => _submitted && !ok ? message : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.screenAddChild),
        automaticallyImplyLeading: !widget.registration,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            if (widget.registration) const StepIndicator(current: 4),
            TextField(
              key: const Key('child-name'),
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.childName,
                errorText: fieldError(_nameOk, l10n.errChildName),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            Text(l10n.childBirthDate, style: text.labelMedium),
            const SizedBox(height: 7),
            InkWell(
              key: const Key('child-birth-date'),
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: InputDecoration(
                  errorText: fieldError(_birthDate != null, l10n.errBirthDate),
                  suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                ),
                child: Text(
                  _birthDate == null
                      ? l10n.childBirthDatePick
                      : arabicDigits(DateFormat.yMMMMd('ar').format(_birthDate!)),
                  style: text.bodyLarge?.copyWith(color: _birthDate == null ? colors.muted : null),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(l10n.childSex, style: text.labelMedium),
            const SizedBox(height: 7),
            Segmented<Sex>(
              options: [(Sex.male, l10n.sexMale), (Sex.female, l10n.sexFemale)],
              value: _sex,
              hasError: _submitted && _sex == null,
              onChanged: (s) => setState(() => _sex = s),
            ),
            if (_submitted && _sex == null)
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 12),
                child: Text(l10n.errSex, style: text.bodySmall?.copyWith(color: colors.dangerText)),
              ),
            const SizedBox(height: 10),
            Notice(l10n.childFixedFieldsNote),
            const SizedBox(height: 14),
            TextField(
              key: const Key('child-weight'),
              controller: _weight,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,٫]'))],
              decoration: InputDecoration(
                labelText: l10n.childBirthWeight,
                suffixText: l10n.kg,
                errorText: fieldError(_weightOk, l10n.errBirthWeight),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('child-allergies'),
              controller: _allergies,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.childAllergies,
                errorText: fieldError(_allergiesOk, l10n.errAllergies),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_duplicateMessage != null) ...[
              const SizedBox(height: 14),
              Notice(_duplicateMessage!, kind: NoticeKind.warn),
            ],
            if (_error != null) ...[
              const SizedBox(height: 14),
              Notice(arabicErrorMessage(_error!, l10n), kind: NoticeKind.danger),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : () => _save(l10n),
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
