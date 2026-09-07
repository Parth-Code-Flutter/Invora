import 'package:flutter/material.dart' hide Text;
import 'package:flutter_svg/flutter_svg.dart';

import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../constants/app_colors.dart';
import '../themes/app_text_styles.dart';
import 'app_button.dart';

enum AppEmptyIllustration {
  invoice('assets/illustrations/empty_invoice.svg'),
  salesInvoice('assets/illustrations/empty_sales_invoice.png'),
  invoiceItems('assets/illustrations/empty_invoice_items.png'),
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

/// Shared empty-screen art at the app-wide 160px size.
class AppEmptyArt extends StatelessWidget {
  const AppEmptyArt({
    required this.illustration,
    this.width = AppEmptyGraphic.graphicSize,
    this.height = AppEmptyGraphic.graphicSize,
    this.semanticLabel,
    super.key,
  });

  final AppEmptyIllustration illustration;
  final double width;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final child = illustration.asset.endsWith('.png')
        ? Image.asset(
            illustration.asset,
            width: width,
            height: height,
            fit: BoxFit.contain,
            semanticLabel: semanticLabel,
          )
        : SvgPicture.asset(
            illustration.asset,
            width: width,
            height: height,
            fit: BoxFit.contain,
            semanticsLabel: semanticLabel,
          );
    return SizedBox(width: width, height: height, child: child);
  }
}

/// Common empty graphic: 160×160 art, 20px title, 13px subtitle, optional CTA.
class AppEmptyGraphic extends StatelessWidget {
  const AppEmptyGraphic({
    required this.title,
    required this.subtitle,
    this.illustration,
    this.asset,
    this.actionLabel,
    this.onAction,
    this.actionLeading,
    this.footer,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    this.semanticLabel,
    super.key,
  }) : assert(illustration != null || asset != null);

  static const graphicSize = 160.0;
  static const titleSize = 20.0;
  static const subtitleSize = 13.0;

  final String title;
  final String subtitle;
  final AppEmptyIllustration? illustration;
  final String? asset;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? actionLeading;
  final Widget? footer;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final graphic = illustration != null
        ? AppEmptyArt(
            illustration: illustration!,
            semanticLabel: semanticLabel ?? title,
          )
        : SizedBox(
            width: graphicSize,
            height: graphicSize,
            child: Image.asset(
              asset!,
              width: graphicSize,
              height: graphicSize,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
          );
    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 390),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            graphic,
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle.copyWith(
                fontSize: titleSize,
                height: 28 / titleSize,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : const Color(0xFF1C1917),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                fontSize: subtitleSize,
                height: 20 / subtitleSize,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.2,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : const Color(0xFF78716C),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                leading: actionLeading,
                radius: 16,
              ),
            ],
            if (footer != null) ...[const SizedBox(height: 20), footer!],
          ],
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedHeight) {
          return Center(child: content);
        }
        return Center(child: SingleChildScrollView(child: content));
      },
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
    this.footer,
    super.key,
  });

  final AppEmptyIllustration illustration;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? actionLeading;
  final bool compact;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return AppEmptyGraphic(
      illustration: illustration,
      title: title,
      subtitle: message,
      actionLabel: actionLabel,
      onAction: onAction,
      actionLeading: actionLeading,
      footer: footer,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 24,
        vertical: compact ? 12 : 24,
      ),
    );
  }
}
