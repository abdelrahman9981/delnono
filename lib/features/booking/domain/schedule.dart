import '../data/booking_settings.dart';
import 'clinic_time.dart';

// Mirrors functions/src/lib/booking/schedule.ts for display; the server decides (research R5).

bool isOpenDay(BookingSettings s, String date) =>
    !s.holidays.contains(date) && (s.workingHours[ClinicTime.weekday(date)] ?? const []).isNotEmpty;

bool isVaccineDay(BookingSettings s, String date) =>
    isOpenDay(s, date) && s.vaccineWeekdays.contains(ClinicTime.weekday(date));

/// Working hours of a date, ascending.
List<int> hoursOf(BookingSettings s, String date) {
  if (!isOpenDay(s, date)) return const [];
  final hours = <int>{
    for (final r in s.workingHours[ClinicTime.weekday(date)] ?? const <HourRange>[])
      for (var h = r.from; h < r.to; h++) h,
  };
  return hours.toList()..sort();
}

/// Days a guardian can pick: today up to the horizon, open (vaccine days when [vaccines]) and with
/// at least one hour that has not started.
List<String> bookableDays(BookingSettings s, DateTime now, {required bool vaccines}) {
  final today = ClinicTime.dateOf(now);
  return [
    for (var i = 0; i <= s.bookingHorizonDays; i++) ClinicTime.addDays(today, i),
  ].where((d) => (vaccines ? isVaccineDay(s, d) : isOpenDay(s, d)) && openHours(s, d, now).isNotEmpty).toList();
}

/// Hours of [date] that have not started.
List<int> openHours(BookingSettings s, String date, DateTime now) =>
    hoursOf(s, date).where((h) => ClinicTime.startsAt(date, h).isAfter(now)).toList();

/// Places left, never below zero (capacity can be lowered below what is booked).
int placesLeft(BookingSettings s, int taken) => (s.capacityPerHour - taken).clamp(0, s.capacityPerHour);

/// True once cancelling or changing is no longer allowed (FR-020).
bool insideCancelWindow(BookingSettings s, DateTime hourStart, DateTime now) =>
    !now.isBefore(hourStart.subtract(Duration(hours: s.cancelWindowHours)));
