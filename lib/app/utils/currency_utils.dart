abstract final class CurrencyUtils {
  static int? parseMinor(String input) {
    final normalized = input.replaceAll(',', '').trim();
    if (!RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(normalized)) return null;
    final parts = normalized.split('.');
    final whole = int.parse(parts.first);
    final fraction = parts.length == 1 ? '00' : parts.last.padRight(2, '0');
    return (whole * 100) + int.parse(fraction);
  }

  static String toInputValue(int minor) {
    final whole = minor ~/ 100;
    final fraction = (minor % 100).abs().toString().padLeft(2, '0');
    return '$whole.$fraction';
  }

  static String compactMinor(int minor, {required String symbol}) {
    final rupees = minor / 100;
    final sign = rupees < 0 ? '-' : '';
    final abs = rupees.abs();
    if (abs >= 10000000) {
      return '$sign$symbol${_oneDecimal(abs / 10000000)}Cr';
    }
    if (abs >= 100000) {
      return '$sign$symbol${_oneDecimal(abs / 100000)}L';
    }
    if (abs >= 1000) {
      return '$sign$symbol${_oneDecimal(abs / 1000)}k';
    }
    return formatMinor(minor, symbol: symbol);
  }

  /// Short shop-style amount without a rupee sign: `99`, `1k`, `4.5k`,
  /// `4 lakh`, `1 crore`. [scale] is a localizable `lakh` / `crore` key.
  static (String amount, String? scale) compactShopParts(int minor) {
    final rupees = minor / 100;
    final sign = rupees < 0 ? '-' : '';
    final abs = rupees.abs();
    if (abs >= 10000000) {
      return ('$sign${_oneDecimal(abs / 10000000)}', 'crore');
    }
    if (abs >= 100000) {
      return ('$sign${_oneDecimal(abs / 100000)}', 'lakh');
    }
    if (abs >= 1000) {
      return ('$sign${_oneDecimal(abs / 1000)}k', null);
    }
    return ('$sign${abs.round()}', null);
  }

  static String compactShopLabel(int minor) {
    final parts = compactShopParts(minor);
    return parts.$2 == null ? parts.$1 : '${parts.$1} ${parts.$2}';
  }

  static String _oneDecimal(double value) {
    final rounded = value >= 10
        ? value.roundToDouble()
        : (value * 10).round() / 10;
    if (rounded == rounded.roundToDouble()) return '${rounded.round()}';
    return rounded.toStringAsFixed(1);
  }

  static String formatMinor(int minor, {required String symbol}) {
    final whole = minor ~/ 100;
    final fraction = (minor % 100).abs();
    final grouped = _groupThousands(whole.abs().toString());
    final sign = minor < 0 ? '-' : '';
    return fraction == 0
        ? '$sign$symbol$grouped'
        : '$sign$symbol$grouped.${fraction.toString().padLeft(2, '0')}';
  }

  static String _groupThousands(String digits) {
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      final remaining = digits.length - index;
      buffer.write(digits[index]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }
}
