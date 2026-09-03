class AccountCountry {
  const AccountCountry({
    required this.iso,
    required this.name,
    required this.dialCode,
    required this.flag,
    this.minLength = 6,
    this.maxLength = 15,
    this.indianLeadingDigit = false,
  });

  final String iso;
  final String name;
  final String dialCode;
  final String flag;
  final int minLength;
  final int maxLength;
  final bool indianLeadingDigit;

  String get e164Prefix => '+$dialCode';

  String get pickerLabel => '$flag  $name  +$dialCode';

  @override
  bool operator ==(Object other) => other is AccountCountry && other.iso == iso;

  @override
  int get hashCode => iso.hashCode;

  static const india = AccountCountry(
    iso: 'IN',
    name: 'India',
    dialCode: '91',
    flag: '🇮🇳',
    minLength: 10,
    maxLength: 10,
    indianLeadingDigit: true,
  );

  static const List<AccountCountry> all = [
    india,
    AccountCountry(
      iso: 'AE',
      name: 'United Arab Emirates',
      dialCode: '971',
      flag: '🇦🇪',
    ),
    AccountCountry(iso: 'AU', name: 'Australia', dialCode: '61', flag: '🇦🇺'),
    AccountCountry(
      iso: 'BD',
      name: 'Bangladesh',
      dialCode: '880',
      flag: '🇧🇩',
    ),
    AccountCountry(iso: 'BH', name: 'Bahrain', dialCode: '973', flag: '🇧🇭'),
    AccountCountry(
      iso: 'CA',
      name: 'Canada',
      dialCode: '1',
      flag: '🇨🇦',
      minLength: 10,
      maxLength: 10,
    ),
    AccountCountry(iso: 'DE', name: 'Germany', dialCode: '49', flag: '🇩🇪'),
    AccountCountry(
      iso: 'GB',
      name: 'United Kingdom',
      dialCode: '44',
      flag: '🇬🇧',
    ),
    AccountCountry(iso: 'KE', name: 'Kenya', dialCode: '254', flag: '🇰🇪'),
    AccountCountry(iso: 'KW', name: 'Kuwait', dialCode: '965', flag: '🇰🇼'),
    AccountCountry(iso: 'LK', name: 'Sri Lanka', dialCode: '94', flag: '🇱🇰'),
    AccountCountry(iso: 'MY', name: 'Malaysia', dialCode: '60', flag: '🇲🇾'),
    AccountCountry(iso: 'NG', name: 'Nigeria', dialCode: '234', flag: '🇳🇬'),
    AccountCountry(iso: 'NP', name: 'Nepal', dialCode: '977', flag: '🇳🇵'),
    AccountCountry(iso: 'OM', name: 'Oman', dialCode: '968', flag: '🇴🇲'),
    AccountCountry(iso: 'PK', name: 'Pakistan', dialCode: '92', flag: '🇵🇰'),
    AccountCountry(iso: 'QA', name: 'Qatar', dialCode: '974', flag: '🇶🇦'),
    AccountCountry(
      iso: 'SA',
      name: 'Saudi Arabia',
      dialCode: '966',
      flag: '🇸🇦',
    ),
    AccountCountry(
      iso: 'SG',
      name: 'Singapore',
      dialCode: '65',
      flag: '🇸🇬',
      minLength: 8,
      maxLength: 8,
    ),
    AccountCountry(
      iso: 'US',
      name: 'United States',
      dialCode: '1',
      flag: '🇺🇸',
      minLength: 10,
      maxLength: 10,
    ),
    AccountCountry(
      iso: 'ZA',
      name: 'South Africa',
      dialCode: '27',
      flag: '🇿🇦',
    ),
  ];

  static AccountCountry byIso(String iso) =>
      all.firstWhere((country) => country.iso == iso, orElse: () => india);
}

class DeviceAccountNumber {
  const DeviceAccountNumber({
    required this.national,
    required this.country,
    this.label = '',
  });

  final String national;
  final AccountCountry country;
  final String label;

  String get e164 => AccountPhone.toE164(national, country: country);

  String get e164Prefix => country.e164Prefix;

  String get displayNumber {
    if (country.iso == 'IN' && national.length == 10) {
      return '$e164Prefix ${national.substring(0, 5)} ${national.substring(5)}';
    }
    return '$e164Prefix $national';
  }

  String get displayName {
    final cleaned = label.trim();
    if (cleaned.isEmpty) return '';
    if (cleaned == 'This phone' || cleaned == 'SIM') return cleaned;
    if (RegExp(r'^[\d+\s-]+$').hasMatch(cleaned)) return '';
    if (cleaned == displayNumber || cleaned == national) return '';
    return cleaned;
  }
}

abstract final class AccountPhone {
  static const indiaPrefix = '+91';

  static String digitsOnly(String raw) => raw.replaceAll(RegExp(r'\D'), '');

  static String normalizeTenDigit(String raw) => digitsOnly(raw);

  static String nationalNumber(
    String raw, {
    AccountCountry country = AccountCountry.india,
  }) {
    var digits = digitsOnly(raw);
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }
    if (digits.startsWith(country.dialCode) &&
        digits.length > country.maxLength) {
      digits = digits.substring(country.dialCode.length);
    }
    if (country.iso == 'IN' && digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits;
  }

  static String toE164(
    String national, {
    AccountCountry country = AccountCountry.india,
  }) {
    final digits = nationalNumber(national, country: country);
    return '${country.e164Prefix}$digits';
  }

  static String toDocId(String e164) =>
      e164.startsWith('+') ? e164.substring(1) : e164;

  static String? validateNational(
    String? value, {
    AccountCountry country = AccountCountry.india,
  }) {
    final national = nationalNumber(value ?? '', country: country);
    if (national.isEmpty) return 'Mobile number is required.';
    if (country.indianLeadingDigit) {
      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(national)) {
        return 'Indian mobiles are 10 digits and start with 6, 7, 8 or 9.';
      }
      return null;
    }
    if (national.length < country.minLength ||
        national.length > country.maxLength) {
      return 'Enter a valid mobile number for this country.';
    }
    return null;
  }

  static DeviceAccountNumber? parseImported(
    String raw, {
    AccountCountry fallback = AccountCountry.india,
  }) {
    final digits = digitsOnly(raw);
    if (digits.isEmpty) return null;

    final ranked = [...AccountCountry.all]
      ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
    for (final country in ranked) {
      if (!digits.startsWith(country.dialCode)) continue;
      final national = digits.substring(country.dialCode.length);
      if (validateNational(national, country: country) == null) {
        return DeviceAccountNumber(national: national, country: country);
      }
    }

    final fallbackNational = nationalNumber(raw, country: fallback);
    if (validateNational(fallbackNational, country: fallback) == null) {
      return DeviceAccountNumber(national: fallbackNational, country: fallback);
    }
    return null;
  }
}
