import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/widgets/notice.dart';
import '../../features/auth/data/auth_repository.dart';
import '../data/staff_session.dart';
import '../widgets/dash_ui.dart';

/// Staff sign-in with email and password (005 FR-001). A signed-in account that is not an active
/// staff member is told so and signed out.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(staffAuthProvider).signIn(_email.text, _password.text);
    } on FirebaseAuthException catch (e) {
      _error = switch (e.code) {
        'user-disabled' => l10n.dashErrDisabled,
        'too-many-requests' => l10n.errTooManyRequests,
        'network-request-failed' => l10n.errNoConnection,
        _ => l10n.dashErrSignIn,
      };
    } catch (_) {
      _error = l10n.errGeneric;
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    // Signed in, but not an active staff member (a guardian, or disabled).
    final notStaff =
        ref.watch(authStateProvider).value != null &&
        ref.watch(staffSessionProvider).hasValue &&
        ref.watch(staffSessionProvider).value == null;

    // The side bar's navy behind a single card (docs/design/dashboard).
    return Scaffold(
      backgroundColor: Dash.navy,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AutofillGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.appTitle, style: text.labelLarge?.copyWith(color: c.blue)),
                    Text(l10n.dashSignInTitle, style: text.headlineSmall),
                    const SizedBox(height: 20),
                    if (notStaff) ...[
                      Notice(l10n.dashNotStaff, kind: NoticeKind.warn),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref.read(staffAuthProvider).signOut(),
                        child: Text(l10n.accountSignOut),
                      ),
                    ] else ...[
                      TextField(
                        key: const Key('dash-email'),
                        controller: _email,
                        textDirection: TextDirection.ltr,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(labelText: l10n.dashEmail),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('dash-password'),
                        controller: _password,
                        obscureText: true,
                        textDirection: TextDirection.ltr,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(labelText: l10n.dashPassword),
                        onSubmitted: (_) => _submit(),
                      ),
                      if (_error != null) ...[const SizedBox(height: 12), Notice(_error!, kind: NoticeKind.danger)],
                      const SizedBox(height: 20),
                      FilledButton(
                        key: const Key('dash-sign-in'),
                        onPressed: _busy ? null : _submit,
                        child: Text(l10n.dashSignIn),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
