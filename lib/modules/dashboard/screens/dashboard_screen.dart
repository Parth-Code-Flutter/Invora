import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/responsive_content.dart';
import '../controllers/dashboard_controller.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome', style: AppTextStyles.small),
              Text(controller.profile.value?.businessName ?? 'Invora'),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ResponsiveContent(
            paddingTop: 8,
            child: Column(
              children: [
                AppCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Business setup complete',
                        style: AppTextStyles.sectionTitle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your offline workspace is ready. Dashboard features arrive in a later phase.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(
                        Icons.people_outline,
                        color: AppColors.primary,
                      ),
                    ),
                    title: const Text('Customers'),
                    subtitle: const Text('Manage customer and billing details'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Get.toNamed<void>(AppRoutes.customers),
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    title: const Text('Create invoice'),
                    subtitle: const Text('Build and save an offline invoice'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Get.toNamed<void>(AppRoutes.invoiceCreate),
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.warningLight,
                      child: Icon(
                        Icons.list_alt_rounded,
                        color: AppColors.warning,
                      ),
                    ),
                    title: const Text('Invoices'),
                    subtitle: const Text('Search and manage saved invoices'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Get.toNamed<void>(AppRoutes.invoices),
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.secondaryLight,
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.secondary,
                      ),
                    ),
                    title: const Text('Products & services'),
                    subtitle: const Text('Manage reusable invoice items'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Get.toNamed<void>(AppRoutes.products),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
