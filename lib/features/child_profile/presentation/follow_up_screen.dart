import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/theme.dart';
import '../../../core/clock.dart';
import '../../../core/format/arabic_digits.dart';
import '../../../core/launch/external_links.dart';
import '../../booking/domain/clinic_time.dart';
import '../../children/data/children_repository.dart';
import '../../clinics/data/clinics_repository.dart';
import '../data/follow_up_repository.dart';
import '../domain/age_band.dart';
import '../domain/child_age.dart';
import 'offline_note.dart';

/// Egypt's ambulance number (D-33); fixed by the emergency services, not a clinic setting.
const ambulanceNumber = '123';

/// Age follow-up and "متى تتصلين بالدكتور" (`/children/:id/follow-up`, design `FollowUp.dc.html`,
/// FR-016 to FR-019). Every item is the doctor's text; until approved it is placeholder in brackets.
class FollowUpScreen extends ConsumerWidget {
  const FollowUpScreen({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final child = ref.watch(childrenProvider).value?.where((k) => k.id == childId).firstOrNull;
    final bands = ref.watch(followUpBandsProvider).value ?? const <FollowUpBand>[];
    final settings = ref.watch(followUpSettingsProvider).value ?? const FollowUpSettings();
    // One call button per clinic with a phone (004 FR-019).
    final clinics = (ref.watch(clinicsProvider).value ?? const <Clinic>[]).where((c) => c.phone != null).toList();
    final today = ClinicTime.dateOf(ref.watch(clockProvider)());

    if (child == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.followUpTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final age = ageInMonths(child.birthDate, today);
    final overAge = age >= settings.maxAgeMonths;
    final band = bandFor(bands, age, settings.maxAgeMonths);
    final placeholder = (band?.items ?? settings.dangerSigns).any((i) => i.trimLeft().startsWith('['));
    final links = ref.read(externalLinksProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.followUpTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            const OfflineNote(),
            if (overAge)
              Text(
                key: const Key('follow-up-over-age'),
                l10n.followUpOverAge(arabicDigits(settings.maxAgeMonths ~/ 12)),
                style: text.bodyMedium?.copyWith(color: c.muted),
              )
            else if (band == null)
              Text(l10n.followUpNoBand, style: text.bodyMedium?.copyWith(color: c.muted))
            else
              Card(
                key: const Key('follow-up-band'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(band.title, style: text.titleMedium),
                      if (placeholder) ...[
                        const SizedBox(height: 2),
                        Text(l10n.followUpPlaceholder, style: text.bodySmall?.copyWith(color: c.muted)),
                      ],
                      const SizedBox(height: 10),
                      for (final item in band.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check_circle_outline, size: 18, color: c.green),
                              const SizedBox(width: 8),
                              Expanded(child: Text(item, style: text.bodyMedium)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Container(
              key: const Key('when-to-call'),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: c.dangerBg, borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: c.dangerText),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(l10n.whenToCall, style: text.titleMedium?.copyWith(color: c.dangerText)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(l10n.whenToCallIntro, style: text.bodyMedium?.copyWith(color: c.dangerText)),
                  const SizedBox(height: 8),
                  for (final sign in settings.dangerSigns)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text('• $sign', style: text.bodyMedium?.copyWith(color: c.dangerText)),
                    ),
                  const SizedBox(height: 12),
                  for (final clinic in clinics) ...[
                    FilledButton.icon(
                      key: Key('call-clinic-${clinic.id}'),
                      onPressed: () => links.callNumber(clinic.phone!),
                      icon: const Icon(Icons.call_outlined),
                      label: Text(clinics.length == 1 ? l10n.callClinicPhone : l10n.callClinicAt(clinic.area)),
                    ),
                    const SizedBox(height: 8),
                  ],
                  FilledButton.icon(
                    key: const Key('call-ambulance'),
                    style: FilledButton.styleFrom(backgroundColor: c.emergency, foregroundColor: Colors.white),
                    onPressed: () => links.callNumber(ambulanceNumber),
                    icon: const Icon(Icons.emergency_outlined),
                    label: Text(l10n.callAmbulance),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.followUpDisclaimer,
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}
