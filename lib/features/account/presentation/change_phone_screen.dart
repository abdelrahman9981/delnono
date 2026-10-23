import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/messenger.dart';
import '../../../app/route_guard.dart';
import '../../../app/theme.dart';
import '../../../core/errors/arabic_errors.dart';
import '../../../core/format/arabic_digits.dart';
import '../../../core/phone/egypt_phone.dart';
import '../../../core/widgets/code_boxes.dart';
import '../../../core/widgets/notice.dart';
import '../../../core/widgets/phone_number_field.dart';
import '../../auth/application/otp_controller.dart';
import '../../registration/data/guardian_repository.dart';
import '../data/account_api.dart';

/// Change the account's number with a code sent to the new number (FR-025, FR-026). The same code
/// rules as sign-in apply (FR-006 to FR-008). A number that already has an account is refused and
/// the guardian is asked to contact the clinic (FR-025a).
class ChangePhoneScreen extends ConsumerStatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  ConsumerState<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends ConsumerState<ChangePhoneScreen> {
  final _number = TextEditingController();
  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _ticker;
  String? _numberError;
  bool _syncing = false;
  Object? _syncError;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _number.dispose();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send(AppLocalizations l10n) async {
    final phone = normalizeEgyptMobile(_number.text);
    final current = ref.read(guardianProvider).value?.phone;
    setState(() => _numberError = phone == null ? l10n.phoneInvalid : (phone == current ? l10n.changePhoneSame : null));
    if (_numberError != null) return;
    await ref.read(phoneChangeOtpProvider.notifier).sendCode(phone!);
  }

  Future<void> _verify(AppLocalizations l10n) async {
    if (_code.text.length != codeLength) return;
    final otp = ref.read(phoneChangeOtpProvider.notifier);
    await otp.verify(_code.text);
    if (!mounted) return;
    final state = ref.read(phoneChangeOtpProvider);
    if (state.phase != OtpPhase.signedIn) {
      _code.clear();
      return;
    }
    setState(() => _syncing = true);
    try {
      await ref.read(accountApiProvider).syncPhoneNumber();
      showAppMessage(l10n.changePhoneDone(formatEgyptMobile(state.phone!)));
      otp.reset();
      if (mounted) context.go(Routes.account);
    } catch (e) {
      if (mounted) setState(() => _syncError = e);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    // Watched so the current number is known when sending.
    ref.watch(guardianProvider);
    final state = ref.watch(phoneChangeOtpProvider);
    final otp = ref.read(phoneChangeOtpProvider.notifier);
    final codeStage = state.phone != null && (state.hasCode || state.discarded != CodeDiscarded.none);
    final busy = state.phase == OtpPhase.sending || state.phase == OtpPhase.verifying || _syncing;

    String? problem;
    if (state.error case FirebaseAuthException(code: 'credential-already-in-use')) {
      problem = l10n.errNumberInUse;
    } else if (state.discarded == CodeDiscarded.expired || (state.hasCode && otp.isExpired())) {
      problem = l10n.errCodeExpired;
    } else if (state.discarded == CodeDiscarded.attemptsUsed) {
      problem = l10n.otpNoAttemptsLeft;
    } else if (state.error case FirebaseAuthException(code: 'invalid-verification-code')) {
      problem = l10n.otpWrongCode(l10n.otpAttempts(otp.attemptsLeft, arabicDigits(otp.attemptsLeft)));
    } else if (state.error != null) {
      problem = arabicErrorMessage(state.error!, l10n);
    } else if (_syncError != null) {
      problem = arabicErrorMessage(_syncError!, l10n);
    }
    final canType = state.hasCode && !otp.isExpired() && !busy;
    final wait = otp.resendWait();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.screenChangePhone),
        leading: BackButton(onPressed: () {
          otp.reset();
          context.go(Routes.account);
        }),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            Text(l10n.changePhoneHeading, style: text.headlineMedium),
            const SizedBox(height: 8),
            Text(l10n.changePhoneIntro, style: text.bodyMedium?.copyWith(color: c.muted)),
            const SizedBox(height: 22),
            PhoneNumberField(
              controller: _number,
              fieldKey: const Key('new-phone-field'),
              hasError: _numberError != null,
              onSubmitted: (_) => _send(l10n),
            ),
            if (_numberError != null) ...[
              const SizedBox(height: 7),
              Notice(_numberError!, kind: NoticeKind.danger),
            ],
            const SizedBox(height: 14),
            if (!codeStage)
              FilledButton(
                onPressed: busy ? null : () => _send(l10n),
                child: Text(l10n.changePhoneSend),
              )
            else ...[
              Text(
                l10n.otpSentTo('\u2066${formatEgyptMobile(state.phone!)}\u2069'),
                style: text.bodyMedium?.copyWith(color: c.muted),
              ),
              const SizedBox(height: 14),
              CodeBoxes(
                controller: _code,
                focusNode: _focus,
                enabled: canType,
                fieldKey: const Key('new-phone-otp-field'),
                onCompleted: () => _verify(l10n),
              ),
              const SizedBox(height: 10),
              Center(
                child: wait == Duration.zero
                    ? TextButton(onPressed: busy ? null : () => otp.resend(), child: Text(l10n.otpResend))
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(l10n.otpResendIn(arabicCountdown(wait)), style: text.bodySmall),
                      ),
              ),
            ],
            if (problem != null) ...[
              const SizedBox(height: 12),
              Notice(problem, kind: NoticeKind.danger),
            ],
            if (codeStage) ...[
              const SizedBox(height: 20),
              ValueListenableBuilder(
                valueListenable: _code,
                builder: (context, value, _) => FilledButton(
                  onPressed: canType && value.text.length == codeLength ? () => _verify(l10n) : null,
                  child: busy
                      ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : Text(l10n.otpConfirm),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
