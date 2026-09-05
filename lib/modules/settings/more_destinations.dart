import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/constants/app_colors.dart';
import '../../app/routes/app_routes.dart';

abstract final class MoreIcons {
  static const search = 'assets/icons/more/search.svg';
  static const chevron = 'assets/icons/more/chevron.svg';
  static const lock = 'assets/icons/more/lock.svg';
  static const productSettings = 'assets/icons/more/product_settings.svg';
  static const defaultUnit = 'assets/icons/more/default_unit.svg';
  static const products = 'assets/icons/more/products.svg';
  static const estimates = 'assets/icons/more/estimates.svg';
  static const deliveryChallans = 'assets/icons/more/delivery_challans.svg';
  static const purchaseOrders = 'assets/icons/more/purchase_orders.svg';
  static const expenses = 'assets/icons/more/expenses.svg';
  static const cashBook = 'assets/icons/more/cash_book.svg';
  static const reports = 'assets/icons/more/reports.svg';
  static const ageing = 'assets/icons/more/ageing.svg';
  static const importData = 'assets/icons/more/import_data.svg';
  static const gstExport = 'assets/icons/more/gst_export.svg';
  static const backup = 'assets/icons/more/backup.svg';
  static const appSettings = 'assets/icons/more/app_settings.svg';
  static const planBilling = 'assets/icons/more/plan_billing.svg';
}

abstract final class MoreWells {
  static const roseFill = Color(0xFFFFF1F2);
  static const roseBorder = Color(0xCCFFE4E6);
  static const emeraldFill = Color(0xFFECFDF5);
  static const emeraldBorder = Color(0xCCD1FAE5);
  static const orangeFill = Color(0xFFFFF7ED);
  static const orangeBorder = Color(0xCCFFEDD5);
  static const purpleFill = Color(0xFFFAF5FF);
  static const purpleBorder = Color(0xCCF3E8FF);
  static const amberFill = Color(0xFFFFFBEB);
  static const amberBorder = Color(0xCCFEF3C7);
  static const tealFill = Color(0xFFF0FDFA);
  static const tealBorder = Color(0xCCCCFBF1);
  static const fuchsiaFill = Color(0xFFFDF4FF);
  static const fuchsiaBorder = Color(0xCCFAE8FF);
}

enum MoreDestinationAction { openRoute }

class MoreDestination {
  const MoreDestination({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconAsset,
    required this.action,
    this.route,
    this.color = AppColors.secondary,
    this.iconWell = MoreWells.purpleFill,
    this.iconWellBorder = MoreWells.purpleBorder,
    this.keywords = const [],
    this.requiresStock = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String iconAsset;
  final MoreDestinationAction action;
  final String? route;
  final Color color;
  final Color iconWell;
  final Color iconWellBorder;
  final List<String> keywords;
  final bool requiresStock;
}

class MoreDestinationGroup {
  const MoreDestinationGroup({
    required this.id,
    required this.label,
    required this.items,
  });

  final String id;
  final String label;
  final List<MoreDestination> items;
}

const moreDestinationCatalog = <MoreDestinationGroup>[
  MoreDestinationGroup(
    id: 'customization',
    label: 'Customization',
    items: [
      MoreDestination(
        title: 'Product settings',
        subtitle: 'Business category, fields and invoice display',
        icon: Symbols.tune_rounded,
        iconAsset: MoreIcons.productSettings,
        color: Color(0xFFF43F5E),
        iconWell: MoreWells.roseFill,
        iconWellBorder: MoreWells.roseBorder,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.productSettings,
        keywords: ['category', 'HSN', 'fields', 'attributes'],
      ),
      MoreDestination(
        title: 'Set default unit',
        subtitle: 'Manage units and choose the default for new items',
        icon: Symbols.straighten_rounded,
        iconAsset: MoreIcons.defaultUnit,
        color: Color(0xFF059669),
        iconWell: MoreWells.emeraldFill,
        iconWellBorder: MoreWells.emeraldBorder,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.unitSettings,
        keywords: ['UOM', 'kg', 'pcs', 'units'],
      ),
    ],
  ),
  MoreDestinationGroup(
    id: 'create',
    label: 'Create & manage',
    items: [
      MoreDestination(
        title: 'Products & services',
        subtitle: 'Saved items, pricing and tax',
        icon: Symbols.package_2_rounded,
        iconAsset: MoreIcons.products,
        color: Color(0xFFEA580C),
        iconWell: MoreWells.orangeFill,
        iconWellBorder: MoreWells.orangeBorder,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.products,
        keywords: ['catalog', 'item', 'price', 'HSN'],
      ),
      MoreDestination(
        title: 'Stock',
        subtitle: 'Movements and quantity adjustments',
        icon: Symbols.warehouse_rounded,
        iconAsset: MoreIcons.products,
        color: Color(0xFF0D9488),
        iconWell: MoreWells.tealFill,
        iconWellBorder: MoreWells.tealBorder,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.stock,
        keywords: ['inventory', 'warehouse', 'quantity', 'opening'],
        requiresStock: true,
      ),
      MoreDestination(
        title: 'Estimates',
        subtitle: 'Create and manage client quotations',
        icon: Symbols.request_quote_rounded,
        iconAsset: MoreIcons.estimates,
        color: Color(0xFF9333EA),
        iconWell: MoreWells.purpleFill,
        iconWellBorder: MoreWells.purpleBorder,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.quotations,
        keywords: ['quotation', 'quote', 'estimate'],
      ),
      MoreDestination(
        title: 'Delivery challans',
        subtitle: 'Dispatch goods, then convert remaining quantities',
        icon: Symbols.local_shipping_rounded,
        iconAsset: MoreIcons.deliveryChallans,
        color: Color(0xFFD97706),
        iconWell: MoreWells.amberFill,
        iconWellBorder: MoreWells.amberBorder,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.deliveryChallans,
        keywords: ['DC', 'dispatch', 'e-way', 'challan'],
      ),
      MoreDestination(
        title: 'Purchase orders',
        subtitle:
            'Order from a supplier, receive goods, then bill remaining quantity',
        icon: Symbols.order_approve_rounded,
        iconAsset: MoreIcons.purchaseOrders,
        color: Color(0xFF0D9488),
        iconWell: MoreWells.tealFill,
        iconWellBorder: MoreWells.tealBorder,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.purchaseOrders,
        keywords: ['PO', 'order', 'receive', 'supplier'],
      ),
      MoreDestination(
        title: 'Expenses',
        subtitle: 'Rent, fuel, salary and other cash spends',
        icon: Symbols.payments_rounded,
        iconAsset: MoreIcons.expenses,
        color: Color(0xFFF43F5E),
        iconWell: MoreWells.roseFill,
        iconWellBorder: MoreWells.roseBorder,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.expenses,
        keywords: ['rent', 'fuel', 'salary', 'spend'],
      ),
      MoreDestination(
        title: 'Cash book',
        subtitle: 'Cash, bank, UPI, transfers and daily closing',
        icon: Symbols.account_balance_wallet_rounded,
        iconAsset: MoreIcons.cashBook,
        color: Color(0xFF059669),
        iconWell: MoreWells.emeraldFill,
        iconWellBorder: MoreWells.emeraldBorder,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.cashBook,
        keywords: ['bank', 'UPI', 'cheque', 'transfer', 'closing'],
      ),
    ],
  ),
  MoreDestinationGroup(
    id: 'insights',
    label: 'Insights & data',
    items: [
      MoreDestination(
        title: 'Reports',
        subtitle: 'Review sales, receipts and outstanding totals',
        icon: Symbols.monitoring_rounded,
        iconAsset: MoreIcons.reports,
        color: Color(0xFFC026D3),
        iconWell: MoreWells.fuchsiaFill,
        iconWellBorder: MoreWells.fuchsiaBorder,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.reports,
        keywords: ['sales', 'outstanding', 'receipts'],
      ),
      MoreDestination(
        title: 'Stock reports',
        subtitle: 'On-hand as of a date, and every posted movement',
        icon: Symbols.inventory_2_rounded,
        iconAsset: MoreIcons.reports,
        color: Color(0xFF059669),
        iconWell: MoreWells.emeraldFill,
        iconWellBorder: MoreWells.emeraldBorder,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.stockReports,
        keywords: ['on-hand', 'movement', 'inventory'],
        requiresStock: true,
      ),
      MoreDestination(
        title: 'Ageing & reminders',
        subtitle: 'Buckets to collect or pay, then share a reminder',
        icon: Symbols.hourglass_rounded,
        iconAsset: MoreIcons.ageing,
        color: Color(0xFFD97706),
        iconWell: MoreWells.amberFill,
        iconWellBorder: MoreWells.amberBorder,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.ageing,
        keywords: ['overdue', 'collect', 'reminder', 'ageing'],
      ),
      MoreDestination(
        title: 'Import data',
        subtitle: 'CSV templates for parties, items and unpaid bills',
        icon: Symbols.upload_file_rounded,
        iconAsset: MoreIcons.importData,
        color: Color(0xFF059669),
        iconWell: MoreWells.emeraldFill,
        iconWellBorder: MoreWells.emeraldBorder,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.dataImport,
        keywords: ['CSV', 'Excel', 'upload', 'parties'],
      ),
      MoreDestination(
        title: 'GST / CA export',
        subtitle: 'Prepared registers for your accountant',
        icon: Symbols.account_balance_rounded,
        iconAsset: MoreIcons.gstExport,
        color: Color(0xFF7C3AED),
        iconWell: MoreWells.purpleFill,
        iconWellBorder: MoreWells.purpleBorder,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.gstExport,
        keywords: ['GSTR', 'tax', 'accountant', 'CA', 'GST'],
      ),
      MoreDestination(
        title: 'Backup & restore',
        subtitle: 'Export or restore your offline records',
        icon: Symbols.cloud_sync_rounded,
        iconAsset: MoreIcons.backup,
        color: Color(0xFFEA580C),
        iconWell: MoreWells.orangeFill,
        iconWellBorder: MoreWells.orangeBorder,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.backup,
        keywords: [
          'ZIP',
          'export',
          'restore',
          'password',
          'erase',
          'reset',
          'wipe',
        ],
      ),
    ],
  ),
  MoreDestinationGroup(
    id: 'preferences',
    label: 'Preferences',
    items: [
      MoreDestination(
        title: 'App settings',
        subtitle: 'Invoice defaults, look, language and lock',
        icon: Symbols.settings_rounded,
        iconAsset: MoreIcons.appSettings,
        color: Color(0xFF7C3AED),
        iconWell: MoreWells.purpleFill,
        iconWellBorder: MoreWells.purpleBorder,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.settings,
        keywords: ['PIN', 'fingerprint', 'dark', 'language', 'defaults'],
      ),
      MoreDestination(
        title: 'Plan & billing',
        subtitle: 'Trial, Creovo Yearly, and account mobile',
        icon: Symbols.workspace_premium_rounded,
        iconAsset: MoreIcons.planBilling,
        color: Color(0xFFEA580C),
        iconWell: MoreWells.orangeFill,
        iconWellBorder: MoreWells.orangeBorder,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.plan,
        keywords: [
          'subscription',
          'trial',
          'yearly',
          'billing',
          'plan',
          'subscribe',
          'OTP',
        ],
      ),
    ],
  ),
];

bool moreDestinationMatches(
  MoreDestination item,
  String query, {
  String Function(String value)? translate,
}) {
  return _matchesAny(
    [item.title, item.subtitle, ...item.keywords],
    query,
    translate: translate,
  );
}

List<MoreDestinationGroup> filterMoreDestinations({
  required String query,
  required bool stockEnabled,
  List<MoreDestinationGroup> catalog = moreDestinationCatalog,
  String Function(String value)? translate,
}) {
  final trimmed = query.trim();
  return [
    for (final group in catalog)
      MoreDestinationGroup(
        id: group.id,
        label: group.label,
        items: [
          for (final item in group.items)
            if (!item.requiresStock || stockEnabled)
              if (trimmed.isEmpty ||
                  _matchesAny([group.label], trimmed, translate: translate) ||
                  moreDestinationMatches(item, trimmed, translate: translate))
                item,
        ],
      ),
  ].where((group) => group.items.isNotEmpty).toList();
}

bool _matchesAny(
  Iterable<String> values,
  String query, {
  String Function(String value)? translate,
}) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return true;
  final haystack = <String>[
    ...values,
    if (translate != null) ...values.map(translate),
  ];
  return haystack.any((value) => value.toLowerCase().contains(needle));
}
