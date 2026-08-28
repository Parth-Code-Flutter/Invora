abstract final class ImportValueParsers {
  static final gstinPattern = RegExp(r'^[0-9A-Z]{15}$');
  static final hsnPattern = RegExp(r'^\d{4,8}$');

  static String normalizeHeader(String raw) => raw
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static String? blankToNull(String? raw) {
    final value = raw?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  static String? parseGstin(String? raw) {
    final value = blankToNull(raw)?.toUpperCase();
    if (value == null) return null;
    return gstinPattern.hasMatch(value) ? value : null;
  }

  static bool hasInvalidGstin(String? raw) {
    final value = blankToNull(raw)?.toUpperCase();
    if (value == null) return false;
    return !gstinPattern.hasMatch(value);
  }

  static bool hasOddHsn(String? raw) {
    final value = blankToNull(raw);
    if (value == null) return false;
    return !hsnPattern.hasMatch(value);
  }

  static DateTime? parseDate(String? raw) {
    final value = blankToNull(raw);
    if (value == null) return null;
    final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(value);
    if (iso != null) {
      return _date(
        int.parse(iso.group(1)!),
        int.parse(iso.group(2)!),
        int.parse(iso.group(3)!),
      );
    }
    final dmy = RegExp(
      r'^(\d{1,2})[/-](\d{1,2})[/-](\d{2}|\d{4})$',
    ).firstMatch(value);
    if (dmy != null) {
      var year = int.parse(dmy.group(3)!);
      if (year < 100) year += year >= 70 ? 1900 : 2000;
      return _date(year, int.parse(dmy.group(2)!), int.parse(dmy.group(1)!));
    }
    return null;
  }

  static int? parseMoneyMinor(String? raw) {
    var value = (raw ?? '').trim().replaceAll('₹', '').replaceAll('Rs.', '');
    value = value.replaceAll(RegExp(r'[\s()]'), '');
    if (value.isEmpty) return null;
    if (value.contains('.') && value.contains(',')) {
      value = value.replaceAll(',', '');
    } else if (value.contains(',') && !value.contains('.')) {
      final parts = value.split(',');
      value = parts.length == 2 && parts.last.length <= 2
          ? '${parts.first}.${parts.last}'
          : parts.join();
    }
    final amount = double.tryParse(value);
    if (amount == null || amount < 0) return null;
    return (amount * 100).round();
  }

  static int? parseGstBasisPoints(String? raw) {
    var value = (raw ?? '').trim().replaceAll('%', '');
    if (value.isEmpty) return 0;
    final amount = double.tryParse(value.replaceAll(',', ''));
    if (amount == null || amount < 0 || amount > 100) return null;
    return (amount * 100).round();
  }

  static int? parseQuantityScaled(String? raw) {
    final value = blankToNull(raw) ?? '1';
    if (!RegExp(r'^\d+(\.\d{0,3})?$').hasMatch(value)) return null;
    final parts = value.split('.');
    final whole = int.parse(parts.first);
    final fraction = parts.length == 1 ? '000' : parts.last.padRight(3, '0');
    final scaled = (whole * 1000) + int.parse(fraction);
    return scaled <= 0 ? null : scaled;
  }

  static DateTime? _date(int year, int month, int day) {
    final value = DateTime(year, month, day);
    if (value.year != year || value.month != month || value.day != day) {
      return null;
    }
    return value;
  }
}
