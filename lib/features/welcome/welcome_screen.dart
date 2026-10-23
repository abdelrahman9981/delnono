import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/route_guard.dart';
import '../../app/theme.dart';

/// Welcome (design screen 1, docs/design/screens/Main.dc.html). Where a signed-out visitor starts:
/// register, or browse content without an account (FR-001, D-09).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
              sliver: SliverList.list(children: [
                const _DoctorHero(),
                const SizedBox(height: 24),
                Text(l10n.welcomeHeading, style: text.headlineMedium?.copyWith(fontSize: 22)),
                const SizedBox(height: 6),
                Text(l10n.welcomeIntro, style: text.bodyLarge?.copyWith(color: c.muted, fontSize: 14, height: 1.7)),
                const SizedBox(height: 16),
                _Feature(
                  icon: Icons.calendar_month_outlined,
                  background: c.blueSoft,
                  foreground: c.blue,
                  title: l10n.welcomeBookTitle,
                  body: l10n.welcomeBookBody,
                ),
                const SizedBox(height: 8),
                _Feature(
                  icon: Icons.show_chart,
                  background: c.greenSoft,
                  foreground: dark ? const Color(0xFF79D8BC) : const Color(0xFF258D70),
                  title: l10n.welcomeProfileTitle,
                  body: l10n.welcomeProfileBody,
                ),
                const SizedBox(height: 8),
                _Feature(
                  icon: Icons.favorite_border,
                  background: c.pinkSoft,
                  foreground: dark ? const Color(0xFFFFB4C6) : const Color(0xFFC85E78),
                  title: l10n.welcomeTipsTitle,
                  body: l10n.welcomeTipsBody,
                ),
              ]),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(onPressed: () => context.go(Routes.signIn), child: Text(l10n.welcomeRegister)),
                    const SizedBox(height: 8),
                    OutlinedButton(onPressed: () => context.go(Routes.content), child: Text(l10n.welcomeBrowse)),
                    const SizedBox(height: 10),
                    Text(l10n.welcomeDisclaimer, style: text.bodySmall?.copyWith(height: 1.6), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hero card with the doctor's photo. The photo is a marked placeholder until the clinic sends
/// the real one (D-36).
class _DoctorHero extends StatelessWidget {
  const _DoctorHero();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const ink = Color(0xFF27516A);

    return Container(
      height: 300,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF8AC9E9), Color(0xFFCBE7EE), Color(0xFFF4CCD6)],
          stops: [0, .55, 1],
        ),
        boxShadow: const [BoxShadow(color: Color(0x1216324B), blurRadius: 30, offset: Offset(0, 8))],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            label: l10n.welcomePhotoPlaceholder,
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .3),
                      border: Border.all(color: ink.withValues(alpha: .5), width: 2),
                    ),
                    child: const Icon(Icons.person_outline, size: 40, color: ink),
                  ),
                  const SizedBox(height: 6),
                  Text(l10n.welcomePhotoPlaceholder,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ink)),
                  Text(l10n.welcomePhotoSoon, style: TextStyle(fontSize: 11, color: ink.withValues(alpha: .8))),
                ],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00081D2B), Color(0xD9081D2B)],
                stops: [.35, 1],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.welcomeClinic, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: .9))),
                const SizedBox(height: 2),
                Text(l10n.welcomeDoctorName,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 2),
                Text(l10n.welcomeDoctorTitle, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: .88))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(13)),
              child: Icon(icon, size: 20, color: foreground),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(body, style: TextStyle(fontSize: 12, color: c.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
