import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../format/digit_input.dart';

/// Egyptian mobile number entry: a fixed "+20" box and the national number, left to right
/// (`.phone-input` in tokens.css).
class PhoneNumberField extends StatelessWidget {
  const PhoneNumberField({
    super.key,
    required this.controller,
    this.fieldKey = const Key('phone-field'),
    this.hasError = false,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final Key fieldKey;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          Container(
            width: 84,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text('+20', style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: fieldKey,
              controller: controller,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.send,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              inputFormatters: const [WesternDigitsFormatter(allowSpaces: true)],
              style: text.bodyLarge?.copyWith(letterSpacing: 1),
              decoration: InputDecoration(
                hintText: '10 1234 5678',
                errorText: hasError ? '' : null,
                errorStyle: const TextStyle(height: 0, fontSize: 0),
              ),
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            ),
          ),
        ],
      ),
    );
  }
}
