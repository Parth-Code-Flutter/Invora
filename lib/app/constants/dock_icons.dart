import 'package:flutter_svg/flutter_svg.dart';

abstract final class DockIcons {
  /// Warm both states before the first dock and before replacing a root route.
  /// SvgAssetLoader reuses the decoded cache synchronously on subsequent loads.
  static Future<void> preload() async {
    await Future.wait([
      for (final asset in [
        homeOutline,
        homeFilled,
        documentsOutline,
        documentsFilled,
        productsOutline,
        productsFilled,
        partiesOutline,
        partiesFilled,
        moreOutline,
        moreFilled,
      ])
        SvgAssetLoader(asset).loadBytes(null),
    ]);
  }

  static const homeOutline = 'assets/icons/dock/home_outline.svg';
  static const homeFilled = 'assets/icons/dock/home_filled.svg';
  static const documentsOutline = 'assets/icons/dock/documents_outline.svg';
  static const documentsFilled = 'assets/icons/dock/documents_filled.svg';
  static const productsOutline = 'assets/icons/dock/products_outline.svg';
  static const productsFilled = 'assets/icons/dock/products_filled.svg';
  static const partiesOutline = 'assets/icons/dock/parties_outline.svg';
  static const partiesFilled = 'assets/icons/dock/parties_filled.svg';
  static const moreOutline = 'assets/icons/dock/more_outline.svg';
  static const moreFilled = 'assets/icons/dock/more_filled.svg';
}
