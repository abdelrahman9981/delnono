import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// A card with a checkbox, a bold line and an optional small line (`.check-row` in tokens.css).
/// Starts unticked; the whole row toggles it.
class CheckRow extends StatelessWidget {
  const CheckRow({super.key, required this.value, required this.onChanged, required this.title, this.subtitle});

  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Card(
      child: MergeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox.square(
                  dimension: 24,
                  child: Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(subtitle!, style: TextStyle(fontSize: 11, height: 1.6, color: c.muted)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
