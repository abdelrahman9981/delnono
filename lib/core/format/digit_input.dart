import 'package:flutter/services.dart';

/// Turns Arabic-Indic digits typed on an Arabic keyboard into Western digits and drops everything
/// except digits and spaces. Keeps the caret at the end.
class WesternDigitsFormatter extends TextInputFormatter {
  const WesternDigitsFormatter({this.allowSpaces = false});

  final bool allowSpaces;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final out = StringBuffer();
    for (final rune in newValue.text.runes) {
      if (rune >= 0x30 && rune <= 0x39) {
        out.writeCharCode(rune);
      } else if (rune >= 0x0660 && rune <= 0x0669) {
        out.writeCharCode(0x30 + rune - 0x0660);
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        out.writeCharCode(0x30 + rune - 0x06F0);
      } else if (allowSpaces && rune == 0x20) {
        out.writeCharCode(rune);
      }
    }
    final text = out.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
