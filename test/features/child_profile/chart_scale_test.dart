import 'package:delnono/features/child_profile/domain/chart_scale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round steps covering the range', () {
    final s = AxisScale.of(4.3, 9.4);
    expect(s.step, 2);
    expect(s.ticks, [4, 6, 8, 10]);
    expect(s.min <= 4.3 && s.max >= 9.4, isTrue);
  });

  test('larger values', () {
    final s = AxisScale.of(54, 98);
    expect(s.step, 20);
    expect(s.ticks, [40, 60, 80, 100]);
  });

  test('one value gets a range around it', () {
    final s = AxisScale.of(48, 48);
    expect(s.min < 48 && s.max > 48, isTrue);
    expect(s.fraction(48), inInclusiveRange(0.2, 0.8));
  });

  test('fraction maps the ends to 0 and 1', () {
    final s = AxisScale.of(0, 10);
    expect(s.fraction(s.min), 0);
    expect(s.fraction(s.max), 1);
  });
}
