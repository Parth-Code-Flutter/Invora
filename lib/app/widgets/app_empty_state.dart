import 'package:flutter/material.dart' hide Text;
import 'package:flutter_svg/flutter_svg.dart';

import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../themes/app_text_styles.dart';
import 'app_button.dart';

enum AppEmptyIllustration {
  invoice('assets/illustrations/empty_invoice.svg'),
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
    this.compact = false,
    super.key,
  });

  final AppEmptyIllustration illustration;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: compact ? 280 : 360),
        child: Padding(
          padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppEmptyArt(
                illustration: illustration,
                width: compact ? 128 : 176,
                height: compact ? 96 : 132,
                semanticLabel: title,
              ),
              SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: compact
                    ? AppTextStyles.listName
                    : AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: (compact ? AppTextStyles.small : AppTextStyles.body)
                    .copyWith(color: AppColors.textSecondary),
              ),
              if (actionLabel != null && onAction != null) ...[
                SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
                AppButton(label: actionLabel!, onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
