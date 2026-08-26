import 'package:flutter/material.dart';

import '../utils/responsive_utils.dart';
import 'app_main_navigation.dart';
import 'app_purchase_navigation.dart';

/// Phone: existing bottom navigation. Tablet: side [NavigationRail].
/// Nested/detail screens omit destinations and keep a normal scaffold.
class AppShell extends StatelessWidget {
  const AppShell({
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.salesDestination,
    this.purchaseDestination,
    super.key,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final MainDestination? salesDestination;
  final PurchaseDestination? purchaseDestination;

  bool get _hasNav => salesDestination != null || purchaseDestination != null;

  @override
  Widget build(BuildContext context) {
    final tablet = ResponsiveUtils.isTablet(context) && _hasNav;
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: tablet
          ? null
          : salesDestination != null
          ? AppMainNavigation(current: salesDestination!)
          : purchaseDestination != null
          ? AppPurchaseNavigation(current: purchaseDestination!)
          : null,
      body: tablet
          ? Row(
              children: [
                if (salesDestination != null)
                  AppSalesNavigationRail(current: salesDestination!)
                else if (purchaseDestination != null)
                  AppPurchaseNavigationRail(current: purchaseDestination!),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
    );
  }
}
