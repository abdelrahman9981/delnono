import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/route_guard.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/errors/arabic_errors.dart';
import '../../../core/format/arabic_digits.dart';
import '../../../core/phone/egypt_phone.dart';
import '../../../core/settings/settings_repository.dart';
import '../../../core/widgets/code_boxes.dart';
import '../../../core/widgets/notice.dart';
import '../../../core/widgets/step_indicator.dart';
import '../../registration/data/guardian_repository.dart';
import '../application/otp_controller.dart';



/// Code entry (design screen 3, docs/design/screens/Otp.dc.html). After a successful sign-in the
/// router guard moves the guardian to the next step, keeping `from` (FR-003).
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, this.from});

  final String? from;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

/// After a correct code, the most the app waits for the guardian's data before offering a retry.
const postSignInTimeout = Duration(seconds: 10);

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _ticker;

  /// When the current wait for the guardian's data after sign-in began.
  DateTime? _waitingSince;

  String get _signInLocation =>
      Uri(path: Routes.signIn, queryParameters: widget.from == null ? null : {'from': widget.from}).toString();

  @override
  void initState() {
    super.initState();
    // Countdown and expiry are computed from the clock; repaint every second.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(otpControllerProvider).phone == null) context.go(_signInLocation);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _code.text;
    if (code.length != codeLength) return;
    await ref.read(otpControllerProvider.notifier).verify(code);
    if (!mounted) return;
    if (ref.read(otpControllerProvider).phase != OtpPhase.signedIn) _code.clear();
  }

  Future<void> _resend() async {
    _code.clear();
    await ref.read(otpControllerProvider.notifier).resend();
  }

  void _changeNumber() => context.go(_signInLocation);

  /// Reloads the guardian and policy after a failed or slow load (never leave the guardian stuck).
  void _retryLoad() {
    ref.invalidate(guardianProvider);
    ref.invalidate(policySettingsProvider);
    setState(() => _waitingSince = ref.read(clockProvider)());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(otpControllerProvider);
    final otp = ref.read(otpControllerProvider.notifier);
    final phone = state.phone;
    if (phone == null) return const Scaffold();

    final expired = state.discarded == CodeDiscarded.expired || (state.hasCode && otp.isExpired());
    final busy = state.phase == OtpPhase.verifying || state.phase == OtpPhase.sending;
    final canType = state.hasCode && !expired && !busy;
    final resendWait = otp.resendWait();

    // Signed in: the guard moves on as soon as the guardian's data arrives (details screen when there
    // is no guardian yet). A load error, or a wait longer than [postSignInTimeout], shows a retry.
    final signedIn = state.phase == OtpPhase.signedIn;
    final guard = ref.watch(guardStateProvider);
    final now = ref.read(clockProvider)();
    if (!signedIn || !guard.loading) {
      _waitingSince = null;
    } else {
      _waitingSince ??= now;
    }
    final stuck = signedIn &&
        (guard.loadError || (_waitingSince != null && now.difference(_waitingSince!) >= postSignInTimeout));

    String? problem;
    if (expired) {
      problem = l10n.errCodeExpired;
    } else if (state.discarded == CodeDiscarded.attemptsUsed) {
      problem = l10n.otpNoAttemptsLeft;
    } else if (state.error case FirebaseAuthException(code: 'invalid-verification-code')) {
      final left = otp.attemptsLeft;
      problem = l10n.otpWrongCode(l10n.otpAttempts(left, arabicDigits(left)));
    } else if (state.error != null) {
      problem = arabicErrorMessage(state.error!, l10n);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenOtp), leading: BackButton(onPressed: _changeNumber)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            // Number and code are one step in the design (Guardian.dc.html shows ✓ then ٢).
            const StepIndicator(current: 1),
            Text(l10n.otpHeading, style: text.headlineMedium),
            const SizedBox(height: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.otpSentTo('\u2066${formatEgyptMobile(phone)}\u2069'),
                  style: text.bodyMedium?.copyWith(color: colors.muted),
                ),
                Text(' · ', style: text.bodyMedium?.copyWith(color: colors.muted)),
                TextButton(
                  onPressed: _changeNumber,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
                  child: Text(l10n.otpChangeNumber),
                ),
              ],
            ),
            const SizedBox(height: 18),
            CodeBoxes(controller: _code, focusNode: _focus, enabled: canType, onCompleted: _verify),
            const SizedBox(height: 14),
            if (stuck) ...[
              Notice(l10n.signInLoadError, key: const Key('sign-in-load-error'), kind: NoticeKind.danger),
              const SizedBox(height: 8),
              FilledButton(key: const Key('sign-in-retry'), onPressed: _retryLoad, child: Text(l10n.signInRetry)),
              const SizedBox(height: 12),
            ] else if (signedIn && guard.loading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Center(child: CircularProgressIndicator(key: Key('sign-in-loading'))),
              ),
            if (problem != null) ...[
              Notice(problem, kind: NoticeKind.danger),
              const SizedBox(height: 12),
            ] else
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.otpValidFor(otp.codeValidityMinutes, arabicDigits(otp.codeValidityMinutes)),
                  style: text.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            Center(
              child: resendWait == Duration.zero
                  ? TextButton(onPressed: busy ? null : _resend, child: Text(l10n.otpResend))
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(l10n.otpResendIn(arabicCountdown(resendWait)), style: text.bodySmall),
                    ),
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder(
              valueListenable: _code,
              builder: (context, value, _) => FilledButton(
                onPressed: canType && value.text.length == codeLength ? _verify : null,
                child: state.phase == OtpPhase.verifying
                    ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : Text(l10n.otpConfirm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
