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
