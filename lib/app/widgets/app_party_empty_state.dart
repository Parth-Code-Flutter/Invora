import 'package:flutter/material.dart' hide Text;
import 'package:flutter_svg/flutter_svg.dart';
import '../localization/localized_text.dart';
import '../constants/app_colors.dart';
import '../themes/app_text_styles.dart';
import 'app_button.dart';

/// Responsive composition of the exported Parties empty-state designs.
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
                    'assets/illustrations/empty_${supplier ? 'suppliers' : 'customers'}_figma.png',
                    width: compact ? 170 : 270,
                    height: compact ? 170 : 270,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                  SizedBox(height: compact ? 16 : 24),
                  Text(
                    supplier ? 'No suppliers yet' : 'No customers yet',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.sectionTitle.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.5,
                      color: dark
                          ? AppColors.darkTextPrimary
                          : const Color(0xFF1C1917),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    supplier
                        ? 'Keep wholesale purchases and supplier bills in one tap.'
                        : 'Fast GST billing starts with your first customer.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      height: 1.6,
                      color: dark
                          ? AppColors.darkTextSecondary
                          : const Color(0xFF78716C),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    label: supplier ? 'Add supplier' : 'Add customer',
                    onPressed: onAdd,
                    radius: 16,
                    leading: SvgPicture.asset(
                      'assets/icons/party_add.svg',
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
