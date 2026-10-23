import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/route_guard.dart';

/// Top-bar entry to the account screen (design screen 11).
class AccountButton extends StatelessWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
        key: const Key('account-button'),
        tooltip: AppLocalizations.of(context).screenAccount,
        icon: const Icon(Icons.person_outline),
        onPressed: () => context.go(Routes.account),
      );
}
