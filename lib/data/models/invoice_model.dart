import '../../app/enums/discount_type.dart';
import '../../app/enums/invoice_status.dart';
import '../../app/enums/tax_type.dart';
import 'customer_model.dart';
import 'invoice_calculation_models.dart';

enum InvoiceListFilter { all, draft, unpaid, paid, overdue }

enum InvoiceSort { newest, oldest, highestAmount, lowestAmount }

class InvoiceSummaryModel {
  const InvoiceSummaryModel({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    this.companyName,
    required this.invoiceDate,
    this.dueDate,
    required this.status,
    required this.grandTotalMinor,
    required this.balanceMinor,
  });

  final int id;
  final String invoiceNumber;
  final String customerName;
  final String? companyName;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final InvoiceStatus status;
  final int grandTotalMinor;
  final int balanceMinor;

  InvoiceStatus effectiveStatus(DateTime now) {
    final canBecomeOverdue =
        status == InvoiceStatus.unpaid || status == InvoiceStatus.partiallyPaid;
    if (canBecomeOverdue &&
        dueDate != null &&
        dueDate!.isBefore(_dateOnly(now))) {
      return InvoiceStatus.overdue;
    }
    return status;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

class CustomerSnapshotModel {
  const CustomerSnapshotModel({
    this.customerId,
    required this.name,
    this.companyName,
    this.mobile,
    this.email,
    this.address,
    this.city,
    this.state,
    this.pinCode,
    this.gstin,
  });

  factory CustomerSnapshotModel.fromCustomer(CustomerModel customer) =>
      CustomerSnapshotModel(
        customerId: customer.id,
        name: customer.name,
        companyName: customer.companyName,
        mobile: customer.mobile,
        email: customer.email,
        address: customer.address,
        city: customer.city,
        state: customer.state,
        pinCode: customer.pinCode,
        gstin: customer.gstin,
      );

  final int? customerId;
  final String name;
  final String? companyName;
  final String? mobile;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pinCode;
  final String? gstin;
}

class InvoiceItemModel {
  const InvoiceItemModel({
    required this.localId,
    this.id,
    this.productId,
    required this.name,
    this.description,
    required this.quantityScaled,
    required this.unit,
    required this.rateMinor,
    this.hsnSac,
    this.taxRateBasisPoints = 0,
    this.discount = const DiscountInput.none(),
  });

  final String localId;
  final int? id;
  final int? productId;
  final String name;
  final String? description;
  final int quantityScaled;
  final String unit;
  final int rateMinor;
  final String? hsnSac;
  final int taxRateBasisPoints;
  final DiscountInput discount;
}

class InvoiceChargeModel {
  const InvoiceChargeModel({required this.title, required this.amountMinor});
  final String title;
  final int amountMinor;
}

class InvoiceModel {
  const InvoiceModel({
    this.id,
    required this.invoiceNumber,
    required this.customer,
    required this.invoiceDate,
    this.dueDate,
    required this.status,
    required this.taxType,
    required this.invoiceDiscount,
    required this.items,
    required this.charges,
    required this.calculation,
    this.notes,
    this.terms,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String invoiceNumber;
  final CustomerSnapshotModel customer;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final InvoiceStatus status;
  final TaxType taxType;
  final DiscountInput invoiceDiscount;
  final List<InvoiceItemModel> items;
  final List<InvoiceChargeModel> charges;
  final InvoiceCalculationResult calculation;
  final String? notes;
  final String? terms;
  final DateTime createdAt;
  final DateTime updatedAt;
}

int discountStorageValue(DiscountInput discount) =>
    discount.type == DiscountType.fixed
    ? discount.fixedMinor
    : discount.percentageBasisPoints;

DiscountInput discountFromStorage(DiscountType type, int value) =>
    switch (type) {
      DiscountType.none => const DiscountInput.none(),
      DiscountType.fixed => DiscountInput.fixed(value),
      DiscountType.percentage => DiscountInput.percentage(value),
    };
