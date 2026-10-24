import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../core/widgets/notice.dart';
import '../data/dashboard_api.dart';
import '../data/staff_session.dart';

/// First sign-in: the temporary password is replaced by the staff member's own (005 FR-001).
class PasswordScreen extends ConsumerStatefulWidget {
  const PasswordScreen({super.key});

  @override
  ConsumerState<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends ConsumerState<PasswordScreen> {
  final _password = TextEditingController();
  final _again = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_password.text.length < 8) return setState(() => _error = l10n.dashPasswordRule);
    if (_password.text != _again.text) return setState(() => _error = l10n.dashPasswordMismatch);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(staffAuthProvider).changePassword(_password.text);
      await ref.read(dashboardApiProvider).call('staffPasswordChanged', {});
    } on FirebaseAuthException catch (e) {
      _error = e.code == 'weak-password' ? l10n.dashPasswordRule : l10n.errGeneric;
    } catch (_) {
      _error = l10n.errGeneric;
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.dashPasswordTitle, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(l10n.dashPasswordIntro),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('dash-new-password'),
                    controller: _password,
                    obscureText: true,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(labelText: l10n.dashNewPassword),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('dash-new-password-again'),
                    controller: _again,
                    obscureText: true,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(labelText: l10n.dashNewPasswordAgain),
                  ),
                  if (_error != null) ...[const SizedBox(height: 12), Notice(_error!, kind: NoticeKind.danger)],
                  const SizedBox(height: 20),
                  FilledButton(
                    key: const Key('dash-save-password'),
                    onPressed: _busy ? null : _save,
                    child: Text(l10n.save),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
