import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/callable.dart';
import '../../../core/firebase/functions_region.dart';
import '../domain/price_preview.dart';

/// What the guardian chose (contracts/callables.md, `selection`).
class BookingSelection {
  const BookingSelection({
    required this.clinicId,
    required this.visitType,
    required this.date,
    required this.hour,
    required this.children,
  });

  /// The clinic booked at (004). A change keeps the booking's clinic; the server ignores this there.
  final String clinicId;
  final VisitType visitType;
  final String date;
  final int hour;

  /// Child id → vaccine ids, in the order the children were picked.
  final Map<String, List<String>> children;

  Map<String, Object> toMap(int expectedTotal) => {
        'clinicId': clinicId,
        'visitType': visitType == VisitType.visit ? 'visit' : 'vaccine_only',
        'date': date,
        'hour': hour,
        'children': [
          for (final MapEntry(key: childId, value: vaccines) in children.entries)
            {'childId': childId, 'vaccines': vaccines},
        ],
        'expectedTotal': expectedTotal,
      };
}

class BookingResult {
  const BookingResult(this.bookingId, this.number, this.price);

  final String bookingId;
  final int number;
  final PriceSnapshot price;
}

/// "الميعاد اتحجز": the hour filled before confirming (FR-009).
class BookingFullException implements Exception {
  const BookingFullException();
}

/// The day or hour cannot be booked: `closed`, `outside_hours`, `beyond_horizon`, `started`,
/// `not_vaccine_day`; or cancel/change refused: `inside_window`, `not_confirmed`.
class BookingRefusedException implements Exception {
  const BookingRefusedException(this.reason);

  final String reason;
}

/// The family already has a booking that day (FR-011).
class BookingSameDayException implements Exception {
  const BookingSameDayException(this.bookingId);

  final String? bookingId;
}

/// The family already holds the maximum upcoming bookings (FR-011a).
class BookingLimitException implements Exception {
  const BookingLimitException();
}

/// A price changed after the summary was shown; [price] is today's (FR-015).
class BookingPriceChangedException implements Exception {
  const BookingPriceChangedException(this.price);

  final PriceSnapshot price;
}

abstract interface class BookingApi {
  Future<BookingResult> create(BookingSelection selection, int expectedTotal);

  Future<void> cancel(String bookingId);

  Future<BookingResult> change(String bookingId, BookingSelection selection, int expectedTotal);
}

class FirebaseBookingApi implements BookingApi {
  FirebaseBookingApi(this._functions);

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> _call(String name, Map<String, Object> data) async {
    try {
      final result = await _functions.callFunction<Map<String, dynamic>>(name, data);
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      final details = e.details is Map ? Map<String, dynamic>.from(e.details as Map) : const <String, dynamic>{};
      final reason = details['reason'] as String?;
      switch (e.code) {
        case 'resource-exhausted' when reason == 'full':
          throw const BookingFullException();
        case 'failed-precondition' when reason == 'price_changed':
          throw BookingPriceChangedException(PriceSnapshot.fromMap(Map<String, dynamic>.from(details['price'] as Map)));
        case 'failed-precondition' when reason != null:
          throw BookingRefusedException(reason);
        case 'already-exists':
          throw BookingSameDayException(details['bookingId'] as String?);
        case 'out-of-range':
          throw const BookingLimitException();
      }
      rethrow;
    }
  }

  BookingResult _result(Map<String, dynamic> d) => BookingResult(
        d['bookingId'] as String,
        (d['number'] as num).toInt(),
        PriceSnapshot.fromMap(Map<String, dynamic>.from(d['price'] as Map)),
      );

  @override
  Future<BookingResult> create(BookingSelection selection, int expectedTotal) async =>
      _result(await _call('createBooking', selection.toMap(expectedTotal)));

  @override
  Future<void> cancel(String bookingId) => _call('cancelBooking', {'bookingId': bookingId});

  @override
  Future<BookingResult> change(String bookingId, BookingSelection selection, int expectedTotal) async =>
      _result(await _call('changeBooking', {
        'bookingId': bookingId,
        'selection': selection.toMap(expectedTotal)..remove('expectedTotal'),
        'expectedTotal': expectedTotal,
      }));
}

final bookingApiProvider = Provider<BookingApi>((ref) => FirebaseBookingApi(ref.watch(functionsProvider)));
