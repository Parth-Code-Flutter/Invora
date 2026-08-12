import '../../app/constants/app_storage_key_const.dart';
import '../../app/enums/tax_type.dart';
import '../../app/utils/tax_utils.dart';
import 'app_storage.dart';

class InvoiceDefaultsService {
  InvoiceDefaultsService(this._storage);

  final AppStorage _storage;

  int get dueDays => _storage.getInt(AppStorageKeyConst.defaultDueDays) ?? 0;

  TaxType get taxType {
    final stored = _storage.getString(AppStorageKeyConst.defaultTaxType);
    return TaxType.values.firstWhere(
      (value) => value.name == stored,
      orElse: () => TaxType.cgstSgst,
    );
  }

  int get gstRateBasisPoints {
    final stored =
        _storage.getInt(AppStorageKeyConst.defaultGstRateBasisPoints) ?? 1800;
    return TaxUtils.gstRateBasisPoints.contains(stored) ? stored : 1800;
  }

  String get notes =>
      _storage.getString(AppStorageKeyConst.defaultInvoiceNotes) ?? '';

  String get terms =>
      _storage.getString(AppStorageKeyConst.defaultInvoiceTerms) ?? '';

  String get paymentMethod =>
      _storage.getString(AppStorageKeyConst.defaultPaymentMethod) ?? 'UPI';

  Future<void> save({
    required int dueDays,
    required TaxType taxType,
    required int gstRateBasisPoints,
    required String notes,
    required String terms,
    required String paymentMethod,
  }) async {
    await Future.wait([
      _storage.setInt(AppStorageKeyConst.defaultDueDays, dueDays),
      _storage.setString(AppStorageKeyConst.defaultTaxType, taxType.name),
      _storage.setInt(
        AppStorageKeyConst.defaultGstRateBasisPoints,
        gstRateBasisPoints,
      ),
      _storage.setString(AppStorageKeyConst.defaultInvoiceNotes, notes.trim()),
      _storage.setString(AppStorageKeyConst.defaultInvoiceTerms, terms.trim()),
      _storage.setString(
        AppStorageKeyConst.defaultPaymentMethod,
        paymentMethod,
      ),
    ]);
  }
}
