import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Clinic time (Cairo, with Egypt's summer time). Used only to decide what to show; the server
/// decides every booking (research R5).
abstract final class ClinicTime {
  static tz.Location? _cairo;

  static tz.Location get cairo {
    if (_cairo == null) {
      tzdata.initializeTimeZones();
      _cairo = tz.getLocation('Africa/Cairo');
    }
    return _cairo!;
  }

  /// Cairo calendar date of [instant] as `YYYY-MM-DD`.
  static String dateOf(DateTime instant) {
    final c = tz.TZDateTime.from(instant, cairo);
    return '${c.year.toString().padLeft(4, '0')}-${c.month.toString().padLeft(2, '0')}-${c.day.toString().padLeft(2, '0')}';
  }

  /// The instant an hour starts in Cairo.
  static DateTime startsAt(String date, int hour) {
    final p = date.split('-').map(int.parse).toList();
    return tz.TZDateTime(cairo, p[0], p[1], p[2], hour).toUtc();
  }

  /// ISO weekday: 1 = Monday … 7 = Sunday.
  static int weekday(String date) {
    final p = date.split('-').map(int.parse).toList();
    return DateTime.utc(p[0], p[1], p[2]).weekday;
  }

  static String addDays(String date, int days) {
    final p = date.split('-').map(int.parse).toList();
    final d = DateTime.utc(p[0], p[1], p[2] + days);
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static DateTime asDate(String date) {
    final p = date.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }
}
