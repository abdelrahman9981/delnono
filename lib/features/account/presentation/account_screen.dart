import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/messenger.dart';
import '../../../app/route_guard.dart';
import '../../../app/theme.dart';
import '../../../core/format/arabic_digits.dart';
import '../../../core/launch/external_links.dart';
import '../../../core/phone/egypt_phone.dart';
import '../../../core/settings/settings_repository.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/data/auth_repository.dart';
import '../../children/data/children_repository.dart';
import '../../registration/data/guardian_repository.dart';
import '../../registration/presentation/policy_sheet.dart';

/// Account (design screen 11, docs/design/screens/Account.dc.html; FR-033 to FR-035).
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final guardian = ref.watch(guardianProvider).value;
    final children = ref.watch(childrenProvider).value ?? const [];
    final policy = ref.watch(policySettingsProvider).value ?? const PolicySettings();
    final whatsapp = ref.watch(clinicSettingsProvider).value?.whatsappNumber;

    if (guardian == null) {
      return Scaffold(appBar: AppBar(title: Text(l10n.screenAccount)), body: const Center(child: CircularProgressIndicator()));
    }

    final relation = switch (guardian.relation) {
      Relation.mother => l10n.relationMother,
      Relation.father => l10n.relationFather,
      Relation.other => l10n.relationOther,
    };
    final green = dark ? const Color(0xFF79D8BC) : const Color(0xFF258D70);
    final pink = dark ? const Color(0xFFFFB4C6) : const Color(0xFFC85E78);
    final yellow = dark ? const Color(0xFFFFD46D) : const Color(0xFF946600);

    Widget row({
      required Key key,
      required IconData icon,
      required Color bg,
      required Color fg,
      required String title,
      String? subtitle,
      VoidCallback? onTap,
    }) =>
        ListTile(
          key: key,
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, size: 19, color: fg),
          ),
          title: Text(title, style: text.titleSmall),
          subtitle: subtitle == null ? null : Text(subtitle, style: text.bodySmall),
          trailing: Icon(Icons.chevron_left, color: c.muted),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenAccount)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: c.blueSoft,
                      foregroundColor: c.blue,
                      child: Text(guardian.fullName.characters.first,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(guardian.fullName, style: text.titleMedium),
                          Text(
                            formatEgyptMobile(guardian.phone),
                            textDirection: TextDirection.ltr,
                            style: text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(color: c.greenSoft, borderRadius: BorderRadius.circular(20)),
                      child: Text(relation, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: green)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  row(
                    key: const Key('account-children'),
                    icon: Icons.child_care_outlined,
                    bg: c.blueSoft,
                    fg: c.blue,
                    title: l10n.accountChildren,
                    subtitle: [...children.map((ch) => ch.name), l10n.childrenAdd].join(' · '),
                    onTap: () => context.go(Routes.children),
                  ),
                  const Divider(indent: 12, endIndent: 12),
                  row(
                    key: const Key('account-change-phone'),
                    icon: Icons.phone_iphone,
                    bg: c.pinkSoft,
                    fg: pink,
                    title: l10n.accountChangePhone,
                    subtitle: l10n.accountChangePhoneSub,
                    onTap: () => context.go(Routes.accountPhone),
                  ),
                  const Divider(indent: 12, endIndent: 12),
                  row(
                    key: const Key('account-notifications'),
                    icon: Icons.notifications_none,
                    bg: c.yellowSoft,
                    fg: yellow,
                    title: l10n.accountNotifications,
                    subtitle: l10n.placeholderTag,
                    onTap: () => context.go(Routes.notifications),
                  ),
                  const Divider(indent: 12, endIndent: 12),
                  row(
                    key: const Key('account-privacy'),
                    icon: Icons.shield_outlined,
                    bg: c.greenSoft,
                    fg: green,
                    title: l10n.accountPrivacy,
                    subtitle: l10n.accountPrivacySub(arabicDigits(guardian.consentVersion)),
                    onTap: () => showPolicySheet(context, policy),
                  ),
                  const Divider(indent: 12, endIndent: 12),
                  row(
                    key: const Key('account-whatsapp'),
                    icon: Icons.chat_outlined,
                    bg: c.greenSoft,
                    fg: green,
                    title: l10n.accountWhatsApp,
                    subtitle: l10n.accountWhatsAppSub,
                    onTap: () {
                      if (whatsapp == null) {
                        showAppMessage(l10n.accountWhatsAppUnavailable);
                      } else {
                        ref.read(externalLinksProvider).openWhatsApp(whatsapp);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('account-sign-out'),
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                ref.read(sessionControllerProvider.notifier).reset();
                // Messages about this account must not stay on screen for the next person.
                appMessengerKey.currentState?.clearSnackBars();
                if (context.mounted) context.go(Routes.welcome);
              },
              child: Text(l10n.accountSignOut),
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: c.dangerBg),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.accountDeleteTitle,
                        style: text.titleSmall?.copyWith(color: c.dangerText, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(l10n.accountDeleteBody, style: text.bodySmall?.copyWith(fontSize: 12, height: 1.7)),
                    const SizedBox(height: 10),
                    FilledButton(
                      key: const Key('account-delete'),
                      style: FilledButton.styleFrom(backgroundColor: c.dangerBg, foregroundColor: c.dangerText),
                      onPressed: () => context.go(Routes.accountDelete),
                      child: Text(l10n.accountDeleteButton),
                    ),
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
