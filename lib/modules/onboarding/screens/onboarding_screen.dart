import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../app/utils/responsive_utils.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  static const _pages = [
    _OnboardingData(
      icon: Icons.bolt_rounded,
      title: 'Invoices in seconds',
      message:
          'Create polished GST or non-GST invoices with a fast, focused workflow.',
    ),
    _OnboardingData(
      icon: Icons.lock_outline_rounded,
      title: 'Private by design',
      message:
          'Your business and invoice data stays on your device—no account or cloud required.',
    ),
    _OnboardingData(
      icon: Icons.picture_as_pdf_outlined,
      title: 'Ready to share',
      message:
          'Generate professional PDFs offline, then share or print whenever you need.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveContent(
          paddingTop: 8,
          tabletMaxWidth: 980,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: controller.complete,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: controller.pageController,
                  onPageChanged: controller.onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) =>
                      _OnboardingPage(data: _pages[index]),
                ),
              ),
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: controller.currentPage.value == index ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: controller.currentPage.value == index
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              ResponsiveUtils.verticalGap(context, 28),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveUtils.isTablet(context) ? 420 : 520,
                ),
                child: Obx(
                  () => AppButton(
                    label: controller.currentPage.value == _pages.length - 1
                        ? 'Set up my business'
                        : 'Continue',
                    onPressed: controller.next,
                    icon: Icons.arrow_forward_rounded,
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

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingData data;

  @override
  Widget build(BuildContext context) {
    final illustration = Container(
      width: ResponsiveUtils.width(context, 132),
      height: ResponsiveUtils.width(context, 132),
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      child: Icon(
        data.icon,
        size: ResponsiveUtils.width(context, 58),
        color: AppColors.primary,
      ),
    );
    final copy = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.pageTitle.copyWith(
              fontSize: ResponsiveUtils.fontSize(context, 24),
            ),
          ),
          ResponsiveUtils.verticalGap(context, 14),
          Text(
            data.message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
              fontSize: ResponsiveUtils.fontSize(context, 15),
            ),
          ),
        ],
      ),
    );
    return Center(
      child: ResponsiveUtils.isTablet(context)
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                illustration,
                ResponsiveUtils.horizontalGap(context, 56),
                Flexible(child: copy),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                illustration,
                ResponsiveUtils.verticalGap(context, 40),
                copy,
              ],
            ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;
}
