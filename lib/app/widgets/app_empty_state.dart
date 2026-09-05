import 'package:flutter/material.dart' hide Text;
import 'package:flutter_svg/flutter_svg.dart';

import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../themes/app_text_styles.dart';
import 'app_button.dart';

enum AppEmptyIllustration {
  invoice('assets/illustrations/empty_invoice.svg'),
  salesInvoice('assets/illustrations/empty_sales_invoice.png'),
  purchaseBills('assets/illustrations/empty_purchase_bills.png'),
  search('assets/illustrations/empty_search.svg'),
  people('assets/illustrations/empty_people.svg'),
  package('assets/illustrations/empty_package.svg'),
  wallet('assets/illustrations/empty_wallet.svg'),
  clipboard('assets/illustrations/empty_clipboard.svg'),
  store('assets/illustrations/empty_store.svg'),
  parcel('assets/illustrations/empty_parcel.svg'),
  coins('assets/illustrations/empty_coins.svg'),
  subscribe('assets/illustrations/subscribe_plan.svg'),
  error('assets/illustrations/empty_error.svg');

  const AppEmptyIllustration(this.asset);
  final String asset;
}

class AppEmptyArt extends StatelessWidget {
  const AppEmptyArt({
    required this.illustration,
    this.width = 176,
    this.height = 132,
    this.semanticLabel,
    super.key,
  });

  final AppEmptyIllustration illustration;
  final double width;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (illustration.asset.endsWith('.png')) {
      return Image.asset(
        illustration.asset,
        width: width,
        height: height,
        fit: BoxFit.contain,
        semanticLabel: semanticLabel,
      );
    }
    return SvgPicture.asset(
      illustration.asset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      semanticsLabel: semanticLabel,
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.illustration,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionLeading,
    this.compact = false,
    super.key,
  });

  final AppEmptyIllustration illustration;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? actionLeading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final salesEmpty = illustration == AppEmptyIllustration.salesInvoice;
    final purchaseEmpty = illustration == AppEmptyIllustration.purchaseBills;
    return LayoutBuilder(
      builder: (context, constraints) {
        final short =
            constraints.hasBoundedHeight && constraints.maxHeight < 420;
        final smallArt = compact || short;
        return Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: compact ? 280 : 360),
              child: Padding(
                padding: EdgeInsets.all(
                  smallArt ? AppSpacing.md : AppSpacing.xl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppEmptyArt(
                      illustration: illustration,
                      width: smallArt
                          ? 128
                          : purchaseEmpty
                          ? 192
                          : salesEmpty
                          ? 192
                          : 176,
                      height: smallArt
                          ? 96
                          : purchaseEmpty
                          ? 192
                          : salesEmpty
                          ? 176
                          : 132,
                      semanticLabel: title,
                    ),
                    SizedBox(height: smallArt ? AppSpacing.sm : AppSpacing.lg),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: compact
                          ? AppTextStyles.listName
                          : AppTextStyles.sectionTitle.copyWith(
                              fontSize: 20,
                              height: purchaseEmpty ? 27.5 / 20 : 25 / 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: purchaseEmpty ? -0.5 : -0.4,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : const Color(0xFF111827),
                            ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style:
                          (compact ? AppTextStyles.small : AppTextStyles.body)
                              .copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : purchaseEmpty
                                    ? const Color(0xFF78716C)
                                    : salesEmpty
                                    ? const Color(0xFF6B7280)
                                    : AppColors.textSecondary,
                                fontSize: compact
                                    ? null
                                    : salesEmpty
                                    ? 12
                                    : 14,
                                height: compact
                                    ? null
                                    : salesEmpty
                                    ? 19.5 / 12
                                    : 22.75 / 14,
                                fontWeight: FontWeight.w400,
                              ),
                    ),
                    if (actionLabel != null && onAction != null) ...[
                      SizedBox(
                        height: smallArt ? AppSpacing.md : AppSpacing.xl,
                      ),
                      AppButton(
                        label: actionLabel!,
                        onPressed: onAction,
                        leading: actionLeading,
                        radius: compact ? null : 16,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
