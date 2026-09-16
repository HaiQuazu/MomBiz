enum MoneyCurrency {
  khr,
  usd,
}

extension MoneyCurrencyX on MoneyCurrency {
  String get code {
    switch (this) {
      case MoneyCurrency.khr:
        return 'KHR';
      case MoneyCurrency.usd:
        return 'USD';
    }
  }

  String get symbol {
    switch (this) {
      case MoneyCurrency.khr:
        return '៛';
      case MoneyCurrency.usd:
        return '\$';
    }
  }

  static MoneyCurrency fromCode(String code) {
    switch (code) {
      case 'USD':
        return MoneyCurrency.usd;
      case 'KHR':
      default:
        return MoneyCurrency.khr;
    }
  }
}

class MoneyUtils {
  static int? parse(
    String input,
    MoneyCurrency currency,
  ) {
    final value = input
        .trim()
        .replaceAll(',', '')
        .replaceAll(' ', '');

    if (value.isEmpty) {
      return null;
    }

    if (currency == MoneyCurrency.khr) {
      if (!RegExp(r'^\d+$').hasMatch(value)) {
        return null;
      }

      return int.tryParse(value);
    }

    if (!RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(value)) {
      return null;
    }

    final parts = value.split('.');

    final dollars = int.tryParse(parts[0]) ?? 0;

    var cents = 0;

    if (parts.length == 2) {
      final decimal = parts[1].padRight(2, '0');
      cents = int.tryParse(decimal) ?? 0;
    }

    return (dollars * 100) + cents;
  }

  static String format(
    int amount,
    MoneyCurrency currency,
  ) {
    if (currency == MoneyCurrency.khr) {
      return '${_withCommas(amount)}៛';
    }

    final dollars = amount ~/ 100;
    final cents = amount % 100;

    return '\$${_withCommas(dollars)}.${cents.toString().padLeft(2, '0')}';
  }

  static String _withCommas(int value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(text[i]);
    }

    return buffer.toString();
  }
}
