import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'theme.dart';

/// The web demo (D-43): on a wide browser window the app shows in a centred 390 × 844 phone frame
/// with the app's name above it; on a phone (or any narrow window) it fills the screen. Not used on
/// phones' native builds.
class WebPhoneFrame extends StatelessWidget {
  const WebPhoneFrame({super.key, required this.child, this.force = false});

  static const phone = Size(390, 844);

  final Widget child;

  /// Tests set this to frame outside the web.
  final bool force;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && !force) return child;
    final media = MediaQuery.of(context);
    if (media.size.width < 600) return child;
    final c = Theme.of(context).extension<AppColors>()!;
    return ColoredBox(
      key: const Key('web-phone-frame'),
      color: c.canvas,
      child: SafeArea(
        child: Center(
          child: FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  AppLocalizations.of(context).appTitle,
                  textDirection: TextDirection.rtl,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: c.blueDeep, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Container(
                  width: phone.width + 20,
                  height: phone.height + 20,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16324B),
                    borderRadius: BorderRadius.circular(54),
                    boxShadow: const [BoxShadow(color: Color(0x3316324B), blurRadius: 40, offset: Offset(0, 18))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(44),
                    child: MediaQuery(
                      data: media.copyWith(size: phone, padding: EdgeInsets.zero, viewPadding: EdgeInsets.zero),
                      child: SizedBox.fromSize(size: phone, child: child),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
