import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/l10n/app_localizations.dart';
import '../app/theme.dart';
import '../features/clinics/data/clinics_repository.dart';
import 'data/staff_session.dart';
import 'router.dart';

/// Side navigation on a desktop, a drawer on a tablet (research R9); the top bar names the clinic,
/// with a switcher for the doctor (D-47).
class DashboardShell extends ConsumerWidget {
  const DashboardShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const wide = 900.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    final staff = ref.watch(staffSessionProvider).value;
    final items = <(String, IconData, String)>[
      (DashRoutes.today, Icons.today_outlined, l10n.dashNavToday),
      (DashRoutes.children, Icons.child_care_outlined, l10n.dashNavChildren),
      (DashRoutes.clinic, Icons.store_mall_directory_outlined, l10n.dashNavClinic),
      (DashRoutes.content, Icons.menu_book_outlined, l10n.dashNavContent),
      (DashRoutes.followUp, Icons.checklist_rtl, l10n.dashNavFollowUp),
      (DashRoutes.reports, Icons.bar_chart_outlined, l10n.dashNavReports),
      if (staff?.isDoctor ?? false) ...[
        (DashRoutes.vaccines, Icons.vaccines_outlined, l10n.dashNavVaccines),
        (DashRoutes.settings, Icons.tune, l10n.dashNavSettings),
        (DashRoutes.staff, Icons.badge_outlined, l10n.dashNavStaff),
        (DashRoutes.audit, Icons.history, l10n.dashNavAudit),
      ],
    ];
    final selected = items.indexWhere((i) => location == i.$1 || location.startsWith('${i.$1}/'));

    return LayoutBuilder(
      builder: (context, box) {
        final isWide = box.maxWidth >= wide;
        final nav = NavigationRail(
          key: const Key('dash-nav'),
          extended: box.maxWidth >= 1200,
          selectedIndex: selected < 0 ? null : selected,
          labelType: box.maxWidth >= 1200 ? null : NavigationRailLabelType.all,
          backgroundColor: c.surface,
          onDestinationSelected: (i) => context.go(items[i].$1),
          destinations: [
            for (final (_, icon, label) in items) NavigationRailDestination(icon: Icon(icon), label: Text(label)),
          ],
        );
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.dashTitle),
            actions: [
              const _ClinicPicker(),
              const SizedBox(width: 8),
              if (staff != null && box.maxWidth >= 1000)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(child: Text(staff.name, style: Theme.of(context).textTheme.bodySmall)),
                ),
              IconButton(
                key: const Key('dash-sign-out'),
                tooltip: l10n.accountSignOut,
                icon: const Icon(Icons.logout),
                onPressed: () => ref.read(staffAuthProvider).signOut(),
              ),
            ],
          ),
          drawer: isWide
              ? null
              : Drawer(
                  child: SafeArea(
                    child: ListView(
                      children: [
                        for (final (i, (path, icon, label)) in items.indexed)
                          ListTile(
                            leading: Icon(icon),
                            title: Text(label),
                            selected: i == selected,
                            onTap: () {
                              Navigator.pop(context);
                              context.go(path);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
          body: Row(
            children: [
              if (isWide) nav,
              if (isWide) const VerticalDivider(width: 1),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1200), child: child),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The clinic in the top bar: a menu for the doctor, the clinic's name for a secretary.
class _ClinicPicker extends ConsumerWidget {
  const _ClinicPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(staffSessionProvider).value;
    final clinics = ref.watch(allClinicsProvider).value ?? const <Clinic>[];
    final currentId = ref.watch(currentClinicIdProvider);
    final current = clinics.where((c) => c.id == currentId).firstOrNull;
    if (staff == null || current == null) return const SizedBox.shrink();
    if (!staff.isDoctor) return Center(child: Text(current.name, key: const Key('dash-clinic-name')));
    return PopupMenuButton<String>(
      key: const Key('dash-clinic-picker'),
      tooltip: AppLocalizations.of(context).dashSwitchClinic,
      initialValue: current.id,
      onSelected: (id) => ref.read(selectedClinicIdProvider.notifier).select(id),
      itemBuilder: (_) => [for (final c in clinics) PopupMenuItem(value: c.id, child: Text(c.name))],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Text(current.name), const Icon(Icons.arrow_drop_down)]),
      ),
    );
  }
}
