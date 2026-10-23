import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef BirthDatePicker = Future<DateTime?> Function(BuildContext context, {DateTime? initial});

/// Birth-date picker for the last 18 years (data-model.md). Opens on the year view, since birth
/// dates are often years back. A provider so tests can supply a date.
final birthDatePickerProvider = Provider<BirthDatePicker>((ref) => showBirthDatePicker);

Future<DateTime?> showBirthDatePicker(BuildContext context, {DateTime? initial}) {
  final today = DateUtils.dateOnly(DateTime.now());
  return showDatePicker(
    context: context,
    initialDate: initial ?? today,
    firstDate: DateTime(today.year - 18, today.month, today.day),
    lastDate: today,
    initialDatePickerMode: DatePickerMode.year,
  );
}
