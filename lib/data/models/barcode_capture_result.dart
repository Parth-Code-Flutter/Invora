import 'product_service_model.dart';

/// One barcode from the camera, plus a catalog match when one exists.
class BarcodeCaptureResult {
  const BarcodeCaptureResult({required this.code, this.product});

  final String code;
  final ProductServiceModel? product;

  bool get foundInCatalog => product != null;
}
