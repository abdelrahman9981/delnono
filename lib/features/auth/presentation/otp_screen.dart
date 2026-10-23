import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/route_guard.dart';
import '../../../app/theme.dart';
import '../../../core/errors/arabic_errors.dart';
import '../../../core/format/arabic_digits.dart';
import '../../../core/format/digit_input.dart';
import '../../../core/phone/egypt_phone.dart';
import '../../../core/widgets/notice.dart';
import '../../../core/widgets/step_indicator.dart';
import '../application/otp_controller.dart';

const _codeLength = 6;

/// Code entry (design screen 3, docs/design/screens/Otp.dc.html). After a successful sign-in the
/// router guard moves the guardian to the next step, keeping `from` (FR-003).
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, this.from});

  final String? from;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _ticker;

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
    if (code.length != _codeLength) return;
    await ref.read(otpControllerProvider.notifier).verify(code);
    if (!mounted) return;
    if (ref.read(otpControllerProvider).phase != OtpPhase.signedIn) _code.clear();
  }

  Future<void> _resend() async {
    _code.clear();
    await ref.read(otpControllerProvider.notifier).resend();
  }

  void _changeNumber() => context.go(_signInLocation);

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
            _CodeBoxes(controller: _code, focusNode: _focus, enabled: canType, onCompleted: _verify),
            const SizedBox(height: 14),
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
                onPressed: canType && value.text.length == _codeLength ? _verify : null,
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

/// Six boxes over one invisible text field, so paste and iOS code autofill work (`.otp` in
/// tokens.css). Digits run left to right, like the code in the SMS.
class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onCompleted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, _) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _codeLength; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  _box(colors, i < value.text.length ? value.text[i] : null, enabled),
                ],
              ],
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                key: const Key('otp-field'),
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                autofocus: true,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: _codeLength,
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: const [WesternDigitsFormatter()],
                decoration: InputDecoration(counterText: '', labelText: l10n.otpCodeField),
                onChanged: (v) {
                  if (v.length == _codeLength) onCompleted();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _box(AppColors c, String? digit, bool enabled) => Container(
        width: 46,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: digit != null ? c.blueSoft : c.surface,
          border: Border.all(color: digit != null ? c.blue : c.border, width: digit != null ? 2 : 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          digit ?? '',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: enabled ? c.text : c.muted),
        ),
      );
}
