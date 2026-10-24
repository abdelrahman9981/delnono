import 'package:delnono/features/booking/data/booking_settings.dart';
import 'package:delnono/features/booking/data/vaccines_repository.dart';
import 'package:delnono/features/clinics/data/clinics_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// The two seeded clinics (004 quickstart.md), as the app reads them.
const clinic1 = Clinic(
  id: 'clinic-1',
  name: '[عيادة المقطم · بيانات مؤقتة]',
  area: 'المقطم',
  address: '[عنوان مؤقت · المقطم]',
  phone: '+201000000000',
  whatsapp: '+201000000000',
  order: 0,
  workingHours: BookingSettings.defaultWorkingHours,
);

const _morning = [HourRange(10, 14)];
const clinic2 = Clinic(
  id: 'clinic-2',
  name: '[عيادة مدينة نصر · بيانات مؤقتة]',
  area: 'مدينة نصر',
  address: '[عنوان مؤقت · مدينة نصر]',
  phone: '+201000000002',
  whatsapp: '+201000000002',
  order: 1,
  workingHours: {1: _morning, 2: _morning, 3: _morning, 4: _morning, 5: [], 6: [], 7: _morning},
);

const clinic2Settings = BookingSettings(
  capacityPerHour: 5,
  workingHours: {1: _morning, 2: _morning, 3: _morning, 4: _morning, 5: [], 6: [], 7: _morning},
  vaccineWeekdays: [7, 2],
  visitPrice: 350,
  cancelWindowHours: 6,
);

/// Clinic providers for widget tests: [clinics] (active ones are shown), each clinic's booking
/// [settings] (002 defaults when missing) and offered [vaccines].
List<Override> clinicOverrides({
  List<Clinic> clinics = const [clinic1],
  Map<String, BookingSettings> settings = const {},
  Map<String, List<Vaccine>> vaccines = const {},
}) =>
    [
      allClinicsProvider.overrideWith((ref) => Stream.value(clinics)),
      bookingSettingsProvider.overrideWith((ref, id) => Stream.value(settings[id] ?? const BookingSettings())),
      vaccinesProvider.overrideWith((ref, id) => Stream.value(vaccines[id] ?? const <Vaccine>[])),
    ];
