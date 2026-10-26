import 'package:flutter/material.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme.dart';

/// A read that failed: a message and «حاولي تاني». Screens show this instead of nothing, and never
/// treat a failed read as "no data" (bug 0003).
class LoadErrorView extends StatelessWidget {
  const LoadErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Padding(
        key: const Key('load-error'),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off_outlined, size: 44, color: c.muted),
          const SizedBox(height: 10),
          Text(l10n.loadError, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 14),
          FilledButton(key: const Key('load-retry'), onPressed: onRetry, child: Text(l10n.signInRetry)),
        ]),
      ),
    );
  }
}
