import 'dart:math' as math;

/// Axis ticks for the growth chart: round steps (1, 2, 5 × 10ⁿ) covering [min]..[max] with about
/// [targetTicks] lines. Pure layout; it says nothing about the values (D-37).
class AxisScale {
  const AxisScale(this.min, this.max, this.step);

  factory AxisScale.of(double min, double max, {int targetTicks = 4}) {
    if (max < min) (min, max) = (max, min);
    if (max - min < 1e-9) {
      // One value: centre it with one step either side.
      final step = _niceStep(math.max(min.abs(), 1) / 2);
      final lo = (min / step).floor() * step - step;
      return AxisScale(math.max(0, lo), lo + 3 * step, step);
    }
    final step = _niceStep((max - min) / targetTicks);
    final lo = (min / step).floor() * step;
    final hi = (max / step).ceil() * step;
    return AxisScale(lo, hi == lo ? lo + step : hi, step);
  }

  final double min;
  final double max;
  final double step;

  List<double> get ticks => [for (var v = min; v <= max + step / 1000; v += step) double.parse(v.toStringAsFixed(6))];

  /// 0 at [min], 1 at [max].
  double fraction(double v) => (v - min) / (max - min);

  static double _niceStep(double raw) {
    final exp = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final f = raw / exp;
    final nice = f <= 1
        ? 1
        : f <= 2
        ? 2
        : f <= 5
        ? 5
        : 10;
    return nice * exp;
  }
}
