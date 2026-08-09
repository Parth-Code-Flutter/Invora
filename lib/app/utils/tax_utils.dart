abstract final class TaxUtils {
  static int? parseBasisPoints(String input) {
    final value = double.tryParse(input.trim());
    if (value == null || value < 0 || value > 100) return null;
    return (value * 100).round();
  }

  static String toInputValue(int basisPoints) {
    final value = basisPoints / 100;
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  }

  static String formatBasisPoints(int basisPoints) =>
      '${toInputValue(basisPoints)}%';
}
