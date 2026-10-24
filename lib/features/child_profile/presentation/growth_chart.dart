import 'package:flutter/material.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/theme.dart';
import '../../../core/format/arabic_digits.dart';
import '../../../core/widgets/segmented.dart';
import '../data/measurements_repository.dart';
import '../domain/chart_scale.dart';
import '../domain/child_age.dart';
import '../domain/latest_measurements.dart';

/// "منحنى النمو": the child's own recorded values against age (FR-004, research R5). No reference
/// curves, ranges or colours that mean good or bad (D-37).
class GrowthChartCard extends StatefulWidget {
  const GrowthChartCard({super.key, required this.measurements, required this.birthDate, this.birthWeightKg});

  final List<Measurement> measurements;
  final String birthDate;
  final double? birthWeightKg;

  @override
  State<GrowthChartCard> createState() => _GrowthChartCardState();
}

class _GrowthChartCardState extends State<GrowthChartCard> {
  Metric _metric = Metric.weight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final label = switch (_metric) {
      Metric.weight => l10n.measureWeight,
      Metric.length => l10n.measureLength,
      Metric.head => l10n.measureHead,
    };
    final points = seriesOf(
      widget.measurements,
      _metric,
      birthDate: widget.birthDate,
      birthWeightKg: widget.birthWeightKg,
    );

    return Card(
      key: const Key('growth-chart'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.growthChart, style: text.titleMedium),
            const SizedBox(height: 2),
            Text(l10n.growthChartSubtitle(label), style: text.bodySmall?.copyWith(color: c.muted)),
            const SizedBox(height: 12),
            Segmented<Metric>(
              options: [
                (Metric.weight, l10n.measureWeight),
                (Metric.length, l10n.measureLength),
                (Metric.head, l10n.measureHead),
              ],
              value: _metric,
              onChanged: (m) => setState(() => _metric = m),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 190,
              child: points.isEmpty
                  ? Center(
                      child: Text(l10n.notRecordedYet, style: text.bodyMedium?.copyWith(color: c.muted)),
                    )
                  : CustomPaint(
                      key: ValueKey('chart-${_metric.name}-${points.length}'),
                      size: Size.infinite,
                      painter: _ChartPainter(
                        points: [for (final p in points) (x: ageInMonthsExact(widget.birthDate, p.date), y: p.value)],
                        line: c.blue,
                        fill: c.blueSoft,
                        grid: c.border,
                        labels: c.muted,
                        surface: c.surface,
                        textDirection: Directionality.of(context),
                        xLabel: (months) => months == 0
                            ? l10n.chartBirth
                            : months % 12 == 0
                            ? l10n.ageYears(months ~/ 12, arabicDigits(months ~/ 12))
                            : l10n.ageMonths(months, arabicDigits(months)),
                        yLabel: (v) => v == v.roundToDouble() ? arabicDigits(v.toInt()) : arabicDecimal(v),
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: c.greenSoft, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: c.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.doctorReviewsMeasurements, style: text.bodySmall)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.points,
    required this.line,
    required this.fill,
    required this.grid,
    required this.labels,
    required this.surface,
    required this.textDirection,
    required this.xLabel,
    required this.yLabel,
  });

  final List<({double x, double y})> points;
  final Color line;
  final Color fill;
  final Color grid;
  final Color labels;
  final Color surface;
  final TextDirection textDirection;
  final String Function(int months) xLabel;
  final String Function(double value) yLabel;

  static const _labelStyle = TextStyle(fontSize: 11);

  TextPainter _text(String s) => TextPainter(
    text: TextSpan(
      text: s,
      style: _labelStyle.copyWith(color: labels),
    ),
    textDirection: textDirection,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final ys = points.map((p) => p.y);
    final yScale = AxisScale.of(ys.reduce((a, b) => a < b ? a : b), ys.reduce((a, b) => a > b ? a : b));
    final maxX = points.map((p) => p.x).reduce((a, b) => a > b ? a : b);
    final xScale = AxisScale.of(0, maxX < 1 ? 1 : maxX, targetTicks: 3);

    // Age runs right to left in RTL, like the design (birth on the right).
    final rtl = textDirection == TextDirection.rtl;
    final yLabelWidth = yScale.ticks.map((t) => _text(yLabel(t)).width).reduce((a, b) => a > b ? a : b) + 6;
    const bottom = 22.0;
    final plot = Rect.fromLTRB(rtl ? 4 : yLabelWidth, 6, size.width - (rtl ? yLabelWidth : 4), size.height - bottom);

    double px(double x) {
      final f = xScale.fraction(x).clamp(0.0, 1.0);
      return rtl ? plot.right - f * plot.width : plot.left + f * plot.width;
    }

    double py(double y) => plot.bottom - yScale.fraction(y) * plot.height;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final t in yScale.ticks) {
      final y = py(t);
      for (var x = plot.left; x < plot.right; x += 8) {
        canvas.drawLine(Offset(x, y), Offset((x + 4).clamp(plot.left, plot.right), y), gridPaint);
      }
      final tp = _text(yLabel(t));
      tp.paint(canvas, Offset(rtl ? plot.right + 6 : plot.left - tp.width - 6, y - tp.height / 2));
    }
    for (final t in xScale.ticks) {
      final tp = _text(xLabel(t.round()));
      final x = px(t).clamp(plot.left + tp.width / 2, plot.right - tp.width / 2);
      tp.paint(canvas, Offset(x - tp.width / 2, plot.bottom + 6));
    }

    final offsets = [for (final p in points) Offset(px(p.x), py(p.y))];
    if (offsets.length > 1) {
      final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
      for (final o in offsets.skip(1)) {
        path.lineTo(o.dx, o.dy);
      }
      final area = Path.from(path)
        ..lineTo(offsets.last.dx, plot.bottom)
        ..lineTo(offsets.first.dx, plot.bottom)
        ..close();
      canvas.drawPath(area, Paint()..color = fill.withValues(alpha: 0.7));
      canvas.drawPath(
        path,
        Paint()
          ..color = line
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }
    for (final (i, o) in offsets.indexed) {
      final last = i == offsets.length - 1;
      canvas.drawCircle(o, last ? 7 : 4, Paint()..color = last ? surface : line);
      if (last) {
        canvas.drawCircle(
          o,
          7,
          Paint()
            ..color = line
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.points != points || old.line != line || old.textDirection != textDirection;
}
