import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/messenger.dart';
import '../../../app/route_guard.dart';
import '../../../app/theme.dart';
import '../../../core/errors/arabic_errors.dart';
import '../../../core/widgets/check_row.dart';
import '../../../core/widgets/notice.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/data/auth_repository.dart';
import '../data/account_api.dart';

/// Delete account (`/account/delete`; FR-027 to FR-030). Explains what is removed and what the
/// clinic keeps, and needs an explicit confirmation before anything is deleted.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  bool _confirmed = false;
  bool _deleting = false;
  Object? _error;

  Future<void> _delete(AppLocalizations l10n) async {
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await ref.read(accountApiProvider).deleteAccount();
      // The server removed the Auth user; sign out here and clear the offline cache.
      await ref.read(authRepositoryProvider).signOut();
      ref.read(sessionControllerProvider.notifier).reset();
      appMessengerKey.currentState?.clearSnackBars();
      showAppMessage(l10n.deleteDone);
      if (mounted) context.go(Routes.welcome);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;

    Widget section(IconData icon, Color color, String title, String body) => Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.titleSmall),
                      const SizedBox(height: 4),
                      Text(body, style: text.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenDeleteAccount)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            Text(l10n.deleteHeading, style: text.headlineMedium),
            const SizedBox(height: 16),
            section(Icons.delete_outline, c.dangerText, l10n.deleteRemovedTitle, l10n.deleteRemoved),
            const SizedBox(height: 8),
            section(Icons.folder_shared_outlined, c.blue, l10n.deleteKeptTitle, l10n.deleteKept),
            const SizedBox(height: 12),
            Notice(l10n.deleteComeBack),
            const SizedBox(height: 16),
            CheckRow(
              key: const Key('delete-confirm'),
              value: _confirmed,
              onChanged: (v) => setState(() => _confirmed = v),
              title: l10n.deleteConfirmCheck,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Notice(arabicErrorMessage(_error!, l10n), kind: NoticeKind.danger),
            ],
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('delete-button'),
              style: FilledButton.styleFrom(backgroundColor: c.dangerText, foregroundColor: c.surface),
              onPressed: _confirmed && !_deleting ? () => _delete(l10n) : null,
              child: _deleting
                  ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(l10n.deleteButton),
            ),
          ],
        ),
      ),
    );
  }
}
