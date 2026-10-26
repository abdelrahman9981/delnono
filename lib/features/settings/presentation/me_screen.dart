import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/messenger.dart';
import '../../../app/route_guard.dart';
import '../../../app/theme.dart';
import '../../../core/format/age.dart';
import '../../../core/format/arabic_digits.dart';
import '../../../core/launch/external_links.dart';
import '../../../core/phone/egypt_phone.dart';
import '../../../core/settings/settings_repository.dart';
import '../../../core/widgets/load_error.dart';
import '../../../core/widgets/segmented.dart';
import '../../auth/data/auth_repository.dart';
import '../../booking/presentation/booking_format.dart';
import '../../children/data/children_repository.dart';
import '../../clinics/data/clinics_repository.dart';
import '../../notifications/data/notification_prefs.dart';
import '../../packages/data/packages_repository.dart';
import '../../packages/presentation/package_screen.dart';
import '../../registration/data/guardian_repository.dart';
import '../../registration/presentation/policy_sheet.dart';
import '../data/app_settings.dart';

/// The app's version for «عن التطبيق».
final appVersionProvider = FutureProvider<String>((ref) async => (await PackageInfo.fromPlatform()).version);

/// «حسابي», the fifth tab (design screen 12, docs/design/screens/Settings.dc.html): the guardian,
/// their children, appearance (theme, text size), settings (language, notifications, preferred
/// clinic) and about. Signed out, it offers sign-in and keeps appearance and about.
class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final signedIn = ref.watch(authStateProvider).value != null;
    final guardian = ref.watch(guardianProvider).value;
    final children = signedIn ? ref.watch(childrenProvider).value ?? const <Child>[] : const <Child>[];
    final settings = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final prefs = ref.watch(notificationPrefsProvider).value ?? const NotificationPrefs();
    final clinics = ref.watch(clinicsProvider).value ?? const <Clinic>[];
    final whatsapp = ref.watch(mainClinicProvider)?.whatsapp;
    final policy = ref.watch(policySettingsProvider).value ?? const PolicySettings();
    final version = ref.watch(appVersionProvider).value;
    final preferred = clinics.where((x) => x.id == guardian?.preferredClinicId).firstOrNull;
    final pkg = ref.watch(familyPackageViewProvider);

    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(title, style: text.titleSmall?.copyWith(color: c.muted)),
    );
    Widget chip(IconData icon, Color bg, Color fg) => Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, size: 20, color: fg),
    );
    // chevron_right mirrors with the text direction: it points left (‹, forward) in RTL.
    final forward = Icon(Icons.chevron_right, color: c.muted);
    Widget row({
      required Key key,
      required Widget leading,
      required String title,
      String? subtitle,
      Widget? trailing,
      VoidCallback? onTap,
    }) => ListTile(
      key: key,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: leading,
      title: Text(title, style: text.titleSmall),
      subtitle: subtitle == null ? null : Text(subtitle, style: text.bodySmall),
      trailing: trailing ?? (onTap == null ? null : forward),
    );
    Widget divider() => Divider(height: 1, indent: 12, endIndent: 12, color: c.border);
    Widget card(List<Widget> children) => Card(margin: EdgeInsets.zero, child: Column(children: children));

    final notificationsSubtitle = switch ((prefs.booking, prefs.vaccine)) {
      (true, true) => l10n.meNotificationsBoth,
      (true, false) => l10n.meNotificationsBooking,
      (false, true) => l10n.meNotificationsVaccine,
      (false, false) => l10n.meNotificationsOff,
    };

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Text(l10n.appTitle, style: text.labelLarge?.copyWith(color: c.blue)),
            Text(l10n.meTitle, style: text.headlineMedium),
            const SizedBox(height: 14),
            if (signedIn && guardian != null)
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  key: const Key('me-guardian'),
                  contentPadding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                  onTap: () => context.push(Routes.account),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: c.blueSoft,
                    foregroundColor: c.blue,
                    child: Text(guardian.fullName.characters.first, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
                  title: Text(guardian.fullName, style: text.titleMedium),
                  subtitle: Text(formatEgyptMobile(guardian.phone), textDirection: TextDirection.ltr, textAlign: TextAlign.end),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: c.blueSoft, borderRadius: BorderRadius.circular(999)),
                      child: Text(l10n.meEdit, style: TextStyle(fontSize: 12, color: c.blue, fontWeight: FontWeight.w600)),
                    ),
                    forward,
                  ]),
                ),
              )
            else if (!signedIn)
              Card(
                key: const Key('me-sign-in'),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(l10n.meSignInPrompt, style: text.bodyMedium),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: () => context.go(Routes.signIn), child: Text(l10n.meSignIn)),
                  ]),
                ),
              ),
            if (signedIn && ref.watch(childrenProvider).hasError) ...[
              section(l10n.meChildren),
              Card(margin: EdgeInsets.zero, child: LoadErrorView(onRetry: () => ref.invalidate(childrenProvider))),
            ] else if (signedIn) ...[
              section(l10n.meChildren),
              card([
                for (final (i, child) in children.indexed) ...[
                  if (i > 0) divider(),
                  row(
                    key: Key('me-child-${child.id}'),
                    leading: CircleAvatar(
                      backgroundColor: child.sex == Sex.female ? c.pinkSoft : c.blueSoft,
                      foregroundColor: child.sex == Sex.female ? c.pink : c.blue,
                      child: Text(child.name.characters.first, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    title: child.name,
                    subtitle: arabicAge(child.birthDate, l10n),
                    onTap: () => context.push('${Routes.children}/${child.id}'),
                  ),
                ],
                if (children.isNotEmpty) divider(),
                ListTile(
                  key: const Key('me-add-child'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  onTap: () => context.push(Routes.childrenAdd),
                  leading: chip(Icons.add, c.blueSoft, c.blue),
                  title: Text(l10n.meAddChild, style: text.titleSmall?.copyWith(color: c.blue)),
                ),
              ]),
              // The family package, per child (008 FR-001).
              section(l10n.mePackage),
              card([
                if (pkg.current == null)
                  row(
                    key: const Key('me-package-none'),
                    leading: chip(Icons.card_giftcard, c.greenSoft, c.green),
                    title: pkg.lastEnded == null ? l10n.pkgNone : l10n.pkgEndedOn(dayLabel(pkg.lastEnded!.endsOn)),
                    subtitle: l10n.pkgNoneSub,
                    onTap: () => context.push(Routes.package),
                  )
                else
                  for (final (i, child) in children.indexed) ...[
                    if (i > 0) divider(),
                    row(
                      key: Key('me-package-${child.id}'),
                      leading: chip(Icons.card_giftcard, c.greenSoft, c.green),
                      title: l10n.pkgChildLine(child.name),
                      subtitle: l10n.pkgActiveUntil(dayLabel((pkg.next ?? pkg.current!).endsOn)),
                      trailing: const PackagePill(active: true),
                      onTap: () => context.push(Routes.package),
                    ),
                  ],
              ]),
            ],
            section(l10n.meAppearance),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    chip(Icons.dark_mode_outlined, c.blueSoft, c.blue),
                    const SizedBox(width: 12),
                    Text(l10n.meTheme, style: text.titleSmall),
                  ]),
                  const SizedBox(height: 10),
                  Segmented<ThemeMode>(
                    key: const Key('me-theme'),
                    options: [
                      (ThemeMode.light, l10n.themeLight),
                      (ThemeMode.dark, l10n.themeDark),
                      (ThemeMode.system, l10n.themeSystem),
                    ],
                    value: settings.themeMode,
                    onChanged: (m) => ref.read(appSettingsProvider.notifier).setThemeMode(m),
                  ),
                  const SizedBox(height: 14),
                  Divider(height: 1, color: c.border),
                  const SizedBox(height: 14),
                  Row(children: [
                    chip(Icons.format_size, c.greenSoft, c.green),
                    const SizedBox(width: 12),
                    Text(l10n.meTextSize, style: text.titleSmall),
                  ]),
                  const SizedBox(height: 10),
                  Segmented<TextSizeChoice>(
                    key: const Key('me-text-size'),
                    options: [
                      (TextSizeChoice.small, l10n.textSmall),
                      (TextSizeChoice.normal, l10n.textNormal),
                      (TextSizeChoice.large, l10n.textLarge),
                    ],
                    value: settings.textSize,
                    onChanged: (s) => ref.read(appSettingsProvider.notifier).setTextSize(s),
                  ),
                ]),
              ),
            ),
            section(l10n.meSettings),
            card([
              // Arabic only in Phase 1; English is announced, not offered.
              row(
                key: const Key('me-language'),
                leading: chip(Icons.language, c.yellowSoft, c.yellow),
                title: l10n.meLanguage,
                subtitle: l10n.meLanguageArabic,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(999)),
                  child: Text(l10n.meEnglishSoon, style: TextStyle(fontSize: 11, color: c.muted)),
                ),
              ),
              if (signedIn) ...[
                divider(),
                row(
                  key: const Key('me-notifications'),
                  leading: chip(Icons.notifications_none, c.pinkSoft, c.pink),
                  title: l10n.meNotifications,
                  subtitle: notificationsSubtitle,
                  onTap: () => context.push(Routes.notifications),
                ),
                divider(),
                row(
                  key: const Key('me-preferred-clinic'),
                  leading: chip(Icons.location_on_outlined, c.greenSoft, c.green),
                  title: l10n.mePreferredClinic,
                  subtitle: l10n.mePreferredClinicSub,
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      preferred == null ? l10n.mePreferredNone : (preferred.area.isEmpty ? preferred.name : preferred.area),
                      style: text.bodySmall?.copyWith(color: c.blue, fontWeight: FontWeight.w600),
                    ),
                    forward,
                  ]),
                  onTap: guardian == null ? null : () => _pickClinic(context, ref, guardian, clinics),
                ),
              ],
            ]),
            section(l10n.meAbout),
            card([
              if (whatsapp != null) ...[
                row(
                  key: const Key('me-whatsapp'),
                  leading: chip(Icons.chat_outlined, c.greenSoft, c.green),
                  title: l10n.meWhatsApp,
                  onTap: () => ref.read(externalLinksProvider).openWhatsApp(whatsapp),
                ),
                divider(),
              ],
              row(
                key: const Key('me-privacy'),
                leading: chip(Icons.privacy_tip_outlined, c.blueSoft, c.blue),
                title: l10n.mePrivacy,
                onTap: () => showPolicySheet(context, policy),
              ),
              divider(),
              // The store link comes when the app is published.
              row(
                key: const Key('me-rate'),
                leading: chip(Icons.star_outline, c.yellowSoft, c.yellow),
                title: l10n.meRate,
                onTap: () => showAppMessage(l10n.meRateSoon),
              ),
            ]),
            const SizedBox(height: 14),
            if (version != null)
              Text(
                l10n.meVersion(arabicDigits(version)),
                key: const Key('me-version'),
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: c.muted),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickClinic(BuildContext context, WidgetRef ref, Guardian guardian, List<Clinic> clinics) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<(String?,)>(
      context: context,
      builder: (context) => SafeArea(
        child: RadioGroup<String?>(
          groupValue: guardian.preferredClinicId,
          onChanged: (id) => Navigator.pop(context, (id,)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(title: Text(l10n.mePreferredClinic, style: Theme.of(context).textTheme.titleMedium)),
            for (final clinic in clinics)
              RadioListTile<String?>(key: Key('preferred-${clinic.id}'), value: clinic.id, title: Text(clinic.name)),
            RadioListTile<String?>(key: const Key('preferred-none'), value: null, title: Text(l10n.mePreferredNone)),
          ]),
        ),
      ),
    );
    if (picked == null) return;
    await ref.read(guardianRepositoryProvider).setPreferredClinic(guardian.uid, picked.$1);
  }
}
