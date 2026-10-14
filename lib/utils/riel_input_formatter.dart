import 'package:flutter/services.dart';

/// Formats whole Cambodian riel amounts with thousands separators while typing.
///
/// Example: 100000 -> 100,000
/// Only digits are kept. The commas are visual; stored values remain integers.
class RielInputFormatter extends TextInputFormatter {
  const RielInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawText = newValue.text;

    if (rawText.isEmpty) {
      return const TextEditingValue();
    }

    final safeOffset =
        newValue.selection.baseOffset.clamp(0, rawText.length);
    final digitsBeforeCursor = rawText
        .substring(0, safeOffset)
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;

    final digits = rawText.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return const TextEditingValue();
    }

    final formatted = _withCommas(digits);
    final cursorOffset = _cursorAfterDigits(formatted, digitsBeforeCursor);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
  }

  static String _withCommas(String digits) {
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(digits[index]);
    }

    return buffer.toString();
  }

  static int _cursorAfterDigits(String formatted, int digitCount) {
    if (digitCount <= 0) {
      return 0;
    }

    var seen = 0;

    for (var index = 0; index < formatted.length; index++) {
      if (_isDigit(formatted.codeUnitAt(index))) {
        seen++;

        if (seen == digitCount) {
          return index + 1;
        }
      }
    }

    return formatted.length;
  }

  static bool _isDigit(int codeUnit) => codeUnit >= 48 && codeUnit <= 57;
}
