import 'package:delnono/core/clock.dart';
import 'package:delnono/dashboard/data/dashboard_api.dart';
import 'package:delnono/dashboard/data/staff_session.dart';
import 'package:delnono/dashboard/data/today_repository.dart';
import 'package:delnono/features/booking/domain/booking.dart';
import 'package:delnono/features/booking/domain/price_preview.dart';
import 'package:delnono/features/child_profile/data/vaccine_schedule_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../helpers/clinic_fakes.dart';

/// Sunday 15 Nov 2026, 18:30 Cairo (UTC+2).
final now = DateTime.utc(2026, 11, 15, 16, 30);

const doctorSession = StaffSession(uid: 'doc', name: '[د. أحمد]', email: 'doctor@demo.delnono', role: StaffRole.doctor);
const secretarySession =
    StaffSession(uid: 'sec1', name: '[سكرتيرة]', email: 'sec1@demo.delnono', role: StaffRole.secretary, clinicId: 'clinic-1');

/// Records every call; [responses] answers by callable name; [error] fails the next call.
class FakeDashboardApi implements DashboardApi {
  final calls = <(String, Map<String, Object?>)>[];
  final responses = <String, Map<String, dynamic>>{};
  Object? error;

  @override
  Future<Map<String, dynamic>> call(String name, Map<String, Object?> data) async {
    calls.add((name, data));
    if (error != null) throw error!;
    return responses[name] ?? {};
  }
}

QueueBooking queueBooking(String id, int hour, {String status = 'confirmed', DateTime? arrivedAt, int number = 1}) => QueueBooking(
      booking: Booking(
        id: id,
        clinicId: 'clinic-1',
        number: number,
        visitType: VisitType.visit,
        children: const [BookedChild(childId: 'c1', name: 'يوسف', vaccines: [])],
        date: '2026-11-15',
        hour: hour,
        startsAt: DateTime.utc(2026, 11, 15, hour - 2),
        status: BookingStatus.confirmed,
        price: const PriceSnapshot(visitAmount: 300, visitCovered: false, vaccines: [], total: 300, hasHiddenPrices: false),
      ),
      statusRaw: status,
      arrivedAt: arrivedAt,
    );

/// Dashboard overrides: the staff [session], clinics, today's bookings and walk-ins, and the [api].
List<Override> dashboardOverrides({
  StaffSession session = secretarySession,
  required FakeDashboardApi api,
  List<QueueBooking> bookings = const [],
  List<WalkIn> walkIns = const [],
  bool stopped = false,
}) =>
    [
      clockProvider.overrideWithValue(() => now),
      staffSessionProvider.overrideWith((ref) => Stream.value(session)),
      dashboardApiProvider.overrideWithValue(api),
      ...clinicOverrides(clinics: const [clinic1, clinic2], settings: const {'clinic-2': clinic2Settings}),
      dayBookingsProvider.overrideWith((ref, day) => Stream.value(day.clinicId == 'clinic-1' ? bookings : const [])),
      dayWalkInsProvider.overrideWith((ref, day) => Stream.value(day.clinicId == 'clinic-1' ? walkIns : const [])),
      walkInsStoppedProvider.overrideWith((ref, day) => Stream.value(stopped)),
      vaccineCatalogueProvider.overrideWith((ref) => Stream.value(const {
            'v1': VaccineInfo(id: 'v1', name: '[تطعيم ١]', kind: VaccineKind.basic),
          })),
    ];
