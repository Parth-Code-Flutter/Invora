import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_filter_chip.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/models/data_import_models.dart';
import '../../../data/services/data_import_templates.dart';
import '../controllers/data_import_controller.dart';

class DataImportScreen extends GetView<DataImportController> {
  const DataImportScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const AppBarTitle('Import data'),
    ),
    body: Obx(() {
      final preview = controller.preview.value;
      return ResponsiveContent(
        tabletMaxWidth: 720,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: .65),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.file_upload_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Import stays on this device. Download a template, pick CSV or Excel, preview rows, then save in one step. Opening stock waits until Inventory.',
                      style: AppTextStyles.secondaryBody,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('WHAT TO IMPORT', style: AppTextStyles.small),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final template in DataImportTemplates.all)
                  AppFilterChip(
                    label: template.title,
                    selected: controller.kind.value == template.kind,
                    onSelected: (_) => controller.selectKind(template.kind),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              controller.template.subtitle,
              style: AppTextStyles.secondaryBody,
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'If a row already exists',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AppFilterChip(
                        label: 'Skip',
                        selected:
                            controller.policy.value ==
                            DuplicateImportPolicy.skip,
                        onSelected: (_) => controller.policy.value =
                            DuplicateImportPolicy.skip,
                      ),
                      AppFilterChip(
                        label: 'Update matching',
                        selected:
                            controller.policy.value ==
                            DuplicateImportPolicy.update,
                        onSelected: (_) => controller.policy.value =
                            DuplicateImportPolicy.update,
                      ),
                      AppFilterChip(
                        label: 'Import as new',
                        selected:
                            controller.policy.value ==
                            DuplicateImportPolicy.importAsNew,
                        onSelected: (_) => controller.policy.value =
                            DuplicateImportPolicy.importAsNew,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.isBusy.value
                        ? null
                        : () => controller.downloadTemplate(share: false),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Template'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: controller.isBusy.value
                        ? null
                        : controller.pickFile,
                    icon: const Icon(Icons.folder_open_outlined),
                    label: const Text('Pick file'),
                  ),
                ),
              ],
            ),
            if (preview != null) ...[
              const SizedBox(height: 18),
              _PreviewCard(controller: controller, preview: preview),
            ],
            if (controller.lastResult.value != null) ...[
              const SizedBox(height: 12),
              _ResultCard(controller: controller),
            ],
            if (controller.batches.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text('RECENT IMPORTS', style: AppTextStyles.small),
              const SizedBox(height: 8),
              for (final batch in controller.batches)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _BatchTile(controller: controller, batch: batch),
                ),
            ],
          ],
        ),
      );
    }),
  );
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.controller, required this.preview});
  final DataImportController controller;
  final ImportPreview preview;

  @override
  Widget build(BuildContext context) {
    final headers = preview.fileHeaders;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(preview.sourceFileName, style: AppTextStyles.cardTitle),
          const SizedBox(height: 6),
          Text(
            '${preview.validCount} ready · ${preview.warningCount} warnings · ${preview.rejectedCount} rejected',
            style: AppTextStyles.secondaryBody,
          ),
          const SizedBox(height: 12),
          for (final column in controller.template.columns)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      column.required ? '${column.header} *' : column.header,
                      style: AppTextStyles.small,
                    ),
                  ),
                  DropdownButton<String>(
                    value: headers.contains(preview.mapping[column.key])
                        ? preview.mapping[column.key]
                        : null,
                    hint: const Text('Skip'),
                    items: [
                      for (final header in headers)
                        DropdownMenuItem(value: header, child: Text(header)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        controller.mapColumn(column.key, value);
                      }
                    },
                  ),
                ],
              ),
            ),
          if (preview.issues.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final issue in preview.issues.take(8))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Row ${issue.rowNumber}: ${issue.message}',
                  style: AppTextStyles.small.copyWith(
                    color: issue.warning ? AppColors.warning : AppColors.error,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 12),
          AppButton(
            label: 'Import ${preview.validCount} rows',
            icon: Icons.save_outlined,
            isLoading: controller.isBusy.value,
            onPressed: preview.validCount == 0 ? null : controller.importRows,
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.controller});
  final DataImportController controller;

  @override
  Widget build(BuildContext context) {
    final result = controller.lastResult.value!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Saved offline', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 6),
          Text(
            '${result.importedCount} imported, ${result.skippedCount} skipped, ${result.rejectedCount} rejected.',
            style: AppTextStyles.secondaryBody,
          ),
          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: controller.shareErrors,
              icon: const Icon(Icons.ios_share_outlined),
              label: const Text('Share error CSV'),
            ),
          ],
        ],
      ),
    );
  }
}

class _BatchTile extends StatelessWidget {
  const _BatchTile({required this.controller, required this.batch});
  final DataImportController controller;
  final ImportBatchSummary batch;

  @override
  Widget build(BuildContext context) {
    final reversed = batch.status == 'reversed';
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(batch.sourceFileName, style: AppTextStyles.cardTitle),
                Text(
                  reversed
                      ? 'Reversed · ${batch.importedCount} rows'
                      : '${batch.importedCount} imported from ${batch.kind.name}',
                  style: AppTextStyles.small,
                ),
              ],
            ),
          ),
          if (!reversed)
            TextButton(
              onPressed: controller.isBusy.value
                  ? null
                  : () => controller.reverse(batch),
              child: const Text('Undo'),
            ),
        ],
      ),
    );
  }
}
