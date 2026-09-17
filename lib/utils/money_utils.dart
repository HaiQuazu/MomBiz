enum MoneyCurrency {
  khr,
  usd;

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

  String get label {
    switch (this) {
      case MoneyCurrency.khr:
        return 'KHR';
      case MoneyCurrency.usd:
        return 'USD';
    }
  }

  static MoneyCurrency fromCode(String? value) {
    switch (value?.toUpperCase()) {
      case 'USD':
        return MoneyCurrency.usd;

      case 'KHR':
      default:
        return MoneyCurrency.khr;
    }
  }
}

class MoneyUtils {
  MoneyUtils._();

  static int? parse(String input, MoneyCurrency currency) {
    final cleaned = input
        .trim()
        .replaceAll(',', '')
        .replaceAll('៛', '')
        .replaceAll('\$', '');

    if (cleaned.isEmpty) {
      return null;
    }

    switch (currency) {
      case MoneyCurrency.khr:
        final value = num.tryParse(cleaned);

        if (value == null) {
          return null;
        }

        return value.round();

      case MoneyCurrency.usd:
        final value = double.tryParse(cleaned);

        if (value == null) {
          return null;
        }

        return (value * 100).round();
    }
  }

  static String format(int amountMinor, MoneyCurrency currency) {
    switch (currency) {
      case MoneyCurrency.khr:
        return '${_withCommas(amountMinor)}៛';

      case MoneyCurrency.usd:
        final negative = amountMinor < 0;

        final absolute = amountMinor.abs();

        final dollars = absolute ~/ 100;

        final cents = absolute % 100;

        final formatted =
            '\$${_withCommas(dollars)}.'
            '${cents.toString().padLeft(2, '0')}';

        return negative ? '-$formatted' : formatted;
    }
  }

  static String _withCommas(int value) {
    final negative = value < 0;

    final text = value.abs().toString();

    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(text[i]);
    }

    return negative ? '-$buffer' : buffer.toString();
  }
}

class MoneyCurrencyX {
  MoneyCurrencyX._();

  static MoneyCurrency fromCode(String? value) {
    return MoneyCurrency.fromCode(value);
  }
}
