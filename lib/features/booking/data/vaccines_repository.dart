import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_repository.dart';
import 'booking_settings.dart';

/// A vaccine bookable at a clinic, with that clinic's price (`vaccines/{id}` + `clinics/{id}`).
class Vaccine {
  const Vaccine({required this.id, required this.name, required this.price, required this.showPrice});

  final String id;
  final String name;
  final int price;

  /// False: the app shows "بالسعر في العيادة" instead of the price.
  final bool showPrice;
}

/// The doctor's active vaccines offered at [clinicId], by name, with the clinic's prices (004 R4).
final vaccinesProvider = StreamProvider.family<List<Vaccine>, String>((ref, clinicId) {
  final prices = ref.watch(bookingSettingsProvider(clinicId)).value?.vaccinePrices ?? const {};
  return ref
      .watch(firestoreProvider)
      .collection('vaccines')
      .where('active', isEqualTo: true)
      .snapshots()
      .map((q) => [
            for (final d in q.docs)
              if (prices[d.id] case final offer? when offer.offered)
                Vaccine(id: d.id, name: d['name'] as String, price: offer.price, showPrice: offer.shown),
          ]..sort((a, b) => a.name.compareTo(b.name)));
});
