import 'package:delnono/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('the ambulance 123 button is a deeper red in dark mode (#B3412F)', () {
    expect(AppColors.dark.emergency, const Color(0xFFB3412F));
  });

  for (final (name, c) in [('light', AppColors.light), ('dark', AppColors.dark)]) {
    test('white text on the emergency button is readable in $name mode (WCAG AA, 4.5:1)', () {
      expect(_contrast(c.emergency, Colors.white), greaterThanOrEqualTo(4.5));
    });
  }
}
