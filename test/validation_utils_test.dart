import 'package:creovo_invoice/app/utils/validation_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mobile validation', () {
    test('accepts an empty optional value and a valid Indian mobile', () {
      expect(ValidationUtils.optionalIndianMobile(''), isNull);
      expect(ValidationUtils.optionalIndianMobile('9876543210'), isNull);
    });

    test('rejects invalid length and invalid starting digits', () {
      expect(ValidationUtils.optionalIndianMobile('987654321'), isNotNull);
      expect(ValidationUtils.optionalIndianMobile('98765432100'), isNotNull);
      expect(ValidationUtils.optionalIndianMobile('5876543210'), isNotNull);
    });
  });

  group('email validation', () {
    test('accepts an empty optional value and a valid email', () {
      expect(ValidationUtils.optionalEmail(''), isNull);
      expect(ValidationUtils.optionalEmail('billing@example.com'), isNull);
    });

    test('rejects malformed email addresses', () {
      expect(ValidationUtils.optionalEmail('billing@'), isNotNull);
      expect(ValidationUtils.optionalEmail('billing@example'), isNotNull);
      expect(ValidationUtils.optionalEmail('bill..ing@example.com'), isNotNull);
      expect(ValidationUtils.optionalEmail('billing @example.com'), isNotNull);
    });
  });
}
