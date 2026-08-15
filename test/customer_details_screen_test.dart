import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:creovo_invoice/app/enums/invoice_status.dart';
import 'package:creovo_invoice/app/enums/tax_type.dart';
import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/app/widgets/app_button.dart';
import 'package:creovo_invoice/app/widgets/app_invoice_summary_card.dart';
import 'package:creovo_invoice/data/models/business_profile_model.dart';
import 'package:creovo_invoice/data/models/customer_model.dart';
import 'package:creovo_invoice/data/models/invoice_calculation_models.dart';
import 'package:creovo_invoice/data/models/invoice_model.dart';
import 'package:creovo_invoice/data/repositories/business_repository.dart';
import 'package:creovo_invoice/data/repositories/customer_repository.dart';
import 'package:creovo_invoice/data/repositories/invoice_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/invoice_calculation_service.dart';
import 'package:creovo_invoice/modules/customers/controllers/customer_details_controller.dart';
import 'package:creovo_invoice/modules/customers/screens/customer_details_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  testWidgets(
    'customer workspace puts the name in the AppBar and does not repeat phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final now = DateTime(2026, 8, 15);
      await BusinessRepository(database).saveProfile(
        BusinessProfileModel(
          businessName: 'Creovo Billing',
          currencySymbol: '₹',
          createdAt: now,
          updatedAt: now,
        ),
      );
      final customer = await CustomerRepository(database).save(
        CustomerModel(
          name: 'Chetan Bhai Freelance',
          companyName: 'Northwind Trading',
          mobile: '9876543210',
          email: 'chetan@example.com',
          gstin: '24AAACC1206D1ZM',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await InvoiceRepository(
        database,
      ).save(_invoice(customer, 'INV-0008', now, 1060000));

      Get.put<CustomerDetailsController>(
        _TestCustomerDetailsController(
          CustomerRepository(database),
          InvoiceRepository(database),
          BusinessRepository(database),
          customer.id!,
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          home: const CustomerDetailsScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(find.text('Chetan Bhai Freelance'), findsOneWidget);
      expect(find.text('Customer details'), findsNothing);
      expect(find.text('CUSTOMER ACCOUNT'), findsNothing);
      expect(find.text('9876543210'), findsOneWidget);
      expect(find.textContaining('Northwind Trading'), findsOneWidget);
      expect(find.text('Collect outstanding'), findsOneWidget);
      expect(find.text('View customer statement'), findsNothing);
      expect(find.text('₹10,600'), findsWidgets);
      expect(find.byType(AppInvoiceSummaryCard), findsOneWidget);
      expect(find.text('Chetan Bhai Freelance'), findsOneWidget);
      expect(find.text('INV-0008'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('paid customer uses statement as the primary action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime(2026, 8, 15);
    await BusinessRepository(database).saveProfile(
      BusinessProfileModel(
        businessName: 'Creovo Billing',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final customer = await CustomerRepository(database).save(
      CustomerModel(
        name: 'Rinkal Ben',
        mobile: '9123456789',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await InvoiceRepository(database).save(
      _invoice(
        customer,
        'INV-0001',
        now,
        55000,
        status: InvoiceStatus.paid,
        paidMinor: 55000,
      ),
    );

    Get.put<CustomerDetailsController>(
      _TestCustomerDetailsController(
        CustomerRepository(database),
        InvoiceRepository(database),
        BusinessRepository(database),
        customer.id!,
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: const CustomerDetailsScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('Rinkal Ben'), findsOneWidget);
    expect(find.text('Paid in full'), findsOneWidget);
    expect(find.text('View customer statement'), findsOneWidget);
    expect(find.text('Collect outstanding'), findsNothing);
    expect(find.byType(AppButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty customer makes new invoice the primary action', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime(2026, 8, 15);
    final customer = await CustomerRepository(
      database,
    ).save(CustomerModel(name: 'New Client', createdAt: now, updatedAt: now));

    Get.put<CustomerDetailsController>(
      _TestCustomerDetailsController(
        CustomerRepository(database),
        InvoiceRepository(database),
        BusinessRepository(database),
        customer.id!,
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.dark, home: const CustomerDetailsScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('New Client'), findsOneWidget);
    expect(find.text('No invoices yet'), findsOneWidget);
    expect(find.text('New invoice'), findsOneWidget);
    expect(find.text('Collect outstanding'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _TestCustomerDetailsController extends CustomerDetailsController {
  _TestCustomerDetailsController(
    super.repository,
    super.invoices,
    super.business,
    this._id,
  );

  final int _id;

  @override
  int get customerId => _id;
}

InvoiceModel _invoice(
  CustomerModel customer,
  String number,
  DateTime date,
  int total, {
  InvoiceStatus status = InvoiceStatus.unpaid,
  int paidMinor = 0,
}) {
  const item = InvoiceItemModel(
    localId: 'item',
    name: 'Service',
    quantityScaled: 1000,
    unit: 'service',
    rateMinor: 10000,
  );
  final calculation = const InvoiceCalculationService().calculate(
    InvoiceCalculationInput(
      items: [
        InvoiceCalculationItemInput(
          id: 'item',
          quantityScaled: 1000,
          rateMinor: total,
        ),
      ],
      taxType: TaxType.none,
      paidAmountMinor: paidMinor,
    ),
  );
  return InvoiceModel(
    invoiceNumber: number,
    customer: CustomerSnapshotModel.fromCustomer(customer),
    invoiceDate: date,
    status: status,
    taxType: TaxType.none,
    invoiceDiscount: const DiscountInput.none(),
    items: [
      InvoiceItemModel(
        localId: item.localId,
        name: item.name,
        quantityScaled: item.quantityScaled,
        unit: item.unit,
        rateMinor: total,
      ),
    ],
    charges: const [],
    calculation: calculation,
    createdAt: date,
    updatedAt: date,
  );
}
