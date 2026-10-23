import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_repository.dart';

/// A bookable vaccine (`vaccines/{id}`). The schedule per child comes in feature 003.
class Vaccine {
  const Vaccine({required this.id, required this.name, required this.price, required this.showPrice});

  final String id;
  final String name;
  final int price;

  /// False: the app shows "بالسعر في العيادة" instead of the price.
  final bool showPrice;
}

/// Active vaccines, by name.
final vaccinesProvider = StreamProvider<List<Vaccine>>((ref) => ref
    .watch(firestoreProvider)
    .collection('vaccines')
    .where('active', isEqualTo: true)
    .snapshots()
    .map((q) => q.docs
        .map((d) => Vaccine(
              id: d.id,
              name: d['name'] as String,
              price: (d['price'] as num).toInt(),
              showPrice: d.data()['showPrice'] as bool? ?? true,
            ))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name))));
