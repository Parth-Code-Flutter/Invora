import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/app/enums/item_type.dart';
import 'package:creovo_invoice/data/models/business_profile_model.dart';
import 'package:creovo_invoice/data/models/product_service_model.dart';
import 'package:creovo_invoice/data/models/purchase_models.dart';
import 'package:creovo_invoice/data/services/purchase_bill_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const service = PurchaseBillPdfService();

  test('builds a purchase bill PDF from saved items', () async {
    final now = DateTime(2026, 8, 18);
    final catalog = ProductServiceModel(
      id: 12,
      name: 'Canvas roll',
      type: ItemType.product,
      unit: 'pcs',
      salePriceMinor: 50000,
      taxRateBasisPoints: 1800,
      createdAt: now,
      updatedAt: now,
    );
    final item = PurchaseItemModel.fromCatalog(catalog, quantity: 2);
    expect(item.productId, 12);
    expect(item.rateMinor, 50000);
    expect(item.taxRate, 18);

    final bill = PurchaseBillModel(
      billNumber: 'PB-972765',
      supplierId: 1,
      supplierName: 'Akshara Art Studio',
      billDate: now,
      items: [item],
      createdAt: now,
      updatedAt: now,
    );
    final bytes = await service.build(
      bill: bill,
      business: BusinessProfileModel(
        businessName: 'Creovo Creations',
        currencySymbol: '₹',
        createdAt: now,
        updatedAt: now,
      ),
    );
    expect(bytes, isNotEmpty);
    expect(service.fileName(bill), contains('PB-972765'));
  });

  test('refuses a PDF when business setup is incomplete', () async {
    final now = DateTime(2026, 8, 18);
    final bill = PurchaseBillModel(
      billNumber: 'PB-1',
      supplierId: 1,
      supplierName: 'Vendor',
      billDate: now,
      items: const [
        PurchaseItemModel(
          name: 'Paper',
          quantity: 1,
          unit: 'box',
          rateMinor: 10000,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );
    await expectLater(
      service.build(
        bill: bill,
        business: BusinessProfileModel(
          businessName: '  ',
          createdAt: now,
          updatedAt: now,
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}
