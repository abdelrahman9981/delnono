import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/route_guard.dart';
import '../../../app/theme.dart';
import '../../../core/validation/registration_rules.dart';
import '../../../core/widgets/notice.dart';
import '../../../core/widgets/segmented.dart';
import '../../../core/widgets/step_indicator.dart';
import '../application/registration_controller.dart';
import '../data/guardian_repository.dart';
import '../data/registration_api.dart';

/// Guardian details (design screen 4, docs/design/screens/Guardian.dc.html). Nothing is stored
/// here; the details go to the consent screen in memory (FR-015).
class GuardianDetailsScreen extends ConsumerStatefulWidget {
  const GuardianDetailsScreen({super.key, this.from});

  final String? from;

  @override
  ConsumerState<GuardianDetailsScreen> createState() => _GuardianDetailsScreenState();
}

class _GuardianDetailsScreenState extends ConsumerState<GuardianDetailsScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  Relation? _relation;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final previous = ref.read(registrationControllerProvider).details;
    if (previous != null) {
      _name.text = previous.fullName;
      _email.text = previous.email ?? '';
      _relation = previous.relation;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _nameOk => validFullName(_name.text);
  bool get _emailOk => validOptionalEmail(_email.text);

  void _next() {
    setState(() => _submitted = true);
    if (!_nameOk || _relation == null || !_emailOk) return;
    final email = _email.text.trim();
    ref.read(registrationControllerProvider.notifier).setDetails(GuardianDetails(
          fullName: _name.text.trim(),
          relation: _relation!,
          email: email.isEmpty ? null : email,
        ));
    context.go(Uri(
      path: Routes.registerConsent,
      queryParameters: widget.from == null ? null : {'from': widget.from},
    ).toString());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenGuardian), automaticallyImplyLeading: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            const StepIndicator(current: 2),
            Text(l10n.guardianHeading, style: text.headlineMedium),
            const SizedBox(height: 8),
            Text(l10n.guardianIntro, style: text.bodyMedium?.copyWith(color: colors.muted)),
            const SizedBox(height: 22),
            TextField(
              key: const Key('guardian-name'),
              controller: _name,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: InputDecoration(
                labelText: l10n.guardianFullName,
                errorText: _submitted && !_nameOk ? l10n.errFullName : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            Text(l10n.guardianRelation, style: text.labelMedium),
            const SizedBox(height: 7),
            Segmented<Relation>(
              options: [
                (Relation.mother, l10n.relationMother),
                (Relation.father, l10n.relationFather),
                (Relation.other, l10n.relationOther),
              ],
              value: _relation,
              hasError: _submitted && _relation == null,
              onChanged: (r) => setState(() => _relation = r),
            ),
            if (_submitted && _relation == null)
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 12),
                child: Text(l10n.errRelation, style: text.bodySmall?.copyWith(color: colors.dangerText)),
              ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('guardian-email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: l10n.guardianEmail,
                helperText: l10n.guardianEmailHelp,
                errorText: _submitted && !_emailOk ? l10n.errEmail : null,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _next(),
            ),
            const SizedBox(height: 18),
            Notice(l10n.guardianNothingSaved, icon: Icons.lock_outline),
            const SizedBox(height: 28),
            FilledButton(onPressed: _next, child: Text(l10n.next)),
          ],
        ),
      ),
    );
  }
}
