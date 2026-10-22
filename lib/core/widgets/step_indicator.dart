import 'package:flutter/material.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../format/arabic_digits.dart';

/// Numbered steps of first-run registration (`.steps` in tokens.css): done steps are green, the
/// current one blue.
class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key, required this.current, this.total = 4});

  /// 1-based.
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context);

    Widget dot(int step) {
      final done = step < current;
      final active = step == current;
      return Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? colors.green : (active ? colors.blue : colors.border),
        ),
        child: done
            ? const Icon(Icons.check, size: 15, color: Colors.white)
            : Text(
                arabicDigits(step),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : colors.muted,
                ),
              ),
      );
    }

    return Semantics(
      label: l10n.stepOf(arabicDigits(current), arabicDigits(total)),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var step = 1; step <= total; step++) ...[
              if (step > 1)
                Container(width: 44, height: 2, color: step <= current ? colors.green : colors.border),
              dot(step),
            ],
          ],
        ),
      ),
    );
  }
}
