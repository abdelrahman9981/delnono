import 'package:flutter/material.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/settings/settings_repository.dart';

/// The full privacy policy and terms from `settings/policy`, read-only.
Future<void> showPolicySheet(BuildContext context, PolicySettings policy) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Text(l10n.policyPrivacyTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(policy.privacyPolicyText),
          const SizedBox(height: 24),
          Text(l10n.policyTermsTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(policy.termsText),
        ],
      ),
    ),
  );
}
