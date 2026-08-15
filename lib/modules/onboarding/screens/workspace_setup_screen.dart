import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/services/business_workspace_service.dart';
import '../controllers/onboarding_controller.dart';

class WorkspaceSetupScreen extends GetView<OnboardingController> {
  const WorkspaceSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveContent(
          tabletMaxWidth: 720,
          paddingTop: 20,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              Text(
                'CHOOSE YOUR WORKSPACE',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text('What do you manage most?', style: AppTextStyles.pageTitle),
              const SizedBox(height: 8),
              Text(
                'Choose where Creovo Billing should start. You can switch anytime without losing data.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Obx(
                () => _WorkspaceOption(
                  selected:
                      controller.selectedWorkspace.value ==
                      BusinessWorkspace.sales,
                  icon: Icons.trending_up_rounded,
                  title: 'Sales',
                  subtitle:
                      'Create invoices, manage customers and collect payments.',
                  bullets: const ['Customer invoices', 'Money to receive'],
                  onTap: () =>
                      controller.previewWorkspace(BusinessWorkspace.sales),
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => _WorkspaceOption(
                  selected:
                      controller.selectedWorkspace.value ==
                      BusinessWorkspace.purchases,
                  icon: Icons.shopping_bag_outlined,
                  title: 'Purchases',
                  subtitle:
                      'Record supplier bills and keep track of money to pay.',
                  bullets: const ['Supplier bills', 'Money to pay'],
                  onTap: () =>
                      controller.previewWorkspace(BusinessWorkspace.purchases),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.swap_horiz_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Both workspaces stay available from inside the app.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => AppButton(
                  label:
                      controller.selectedWorkspace.value ==
                          BusinessWorkspace.sales
                      ? 'Continue with Sales'
                      : 'Continue with Purchases',
                  trailingIcon: Icons.arrow_forward_rounded,
                  onPressed: () => controller.selectWorkspace(
                    controller.selectedWorkspace.value,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceOption extends StatelessWidget {
  const _WorkspaceOption({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> bullets;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: title,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryLight
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.secondary : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected ? AppColors.secondary : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title, style: AppTextStyles.cardTitle),
                      ),
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: selected
                            ? AppColors.secondary
                            : AppColors.textTertiary,
                        size: 21,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.secondaryBody.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 7,
                    runSpacing: 6,
                    children: bullets
                        .map(
                          (item) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(item, style: AppTextStyles.caption),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
