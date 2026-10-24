import '../data/vaccines_repository.dart';

// Mirrors functions/src/lib/booking/pricing.ts for the summary; the server prices the booking.

enum VisitType { visit, vaccineOnly }

class VaccineLine {
  const VaccineLine({
    required this.childId,
    required this.vaccineId,
    required this.name,
    required this.amount,
    required this.shown,
  });

  factory VaccineLine.fromMap(Map<String, dynamic> m) => VaccineLine(
        childId: m['childId'] as String,
        vaccineId: m['vaccineId'] as String,
        name: m['name'] as String,
        amount: (m['amount'] as num).toInt(),
        shown: m['shown'] as bool? ?? true,
      );

  final String childId;
  final String vaccineId;
  final String name;
  final int amount;
  final bool shown;
}

class PriceSnapshot {
  const PriceSnapshot({
    required this.visitAmount,
    required this.visitCovered,
    required this.vaccines,
    required this.total,
    required this.hasHiddenPrices,
    this.packageId,
  });

  factory PriceSnapshot.fromMap(Map<String, dynamic> m) {
    final visit = m['visit'] as Map<String, dynamic>?;
    return PriceSnapshot(
      visitAmount: (visit?['amount'] as num?)?.toInt(),
      visitCovered: visit?['covered'] as bool? ?? false,
      vaccines: [for (final l in (m['vaccines'] as List? ?? const [])) VaccineLine.fromMap(Map<String, dynamic>.from(l as Map))],
      total: (m['total'] as num).toInt(),
      hasHiddenPrices: m['hasHiddenPrices'] as bool? ?? false,
      packageId: m['packageId'] as String?,
    );
  }

  /// Null for vaccine only.
  final int? visitAmount;
  final bool visitCovered;
  final List<VaccineLine> vaccines;

  /// What the guardian sees: visit plus shown vaccine prices.
  final int total;
  final bool hasHiddenPrices;
  final String? packageId;
}

PriceSnapshot previewPrice({
  required VisitType visitType,
  required Map<String, List<String>> vaccinesByChild,
  required int visitPrice,
  required Map<String, Vaccine> vaccines,
  String? packageId,
  PriceSnapshot? previous,
}) {
  int? visitAmount;
  var covered = false;
  if (visitType == VisitType.visit) {
    if (packageId != null) {
      visitAmount = 0;
      covered = true;
    } else if (previous?.visitAmount != null && !previous!.visitCovered) {
      visitAmount = previous.visitAmount;
    } else {
      visitAmount = visitPrice;
    }
  }
  final lines = <VaccineLine>[];
  for (final MapEntry(key: childId, value: ids) in vaccinesByChild.entries) {
    for (final id in ids) {
      final kept = previous?.vaccines.where((l) => l.childId == childId && l.vaccineId == id).firstOrNull;
      if (kept != null) {
        lines.add(kept);
        continue;
      }
      final v = vaccines[id];
      if (v == null) continue;
      lines.add(VaccineLine(childId: childId, vaccineId: id, name: v.name, amount: v.price, shown: v.showPrice));
    }
  }
  final total = (visitAmount ?? 0) + lines.where((l) => l.shown).fold<int>(0, (s, l) => s + l.amount);
  return PriceSnapshot(
    visitAmount: visitAmount,
    visitCovered: covered,
    vaccines: lines,
    total: total,
    hasHiddenPrices: lines.any((l) => !l.shown),
    packageId: packageId,
  );
}
