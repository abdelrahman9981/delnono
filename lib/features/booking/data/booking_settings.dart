import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_repository.dart';
import '../../clinics/domain/clinic_hours.dart';

export '../../clinics/domain/clinic_hours.dart' show HourRange;

/// A vaccine's offer at one clinic (`clinics/{id}.vaccinePrices`, 004 R4).
class ClinicVaccinePrice {
  const ClinicVaccinePrice({required this.offered, required this.price, required this.shown});

  final bool offered;
  final int price;
  final bool shown;
}

/// The rules for booking at one clinic: its schedule and prices (`clinics/{id}`) with the
/// family-wide horizon and upcoming maximum (`settings/booking`, D-49). Defaults match the seeded
/// placeholders. Mirrors functions/src/lib/booking/settings.ts.
class BookingSettings {
  const BookingSettings({
    this.capacityPerHour = 6,
    this.workingHours = defaultWorkingHours,
    this.holidays = const [],
    this.vaccineWeekdays = const [1, 3],
    this.visitPrice = 300,
    this.cancelWindowHours = 3,
    this.bookingHorizonDays = 14,
    this.maxUpcomingPerFamily = 2,
    this.vaccinePrices = const {},
  });

  static const _evening = [HourRange(17, 21)];
  static const defaultWorkingHours = <int, List<HourRange>>{
    1: _evening, 2: _evening, 3: _evening, 4: _evening, 5: [], 6: _evening, 7: _evening,
  };

  factory BookingSettings.fromMaps(Map<String, dynamic>? clinic, Map<String, dynamic>? family) {
    const def = BookingSettings();
    int n(Map<String, dynamic>? d, String k, int fallback) => (d?[k] as num?)?.toInt() ?? fallback;
    final prices = clinic?['vaccinePrices'];
    return BookingSettings(
      capacityPerHour: n(clinic, 'capacityPerHour', def.capacityPerHour),
      workingHours: parseWorkingHours(clinic?['workingHours']) ?? def.workingHours,
      holidays: (clinic?['holidays'] as List?)?.cast<String>() ?? def.holidays,
      vaccineWeekdays: (clinic?['vaccineWeekdays'] as List?)?.map((e) => (e as num).toInt()).toList() ?? def.vaccineWeekdays,
      visitPrice: n(clinic, 'visitPrice', def.visitPrice),
      cancelWindowHours: n(clinic, 'cancelWindowHours', def.cancelWindowHours),
      bookingHorizonDays: n(family, 'bookingHorizonDays', def.bookingHorizonDays),
      maxUpcomingPerFamily: n(family, 'maxUpcomingPerFamily', def.maxUpcomingPerFamily),
      vaccinePrices: prices is Map
          ? {
              for (final e in prices.entries)
                if (e.value is Map)
                  e.key.toString(): ClinicVaccinePrice(
                    offered: (e.value as Map)['offered'] == true,
                    price: ((e.value as Map)['price'] as num?)?.toInt() ?? 0,
                    shown: (e.value as Map)['shown'] != false,
                  ),
            }
          : def.vaccinePrices,
    );
  }

  final int capacityPerHour;
  final Map<int, List<HourRange>> workingHours;
  final List<String> holidays;
  final List<int> vaccineWeekdays;
  final int visitPrice;
  final int cancelWindowHours;
  final int bookingHorizonDays;
  final int maxUpcomingPerFamily;
  final Map<String, ClinicVaccinePrice> vaccinePrices;
}

/// `settings/booking`: the family-wide booking horizon and upcoming maximum (D-49).
final familyBookingSettingsProvider = StreamProvider<Map<String, dynamic>?>(
  (ref) => ref.watch(firestoreProvider).doc('settings/booking').snapshots().map((s) => s.data()),
);

/// The booking rules at [clinicId] (004 research R1).
final bookingSettingsProvider = StreamProvider.family<BookingSettings, String>((ref, clinicId) {
  final family = ref.watch(familyBookingSettingsProvider).value;
  return ref
      .watch(firestoreProvider)
      .doc('clinics/$clinicId')
      .snapshots()
      .map((s) => BookingSettings.fromMaps(s.data(), family));
});
