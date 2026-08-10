abstract final class ValidationUtils {
  static final RegExp _indianMobilePattern = RegExp(r'^[6-9][0-9]{9}$');
  static final RegExp _emailPattern = RegExp(
    r'^[A-Za-z0-9.!#$%&\x27*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
  );

  static String? optionalIndianMobile(String? value) {
    final mobile = value?.trim() ?? '';
    if (mobile.isEmpty) return null;
    if (!_indianMobilePattern.hasMatch(mobile)) {
      return 'Enter a valid 10 digit mobile number.';
    }
    return null;
  }

  static String? optionalEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;
    if (email.length > 254 ||
        email.contains('..') ||
        !_emailPattern.hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }
}
