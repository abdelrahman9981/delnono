import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/theme.dart';
import '../../../core/clock.dart';
import '../../../core/format/arabic_digits.dart';
import '../../../core/widgets/notice.dart';
import '../../booking/domain/clinic_time.dart';
import '../../booking/data/booking_settings.dart';
import '../../children/data/children_repository.dart';
import '../../clinics/data/clinics_repository.dart';
import '../data/doses_repository.dart';
import '../data/vaccine_schedule_repository.dart';
import '../domain/dose_state.dart';
import 'offline_note.dart';
import 'profile_format.dart';

/// A child's vaccines (`/children/:id/vaccines`, FR-006 to FR-012): the basic schedule with dose
/// states (D-17) and the doctor's optional additional vaccines, clearly marked (FR-041).
class VaccinesScreen extends ConsumerWidget {
  const VaccinesScreen({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final child = ref.watch(childrenProvider).value?.where((k) => k.id == childId).firstOrNull;
    final schedule = ref.watch(vaccineScheduleProvider);
    final catalogue = ref.watch(vaccineCatalogueProvider).value ?? const <String, VaccineInfo>{};
    final settings = ref.watch(vaccineSettingsProvider).value ?? const VaccineSettings();
    final records = ref.watch(dosesProvider(childId)).value ?? const <DoseRecord>[];
    final today = ClinicTime.dateOf(ref.watch(clockProvider)());

    Widget body() {
      if (child == null || (!schedule.hasValue && !schedule.hasError)) {
        return const Center(child: CircularProgressIndicator());
      }
      final groups = scheduleFor(
        schedule.value ?? const [],
        birthDate: child.birthDate,
        today: today,
        records: records,
        lateAfterDays: settings.lateAfterDays,
      );
      final additional =
          catalogue.values
              .where((v) => v.kind == VaccineKind.additional)
              .where((v) => v.active || additionalDoses(v.id, records).isNotEmpty)
              .toList()
            ..sort((a, b) => (a.suggestedAge?.months ?? 0).compareTo(b.suggestedAge?.months ?? 0));
      String name(String vaccineId) => catalogue[vaccineId]?.name ?? vaccineId;

      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          const OfflineNote(),
          if (settings.source.isNotEmpty || settings.reviewedOn != null)
            Notice(
              [
                if (settings.source.isNotEmpty) l10n.vaccinesSource(settings.source),
                if (settings.reviewedOn != null) l10n.vaccinesReviewed(shortDate(settings.reviewedOn!)),
              ].join('\n'),
              key: const Key('schedule-source'),
              icon: Icons.verified_outlined,
            ),
          const SizedBox(height: 16),
          Text(l10n.vaccinesBasic, style: text.titleMedium),
          const SizedBox(height: 8),
          if (groups.isEmpty) Text(l10n.vaccinesEmpty, style: text.bodyMedium?.copyWith(color: c.muted)),
          for (final (label, doses) in groups) ...[
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 6),
              child: Text(label, style: text.labelLarge?.copyWith(color: c.muted)),
            ),
            Card(
              child: Column(
                children: [
                  for (final (i, d) in doses.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    _DoseRow(dose: d, vaccineName: name(d.entry.vaccineId)),
                  ],
                ],
              ),
            ),
          ],
          if (additional.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(l10n.vaccinesAdditional, style: text.titleMedium),
                const _AdditionalBadge(),
              ],
            ),
            const SizedBox(height: 6),
            Text(l10n.additionalChoice, style: text.bodySmall?.copyWith(color: c.muted)),
            const SizedBox(height: 8),
            for (final v in additional) _AdditionalCard(vaccine: v, given: additionalDoses(v.id, records)),
          ],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.vaccinesTitle)),
      body: SafeArea(child: body()),
    );
  }
}

class _DoseRow extends StatelessWidget {
  const _DoseRow({required this.dose, required this.vaccineName});

  final ScheduledDose dose;
  final String vaccineName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final r = dose.record;
    return Padding(
      key: Key('dose-${dose.entry.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$vaccineName · ${l10n.doseNumber(arabicDigits(dose.entry.dose))}', style: text.titleSmall),
                const SizedBox(height: 3),
                Text(
                  r == null ? l10n.doseDueOn(shortDate(dose.dueDate)) : l10n.doseGivenOn(shortDate(r.givenOn)),
                  style: text.bodySmall?.copyWith(color: c.muted),
                ),
                if (r?.lot != null) Text(l10n.doseLot(r!.lot!), style: text.bodySmall?.copyWith(color: c.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DoseStatePill(dose.state),
        ],
      ),
    );
  }
}

/// The dose state as a pill. States are schedule facts (D-17), not judgments about the child.
class DoseStatePill extends StatelessWidget {
  const DoseStatePill(this.state, {super.key});

  final DoseState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    final (label, bg, fg) = switch (state) {
      DoseState.given => (l10n.doseGiven, c.greenSoft, c.green),
      DoseState.due => (l10n.doseDue, c.blueSoft, c.blue),
      DoseState.scheduled => (l10n.doseScheduled, c.canvas, c.muted),
      DoseState.late => (l10n.doseLate, c.yellowSoft, c.text),
      DoseState.missed => (l10n.doseMissed, c.dangerBg, c.dangerText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _AdditionalBadge extends StatelessWidget {
  const _AdditionalBadge();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: c.pinkSoft, borderRadius: BorderRadius.circular(999)),
      child: Text(
        AppLocalizations.of(context).additionalBadge,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.pink),
      ),
    );
  }
}

class _AdditionalCard extends ConsumerWidget {
  const _AdditionalCard({required this.vaccine, required this.given});

  final VaccineInfo vaccine;
  final List<DoseRecord> given;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final muted = text.bodySmall?.copyWith(color: c.muted);
    return Card(
      key: Key('additional-${vaccine.id}'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(vaccine.name, style: text.titleSmall)),
                const _AdditionalBadge(),
              ],
            ),
            const SizedBox(height: 6),
            if (vaccine.suggestedAge != null)
              Text(l10n.additionalSuggestedAge(ageSpanLabel(l10n, vaccine.suggestedAge!)), style: muted),
            Text(l10n.additionalDoses(arabicDigits(vaccine.doses)), style: muted),
            if (vaccine.doses > 1 && vaccine.intervalWeeks > 0)
              Text(l10n.additionalInterval(arabicDigits(vaccine.intervalWeeks)), style: muted),
            // The price at each clinic that offers it and shows its price (FR-043, D-45).
            for (final clinic in ref.watch(clinicsProvider).value ?? const <Clinic>[])
              if (ref.watch(bookingSettingsProvider(clinic.id)).value?.vaccinePrices[vaccine.id] case final offer?
                  when offer.offered && offer.shown)
                Text(l10n.additionalPriceAt(clinic.area, arabicDigits(offer.price)), style: muted),
            if (vaccine.note != null && vaccine.note!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(vaccine.note!, style: text.bodyMedium),
            ],
            for (final d in given) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      [
                        l10n.doseNumber(arabicDigits(d.dose)),
                        l10n.doseGivenOn(shortDate(d.givenOn)),
                        if (d.lot != null) l10n.doseLot(d.lot!),
                      ].join(' · '),
                      style: muted,
                    ),
                  ),
                  const DoseStatePill(DoseState.given),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
