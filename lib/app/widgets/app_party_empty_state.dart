import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'app_empty_state.dart';

/// Customers and Suppliers first-empty screens.
class AppPartyEmptyState extends StatelessWidget {
  const AppPartyEmptyState({
    required this.supplier,
    required this.onAdd,
    super.key,
  });
  final bool supplier;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return AppEmptyGraphic(
      asset:
          'assets/illustrations/empty_${supplier ? 'suppliers' : 'customers'}_figma.png',
      title: supplier ? 'No suppliers yet' : 'No customers yet',
      subtitle: supplier
          ? 'Keep wholesale purchases and supplier bills in one tap.'
          : 'Fast GST billing starts with your first customer.',
      actionLabel: supplier ? 'Add supplier' : 'Add customer',
      onAction: onAdd,
      actionLeading: SvgPicture.asset(
        'assets/icons/party_add.svg',
        width: 20,
        height: 20,
      ),
    );
  }
}
