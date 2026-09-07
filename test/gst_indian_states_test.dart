import 'package:creovo_invoice/data/services/account_phone.dart';
import 'package:creovo_invoice/data/services/gst_indian_states.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matches GST states by name, label, or code', () {
    expect(GstIndianStates.match('Gujarat')?.code, '24');
    expect(GstIndianStates.match('Gujarat (24)')?.name, 'Gujarat');
    expect(GstIndianStates.match('24')?.name, 'Gujarat');
    expect(GstIndianStates.match(''), isNull);
    expect(GstIndianStates.match('Atlantis'), isNull);
  });

  test('keeps stored E.164 mobiles parseable for the customer form', () {
    final parsed = AccountPhone.parseImported('+971501234567');
    expect(parsed?.country.iso, 'AE');
    expect(parsed?.national, '501234567');
    expect(
      AccountPhone.toE164('9876543210', country: AccountCountry.india),
      '+919876543210',
    );
  });
}
