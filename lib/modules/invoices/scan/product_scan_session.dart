import '../../../data/models/product_service_model.dart';
import '../../../data/models/scanned_invoice_line.dart';
import '../../../data/services/barcode_catalog_lookup.dart';

/// Result of applying one barcode to the current scan session.
enum ScanApplyResult { added, incremented, ignored }

/// In-memory cart for the live barcode scanner.
///
/// The camera stays open while this session accumulates unique products.
/// Repeat scans of the same SKU increase quantity instead of duplicating rows.
class ProductScanSession {
  ProductScanSession({this.cooldown = const Duration(milliseconds: 1400)});

  /// Ignore the same code when the camera keeps firing while held on a label.
  final Duration cooldown;

  final List<ScannedInvoiceLine> _lines = [];
  String? _lastCode;
  DateTime? _lastAcceptedAt;

  List<ScannedInvoiceLine> get lines => List.unmodifiable(_lines);

  int get uniqueItemCount => _lines.length;

  int get totalMinor =>
      _lines.fold(0, (sum, line) => sum + line.lineTotalMinor);

  ScanApplyResult applyProduct({
    required ProductServiceModel product,
    required String rawCode,
    DateTime? now,
  }) {
    final code = BarcodeCatalogLookup.normalize(rawCode);
    if (code.isEmpty) return ScanApplyResult.ignored;
    final clock = now ?? DateTime.now();
    if (_isCoolingDown(code, clock)) return ScanApplyResult.ignored;
    _lastCode = code;
    _lastAcceptedAt = clock;

    final existing = _lines.indexWhere(
      (line) =>
          (product.id != null && line.product.id == product.id) ||
          line.barcode == code,
    );
    if (existing >= 0) {
      _lines[existing] = _lines[existing].increment();
      return ScanApplyResult.incremented;
    }
    _lines.add(ScannedInvoiceLine(product: product, barcode: code));
    return ScanApplyResult.added;
  }

  void incrementAt(int index) {
    if (index < 0 || index >= _lines.length) return;
    _lines[index] = _lines[index].increment();
  }

  /// Returns true when the line was removed because quantity reached zero.
  bool decrementAt(int index) {
    if (index < 0 || index >= _lines.length) return false;
    if (_lines[index].quantityScaled <= 1000) {
      _lines.removeAt(index);
      return true;
    }
    _lines[index] = _lines[index].decrement();
    return false;
  }

  void removeAt(int index) {
    if (index < 0 || index >= _lines.length) return;
    _lines.removeAt(index);
  }

  bool _isCoolingDown(String code, DateTime now) {
    final last = _lastAcceptedAt;
    if (last == null || _lastCode != code) return false;
    return now.difference(last) < cooldown;
  }
}
