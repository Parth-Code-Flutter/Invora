import 'package:flutter/material.dart' hide Text;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../data/services/entitlement_policy.dart';
import '../controllers/subscription_gate_controller.dart';

class SubscriptionGateScreen extends GetView<SubscriptionGateController> {
  const SubscriptionGateScreen({super.key});

  static const headerAsset = 'assets/images/subscription_plan_header_img.svg';
  static const splashAsset = 'assets/images/creovo_warm_splash.png';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pad = ResponsiveUtils.horizontalPadding(context);
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      body: SafeArea(
        child: Obx(() {
          final connect = controller.needsNetwork;
          final snapshot = controller.snapshot;
          return ListView(
            padding: EdgeInsets.fromLTRB(pad, 12, pad, 20),
            children: [
              if (connect) const _ConnectHero() else const _SubscribeHero(),
              const SizedBox(height: 14),
              _YearlyPlanCard(snapshot: snapshot, showOfferBadge: !connect),
              const SizedBox(height: 14),
              Text(
                connect ? 'Turn on internet' : 'Keep creating GST invoices',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.pageTitle.copyWith(
                  fontSize: 18,
                  height: 1.2,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                connect
                    ? 'Today is the last day of your trial. Connect once to confirm your Creovo Yearly plan.'
                    : 'Your trial ended. Data stays on this phone.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              if (snapshot?.trialEndsAt != null) ...[
                const SizedBox(height: 8),
                _StatusPill(connect: connect, endsAt: snapshot!.trialEndsAt!),
              ],
              const SizedBox(height: 12),
              const _TrustRow(),
              if (controller.errorMessage.value.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: controller.errorMessage.value),
              ],
              const SizedBox(height: 14),
              AppConstrainedAction(
                child: connect
                    ? AppButton(
                        label: 'Turn on internet & continue',
                        trailingIcon: Icons.wifi_rounded,
                        isLoading: controller.working.value,
                        onPressed: controller.working.value
                            ? null
                            : controller.retry,
                      )
                    : AppButton(
                        label: 'Subscribe to Creovo Yearly',
                        trailingIcon: Icons.arrow_forward_rounded,
                        isLoading: controller.working.value,
                        onPressed: controller.working.value
                            ? null
                            : controller.subscribe,
                      ),
              ),
              const SizedBox(height: 10),
              _FooterLinks(
                isDark: isDark,
                connect: connect,
                working: controller.working.value,
                onRefresh: controller.retry,
                onChangeNumber: controller.useDifferentNumber,
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _SubscribeHero extends StatelessWidget {
  const _SubscribeHero();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Creovo yearly plan',
      child: AspectRatio(
        aspectRatio: 390 / 320,
        child: SvgPicture.asset(
          SubscriptionGateScreen.headerAsset,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _ConnectHero extends StatelessWidget {
  const _ConnectHero();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.asset(
        SubscriptionGateScreen.splashAsset,
        height: 188,
        width: double.infinity,
        fit: BoxFit.cover,
        semanticLabel: 'Connect to check your plan',
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.connect, required this.endsAt});

  final bool connect;
  final DateTime endsAt;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.yMMMd().format(endsAt.toLocal());
    final label = connect
        ? '${l10n('Plan ends')} $date • ${l10n('Data 100% Safe')}'
        : '${l10n('Trial ended')} $date • ${l10n('Data 100% Safe')}';
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.warning,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _YearlyPlanCard extends StatelessWidget {
  const _YearlyPlanCard({required this.showOfferBadge, this.snapshot});

  final EntitlementSnapshot? snapshot;
  final bool showOfferBadge;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final price = snapshot?.offerPriceInr ?? 499;
    final listPrice = snapshot?.offerListPriceInr ?? 999;
    final monthly = snapshot?.offerMonthlyInr ?? 41;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16, showOfferBadge ? 22 : 16, 16, 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.primary, width: 1.6),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: isDark ? .16 : .1),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      snapshot?.displayTitle ?? 'Creovo Yearly',
                      style: AppTextStyles.sectionTitle.copyWith(fontSize: 15),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.secondary, width: 1),
                    ),
                    child: Text(
                      'Recommended',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'One plan for your entire business',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : const Color(0xFFF7F4F8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          '₹$price',
                          style: AppTextStyles.displayAmount.copyWith(
                            fontSize: 24,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '₹$listPrice',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Text(
                          '/ year',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '50% OFF',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n('Billed annually')} (${l10n('Just')} ₹$monthly / ${l10n('month')})',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              for (final feature in _features)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: feature.background,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          feature.icon,
                          size: 16,
                          color: feature.color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feature.title,
                              style: AppTextStyles.listName.copyWith(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              feature.subtitle,
                              style: AppTextStyles.caption.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                                height: 1.3,
                                fontWeight: FontWeight.w400,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (showOfferBadge)
          const Positioned(
            top: -12,
            left: 0,
            right: 0,
            child: Center(child: _SaveBadge()),
          ),
      ],
    );
  }
}

class _SaveBadge extends StatelessWidget {
  const _SaveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .28),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        'SAVE 50% TODAY',
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    return Row(
      children: [
        Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '100% Safe UPI & Cards',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
        Row(
          children: [
            for (var i = 0; i < 5; i++)
              const Icon(
                Icons.star_rounded,
                size: 12,
                color: Color(0xFFF5A524),
              ),
          ],
        ),
        const SizedBox(width: 6),
        Text(
          '4.9 / 5',
          style: AppTextStyles.caption.copyWith(
            color: muted,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _FooterLinks extends StatelessWidget {
  const _FooterLinks({
    required this.isDark,
    required this.connect,
    required this.working,
    required this.onRefresh,
    required this.onChangeNumber,
  });

  final bool isDark;
  final bool connect;
  final bool working;
  final VoidCallback onRefresh;
  final VoidCallback onChangeNumber;

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.darkTextSecondary : AppColors.textTertiary;
    return Column(
      children: [
        if (!connect)
          Text(
            'Instant activation • No hidden charges • Cancel anytime',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: muted,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        if (!connect) const SizedBox(height: 8),
        if (!connect)
          _CompactLink(
            onTap: working ? null : onRefresh,
            child: Text.rich(
              TextSpan(
                text: 'Already subscribed? ',
                style: AppTextStyles.caption.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: 'Refresh plan',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        _CompactLink(
          onTap: working ? null : onChangeNumber,
          child: Text(
            'Use a different phone number',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Terms of Service  •  Privacy Policy  •  Support',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(color: muted, fontSize: 10),
        ),
      ],
    );
  }
}

class _CompactLink extends StatelessWidget {
  const _CompactLink({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        child: child,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Text(
          message,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _PlanFeature {
  const _PlanFeature({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String subtitle;
}

const _features = [
  _PlanFeature(
    icon: Icons.receipt_long_rounded,
    color: AppColors.primary,
    background: AppColors.primaryLight,
    title: 'Unlimited GST invoices & PDFs',
    subtitle: 'Instant PDF download & WhatsApp 1-tap share.',
  ),
  _PlanFeature(
    icon: Icons.inventory_2_outlined,
    color: AppColors.secondary,
    background: AppColors.secondaryLight,
    title: 'Products, stock, customers & khata',
    subtitle: 'Low stock alerts and balances stay on this phone.',
  ),
  _PlanFeature(
    icon: Icons.lock_rounded,
    color: AppColors.success,
    background: AppColors.successLight,
    title: 'Works 100% offline — data stays on phone',
    subtitle: 'Zero internet required. Safe, private, and local.',
  ),
  _PlanFeature(
    icon: Icons.chat_bubble_outline_rounded,
    color: Color(0xFF2563EB),
    background: Color(0xFFDBEAFE),
    title: 'Payment reminders & WhatsApp share',
    subtitle: 'Share a prepared reminder to collect faster.',
  ),
];
