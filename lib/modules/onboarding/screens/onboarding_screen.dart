import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_button.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  static const _pages = [
    _OnboardingData(
      eyebrow: 'FAST INVOICING',
      icon: Icons.receipt_long_rounded,
      title: 'Your invoice, ready in minutes',
      message:
          'Add a customer, choose your items and let Creovo handle the totals.',
      accent: AppColors.secondary,
    ),
    _OnboardingData(
      eyebrow: 'PRIVATE BY DESIGN',
      icon: Icons.lock_rounded,
      title: 'Your business stays yours',
      message:
          'Bills stay on this phone. Your account number is only for the plan.',
      accent: AppColors.primary,
    ),
    _OnboardingData(
      eyebrow: 'READY TO SEND',
      icon: Icons.picture_as_pdf_rounded,
      title: 'Look professional every time',
      message: 'Preview a polished PDF, then share or print it in just a tap.',
      accent: AppColors.accent,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF6F1FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.horizontalPadding(context),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _BrandHeader(onSkip: controller.complete),
                SizedBox(height: ResponsiveUtils.isTablet(context) ? 12 : 14),
                Expanded(
                  child: ResponsiveUtils.isTablet(context)
                      ? PageView.builder(
                          controller: controller.pageController,
                          onPageChanged: controller.onPageChanged,
                          itemCount: _pages.length,
                          itemBuilder: (context, index) =>
                              _TabletOnboardingPage(
                                data: _pages[index],
                                pageIndex: index,
                                pageCount: _pages.length,
                                currentPage: controller.currentPage,
                                onNext: controller.next,
                              ),
                        )
                      : PageView.builder(
                          controller: controller.pageController,
                          onPageChanged: controller.onPageChanged,
                          itemCount: _pages.length,
                          itemBuilder: (context, index) => _OnboardingPage(
                            data: _pages[index],
                            pageIndex: index,
                          ),
                        ),
                ),
                if (!ResponsiveUtils.isTablet(context)) ...[
                  Obx(
                    () => _PageIndicator(current: controller.currentPage.value),
                  ),
                  ResponsiveUtils.verticalGap(context, 22),
                  Obx(
                    () => AppButton(
                      label: controller.currentPage.value == _pages.length - 1
                          ? 'Set up my business'
                          : 'Show me more',
                      onPressed: controller.next,
                      trailingIcon: Icons.arrow_forward_rounded,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.onSkip});
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x187138E8),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.asset('assets/icons/creovo_invoice_app_icon.png'),
          ),
        ),
        const SizedBox(width: 11),
        Text('Creovo Billing', style: AppTextStyles.cardTitle),
        const Spacer(),
        TextButton(onPressed: onSkip, child: const Text('Skip for now')),
      ],
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data, required this.pageIndex});
  final _OnboardingData data;
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    final visual = _FeatureVisual(data: data, pageIndex: pageIndex);
    final copy = _OnboardingCopy(data: data);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: visual),
        const SizedBox(height: 26),
        copy,
        const SizedBox(height: 10),
      ],
    );
  }
}

class _TabletOnboardingPage extends StatelessWidget {
  const _TabletOnboardingPage({
    required this.data,
    required this.pageIndex,
    required this.pageCount,
    required this.currentPage,
    required this.onNext,
  });

  final _OnboardingData data;
  final int pageIndex;
  final int pageCount;
  final RxInt currentPage;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 460,
                      maxHeight: 520,
                    ),
                    child: AspectRatio(
                      aspectRatio: 0.9,
                      child: _FeatureVisual(data: data, pageIndex: pageIndex),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48),
              Expanded(
                flex: 5,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _OnboardingCopy(data: data),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: 168,
                          child: Obx(
                            () => _PageIndicator(current: currentPage.value),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Obx(
                            () => AppButton(
                              label: currentPage.value == pageCount - 1
                                  ? 'Set up my business'
                                  : 'Show me more',
                              onPressed: onNext,
                              trailingIcon: Icons.arrow_forward_rounded,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingCopy extends StatelessWidget {
  const _OnboardingCopy({required this.data});
  final _OnboardingData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.eyebrow,
          style: AppTextStyles.caption.copyWith(
            color: data.accent,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          data.title,
          style: AppTextStyles.pageTitle.copyWith(
            fontSize: ResponsiveUtils.fontSize(
              context,
              ResponsiveUtils.isTablet(context) ? 34 : 28,
            ),
            height: 1.12,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          data.message,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
            fontSize: ResponsiveUtils.isTablet(context) ? 16 : 14,
          ),
        ),
      ],
    );
  }
}

class _FeatureVisual extends StatelessWidget {
  const _FeatureVisual({required this.data, required this.pageIndex});
  final _OnboardingData data;
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveUtils.isTablet(context);
    final isCompact = MediaQuery.sizeOf(context).height < 700;
    return Container(
      constraints: BoxConstraints(
        maxHeight: isTablet
            ? double.infinity
            : isCompact
            ? 270
            : 330,
        maxWidth: isTablet ? double.infinity : 520,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [data.accent.withValues(alpha: .96), AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: data.accent.withValues(alpha: .24),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(right: -45, top: -55, child: _Glow(size: 160)),
          Positioned(left: -35, bottom: -50, child: _Glow(size: 130)),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveUtils.isTablet(context) ? 24 : 0,
              ),
              child: Center(
                child: _InvoiceScene(pageIndex: pageIndex, accent: data.accent),
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: .22)),
              ),
              child: Row(
                children: [
                  Icon(data.icon, color: Colors.white, size: 17),
                  const SizedBox(width: 7),
                  Text(
                    pageIndex == 0
                        ? 'Simple & fast'
                        : pageIndex == 1
                        ? 'Offline-first'
                        : 'PDF ready',
                    style: AppTextStyles.small.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceScene extends StatelessWidget {
  const _InvoiceScene({required this.pageIndex, required this.accent});
  final int pageIndex;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final leadingIcon = pageIndex == 0
        ? Icons.person_rounded
        : pageIndex == 1
        ? Icons.shield_rounded
        : Icons.picture_as_pdf_rounded;
    return Transform.rotate(
      angle: -.035,
      child: Container(
        width: ResponsiveUtils.isTablet(context) ? 280 : 218,
        margin: const EdgeInsets.only(top: 30),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 25,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(leadingIcon, color: accent, size: 21),
                ),
                const Spacer(),
                Text(
                  pageIndex == 2 ? 'PDF' : 'INV-0001',
                  style: AppTextStyles.small.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 17),
            Container(
              height: 9,
              width: 112,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 7,
              width: 150,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 7),
            Container(
              height: 7,
              width: 126,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 15),
            Row(
              children: [
                Text(
                  pageIndex == 1 ? 'Stored locally' : 'Total',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  pageIndex == 1 ? 'Protected' : '₹12,450',
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: .09),
    ),
  );
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(
      3,
      (index) => Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 4,
          margin: EdgeInsets.only(right: index == 2 ? 0 : 7),
          decoration: BoxDecoration(
            color: index <= current ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    ),
  );
}

class _OnboardingData {
  const _OnboardingData({
    required this.eyebrow,
    required this.icon,
    required this.title,
    required this.message,
    required this.accent,
  });
  final String eyebrow;
  final IconData icon;
  final String title;
  final String message;
  final Color accent;
}
