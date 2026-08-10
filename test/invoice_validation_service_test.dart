import 'package:creovo_invoice/app/enums/invoice_status.dart';
import 'package:creovo_invoice/app/enums/tax_type.dart';
import 'package:creovo_invoice/data/models/invoice_calculation_models.dart';
import 'package:creovo_invoice/data/models/invoice_model.dart';
import 'package:creovo_invoice/data/services/invoice_calculation_service.dart';
import 'package:creovo_invoice/data/services/invoice_validation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validator = InvoiceValidationService();

  test('accepts a complete customer-facing invoice', () {
    expect(validator.validateRequired(_invoice()), isNull);
  });

  test('rejects missing customer and items', () {
    expect(
      validator.validateRequired(_invoice(customerName: '')),
      contains('customer'),
    );
    expect(
      validator.validateRequired(_invoice(includeItem: false)),
      contains('product or service'),
    );
  });

  test('rejects invalid item rate and due date', () {
    expect(
      validator.validateRequired(_invoice(rateMinor: 0)),
      contains('rate'),
    );
    expect(
      validator.validateRequired(_invoice(dueDate: DateTime(2026, 8, 9))),
      contains('due date'),
    );
  });
}

InvoiceModel _invoice({
  String customerName = 'Aarav Shah',
  bool includeItem = true,
  int rateMinor = 10000,
  DateTime? dueDate,
}) {
  final items = includeItem
      ? [
          InvoiceItemModel(
            localId: 'item-1',
            name: 'Consulting',
            quantityScaled: 1000,
            unit: 'service',
            rateMinor: rateMinor,
          ),
        ]
      : <InvoiceItemModel>[];
  final calculation = const InvoiceCalculationService().calculate(
    InvoiceCalculationInput(
      items: includeItem
          ? [
              InvoiceCalculationItemInput(
                id: 'item-1',
                quantityScaled: 1000,
                rateMinor: rateMinor,
              ),
            ]
          : const [],
    ),
  );
  final date = DateTime(2026, 8, 10);
  return InvoiceModel(
    invoiceNumber: 'INV-0001',
    customer: CustomerSnapshotModel(name: customerName),
    invoiceDate: date,
    dueDate: dueDate,
    status: InvoiceStatus.unpaid,
    taxType: TaxType.none,
    invoiceDiscount: const DiscountInput.none(),
    items: items,
    charges: const [],
    calculation: calculation,
    createdAt: date,
    updatedAt: date,
  );
}
