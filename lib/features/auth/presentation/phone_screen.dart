import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/route_guard.dart';
import '../../../app/theme.dart';
import '../../../core/errors/arabic_errors.dart';
import '../../../core/phone/egypt_phone.dart';
import '../../../core/widgets/notice.dart';
import '../../../core/widgets/phone_number_field.dart';
import '../../../core/widgets/step_indicator.dart';
import '../application/otp_controller.dart';

/// Mobile number entry (design screen 2, docs/design/screens/Phone.dc.html).
class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key, this.from});

  /// Where to continue after sign-in (FR-003); passed on to the code screen.
  final String? from;

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _number = TextEditingController();
  bool _invalid = false;

  @override
  void initState() {
    super.initState();
    final phone = ref.read(otpControllerProvider).phone;
    if (phone != null && isValidEgyptMobile(phone)) _number.text = formatEgyptMobile(phone).substring(4);
  }

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final phone = normalizeEgyptMobile(_number.text);
    setState(() => _invalid = phone == null);
    if (phone == null) return;

    await ref.read(otpControllerProvider.notifier).sendCode(phone);
    if (!mounted) return;
    final state = ref.read(otpControllerProvider);
    if (state.phase == OtpPhase.codeSent && state.phone == phone) {
      context.go(Uri(
        path: Routes.signInCode,
        queryParameters: widget.from == null ? null : {'from': widget.from},
      ).toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(otpControllerProvider);
    final sending = state.phase == OtpPhase.sending;
    final error = _invalid ? l10n.phoneInvalid : (state.error == null ? null : arabicErrorMessage(state.error!, l10n));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.signInTitle),
        leading: context.canPop() ? null : BackButton(onPressed: () => context.go(Routes.welcome)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            const StepIndicator(current: 1),
            Text(l10n.phoneHeading, style: text.headlineMedium),
            const SizedBox(height: 8),
            Text(l10n.phoneIntro, style: text.bodyMedium?.copyWith(color: colors.muted)),
            const SizedBox(height: 22),
            Text(l10n.phoneLabel, style: text.labelMedium),
            const SizedBox(height: 7),
            PhoneNumberField(
              controller: _number,
              hasError: error != null,
              onChanged: (_) {
                if (_invalid) setState(() => _invalid = false);
              },
              onSubmitted: (_) => _send(),
            ),
            const SizedBox(height: 7),
            if (error != null) ...[
              Notice(error, kind: NoticeKind.danger),
              const SizedBox(height: 7),
            ],
            Text(l10n.phoneClinicHint, style: text.bodySmall),
            const SizedBox(height: 16),
            Notice(l10n.phoneStaySignedIn, icon: Icons.lock_outline),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: sending ? null : _send,
              child: sending
                  ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(l10n.phoneSendCode),
            ),
            const SizedBox(height: 10),
            Text(l10n.phonePrivacyNote, style: text.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
