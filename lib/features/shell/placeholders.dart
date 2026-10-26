import 'package:flutter/material.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme.dart';

/// A screen that a later task or feature replaces. Always shows the "placeholder" tag so it is
/// never mistaken for finished content (constitution Principle II, D-36).
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, this.showAppBar = true, this.actions});

  final String title;
  final bool showAppBar;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColors>()!;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(title), actions: actions) : null,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!showAppBar) Text(title, style: text.headlineMedium),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.muted),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(l10n.placeholderTag, style: text.labelSmall?.copyWith(color: colors.muted)),
                ),
                const SizedBox(height: 8),
                Text(l10n.placeholderBody, style: text.bodyMedium?.copyWith(color: colors.muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) => PlaceholderScreen(
        title: AppLocalizations.of(context).placeholderHome,
      );
}

class BookingPlaceholder extends StatelessWidget {
  const BookingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) =>
      PlaceholderScreen(title: AppLocalizations.of(context).placeholderBooking, showAppBar: false);
}

class ContentPlaceholder extends StatelessWidget {
  const ContentPlaceholder({super.key});

  @override
  Widget build(BuildContext context) =>
      PlaceholderScreen(title: AppLocalizations.of(context).placeholderContent, showAppBar: false);
}
