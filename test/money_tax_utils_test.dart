import 'package:flutter_test/flutter_test.dart';
import 'package:creovo_invoice/app/utils/currency_utils.dart';
import 'package:creovo_invoice/app/utils/tax_utils.dart';

void main() {
  test('money conversion preserves exact minor units', () {
    expect(CurrencyUtils.parseMinor('120.50'), 12050);
    expect(CurrencyUtils.parseMinor('1,250.05'), 125005);
    expect(CurrencyUtils.parseMinor('10.999'), isNull);
    expect(CurrencyUtils.toInputValue(12050), '120.50');
    expect(CurrencyUtils.formatMinor(125005, symbol: '₹'), '₹1,250.05');
  });

  test('tax conversion uses integer basis points', () {
    expect(TaxUtils.parseBasisPoints('18'), 1800);
    expect(TaxUtils.parseBasisPoints('12.50'), 1250);
    expect(TaxUtils.parseBasisPoints('101'), isNull);
    expect(TaxUtils.formatBasisPoints(1250), '12.5%');
  });
}
