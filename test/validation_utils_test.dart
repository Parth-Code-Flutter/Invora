import 'package:creovo_invoice/app/utils/validation_utils.dart';
import 'package:creovo_invoice/modules/customers/controllers/customer_form_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes imported Indian mobile numbers', () {
    expect(
      CustomerFormController.normalizeIndianMobile('+91 98765 43210'),
      '9876543210',
    );
    expect(
      CustomerFormController.normalizeIndianMobile('09876543210'),
      '9876543210',
    );
    expect(CustomerFormController.normalizeIndianMobile('12345'), isEmpty);
  });

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

    test('requires a mobile number when used by customer forms', () {
      expect(ValidationUtils.requiredIndianMobile(null), isNotNull);
      expect(ValidationUtils.requiredIndianMobile(''), isNotNull);
      expect(ValidationUtils.requiredIndianMobile('9876543210'), isNull);
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
