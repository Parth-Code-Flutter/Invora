import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../utils/responsive_utils.dart';

class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    super.key,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxContentWidth,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.horizontalPadding(context),
            ),
            child: body,
          ),
        ),
      ),
    );
  }
}
