import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/route_guard.dart';
import '../../../app/theme.dart';
import '../../../core/clock.dart';
import '../../../core/format/age.dart';
import '../../../core/format/arabic_digits.dart';
import '../../booking/domain/clinic_time.dart';
import '../../account/presentation/account_button.dart';
import '../../children/data/children_repository.dart';
import '../application/selected_child.dart';
import '../data/family_packages_repository.dart';
import '../data/measurements_repository.dart';
import '../data/offline_status.dart';
import '../domain/latest_measurements.dart';
import '../domain/package_state.dart';
import 'growth_chart.dart';
import 'offline_note.dart';
import 'profile_format.dart';

/// "طفلي" (`/children`, design `figma/child-profile.jpg`): child switcher, latest measurements and
/// the growth chart, with entries to vaccines, visits and follow-up (contracts/routes.md). Values and
/// charts only, never a judgment (D-37).
class MyChildScreen extends ConsumerWidget {
  const MyChildScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final children = ref.watch(childrenProvider);
    final child = ref.watch(currentChildProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.childProfileTitle),
        automaticallyImplyLeading: false,
        actions: const [AccountButton()],
      ),
      body: SafeArea(
        child: children.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const SizedBox.shrink(),
          data: (list) => ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              const OfflineNote(),
              if (child == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.child_care_outlined, size: 48, color: c.muted),
                      const SizedBox(height: 10),
                      Text(
                        // Offline with nothing cached yet: the list is empty only because it never loaded.
                        ref.watch(offlineProvider).value == true ? l10n.needsConnectionFirstTime : l10n.childrenEmpty,
                        textAlign: TextAlign.center,
                        style: text.bodyLarge?.copyWith(color: c.muted),
                      ),
                    ],
                  ),
                )
              else ...[
                _Switcher(children: list, selected: child),
                const _PackageCard(),
                const SizedBox(height: 18),
                _Measurements(child: child),
                const SizedBox(height: 14),
                _Entries(child: child),
              ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const Key('add-child'),
                onPressed: () => context.go(Routes.childrenAdd),
                icon: const Icon(Icons.add),
                label: Text(l10n.childrenAdd),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Switcher extends ConsumerWidget {
  const _Switcher({required this.children, required this.selected});

  final List<Child> children;
  final Child selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;

    Widget chip(Child child) {
      final on = child.id == selected.id;
      final female = child.sex == Sex.female;
      return Semantics(
        button: true,
        selected: on,
        child: InkWell(
          key: Key('child-chip-${child.id}'),
          borderRadius: BorderRadius.circular(16),
          onTap: () => ref.read(selectedChildIdProvider.notifier).select(child.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: on ? c.blueSoft : null, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: female ? c.pinkSoft : c.blueSoft,
                  foregroundColor: female ? c.pink : c.blue,
                  child: Text(child.name.characters.first, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(child.name, style: text.titleSmall),
                    Text(arabicAge(child.birthDate, l10n), style: text.bodySmall?.copyWith(color: c.muted)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      key: const Key('child-switcher'),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (i, child) in children.indexed) ...[if (i > 0) const SizedBox(width: 6), chip(child)],
            ],
          ),
        ),
      ),
    );
  }
}

class _Measurements extends ConsumerWidget {
  const _Measurements({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final measurements = ref.watch(measurementsProvider(child.id)).value ?? const <Measurement>[];
    final last = lastMeasuredOn(measurements);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 8,
          children: [
            Text(l10n.latestMeasurements(child.name), style: text.titleLarge),
            if (last != null)
              Text(l10n.measurementsUpdated(shortDate(last)), style: text.bodySmall?.copyWith(color: c.muted)),
          ],
        ),
        const SizedBox(height: 10),
        if (measurements.isEmpty)
          Container(
            key: const Key('no-measurements'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.border),
            ),
            child: Text(l10n.noMeasurements, style: text.bodyMedium?.copyWith(color: c.muted)),
          )
        else
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _MeasureCard(
                    metric: Metric.weight,
                    label: l10n.measureWeight,
                    unit: l10n.unitKg,
                    icon: Icons.monitor_weight_outlined,
                    soft: c.blueSoft,
                    strong: c.blue,
                    value: latestOf(measurements, Metric.weight),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MeasureCard(
                    metric: Metric.length,
                    label: l10n.measureLength,
                    unit: l10n.unitCm,
                    icon: Icons.straighten,
                    soft: c.greenSoft,
                    strong: c.green,
                    value: latestOf(measurements, Metric.length),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MeasureCard(
                    metric: Metric.head,
                    label: l10n.measureHead,
                    unit: l10n.unitCm,
                    icon: Icons.face_outlined,
                    soft: c.pinkSoft,
                    strong: c.pink,
                    value: latestOf(measurements, Metric.head),
                  ),
                ),
              ],
            ),
          ),
        if (measurements.isNotEmpty || child.birthWeightKg != null) ...[
          const SizedBox(height: 12),
          GrowthChartCard(measurements: measurements, birthDate: child.birthDate, birthWeightKg: child.birthWeightKg),
        ],
      ],
    );
  }
}

class _MeasureCard extends StatelessWidget {
  const _MeasureCard({
    required this.metric,
    required this.label,
    required this.unit,
    required this.icon,
    required this.soft,
    required this.strong,
    required this.value,
  });

  final Metric metric;
  final String label;
  final String unit;
  final IconData icon;
  final Color soft;
  final Color strong;
  final Dated? value;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final v = value;
    return Card(
      key: Key('measure-${metric.name}'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: strong),
            ),
            const SizedBox(height: 10),
            Text(label, style: text.bodySmall?.copyWith(color: c.muted)),
            const SizedBox(height: 4),
            if (v == null)
              Text(l10n.notRecordedYet, style: text.bodySmall)
            else ...[
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(measureValue(v.value), style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    Text(unit, style: text.bodySmall?.copyWith(color: c.muted)),
                  ],
                ),
              ),
              Text(l10n.measuredOn(shortDate(v.date)), style: text.labelSmall?.copyWith(color: c.muted)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Entries extends StatelessWidget {
  const _Entries({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    final base = '${Routes.children}/${child.id}';
    final allergies = child.allergies?.trim();

    Widget entry(String key, IconData icon, String title, String route, {String? subtitle}) => ListTile(
      key: Key(key),
      leading: Icon(icon, color: c.blue),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      // chevron_right mirrors with the text direction: it points left (‹, forward) in RTL.
      trailing: Icon(Icons.chevron_right, color: c.muted),
      onTap: () => context.go(route),
    );

    return Card(
      child: Column(
        children: [
          entry('entry-vaccines', Icons.vaccines_outlined, l10n.entryVaccines, '$base/vaccines'),
          const Divider(height: 1),
          entry('entry-visits', Icons.receipt_long_outlined, l10n.entryVisits, '$base/visits'),
          const Divider(height: 1),
          entry('entry-follow-up', Icons.checklist_rtl, l10n.entryFollowUp, '$base/follow-up'),
          const Divider(height: 1),
          entry(
            'entry-details',
            Icons.badge_outlined,
            l10n.entryDetails,
            base,
            subtitle: allergies == null || allergies.isEmpty
                ? l10n.detailsNoAllergies
                : l10n.detailsAllergies(allergies),
          ),
        ],
      ),
    );
  }
}

/// The family package (FR-020): state, end date and months left; nothing without a package.
class _PackageCard extends ConsumerWidget {
  const _PackageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final today = ClinicTime.dateOf(ref.watch(clockProvider)());
    final status = packageStatus(ref.watch(familyPackagesProvider).value ?? const [], today);
    if (status == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Card(
        key: const Key('package-card'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: c.yellowSoft, borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.verified_user_outlined, color: c.yellow),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.packageTitle, style: text.bodySmall?.copyWith(color: c.muted)),
                    const SizedBox(height: 2),
                    Text(
                      status.active
                          ? l10n.packageActiveUntil(shortDate(status.endsOn))
                          : l10n.packageEndedOn(shortDate(status.endsOn)),
                      style: text.titleSmall,
                    ),
                    if (status.active && status.monthsLeft > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.packageMonthsLeft(l10n.ageMonths(status.monthsLeft, arabicDigits(status.monthsLeft))),
                        style: text.bodySmall?.copyWith(color: c.muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status.active ? c.greenSoft : c.canvas,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status.active ? l10n.packageActive : l10n.packageEnded,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: status.active ? c.green : c.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
