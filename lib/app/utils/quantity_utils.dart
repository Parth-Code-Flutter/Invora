abstract final class QuantityUtils {
  static const scale = 1000;

  static int? parseScaled(String input) {
    final normalized = input.trim();
    if (!RegExp(r'^\d+(\.\d{0,3})?$').hasMatch(normalized)) return null;
    final parts = normalized.split('.');
    final whole = int.parse(parts.first);
    final fraction = parts.length == 1 ? '000' : parts.last.padRight(3, '0');
    return (whole * scale) + int.parse(fraction);
  }

  static String toInputValue(int scaled) {
    final whole = scaled ~/ scale;
    final fraction = (scaled % scale).abs().toString().padLeft(3, '0');
    if (fraction == '000') return whole.toString();
    return '$whole.${fraction.replaceFirst(RegExp(r'0+$'), '')}';
  }

  static String formatSigned(int scaled) {
    if (scaled < 0) return '-${toInputValue(-scaled)}';
    return toInputValue(scaled);
  }

  static int? parseSignedScaled(String input) {
    final normalized = input.trim();
    if (normalized.startsWith('-')) {
      final value = parseScaled(normalized.substring(1));
      return value == null ? null : -value;
    }
    return parseScaled(normalized);
  }
}
