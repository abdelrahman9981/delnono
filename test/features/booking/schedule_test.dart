import 'package:delnono/features/booking/data/booking_settings.dart';
import 'package:delnono/features/booking/domain/clinic_time.dart';
import 'package:delnono/features/booking/domain/schedule.dart';
import 'package:flutter_test/flutter_test.dart';

// Same cases as functions/test/lib/bookingSchedule.test.ts and bookingTime.test.ts.
void main() {
  const s = BookingSettings();
  final now = DateTime.utc(2026, 11, 15, 10); // Sunday, 12:00 Cairo

  test('Cairo hour starts, winter and summer time', () {
    expect(ClinicTime.startsAt('2026-11-15', 18), DateTime.utc(2026, 11, 15, 16));
    expect(ClinicTime.startsAt('2026-07-15', 18), DateTime.utc(2026, 7, 15, 15));
    expect(ClinicTime.dateOf(DateTime.utc(2026, 11, 15, 22, 30)), '2026-11-16');
  });

  test('open days, vaccine days and hours', () {
    expect(isOpenDay(s, '2026-11-15'), isTrue);
    expect(isOpenDay(s, '2026-11-13'), isFalse); // Friday
    expect(isOpenDay(const BookingSettings(holidays: ['2026-11-16']), '2026-11-16'), isFalse);
    expect(isVaccineDay(s, '2026-11-16'), isTrue); // Monday
    expect(isVaccineDay(s, '2026-11-15'), isFalse);
    expect(hoursOf(s, '2026-11-15'), [17, 18, 19, 20]);
  });

  test('bookable days run from today to the horizon and skip closed days', () {
    final days = bookableDays(s, now, vaccines: false);
    expect(days.first, '2026-11-15');
    expect(days.last, '2026-11-29');
    expect(days, isNot(contains('2026-11-20'))); // Friday
    expect(bookableDays(s, now, vaccines: true).every((d) => isVaccineDay(s, d)), isTrue);
  });

  test('started hours are hidden', () {
    expect(openHours(s, '2026-11-15', now), [17, 18, 19, 20]);
    expect(openHours(s, '2026-11-15', DateTime.utc(2026, 11, 15, 16)), [19, 20]);
  });

  test('places left never go below zero', () {
    expect(placesLeft(s, 2), 4);
    expect(placesLeft(const BookingSettings(capacityPerHour: 3), 5), 0);
  });

  test('cancel window', () {
    final start = ClinicTime.startsAt('2026-11-15', 18);
    expect(insideCancelWindow(s, start, DateTime.utc(2026, 11, 15, 12, 59)), isFalse);
    expect(insideCancelWindow(s, start, DateTime.utc(2026, 11, 15, 13)), isTrue);
  });
}
