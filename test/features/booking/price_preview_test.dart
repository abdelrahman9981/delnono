import 'package:delnono/features/booking/data/vaccines_repository.dart';
import 'package:delnono/features/booking/domain/price_preview.dart';
import 'package:flutter_test/flutter_test.dart';

// Same cases as functions/test/lib/bookingPricing.test.ts.
void main() {
  const vaccines = {
    'v1': Vaccine(id: 'v1', name: 'أ', price: 150, showPrice: true),
    'v2': Vaccine(id: 'v2', name: 'ب', price: 200, showPrice: true),
    'v3': Vaccine(id: 'v3', name: 'ج', price: 450, showPrice: false),
  };

  PriceSnapshot price(VisitType t, Map<String, List<String>> byChild, {String? pkg, PriceSnapshot? prev, int visit = 300}) =>
      previewPrice(visitType: t, vaccinesByChild: byChild, visitPrice: visit, vaccines: vaccines, packageId: pkg, previous: prev);

  test('one visit price for siblings', () {
    expect(price(VisitType.visit, {'a': [], 'b': []}).total, 300);
  });

  test('vaccines per child are added', () {
    expect(price(VisitType.visit, {'a': ['v1'], 'b': ['v1', 'v2']}).total, 800);
  });

  test('vaccine only has no visit price', () {
    final p = price(VisitType.vaccineOnly, {'a': ['v2']});
    expect(p.visitAmount, isNull);
    expect(p.total, 200);
  });

  test('hidden prices are left out of the shown total', () {
    final p = price(VisitType.visit, {'a': ['v3']});
    expect(p.total, 300);
    expect(p.hasHiddenPrices, isTrue);
  });

  test('a package covers the visit, not vaccines', () {
    final p = price(VisitType.visit, {'a': ['v1']}, pkg: 'pk');
    expect(p.visitCovered, isTrue);
    expect(p.total, 150);
  });

  test('a change keeps fixed amounts', () {
    final before = price(VisitType.visit, {'a': ['v1']});
    final after = price(VisitType.visit, {'a': ['v1', 'v2']}, prev: before, visit: 400);
    expect(after.visitAmount, 300);
    expect(after.total, 300 + 150 + 200);
  });
}
