import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/l10n/app_localizations.dart';
import '../app/theme.dart';
import 'data/staff_session.dart';
import 'router.dart';
import 'widgets/dash_ui.dart';

/// The navy side bar on a desktop, the same side bar in a drawer on a tablet (research R9,
/// docs/design/dashboard). Each page draws its own top bar with the clinic switch (D-47).
class DashboardShell extends ConsumerWidget {
  const DashboardShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const wide = 900.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, box) {
        final isWide = box.maxWidth >= wide;
        return Scaffold(
          backgroundColor: dark ? c.canvas : Dash.canvasLight,
          appBar: isWide
              ? null
              : AppBar(
                  backgroundColor: Dash.navy,
                  foregroundColor: Colors.white,
                  title: Text(l10n.dashTitle),
                ),
          drawer: isWide ? null : Drawer(width: 260, backgroundColor: Dash.navy, child: _SideBar(location: location, inDrawer: true)),
          body: Row(
            children: [
              if (isWide) SizedBox(width: 248, child: _SideBar(location: location)),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

class _SideBar extends ConsumerWidget {
  const _SideBar({required this.location, this.inDrawer = false});

  final String location;
  final bool inDrawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final staff = ref.watch(staffSessionProvider).value;
    final main = <(String, IconData, String)>[
      (DashRoutes.today, Icons.today_outlined, l10n.dashNavToday),
      (DashRoutes.children, Icons.child_care_outlined, l10n.dashNavChildren),
      (DashRoutes.clinic, Icons.store_mall_directory_outlined, l10n.dashNavClinic),
      (DashRoutes.content, Icons.menu_book_outlined, l10n.dashNavContent),
      (DashRoutes.followUp, Icons.checklist_rtl, l10n.dashNavFollowUp),
      (DashRoutes.reports, Icons.bar_chart_outlined, l10n.dashNavReports),
    ];
    final admin = <(String, IconData, String)>[
      if (staff?.isDoctor ?? false) ...[
        (DashRoutes.vaccines, Icons.vaccines_outlined, l10n.dashNavVaccines),
        (DashRoutes.settings, Icons.tune, l10n.dashNavSettings),
        (DashRoutes.staff, Icons.badge_outlined, l10n.dashNavStaff),
        (DashRoutes.audit, Icons.history, l10n.dashNavAudit),
      ],
    ];
    bool active(String path) => location == path || location.startsWith('$path/');

    Widget item((String, IconData, String) i) {
      final (path, icon, label) = i;
      final on = active(path);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: on ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            key: Key('nav-$path'),
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (inDrawer) Navigator.pop(context);
              context.go(path);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                Icon(icon, size: 20, color: on ? Dash.navy : Dash.navyText),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: on ? Dash.navy : Dash.navyText, fontWeight: on ? FontWeight.w600 : FontWeight.w400),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
    }

    return Container(
      key: const Key('dash-nav'),
      color: Dash.navy,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
              child: Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(colors: [Color(0xFF3A9AD9), Color(0xFFF08AA3)]),
                  ),
                  child: const Text('ن', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l10n.dashBrand, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    Text(l10n.dashTitle, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Dash.navyMuted, fontSize: 12)),
                  ]),
                ),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  ...main.map(item),
                  if (admin.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 18, 12, 6),
                      child: Text(l10n.dashAdminSection, style: const TextStyle(color: Dash.navyMuted, fontSize: 12)),
                    ),
                    ...admin.map(item),
                  ],
                ],
              ),
            ),
            if (staff != null)
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                decoration: BoxDecoration(color: Dash.navy2, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: Dash.navyLine,
                    child: Text(
                      staff.name.isEmpty ? '·' : staff.name.characters.first,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(staff.name, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(
                        staff.isDoctor ? l10n.dashRoleDoctor : l10n.dashRoleSecretary,
                        style: const TextStyle(color: Dash.navyMuted, fontSize: 12),
                      ),
                    ]),
                  ),
                  IconButton(
                    key: const Key('dash-sign-out'),
                    tooltip: l10n.accountSignOut,
                    color: Dash.navyText,
                    icon: const Icon(Icons.logout, size: 20),
                    onPressed: () => ref.read(staffAuthProvider).signOut(),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}
