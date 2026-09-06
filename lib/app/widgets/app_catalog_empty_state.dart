import 'package:flutter/material.dart' hide Text;
import 'package:flutter_svg/flutter_svg.dart';

import '../localization/localized_text.dart';
import '../constants/app_colors.dart';
import '../enums/item_type.dart';
import '../themes/app_text_styles.dart';
import 'app_button.dart';

enum CatalogEmptyKind { all, products, services }

/// Figma empty states for Products & services · All / Products / Services.
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 500;
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    _asset,
                    width: compact ? 170 : 256,
                    height: compact ? 170 : 256,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                  SizedBox(height: compact ? 16 : 24),
                  Text(
                    _title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.sectionTitle.copyWith(
                      fontSize: 22,
                      height: 33 / 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.55,
                      color: dark
                          ? AppColors.darkTextPrimary
                          : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      height: 19.5 / 13,
                      letterSpacing: -0.325,
                      fontWeight: FontWeight.w400,
                      color: dark
                          ? AppColors.darkTextSecondary
                          : const Color(0xFF715E58),
                    ),
                  ),
                  SizedBox(height: compact ? 24 : 32),
                  AppButton(
                    label: _actionLabel,
                    onPressed: onAdd,
                    radius: 16,
                    leading: SvgPicture.asset(
                      'assets/icons/catalog/add.svg',
                      width: 20,
                      height: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
