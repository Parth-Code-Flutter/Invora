import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_constants.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../app/widgets/responsive_content.dart';
import '../controllers/about_controller.dart';

class AboutScreen extends GetView<AboutController> {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const AppBarTitle('About'),
      ),
      bottomNavigationBar: Obx(
        () => SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkBorder
                      : AppColors.border,
                ),
              ),
            ),
            child: AppConstrainedAction(
              maxWidth: ResponsiveUtils.footerMaxWidth(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    label: 'Share diagnostics',
                    icon: Icons.ios_share_rounded,
                    isLoading: controller.isBusy.value,
                    onPressed: controller.share,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: controller.isBusy.value
                          ? null
                          : controller.save,
                      child: const Text('Save diagnostics'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.report.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final report = controller.report.value;
        return ResponsiveContent(
          tabletMaxWidth: 640,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppConstants.appName, style: AppTextStyles.pageTitle),
                    const SizedBox(height: 6),
                    Text(
                      'Privacy-first offline invoicing',
                      style: AppTextStyles.secondaryBody,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      report == null
                          ? 'Version —'
                          : 'Version ${report.appVersion} (${report.buildNumber})',
                      style: AppTextStyles.listName,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Schema ${report?.schemaVersion ?? '—'}',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report == null
                          ? ''
                          : '${report.platform}  ·  App lock ${report.appLockEnabled ? 'On' : 'Off'}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How this app works',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Create, search, print, export, and restore work in airplane mode. Internet is never required to open the app or read business data.',
                      style: AppTextStyles.secondaryBody,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'GST / CA files are labelled Prepared / Not submitted. Filing happens on the GST portal, not in this app.',
                      style: AppTextStyles.secondaryBody,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Backup is a password-protected ZIP on this device. This app does not sync invoices to the cloud.',
                      style: AppTextStyles.secondaryBody,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Diagnostics', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 6),
                    Text(
                      'Share a text file with versions and record counts only — not names, GSTIN, amounts, or a backup.',
                      style: AppTextStyles.secondaryBody,
                    ),
                    if (report != null) ...[
                      const SizedBox(height: 12),
                      for (final entry in report.counts.entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${entry.key}: ${entry.value}',
                            style: AppTextStyles.caption,
                          ),
                        ),
                      Text(
                        'Last backup: ${report.lastBackupAt == null ? 'Never' : _date(report.lastBackupAt!)}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
