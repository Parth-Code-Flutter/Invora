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

  test('compact shop amounts use k, lakh, crore, or a plain rupee count', () {
    expect(CurrencyUtils.compactShopParts(9900), ('99', null));
    expect(CurrencyUtils.compactShopParts(100000), ('1k', null));
    expect(CurrencyUtils.compactShopParts(450000), ('4.5k', null));
    expect(CurrencyUtils.compactShopParts(40000000), ('4', 'lakh'));
    expect(CurrencyUtils.compactShopParts(1000000000), ('1', 'crore'));
    expect(CurrencyUtils.compactShopLabel(6500000), '65k');
    expect(CurrencyUtils.compactShopLabel(40000000), '4 lakh');
    expect(CurrencyUtils.compactShopDisplay(0), '0');
    expect(CurrencyUtils.compactShopDisplay(549000), '5.5k');
    expect(CurrencyUtils.compactShopDisplay(19000000), '1.9 lakh');
    expect(
      CurrencyUtils.compactShopDisplay(40000000, localize: (key) => 'लाख'),
      '4 लाख',
    );
  });

  test('provides current common Indian GST rate presets', () {
    expect(TaxUtils.gstRateBasisPoints, [0, 25, 300, 500, 1200, 1800, 2800]);
  });
}
