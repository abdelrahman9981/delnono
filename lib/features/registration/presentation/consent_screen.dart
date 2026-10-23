import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/route_guard.dart';
import '../../../app/theme.dart';
import '../../../core/errors/arabic_errors.dart';
import '../../../core/format/arabic_digits.dart';
import '../../../core/settings/settings_repository.dart';
import '../../../core/widgets/check_row.dart';
import '../../../core/widgets/notice.dart';
import '../../../core/widgets/step_indicator.dart';
import '../application/registration_controller.dart';
import '../data/guardian_repository.dart';
import 'policy_sheet.dart';

/// Privacy consent (design screen 5, docs/design/screens/Consent.dc.html). Two separate, unticked
/// consents (FR-014). For a new guardian this sends details and consent together (FR-015); for a
/// registered guardian with an outdated version it records the new consent (FR-017). The router
/// guard moves on once the guardian doc reflects the consent.
class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key, this.from});

  final String? from;

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _policy = false;
  bool _childData = false;

  bool get _reconsent => ref.read(guardianProvider).value != null;
  bool _redirecting = false;

  /// New guardians reach consent only with details in memory; after a restart they are gone, so
  /// go back to the details screen. Decided only once the guardian doc has loaded, so a registered
  /// guardian re-consenting (FR-017) is never sent there.
  void _checkDetails() {
    if (_redirecting || _reconsent || ref.read(registrationControllerProvider).details != null) return;
    _redirecting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(Uri(
        path: Routes.registerGuardian,
        queryParameters: widget.from == null ? null : {'from': widget.from},
      ).toString());
    });
  }

  Future<void> _accept(PolicySettings policy) async {
    final controller = ref.read(registrationControllerProvider.notifier);
    if (_reconsent) {
      await controller.acceptPolicy(policy.currentVersion);
    } else {
      await controller.consentAndRegister(policy.currentVersion);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final guardian = ref.watch(guardianProvider);
    if (!guardian.hasValue && !guardian.hasError) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _checkDetails();
    final policy = ref.watch(policySettingsProvider).value ?? const PolicySettings();
    final state = ref.watch(registrationControllerProvider);
    final reconsent = guardian.value != null;

    final version = arabicDigits(policy.currentVersion);
    final versionLine = policy.updatedAt == null
        ? l10n.consentVersion(version)
        : l10n.consentVersionDated(version, arabicDigits(DateFormat.yMMMMd('ar').format(policy.updatedAt!)));
    final canAccept = _policy && _childData && !state.submitting;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.consentTitle),
        leading: reconsent
            ? null
            : BackButton(
                onPressed: () => context.go(Uri(
                  path: Routes.registerGuardian,
                  queryParameters: widget.from == null ? null : {'from': widget.from},
                ).toString()),
              ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            if (!reconsent) const StepIndicator(current: 3),
            Text(reconsent ? l10n.consentUpdatedHeading : l10n.consentHeading, style: text.headlineMedium),
            const SizedBox(height: 8),
            Text(
              reconsent ? l10n.consentUpdatedIntro : l10n.consentIntro,
              style: text.bodyMedium?.copyWith(color: colors.muted),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (icon, line) in [
                      (Icons.folder_outlined, l10n.consentWhat),
                      (Icons.visibility_outlined, l10n.consentWho),
                      (Icons.delete_outline, l10n.consentDelete),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(icon, size: 18, color: colors.blue),
                            const SizedBox(width: 9),
                            Expanded(child: Text(line, style: text.bodyMedium)),
                          ],
                        ),
                      ),
                    TextButton(
                      onPressed: () => showPolicySheet(context, policy),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Text(l10n.consentReadFull),
                    ),
                    if (policy.isPlaceholder)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.muted),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(l10n.consentPlaceholder, style: text.labelSmall?.copyWith(color: colors.muted)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            CheckRow(
              key: const Key('consent-policy'),
              value: _policy,
              onChanged: (v) => setState(() => _policy = v),
              title: l10n.consentPolicyCheck,
              subtitle: versionLine,
            ),
            const SizedBox(height: 8),
            CheckRow(
              key: const Key('consent-child-data'),
              value: _childData,
              onChanged: (v) => setState(() => _childData = v),
              title: l10n.consentChildDataCheck,
              subtitle: l10n.consentChildDataSub,
            ),
            if (state.error != null) ...[
              const SizedBox(height: 12),
              Notice(arabicErrorMessage(state.error!, l10n), kind: NoticeKind.danger),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: canAccept ? () => _accept(policy) : null,
              child: state.submitting
                  ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(l10n.consentAccept),
            ),
            const SizedBox(height: 10),
            Text(l10n.consentBothRequired, style: text.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
