import 'package:delnono/features/booking/data/booking_api.dart';
import 'package:delnono/features/booking/domain/price_preview.dart';

/// Records calls; the next call fails with [error] when set.
class FakeBookingApi implements BookingApi {
  final created = <(BookingSelection, int)>[];
  final changed = <(String, BookingSelection, int)>[];
  final cancelled = <String>[];
  Object? error;

  PriceSnapshot _price(int total) =>
      PriceSnapshot(visitAmount: total, visitCovered: false, vaccines: const [], total: total, hasHiddenPrices: false);

  @override
  Future<BookingResult> create(BookingSelection selection, int expectedTotal) async {
    if (error != null) throw error!;
    created.add((selection, expectedTotal));
    return BookingResult('b${created.length}', 247 + created.length, _price(expectedTotal));
  }

  @override
  Future<void> cancel(String bookingId) async {
    if (error != null) throw error!;
    cancelled.add(bookingId);
  }

  @override
  Future<BookingResult> change(String bookingId, BookingSelection selection, int expectedTotal) async {
    if (error != null) throw error!;
    changed.add((bookingId, selection, expectedTotal));
    return BookingResult(bookingId, 248, _price(expectedTotal));
  }
}
