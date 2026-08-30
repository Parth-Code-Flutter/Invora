import 'package:flutter/material.dart';

import '../../app/routes/app_routes.dart';

enum MoreDestinationAction { salesWorkspace, purchasesWorkspace, openRoute }

class MoreDestination {
  const MoreDestination({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.action,
    this.route,
    this.keywords = const [],
    this.requiresStock = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final MoreDestinationAction action;
  final String? route;
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
    id: 'workspace',
    label: 'Change workspace',
    items: [
      MoreDestination(
        title: 'Sales',
        subtitle: 'Invoices, customers and money to receive',
        icon: Icons.trending_up_rounded,
        action: MoreDestinationAction.salesWorkspace,
        keywords: ['invoice', 'customer', 'receive', 'collect'],
      ),
      MoreDestination(
        title: 'Purchases',
        subtitle: 'Supplier bills and money to pay',
        icon: Icons.shopping_bag_outlined,
        action: MoreDestinationAction.purchasesWorkspace,
        keywords: ['supplier', 'bill', 'payable', 'pay'],
      ),
    ],
  ),
  MoreDestinationGroup(
    id: 'customization',
    label: 'Customization',
    items: [
      MoreDestination(
        title: 'Product settings',
        subtitle: 'Business category, fields and invoice display',
        icon: Icons.tune_rounded,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.productSettings,
        keywords: ['category', 'HSN', 'fields', 'attributes'],
      ),
      MoreDestination(
        title: 'Set default unit',
        subtitle: 'Manage units and choose the default for new items',
        icon: Icons.straighten_rounded,
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
        icon: Icons.inventory_2_outlined,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.products,
        keywords: ['catalog', 'item', 'price', 'HSN'],
      ),
      MoreDestination(
        title: 'Stock',
        subtitle: 'Movements and quantity adjustments',
        icon: Icons.warehouse_outlined,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.stock,
        keywords: ['inventory', 'warehouse', 'quantity', 'opening'],
        requiresStock: true,
      ),
      MoreDestination(
        title: 'Estimates',
        subtitle: 'Create and manage client quotations',
        icon: Icons.request_quote_outlined,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.quotations,
        keywords: ['quotation', 'quote', 'estimate'],
      ),
      MoreDestination(
        title: 'Delivery challans',
        subtitle: 'Dispatch goods, then convert remaining quantities',
        icon: Icons.local_shipping_outlined,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.deliveryChallans,
        keywords: ['DC', 'dispatch', 'e-way', 'challan'],
      ),
      MoreDestination(
        title: 'Purchase orders',
        subtitle:
            'Order from a supplier, receive goods, then bill remaining quantity',
        icon: Icons.assignment_outlined,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.purchaseOrders,
        keywords: ['PO', 'order', 'receive', 'supplier'],
      ),
      MoreDestination(
        title: 'Expenses',
        subtitle: 'Rent, fuel, salary and other cash spends',
        icon: Icons.payments_outlined,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.expenses,
        keywords: ['rent', 'fuel', 'salary', 'spend'],
      ),
      MoreDestination(
        title: 'Cash book',
        subtitle: 'Cash, bank, UPI, transfers and daily closing',
        icon: Icons.account_balance_wallet_outlined,
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
        icon: Icons.insert_chart_outlined_rounded,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.reports,
        keywords: ['sales', 'outstanding', 'receipts'],
      ),
      MoreDestination(
        title: 'Stock reports',
        subtitle: 'On-hand as of a date, and every posted movement',
        icon: Icons.inventory_2_outlined,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.stockReports,
        keywords: ['on-hand', 'movement', 'inventory'],
        requiresStock: true,
      ),
      MoreDestination(
        title: 'Ageing & reminders',
        subtitle: 'Buckets to collect or pay, then share a reminder',
        icon: Icons.hourglass_bottom_rounded,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.ageing,
        keywords: ['overdue', 'collect', 'reminder', 'ageing'],
      ),
      MoreDestination(
        title: 'Import data',
        subtitle: 'CSV templates for parties, items and unpaid bills',
        icon: Icons.file_upload_outlined,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.dataImport,
        keywords: ['CSV', 'Excel', 'upload', 'parties'],
      ),
      MoreDestination(
        title: 'GST / CA export',
        subtitle: 'Prepared registers for your accountant',
        icon: Icons.account_balance_outlined,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.gstExport,
        keywords: ['GSTR', 'tax', 'accountant', 'CA', 'GST'],
      ),
      MoreDestination(
        title: 'Backup & restore',
        subtitle: 'Export or restore your offline records',
        icon: Icons.settings_backup_restore_rounded,
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
        icon: Icons.settings_outlined,
        action: MoreDestinationAction.openRoute,
        route: AppRoutes.settings,
        keywords: ['PIN', 'fingerprint', 'dark', 'language', 'defaults'],
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
