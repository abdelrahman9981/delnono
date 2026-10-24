import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_repository.dart';

class HourRange {
  const HourRange(this.from, this.to);

  final int from;
  final int to;
}

/// `settings/booking` (data-model.md). Defaults match the seeded placeholders.
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
  });

  static const _evening = [HourRange(17, 21)];
  static const defaultWorkingHours = <int, List<HourRange>>{
    1: _evening, 2: _evening, 3: _evening, 4: _evening, 5: [], 6: _evening, 7: _evening,
  };

  factory BookingSettings.fromMap(Map<String, dynamic>? d) {
    const def = BookingSettings();
    if (d == null) return def;
    int n(String k, int fallback) => (d[k] as num?)?.toInt() ?? fallback;
    Map<int, List<HourRange>> hours = def.workingHours;
    final raw = d['workingHours'];
    if (raw is Map) {
      hours = {
        for (final e in raw.entries)
          int.parse(e.key.toString()): [
            for (final r in (e.value as List).cast<Map>())
              HourRange((r['from'] as num).toInt(), (r['to'] as num).toInt()),
          ],
      };
    }
    return BookingSettings(
      capacityPerHour: n('capacityPerHour', def.capacityPerHour),
      workingHours: hours,
      holidays: (d['holidays'] as List?)?.cast<String>() ?? def.holidays,
      vaccineWeekdays: (d['vaccineWeekdays'] as List?)?.map((e) => (e as num).toInt()).toList() ?? def.vaccineWeekdays,
      visitPrice: n('visitPrice', def.visitPrice),
      cancelWindowHours: n('cancelWindowHours', def.cancelWindowHours),
      bookingHorizonDays: n('bookingHorizonDays', def.bookingHorizonDays),
      maxUpcomingPerFamily: n('maxUpcomingPerFamily', def.maxUpcomingPerFamily),
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
}

final bookingSettingsProvider = StreamProvider<BookingSettings>((ref) => ref
    .watch(firestoreProvider)
    .doc('settings/booking')
    .snapshots()
    .map((s) => BookingSettings.fromMap(s.data())));

