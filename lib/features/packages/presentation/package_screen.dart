import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/theme.dart';
import '../../../core/format/arabic_digits.dart';
import '../../auth/data/auth_repository.dart';
import '../../booking/presentation/booking_format.dart';
import '../../clinics/data/clinics_repository.dart';
import '../data/packages_repository.dart';

/// The annual family package (008 US2, FR-48): the family's status first when they have one, each
/// clinic's price and months from clinic settings (D-45), and what it covers (FR-51, FR-56, D-14,
/// D-46). Public: visitors see prices too. Bought and renewed in cash at the clinic (FR-49).
class PackageScreen extends ConsumerWidget {
  const PackageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final green = dark ? const Color(0xFF79D8BC) : const Color(0xFF258D70);
    final signedIn = ref.watch(authStateProvider).value != null;
    final view = ref.watch(familyPackageViewProvider);
    final clinics = [for (final x in ref.watch(clinicsProvider).value ?? const <Clinic>[]) if (x.packagePrice != null) x];

    Widget rule(IconData icon, String line) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: c.blue),
        const SizedBox(width: 10),
        Expanded(child: Text(line, style: text.bodyMedium?.copyWith(height: 1.5))),
      ]),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pkgTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            if (signedIn && (view.current != null || view.lastEnded != null))
              Card(
                key: const Key('pkg-status'),
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: c.greenSoft, borderRadius: BorderRadius.circular(14)),
                    child: Icon(Icons.card_giftcard, color: green),
                  ),
                  title: Text(l10n.pkgYours, style: text.titleMedium),
                  subtitle: Text(
                    view.current != null
                        ? (view.next != null
                            ? l10n.pkgRenewed(dayLabel(view.next!.endsOn))
                            : l10n.pkgActiveUntil(dayLabel(view.current!.endsOn)))
                        : l10n.pkgEndedOn(dayLabel(view.lastEnded!.endsOn)),
                  ),
                  trailing: PackagePill(active: view.current != null),
                ),
              ),
            Text(l10n.pkgTitle, style: text.headlineSmall),
            Text(l10n.pkgSubtitle, style: text.bodyMedium?.copyWith(color: c.muted)),
            const SizedBox(height: 12),
            for (final clinic in clinics)
              Card(
                key: Key('pkg-price-${clinic.id}'),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.location_on_outlined, color: c.blue),
                  title: Text(clinic.name, style: text.titleSmall),
                  subtitle: Text(l10n.pkgPerClinic(arabicDigits(clinic.packagePrice!), arabicDigits(clinic.packageMonths))),
                ),
              ),
            const SizedBox(height: 12),
            Text(l10n.pkgRulesTitle, style: text.titleMedium),
            const SizedBox(height: 4),
            rule(Icons.family_restroom, l10n.pkgRuleSiblings),
            rule(Icons.all_inclusive, l10n.pkgRuleVisits),
            rule(Icons.vaccines_outlined, l10n.pkgRuleVaccines),
            rule(Icons.location_city_outlined, l10n.pkgRuleClinics),
            rule(Icons.event_outlined, l10n.pkgRuleStart),
            rule(Icons.payments_outlined, l10n.pkgRuleCash),
          ],
        ),
      ),
    );
  }
}

/// «سارية» or «خلصت».
class PackagePill extends StatelessWidget {
  const PackagePill({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = active ? (dark ? const Color(0xFF79D8BC) : const Color(0xFF258D70)) : c.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: active ? c.greenSoft : c.border, borderRadius: BorderRadius.circular(999)),
      child: Text(active ? l10n.pkgActive : l10n.pkgEnded, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
