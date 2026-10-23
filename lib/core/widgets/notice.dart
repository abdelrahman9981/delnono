import 'package:flutter/material.dart';

import '../../app/theme.dart';

enum NoticeKind { info, warn, danger }

/// `.notice` and `.danger-alert` in tokens.css.
class Notice extends StatelessWidget {
  const Notice(this.text, {super.key, this.kind = NoticeKind.info, this.icon});

  final String text;
  final NoticeKind kind;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (bg, fg) = switch (kind) {
      NoticeKind.info => (c.blueSoft, dark ? const Color(0xFF8FCBF0) : const Color(0xFF1F5F8A)),
      NoticeKind.warn => (c.yellowSoft, dark ? const Color(0xFFFFD46D) : const Color(0xFF7D5800)),
      NoticeKind.danger => (c.dangerBg, c.dangerText),
    };
    final defaultIcon = switch (kind) {
      NoticeKind.info => Icons.info_outline,
      NoticeKind.warn => Icons.warning_amber_rounded,
      NoticeKind.danger => Icons.error_outline,
    };

    return Semantics(
      liveRegion: kind != NoticeKind.info,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon ?? defaultIcon, size: 18, color: fg),
            const SizedBox(width: 9),
            Expanded(child: Text(text, style: TextStyle(fontSize: 12, height: 1.7, color: fg))),
          ],
        ),
      ),
    );
  }
}
