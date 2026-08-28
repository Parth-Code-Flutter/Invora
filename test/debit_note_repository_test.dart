import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/data/models/business_profile_model.dart';
import 'package:creovo_invoice/data/models/debit_note_model.dart';
import 'package:creovo_invoice/data/models/purchase_models.dart';
import 'package:creovo_invoice/data/repositories/debit_note_repository.dart';
import 'package:creovo_invoice/data/repositories/purchase_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/debit_note_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late PurchaseRepository purchases;
  late DebitNoteRepository debitNotes;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    purchases = PurchaseRepository(database);
    debitNotes = DebitNoteRepository(database, purchases);
  });

  tearDown(() => database.close());

  test('issues a line return without rewriting the original bill', () async {
    final bill = await _savedBill(purchases, totalMinor: 10000);
    final note = await debitNotes.issue(
      bill: bill,
      debitNoteDate: DateTime(2026, 8, 27),
      reason: 'Damaged goods',
      returnedItems: [
        DebitNoteItemDraft(
          purchaseItem: bill.items.single,
          originalQuantityScaled: 1000,
          returnedQuantityScaled: 500,
          alreadyReturnedScaled: 0,
        ),
      ],
      remainder: DebitNoteRemainderAction.applyThenKeep,
    );

    expect(note.debitNoteNumber, 'DN-0001');
    expect(note.grandTotalMinor, 5000);
    expect(note.appliedMinor, 5000);
    expect(note.items.single.purchaseItemId, bill.items.single.id);

    final refreshed = await purchases.getBill(bill.id!);
    expect(refreshed!.totalMinor, 10000);
    expect(refreshed.debitedAmountMinor, 5000);
    expect(refreshed.balanceMinor, 5000);
    expect(refreshed.status, 'partially_paid');
  });

  test('rejects an over-return', () async {
    final bill = await _savedBill(purchases, totalMinor: 10000);
    await expectLater(
      debitNotes.issue(
        bill: bill,
        debitNoteDate: DateTime(2026, 8, 27),
        reason: 'Too much',
        returnedItems: [
          DebitNoteItemDraft(
            purchaseItem: bill.items.single,
            originalQuantityScaled: 1000,
            returnedQuantityScaled: 2000,
            alreadyReturnedScaled: 0,
          ),
        ],
        remainder: DebitNoteRemainderAction.applyThenKeep,
      ),
      throwsArgumentError,
    );
    final refreshed = await purchases.getBill(bill.id!);
    expect(refreshed!.debitedAmountMinor, 0);
    expect(refreshed.totalMinor, 10000);
  });

  test('records a refund on a paid purchase bill', () async {
    final bill = await _savedBill(purchases, totalMinor: 10000);
    await purchases.recordPayment(bill.id!, 10000, method: 'UPI');
    final paid = await purchases.getBill(bill.id!);
    final note = await debitNotes.issue(
      bill: paid!,
      debitNoteDate: DateTime(2026, 8, 27),
      reason: 'Returned after payment',
      returnedItems: [
        DebitNoteItemDraft(
          purchaseItem: paid.items.single,
          originalQuantityScaled: 1000,
          returnedQuantityScaled: 1000,
          alreadyReturnedScaled: 0,
        ),
      ],
      remainder: DebitNoteRemainderAction.applyThenRefund,
      refundMethod: 'UPI',
    );

    expect(note.appliedMinor, 0);
    expect(note.refundedMinor, 10000);
    expect(note.unappliedMinor, 0);
    final refreshed = await purchases.getBill(bill.id!);
    expect(refreshed!.balanceMinor, 0);
    expect(refreshed.debitedAmountMinor, 0);

    final statement = await purchases.supplierStatement(bill.supplierId!);
    expect(statement.any((entry) => entry.type == 'debit_note'), isTrue);
    expect(statement.any((entry) => entry.type == 'refund'), isTrue);
  });

  test('keeps leftover credit and applies it to another bill', () async {
    final source = await _savedBill(
      purchases,
      totalMinor: 10000,
      number: 'PB-DN-SRC',
    );
    await purchases.recordPayment(source.id!, 10000, method: 'UPI');
    final paidSource = await purchases.getBill(source.id!);
    final target = await _savedBill(
      purchases,
      totalMinor: 5000,
      number: 'PB-DN-DST',
      supplierId: source.supplierId,
      supplierName: source.supplierName,
    );
    final note = await debitNotes.issue(
      bill: paidSource!,
      debitNoteDate: DateTime(2026, 8, 27),
      reason: 'Paid in full then returned',
      returnedItems: [
        DebitNoteItemDraft(
          purchaseItem: paidSource.items.single,
          originalQuantityScaled: 1000,
          returnedQuantityScaled: 1000,
          alreadyReturnedScaled: 0,
        ),
      ],
      remainder: DebitNoteRemainderAction.applyThenKeep,
    );

    expect(note.appliedMinor, 0);
    expect(note.unappliedMinor, 10000);

    await debitNotes.applyUnapplied(
      debitNoteId: note.id!,
      billId: target.id!,
      amountMinor: 5000,
    );

    final applied = await debitNotes.getById(note.id!);
    expect(applied!.appliedMinor, 5000);
    expect(applied.unappliedMinor, 5000);

    final refreshedTarget = await purchases.getBill(target.id!);
    expect(refreshedTarget!.debitedAmountMinor, 5000);
    expect(refreshedTarget.balanceMinor, 0);
    expect(refreshedTarget.status, 'paid');

    final refreshedSource = await purchases.getBill(source.id!);
    expect(refreshedSource!.totalMinor, 10000);
    expect(refreshedSource.debitedAmountMinor, 0);
  });

  test('blocks edit, cancel and delete after a debit note is issued', () async {
    final bill = await _savedBill(
      purchases,
      totalMinor: 8000,
      number: 'PB-LOCK',
    );
    await debitNotes.issue(
      bill: bill,
      debitNoteDate: DateTime(2026, 8, 27),
      reason: 'Quality issue',
      returnedItems: [
        DebitNoteItemDraft(
          purchaseItem: bill.items.single,
          originalQuantityScaled: 1000,
          returnedQuantityScaled: 1000,
          alreadyReturnedScaled: 0,
        ),
      ],
      remainder: DebitNoteRemainderAction.applyThenKeep,
    );

    await expectLater(
      purchases.cancelBill(bill.id!, reason: 'No longer needed'),
      throwsStateError,
    );
    await expectLater(purchases.deleteBill(bill.id!), throwsStateError);
    await expectLater(purchases.saveBill(bill), throwsStateError);
    expect(await purchases.getBill(bill.id!), isNotNull);
  });

  test('renders a debit note PDF', () async {
    final bill = await _savedBill(purchases, totalMinor: 73600);
    final note = await debitNotes.issue(
      bill: bill,
      debitNoteDate: DateTime(2026, 8, 27),
      reason: 'Short quantity',
      returnedItems: [
        DebitNoteItemDraft(
          purchaseItem: bill.items.single,
          originalQuantityScaled: 1000,
          returnedQuantityScaled: 1000,
          alreadyReturnedScaled: 0,
        ),
      ],
      remainder: DebitNoteRemainderAction.applyThenKeep,
    );
    final bytes = await const DebitNotePdfService().build(
      note: note,
      business: BusinessProfileModel(
        businessName: 'Creovo QA',
        currencySymbol: '₹',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    expect(bytes, isNotEmpty);
  });

  test('clamps a return date that is earlier than the bill date', () {
    expect(
      DebitNoteDate.clamp(
        billDate: DateTime(2026, 9, 14, 10),
        proposed: DateTime(2026, 8, 27),
        now: DateTime(2026, 8, 27),
      ),
      DateTime(2026, 9, 14),
    );
  });
}

Future<PurchaseBillModel> _savedBill(
  PurchaseRepository purchases, {
  required int totalMinor,
  String? number,
  int? supplierId,
  String? supplierName,
}) async {
  final now = DateTime(2026, 8, 15);
  var id = supplierId;
  var name = supplierName ?? 'Paper Vendor';
  if (id == null) {
    final supplier = await purchases.saveSupplier(
      SupplierModel(name: name, createdAt: now, updatedAt: now),
    );
    id = supplier.id;
    name = supplier.name;
  }
  final billId = await purchases.saveBill(
    PurchaseBillModel(
      billNumber: number ?? 'PB-DN-$totalMinor',
      supplierId: id,
      supplierName: name,
      billDate: now,
      items: [
        PurchaseItemModel(
          name: 'Paper',
          quantity: 1,
          unit: 'box',
          rateMinor: totalMinor,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    ),
  );
  return (await purchases.getBill(billId))!;
}
