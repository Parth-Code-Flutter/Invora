import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../enums/item_type.dart';
import 'app_empty_state.dart';

enum CatalogEmptyKind { all, products, services }

/// Figma empty states for catalog All / Products / Services.
class AppCatalogEmptyState extends StatelessWidget {
  const AppCatalogEmptyState({
    required this.kind,
    required this.onAdd,
    super.key,
  });

  final CatalogEmptyKind kind;
  final VoidCallback onAdd;

  static CatalogEmptyKind forType(ItemType? type) => switch (type) {
    null => CatalogEmptyKind.all,
    ItemType.product => CatalogEmptyKind.products,
    ItemType.service => CatalogEmptyKind.services,
  };

  String get _asset => switch (kind) {
    CatalogEmptyKind.all => 'assets/illustrations/empty_catalog_all.png',
    CatalogEmptyKind.products =>
      'assets/illustrations/empty_catalog_products.png',
    CatalogEmptyKind.services =>
      'assets/illustrations/empty_catalog_services.png',
  };

  String get _title => switch (kind) {
    CatalogEmptyKind.all => 'No items yet',
    CatalogEmptyKind.products => 'No products yet',
    CatalogEmptyKind.services => 'No services yet',
  };

  String get _message => switch (kind) {
    CatalogEmptyKind.all => 'Add products or services to create instant bills.',
    CatalogEmptyKind.products =>
      'Add inventory items and prices to create instant bills.',
    CatalogEmptyKind.services =>
      'Add billable services and hourly rates to charge on bills.',
  };

  String get _actionLabel => switch (kind) {
    CatalogEmptyKind.all => 'Add product or service',
    CatalogEmptyKind.products => 'Add product',
    CatalogEmptyKind.services => 'Add service',
  };

  @override
  Widget build(BuildContext context) {
    return AppEmptyGraphic(
      asset: _asset,
      title: _title,
      subtitle: _message,
      actionLabel: _actionLabel,
      onAction: onAdd,
      actionLeading: SvgPicture.asset(
        'assets/icons/catalog/add.svg',
        width: 20,
        height: 20,
      ),
    );
  }
}
