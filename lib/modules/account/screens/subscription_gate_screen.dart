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
          if (controller.stage.value != SubscriptionStage.offer) {
            return _PurchaseProgress(controller: controller);
          }
          final connect = controller.needsNetwork;
          final snapshot = controller.snapshot;
          return ListView(
            padding: EdgeInsets.fromLTRB(pad, 12, pad, 20),
            children: [
              if (connect) const _ConnectHero() else const _SubscribeHero(),
              const SizedBox(height: 10),
              Text(
                connect ? 'Turn on internet' : 'Keep creating GST invoices',
                textAlign: TextAlign.center,
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
              const SizedBox(height: 28),
              _YearlyPlanCard(
                snapshot: snapshot,
                showOfferBadge: false,
                yearlyPrice: controller.displayedYearlyPrice,
                storeCaption: controller.hasLiveStorePrice
                    ? 'Auto-renews yearly. Cancel in your store account settings.'
                    : 'Price available from the store at checkout. Auto-renews yearly.',
                subscribeAction: connect
                    ? null
                    : AppButton(
                        label: 'Subscribe',
                        trailingIcon: Icons.arrow_forward_rounded,
                        radius: 16,
                        isLoading: controller.working.value,
                        onPressed: controller.working.value
                            ? null
                            : () => controller.subscribe(context),
                      ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Payment is handled securely by your app store.',
                textAlign: TextAlign.center,
              ),
              if (controller.errorMessage.value.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: controller.errorMessage.value),
              ],
              const SizedBox(height: 14),
              if (connect)
                AppConstrainedAction(
                  child: AppButton(
                    label: 'Turn on internet & continue',
                    trailingIcon: Icons.wifi_rounded,
                    isLoading: controller.working.value,
                    onPressed: controller.working.value
                        ? null
                        : controller.retry,
                  ),
                ),
              const SizedBox(height: 10),
              _FooterLinks(
                isDark: isDark,
                connect: connect,
                working: controller.working.value,
                onRefresh: () => controller.restore(context),
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
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: SvgPicture.asset(
          SubscriptionGateScreen.headerAsset,
          fit: BoxFit.fill,
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
  const _YearlyPlanCard({
    required this.showOfferBadge,
    this.snapshot,
    this.yearlyPrice,
    this.storeCaption,
    this.subscribeAction,
  });
  final Widget? subscribeAction;

  final EntitlementSnapshot? snapshot;
  final String? yearlyPrice;
  final String? storeCaption;
  final bool showOfferBadge;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          key: const ValueKey('yearly-plan-card'),
          margin: EdgeInsets.only(bottom: subscribeAction == null ? 0 : 24),
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            16,
            showOfferBadge ? 22 : 16,
            16,
            subscribeAction == null ? 16 : 36,
          ),
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
                      : const Color(0xFFFFF1EC),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: .3),
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      yearlyPrice ??
                          '₹${snapshot?.offerPriceInr ?? 499} / year',
                      style: AppTextStyles.displayAmount.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      storeCaption ??
                          'Auto-renews yearly. Cancel in your store account settings.',
                      style: const TextStyle(fontSize: 12, height: 1.4),
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
        if (subscribeAction != null)
          Positioned(bottom: 0, left: 32, right: 32, child: subscribeAction!),
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
            'Your store confirms the price and renewal terms before payment.',
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
                    text: 'Restore purchases',
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
    title: 'Products, stock & customers',
    subtitle: 'Low stock alerts and balances stay on this phone.',
  ),
  _PlanFeature(
    icon: Icons.lock_rounded,
    color: AppColors.success,
    background: AppColors.successLight,
    title: 'Works 100% offline — data stays on phone',
    subtitle: 'Zero internet required. Safe, private, and local.',
  ),
];

class _PurchaseProgress extends StatelessWidget {
  const _PurchaseProgress({required this.controller});
  final SubscriptionGateController controller;
  @override
  Widget build(BuildContext context) {
    final state = controller.stage.value;
    final success = state == SubscriptionStage.success;
    final pending = state == SubscriptionStage.pending;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: success
                      ? AppColors.successLight
                      : AppColors.primaryLight,
                ),
                child: Icon(
                  success
                      ? Icons.verified_rounded
                      : Icons.hourglass_top_rounded,
                  size: 44,
                  color: success ? AppColors.success : AppColors.secondary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                success
                    ? 'You’re subscribed!'
                    : pending
                    ? 'Waiting for payment confirmation'
                    : 'Confirming your subscription',
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 12),
              Text(
                success
                    ? 'Your Creovo access is ready. Let’s get back to your business.'
                    : pending
                    ? 'Your store has not confirmed payment yet. Complete any instructions from Apple or Google. You do not need to pay again.'
                    : 'Follow the store instructions. We’ll verify your subscription automatically.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (controller.working.value)
                const CircularProgressIndicator()
              else
                AppButton(
                  label: success ? 'Continue' : 'Check status',
                  onPressed: success
                      ? controller.continueAfterPurchase
                      : controller.checkPurchase,
                ),
              if (controller.errorMessage.value.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
