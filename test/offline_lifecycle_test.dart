import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/app/enums/invoice_status.dart';
import 'package:creovo_invoice/app/enums/item_type.dart';
import 'package:creovo_invoice/app/enums/tax_type.dart';
import 'package:creovo_invoice/data/models/business_profile_model.dart';
import 'package:creovo_invoice/data/models/customer_model.dart';
import 'package:creovo_invoice/data/models/invoice_calculation_models.dart';
import 'package:creovo_invoice/data/models/invoice_model.dart';
import 'package:creovo_invoice/data/models/product_service_model.dart';
import 'package:creovo_invoice/data/repositories/business_repository.dart';
import 'package:creovo_invoice/data/repositories/customer_repository.dart';
import 'package:creovo_invoice/data/repositories/invoice_repository.dart';
import 'package:creovo_invoice/data/repositories/product_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/backup_service.dart';
import 'package:creovo_invoice/data/services/invoice_calculation_service.dart';
import 'package:creovo_invoice/data/services/invoice_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('runs the complete offline GST invoicing lifecycle', () async {
    SharedPreferences.setMockInitialValues({});
    final directory = await Directory.systemTemp.createTemp(
      'creovo_lifecycle_',
    );
    final databaseFile = File('${directory.path}/creovo.sqlite');
    final database = AppDatabase.forTesting(NativeDatabase(databaseFile));
    addTearDown(() async {
      await database.close();
      await directory.delete(recursive: true);
    });

    final businessRepository = BusinessRepository(database);
    final customerRepository = CustomerRepository(database);
    final productRepository = ProductRepository(database);
    final invoiceRepository = InvoiceRepository(database);
    const calculator = InvoiceCalculationService();
    final now = DateTime(2026, 8, 12, 10, 30);

    final business = await businessRepository.saveProfile(
      BusinessProfileModel(
        businessName: 'Creovo QA Studio',
        ownerName: 'Parth Mandavia',
        mobile: '9876543210',
        email: 'billing@creovo.example',
        address: '12 Market Road',
        city: 'Surat',
        state: 'Gujarat',
        pinCode: '395003',
        gstRegistered: true,
        gstin: '24ABCDE1234F1Z5',
        pan: 'ABCDE1234F',
        invoicePrefix: 'INV',
        currencyCode: 'INR',
        currencySymbol: '₹',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final customer = await customerRepository.save(
      CustomerModel(
        name: 'Rinkal Ben',
        companyName: 'Rinkal Designs',
        mobile: '9876543211',
        email: 'rinkal@example.com',
        gstin: '24AACCR1234A1Z5',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final product = await productRepository.save(
      ProductServiceModel(
        name: 'MDF Circle 6mm',
        type: ItemType.product,
        description: 'Precision-cut MDF circle',
        unit: 'pcs',
        salePriceMinor: 21200,
        hsnSac: '4411',
        taxRateBasisPoints: 1800,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final item = InvoiceItemModel(
      localId: 'qa-item',
      productId: product.id,
      name: product.name,
      description: product.description,
      quantityScaled: 3000,
      unit: product.unit,
      rateMinor: product.salePriceMinor,
      hsnSac: product.hsnSac,
      taxRateBasisPoints: product.taxRateBasisPoints,
    );
    final calculation = calculator.calculate(
      InvoiceCalculationInput(
        items: [
          InvoiceCalculationItemInput(
            id: item.localId,
            quantityScaled: item.quantityScaled,
            rateMinor: item.rateMinor,
            taxRateBasisPoints: item.taxRateBasisPoints,
          ),
        ],
        additionalCharges: const [
          AdditionalChargeInput(title: 'Delivery', amountMinor: 5000),
        ],
        taxType: TaxType.cgstSgst,
        automaticRoundOff: true,
      ),
    );
    final invoice = await invoiceRepository.save(
      InvoiceModel(
        invoiceNumber: 'INV-QA-0001',
        customer: CustomerSnapshotModel.fromCustomer(customer),
        invoiceDate: now,
        dueDate: now.add(const Duration(days: 7)),
        status: InvoiceStatus.unpaid,
        taxType: TaxType.cgstSgst,
        invoiceDiscount: const DiscountInput.none(),
        items: [item],
        charges: const [
          InvoiceChargeModel(title: 'Delivery', amountMinor: 5000),
        ],
        calculation: calculation,
        notes: 'Thank you for your business.',
        createdAt: now,
        updatedAt: now,
      ),
    );
    expect(invoice.calculation.taxTotalMinor, greaterThan(0));
    expect(invoice.calculation.cgstMinor, invoice.calculation.sgstMinor);

    await invoiceRepository.recordPayment(
      invoiceId: invoice.id!,
      amountMinor: 10000,
      paidAt: now,
      method: 'UPI',
      reference: 'QA-PAY-1',
    );
    final partial = (await invoiceRepository.getById(invoice.id!))!;
    expect(partial.status, InvoiceStatus.partiallyPaid);
    final firstPayment = (await invoiceRepository.getPayments(
      invoice.id!,
    )).single;
    await invoiceRepository.reversePayment(
      invoiceId: invoice.id!,
      paymentId: firstPayment.id!,
      reason: 'QA reversal check',
      reversedAt: now.add(const Duration(minutes: 1)),
    );
    final reversed = (await invoiceRepository.getById(invoice.id!))!;
    expect(reversed.calculation.paidAmountMinor, 0);
    await invoiceRepository.recordPayment(
      invoiceId: invoice.id!,
      amountMinor: reversed.calculation.grandTotalMinor,
      paidAt: now.add(const Duration(minutes: 2)),
      method: 'Bank transfer',
    );
    expect(
      (await invoiceRepository.getById(invoice.id!))?.status,
      InvoiceStatus.paid,
    );

    final duplicate = await invoiceRepository.duplicate(
      id: invoice.id!,
      newInvoiceNumber: 'INV-QA-0002',
    );
    expect(duplicate.calculation.paidAmountMinor, 0);
    await invoiceRepository.cancel(duplicate.id!);
    expect(
      (await invoiceRepository.getById(duplicate.id!))?.status,
      InvoiceStatus.cancelled,
    );
    await invoiceRepository.delete(duplicate.id!);
    expect(await invoiceRepository.getById(duplicate.id!), isNull);

    final quotation = await invoiceRepository.save(
      InvoiceModel(
        documentType: DocumentType.quotation,
        invoiceNumber: 'QTN-QA-0001',
        customer: CustomerSnapshotModel.fromCustomer(customer),
        invoiceDate: now,
        status: InvoiceStatus.sent,
        taxType: TaxType.cgstSgst,
        invoiceDiscount: const DiscountInput.none(),
        items: [item],
        charges: const [],
        calculation: calculator.calculate(
          InvoiceCalculationInput(
            items: [
              InvoiceCalculationItemInput(
                id: item.localId,
                quantityScaled: item.quantityScaled,
                rateMinor: item.rateMinor,
                taxRateBasisPoints: item.taxRateBasisPoints,
              ),
            ],
            taxType: TaxType.cgstSgst,
            automaticRoundOff: true,
          ),
        ),
        createdAt: now,
        updatedAt: now,
      ),
    );
    final converted = await invoiceRepository.convertQuotationToInvoice(
      quotationId: quotation.id!,
      invoiceNumber: 'INV-QA-0003',
    );
    expect(converted.documentType, DocumentType.invoice);
    expect(
      (await invoiceRepository.getById(quotation.id!))?.status,
      InvoiceStatus.accepted,
    );

    final pdf = await const InvoicePdfService().build(
      invoice: converted,
      business: business,
      template: InvoiceTemplate.professional,
    );
    expect(pdf, isNotEmpty);

    final storage = await AppStorage.create();
    final backupService = BackupService(
      database,
      businessRepository,
      storage,
      databaseFileProvider: () async => databaseFile,
      outputDirectoryProvider: () async => directory,
    );
    final backup = await backupService.createBackup();
    expect(backup.path, endsWith('.zip'));
    expect((await backupService.validate(backup)).isValid, isTrue);
    expect(backupService.lastBackupAt, isNotNull);

    await customerRepository.softDelete(customer.id!);
    await productRepository.softDelete(product.id!);
    expect(
      (await invoiceRepository.getById(invoice.id!))?.customer.name,
      'Rinkal Ben',
    );
    expect(
      (await invoiceRepository.getById(invoice.id!))?.items.single.name,
      'MDF Circle 6mm',
    );
  });
}
