import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/quantity_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_dialog.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../app/widgets/app_dropdown_field.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/models/product_service_model.dart';
import '../../../data/models/stock_models.dart';
import '../controllers/stock_controller.dart';

class StockListScreen extends GetView<StockController> {
  const StockListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const AppBarTitle('Stock'),
        actions: [
          AppBarIconButton(
            tooltip: l10n('Stock reports'),
            onPressed: () => Get.toNamed<void>(AppRoutes.stockReports),
            icon: Icons.assessment_outlined,
          ),
          AppBarIconButton(
            tooltip: l10n('Adjust stock'),
            onPressed: () => _adjust(context),
            icon: Icons.tune_rounded,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.movements.isEmpty) {
          return AppEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No stock movements yet',
            message:
                'Opening quantities, invoices, bills, returns, and adjustments appear here.',
            actionLabel: 'Adjust stock',
            onAction: () => _adjust(context),
          );
        }
        return ResponsiveContent(
          tabletMaxWidth: 640,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: controller.movements.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final movement = controller.movements[index];
              final name =
                  controller.productNames[movement.productId] ?? 'Product';
              final type = StockMovementType.fromStorage(movement.type);
              final qty = QuantityUtils.formatSigned(movement.quantityScaled);
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.border),
                ),
                title: Text(name, style: AppTextStyles.listName),
                subtitle: Text(
                  [
                    type.label,
                    if (movement.reason?.trim().isNotEmpty ?? false)
                      movement.reason!.trim(),
                    _formatDate(movement.createdAt),
                  ].join(' · '),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: Text(
                  qty,
                  style: AppTextStyles.listAmount.copyWith(
                    color: movement.quantityScaled < 0
                        ? AppColors.error
                        : AppColors.textPrimary,
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Future<void> _adjust(BuildContext context) async {
    final options = controller.trackedProducts;
    if (options.isEmpty) {
      AppNotification.info(
        'No products yet',
        'Add a catalog product before recording an adjustment.',
      );
      return;
    }
    var selected = options.first;
    final qty = TextEditingController();
    final reason = TextEditingController();
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setState) => AppDialog(
            tone: AppDialogTone.info,
            icon: Icons.tune_rounded,
            form: true,
            title: const Text('Adjust stock'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppDropdownField<ProductServiceModel>(
                  label: 'Product',
                  value: selected,
                  sheetTitle: 'Choose product',
                  options: [
                    for (final product in options)
                      AppDropdownOption(value: product, label: product.name),
                  ],
                  onChanged: (value) => setState(() => selected = value),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: qty,
                  label: 'Quantity change',
                  hint: 'Use minus to reduce, e.g. -2',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: reason,
                  label: 'Reason *',
                  hint: 'Damaged, count correction, own use…',
                ),
              ],
            ),
            actions: [
              AppDialogButton(
                label: l10n('Cancel'),
                variant: AppDialogButtonVariant.outlined,
                onPressed: () => Navigator.pop(dialogContext),
              ),
              AppDialogButton(
                label: l10n('Save adjustment'),
                onPressed: () async {
                  final productId = selected.id;
                  final quantity = QuantityUtils.parseSignedScaled(qty.text);
                  if (productId == null || quantity == null || quantity == 0) {
                    return;
                  }
                  try {
                    await controller.adjust(
                      productId: productId,
                      quantityScaled: quantity,
                      reason: reason.text,
                    );
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  } catch (_) {}
                },
              ),
            ],
          ),
        ),
      );
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      qty.dispose();
      reason.dispose();
    }
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}
