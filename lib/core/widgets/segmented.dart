import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Equal-width choice buttons (`.segmented` in tokens.css). [value] is null until one is chosen.
class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  final List<(T, String)> options;
  final T? value;
  final ValueChanged<T> onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: hasError ? c.dangerText : c.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (final (i, (option, label)) in options.indexed) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Semantics(
                button: true,
                selected: option == value,
                inMutuallyExclusiveGroup: true,
                child: InkWell(
                  onTap: () => onChanged(option),
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: option == value ? c.blueSoft : null,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        color: option == value ? c.blue : c.muted,
                        fontWeight: option == value ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
