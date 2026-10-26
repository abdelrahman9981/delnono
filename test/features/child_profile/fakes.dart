import 'package:delnono/core/clock.dart';
import 'package:delnono/features/booking/data/booking_settings.dart';
import 'package:delnono/features/booking/data/vaccines_repository.dart';
import 'package:delnono/features/child_profile/application/selected_child.dart';
import 'package:delnono/features/child_profile/data/doses_repository.dart';
import 'package:delnono/features/child_profile/data/family_packages_repository.dart';
import 'package:delnono/features/child_profile/data/follow_up_repository.dart';
import 'package:delnono/features/child_profile/data/measurements_repository.dart';
import 'package:delnono/features/child_profile/data/offline_status.dart';
import 'package:delnono/features/child_profile/data/vaccine_schedule_repository.dart';
import 'package:delnono/features/child_profile/data/visits_repository.dart';
import 'package:delnono/features/child_profile/domain/child_age.dart';
import 'package:delnono/features/children/data/children_repository.dart';
import 'package:delnono/features/registration/data/guardian_repository.dart';
import 'package:delnono/features/clinics/data/clinics_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../../helpers/clinic_fakes.dart';

/// Profile test data shaped like the seed (functions/scripts/seed.ts). Today is 24 Oct 2026, 12:00
/// Cairo time.
final today = DateTime.utc(2026, 10, 24, 10);

const youssef = Child(id: 'c1', name: 'يوسف', birthDate: '2024-03-15', sex: Sex.male, allergies: 'بنسلين');
const salma = Child(id: 'c2', name: 'سلمى', birthDate: '2026-01-20', sex: Sex.female, birthWeightKg: 3.1);
const mariam = Child(id: 'c3', name: 'مريم', birthDate: '2022-07-02', sex: Sex.female);

const youssefMeasurements = [
  Measurement(id: 'm1', measuredOn: '2025-09-15', weightKg: 10.6, lengthCm: 81, visitId: 'v1'),
  Measurement(id: 'm2', measuredOn: '2026-03-15', weightKg: 11.8, lengthCm: 86.5, headCm: 48, visitId: 'v2'),
  Measurement(id: 'm3', measuredOn: '2026-09-15', weightKg: 12.9, lengthCm: 91, visitId: 'v3'),
];

const salmaMeasurements = [
  Measurement(id: 's1', measuredOn: '2026-05-20', weightKg: 6.4, lengthCm: 62, headCm: 40.5),
  Measurement(id: 's2', measuredOn: '2026-07-20', weightKg: 7.3, lengthCm: 65.5, headCm: 42),
];

const schedule = [
  ScheduleEntry(id: 's01', vaccineId: 'v1', dose: 1, dueAge: AgeSpan(), ageLabel: 'عند الولادة', order: 0),
  ScheduleEntry(id: 's05', vaccineId: 'v2', dose: 3, dueAge: AgeSpan(months: 6), ageLabel: 'الشهر السادس', order: 4),
  ScheduleEntry(id: 's06', vaccineId: 'v1', dose: 3, dueAge: AgeSpan(months: 9), ageLabel: 'الشهر التاسع', order: 5),
  ScheduleEntry(id: 's07', vaccineId: 'v2', dose: 4, dueAge: AgeSpan(months: 12), ageLabel: 'السنة الأولى', order: 6),
  ScheduleEntry(
    id: 's08',
    vaccineId: 'v1',
    dose: 4,
    dueAge: AgeSpan(months: 18),
    lastAge: AgeSpan(months: 24),
    ageLabel: 'سنة ونص',
    order: 7,
  ),
];

const catalogue = {
  'v1': VaccineInfo(id: 'v1', name: '[تطعيم مؤقت ١]', kind: VaccineKind.basic),
  'v2': VaccineInfo(id: 'v2', name: '[تطعيم مؤقت ٢]', kind: VaccineKind.basic),
  'v3': VaccineInfo(
    id: 'v3',
    name: '[تطعيم مؤقت ٣]',
    kind: VaccineKind.additional,
    suggestedAge: AgeSpan(months: 12),
    doses: 2,
    intervalWeeks: 4,
    note: '[ملاحظة الدكتور · مؤقتة]',
  ),
  'v5': VaccineInfo(
    id: 'v5',
    name: '[تطعيم مؤقت ٥]',
    kind: VaccineKind.additional,
    suggestedAge: AgeSpan(months: 24),
  ),
};

const salmaDoses = [
  DoseRecord(id: 'd1', scheduleId: 's01', vaccineId: 'v1', dose: 1, givenOn: '2026-01-21', lot: 'LOT-1101'),
  DoseRecord(id: 'd2', scheduleId: 's05', vaccineId: 'v2', dose: 3, givenOn: '2026-07-20'),
];

const youssefDoses = [
  DoseRecord(id: 'y1', scheduleId: 's01', vaccineId: 'v1', dose: 1, givenOn: '2024-03-16', lot: 'LOT-1001'),
  DoseRecord(id: 'y3', vaccineId: 'v3', dose: 1, givenOn: '2025-03-15', lot: 'LOT-3001', visitId: 'v1'),
];

const youssefVisits = [
  Visit(id: 'v3', date: '2026-09-15', type: VisitType.clinic),
  Visit(id: 'v2', date: '2026-03-15', type: VisitType.clinic),
  Visit(id: 'v1', date: '2025-09-15', type: VisitType.vaccine),
];

const bands = [
  FollowUpBand(fromMonths: 6, toMonths: 9, title: 'متابعة الشهر السادس', items: ['[بند متابعة ١ من قائمة الدكتور]']),
  FollowUpBand(
    fromMonths: 9,
    toMonths: 12,
    title: 'متابعة الشهر التاسع',
    items: ['[بند متابعة ١ من قائمة الدكتور]', '[بند متابعة ٢ من قائمة الدكتور]'],
  ),
];

class MemorySelectedChildStore implements SelectedChildStore {
  String? saved;

  @override
  Future<String?> read() async => saved;

  @override
  Future<void> write(String childId) async => saved = childId;
}

/// Overrides for the profile data providers (not the clock or the children). With [anyChild], every
/// child id gets Youssef's records, for app-level tests whose children have other ids.
List<Override> profileDataOverrides({
  Map<String, List<Measurement>> measurements = const {'c1': youssefMeasurements, 'c2': salmaMeasurements},
  Map<String, List<DoseRecord>> doses = const {'c1': youssefDoses, 'c2': salmaDoses},
  Map<String, List<Visit>> visits = const {'c1': youssefVisits},
  VaccineSettings vaccineSettings = const VaccineSettings(source: '[جدول وزارة الصحة · مؤقت]', reviewedOn: '2026-10-01'),
  FollowUpSettings followUpSettings = const FollowUpSettings(dangerSigns: ['[علامة خطر ١ · من قائمة الدكتور]']),
  MemorySelectedChildStore? store,
  bool anyChild = false,
  bool offline = false,
  List<({bool active, String startsOn, String endsOn})> packages = const [],
  List<FollowUpBand> followUpBands = bands,
  List<Vaccine> bookingVaccines = const [],
  List<Clinic> clinics = const [clinic1],
}) =>
    [
      // Clinic 1 hides v3's price and shows v5's (FR-043, D-45).
      ...clinicOverrides(
        clinics: clinics,
        settings: const {
          'clinic-1': BookingSettings(vaccinePrices: {
            'v3': ClinicVaccinePrice(offered: true, price: 450, shown: false),
            'v5': ClinicVaccinePrice(offered: true, price: 300, shown: true),
          }),
        },
        vaccines: {'clinic-1': bookingVaccines},
      ),
      offlineProvider.overrideWith((ref) => Stream.value(offline)),
      familyPackagesProvider.overrideWith((ref) => Stream.value(packages)),
      selectedChildStoreProvider.overrideWithValue(store ?? MemorySelectedChildStore()),
      measurementsProvider.overrideWith(
        (ref, id) => Stream.value(measurements[id] ?? (anyChild ? youssefMeasurements : const <Measurement>[])),
      ),
      dosesProvider.overrideWith((ref, id) => Stream.value(doses[id] ?? (anyChild ? youssefDoses : const <DoseRecord>[]))),
      visitsProvider.overrideWith((ref, id) => Stream.value(visits[id] ?? (anyChild ? youssefVisits : const <Visit>[]))),
      vaccineScheduleProvider.overrideWith((ref) => Stream.value(schedule)),
      vaccineCatalogueProvider.overrideWith((ref) => Stream.value(catalogue)),
      vaccineSettingsProvider.overrideWith((ref) => Stream.value(vaccineSettings)),
      followUpBandsProvider.overrideWith((ref) => Stream.value(followUpBands)),
      followUpSettingsProvider.overrideWith((ref) => Stream.value(followUpSettings)),
    ];

/// Every profile override, with a fixed clock ([today]) and [children].
List<Override> profileOverrides({
  List<Child> children = const [youssef, salma],
  Map<String, List<Measurement>> measurements = const {'c1': youssefMeasurements, 'c2': salmaMeasurements},
  MemorySelectedChildStore? store,
  bool offline = false,
  List<({bool active, String startsOn, String endsOn})> packages = const [],
  List<Clinic> clinics = const [clinic1],
  Guardian? guardian,
  bool includeChildren = true,
  List<FollowUpBand> followUpBands = bands,
}) =>
    [
      clockProvider.overrideWithValue(() => today),
      if (includeChildren) childrenProvider.overrideWith((ref) => Stream.value(children)),
      guardianProvider.overrideWith((ref) => Stream.value(guardian)),
      ...profileDataOverrides(
        measurements: measurements,
        store: store,
        offline: offline,
        packages: packages,
        clinics: clinics,
        followUpBands: followUpBands,
      ),
    ];
