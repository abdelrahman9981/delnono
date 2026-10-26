import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme.dart';

/// Bottom navigation, five tabs. In right-to-left layout the row runs from the right: Home,
/// Booking, My Child, Content, «حسابي». Phase 2 "Ask the doctor" will be a Home button, not a tab
/// (constitution 1.3.2).
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColors>()!;

    final tabs = [
      (path: '/', icon: Icons.home_outlined, label: l10n.navHome),
      (path: '/booking', icon: Icons.calendar_month_outlined, label: l10n.navBooking),
      (path: '/children', icon: Icons.child_care_outlined, label: l10n.navMyChild),
      (path: '/content', icon: Icons.play_circle_outline, label: l10n.navContent),
      (path: '/me', icon: Icons.account_circle_outlined, label: l10n.navMe),
    ];

    return Scaffold(
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: Row(
                children: [
                  for (final tab in tabs)
                    Expanded(
                      child: _NavItem(
                        icon: tab.icon,
                        label: tab.label,
                        selected: _isSelected(tab.path),
                        onTap: () => context.go(tab.path),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isSelected(String path) =>
      path == '/' ? location == '/' : location == path || location.startsWith('$path/');
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final color = selected ? colors.blue : colors.muted;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 30,
              decoration: BoxDecoration(
                color: selected ? colors.blueSoft : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 3),
            // One line that shrinks to fit: slots are ~73 pt wide on a 390 pt phone, and labels
            // must not wrap or overflow at large system text sizes.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
