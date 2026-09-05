import 'package:flutter/material.dart';

import '../utils/responsive_utils.dart';
import 'app_main_navigation.dart';

/// Phone: bottom dock. Tablet: side [NavigationRail].
/// Nested/detail screens omit [destination] and keep a normal scaffold.
class AppShell extends StatelessWidget {
  const AppShell({
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.destination,
    super.key,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final MainDestination? destination;

  @override
  Widget build(BuildContext context) {
    final tablet = ResponsiveUtils.isTablet(context) && destination != null;
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: tablet || destination == null
          ? null
          : Material(
              type: MaterialType.transparency,
              child: AppMainNavigation(current: destination!),
            ),
      body: tablet
          ? Row(
              children: [
                AppSalesNavigationRail(current: destination!),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
    );
  }
}
