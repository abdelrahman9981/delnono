import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/theme.dart';
import '../../../core/format/arabic_digits.dart';
import '../../clinics/data/clinics_repository.dart';
import '../data/doses_repository.dart';
import '../data/measurements_repository.dart';
import '../data/vaccine_schedule_repository.dart';
import '../data/visits_repository.dart';
import 'profile_format.dart';

/// A child's visit history, newest first, with what was recorded at each visit (`/children/:id/visits`,
/// FR-013 to FR-015). Prescription photos are Phase 2 (D-39).
class VisitsScreen extends ConsumerWidget {
  const VisitsScreen({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final visits = ref.watch(visitsProvider(childId));
    final measurements = ref.watch(measurementsProvider(childId)).value ?? const <Measurement>[];
    final doses = ref.watch(dosesProvider(childId)).value ?? const <DoseRecord>[];
    final catalogue = ref.watch(vaccineCatalogueProvider).value ?? const <String, VaccineInfo>{};

    String measured(Visit v) {
      final m = measurements.where((m) => m.visitId == v.id || (m.visitId == null && m.measuredOn == v.date));
      return [
        for (final x in m) ...[
          if (x.weightKg != null) '${l10n.measureWeight} ${measureValue(x.weightKg!)} ${l10n.unitKg}',
          if (x.lengthCm != null) '${l10n.measureLength} ${measureValue(x.lengthCm!)} ${l10n.unitCm}',
          if (x.headCm != null) '${l10n.measureHead} ${measureValue(x.headCm!)} ${l10n.unitCm}',
        ],
      ].join(l10n.nameListSeparator);
    }

    String given(Visit v) => doses
        .where((d) => d.visitId == v.id || (d.visitId == null && d.givenOn == v.date))
        .map((d) => '${catalogue[d.vaccineId]?.name ?? d.vaccineId} (${l10n.doseNumber(arabicDigits(d.dose))})')
        .join(l10n.nameListSeparator);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.visitsTitle)),
      body: SafeArea(
        child: visits.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(l10n.errGeneric)),
          data: (list) => list.isEmpty
              ? Center(
                  child: Text(l10n.visitsEmpty, style: text.bodyLarge?.copyWith(color: c.muted)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final v = list[i];
                    final m = measured(v);
                    final d = given(v);
                    final muted = text.bodySmall?.copyWith(color: c.muted);
                    return Card(
                      key: Key('visit-${v.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${shortDate(v.date)} · ${switch (v.type) {
                                    VisitType.clinic => l10n.visitClinic,
                                    VisitType.vaccine => l10n.visitVaccine,
                                    VisitType.walkIn => l10n.visitWalkIn,
                                  }}',
                                  style: text.titleSmall,
                                ),
                                if (ref.watch(clinicOfProvider(v.clinicId)) case final clinic?)
                                  Text(
                                    key: Key('visit-clinic-${v.id}'),
                                    l10n.visitAtClinic(clinic.name),
                                    style: muted,
                                  ),
                                if (m.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(l10n.visitMeasurements(m), style: muted),
                                ],
                                if (d.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(l10n.visitDoses(d), style: muted),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
