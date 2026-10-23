import 'package:flutter/material.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../format/digit_input.dart';

/// Length of the SMS code.
const codeLength = 6;

/// Six boxes over one invisible text field, so paste and iOS code autofill work (`.otp` in
/// tokens.css). Digits run left to right, like the code in the SMS.
class CodeBoxes extends StatelessWidget {
  const CodeBoxes({
    super.key,
    this.fieldKey = const Key('otp-field'),
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onCompleted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onCompleted;
  final Key fieldKey;

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
                for (var i = 0; i < codeLength; i++) ...[
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
                key: fieldKey,
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                autofocus: true,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: codeLength,
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: const [WesternDigitsFormatter()],
                decoration: InputDecoration(counterText: '', labelText: l10n.otpCodeField),
                onChanged: (v) {
                  if (v.length == codeLength) onCompleted();
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
