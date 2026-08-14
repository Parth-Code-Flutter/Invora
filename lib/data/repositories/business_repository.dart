import 'package:drift/drift.dart';

import '../models/business_profile_model.dart';
import '../services/app_database.dart';
import 'base_repository.dart';

class BusinessRepository extends BaseRepository {
  const BusinessRepository(super.database);

  Future<BusinessProfileModel?> getProfile() async {
    final row = await (database.select(
      database.businessProfiles,
    )..limit(1)).getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  Future<BusinessProfileModel> saveProfile(BusinessProfileModel model) async {
    final companion = BusinessProfilesCompanion(
      id: model.id == null ? const Value.absent() : Value(model.id!),
      businessName: Value(model.businessName),
      ownerName: Value(model.ownerName),
      logoPath: Value(model.logoPath),
      mobile: Value(model.mobile),
      email: Value(model.email),
      address: Value(model.address),
      city: Value(model.city),
      state: Value(model.state),
      pinCode: Value(model.pinCode),
      gstRegistered: Value(model.gstRegistered),
      gstin: Value(model.gstin),
      pan: Value(model.pan),
      invoicePrefix: Value(model.invoicePrefix),
      startingInvoiceNumber: Value(model.startingInvoiceNumber),
      currencyCode: Value(model.currencyCode),
      currencySymbol: Value(model.currencySymbol),
      bankName: Value(model.bankName),
      accountHolderName: Value(model.accountHolderName),
      accountNumber: Value(model.accountNumber),
      ifsc: Value(model.ifsc),
      upiId: Value(model.upiId),
      paymentQrPath: Value(model.paymentQrPath),
      signaturePath: Value(model.signaturePath),
      createdAt: Value(model.createdAt),
      updatedAt: Value(model.updatedAt),
    );
    final id = await database
        .into(database.businessProfiles)
        .insert(companion, mode: InsertMode.insertOrReplace);
    final saved = await (database.select(
      database.businessProfiles,
    )..where((table) => table.id.equals(model.id ?? id))).getSingle();
    return _toModel(saved);
  }

  Future<void> updateMediaPaths({
    required String? logoPath,
    required String? paymentQrPath,
    required String? signaturePath,
  }) => database
      .update(database.businessProfiles)
      .write(
        BusinessProfilesCompanion(
          logoPath: Value(logoPath),
          paymentQrPath: Value(paymentQrPath),
          signaturePath: Value(signaturePath),
        ),
      );

  BusinessProfileModel _toModel(BusinessProfile row) {
    return BusinessProfileModel(
      id: row.id,
      businessName: row.businessName,
      ownerName: row.ownerName,
      logoPath: row.logoPath,
      mobile: row.mobile,
      email: row.email,
      address: row.address,
      city: row.city,
      state: row.state,
      pinCode: row.pinCode,
      gstRegistered: row.gstRegistered,
      gstin: row.gstin,
      pan: row.pan,
      invoicePrefix: row.invoicePrefix,
      startingInvoiceNumber: row.startingInvoiceNumber,
      currencyCode: row.currencyCode,
      currencySymbol: row.currencySymbol,
      bankName: row.bankName,
      accountHolderName: row.accountHolderName,
      accountNumber: row.accountNumber,
      ifsc: row.ifsc,
      upiId: row.upiId,
      paymentQrPath: row.paymentQrPath,
      signaturePath: row.signaturePath,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
