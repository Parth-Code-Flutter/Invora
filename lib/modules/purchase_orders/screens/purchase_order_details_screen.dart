import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/quantity_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/models/purchase_order_model.dart';
import '../../../data/repositories/purchase_order_repository.dart';
import '../controllers/purchase_order_controller.dart';

class PurchaseOrderDetailsScreen
    extends GetView<PurchaseOrderDetailsController> {
  const PurchaseOrderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final order = controller.order.value;
      if (order == null) {
        return Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(),
            title: const AppBarTitle('Purchase order'),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: AppBarTitle(order.orderNumber),
          actions: [
            AppBarIconButton(
              tooltip: l10n('Share'),
              onPressed: controller.share,
              icon: Icons.ios_share_rounded,
            ),
          ],
        ),
        body: ResponsiveContent(
          tabletMaxWidth: 640,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      PurchaseOrderLabels.status(order.status),
                      style: AppTextStyles.caption.copyWith(
                        color: order.isCancelled
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(order.supplier.name, style: AppTextStyles.pageTitle),
                    const SizedBox(height: 4),
                    Text(
                      '${_date(order.orderDate)}${order.expectedDate == null ? '' : '  ·  Expected ${_date(order.expectedDate!)}'}',
                      style: AppTextStyles.secondaryBody,
                    ),
                    if ((order.supplier.gstin ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'GSTIN ${order.supplier.gstin}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Items', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 8),
                    for (final item in order.items) ...[
                      Text(item.name, style: AppTextStyles.listName),
                      Text(
                        '${l10n('Ordered')} ${QuantityUtils.toInputValue(item.orderedQuantityScaled)} · ${l10n('Received')} ${QuantityUtils.toInputValue(item.receivedQuantityScaled)} ${item.unit}',
                        style: AppTextStyles.caption,
                      ),
                      Text(
                        '${l10n('Returned')} ${QuantityUtils.toInputValue(item.returnedQuantityScaled)} · ${l10n('Billed')} ${QuantityUtils.toInputValue(item.billedQuantityScaled)} · ${l10n('Remaining')} ${QuantityUtils.toInputValue(item.remainingToBillScaled)}',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 10),
                    ],
                    Text(
                      'This purchase order does not change stock or payable. Receiving tracks goods; converting creates the supplier bill.',
                      style: AppTextStyles.secondaryBody,
                    ),
                  ],
                ),
              ),
              if (order.conversions.isNotEmpty) ...[
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Converted bills',
                        style: AppTextStyles.sectionTitle,
                      ),
                      for (final conversion in order.conversions)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(conversion.billNumber),
                          subtitle: Text(_date(conversion.convertedAt)),
                          onTap: () => Get.toNamed<void>(
                            AppRoutes.purchaseBillDetails,
                            arguments: conversion.purchaseBillId,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if ((order.terms ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Terms', style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 6),
                      Text(order.terms!),
                    ],
                  ),
                ),
              ],
              if (order.isCancelled &&
                  (order.cancellationReason ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                AppCard(
                  child: Text(
                    '${l10n('Cancelled')}: ${order.cancellationReason}',
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (!order.isCancelled) ...[
                if (order.canConvert)
                  AppButton(
                    label: 'Convert to purchase bill',
                    icon: Icons.receipt_long_outlined,
                    onPressed: controller.openConvert,
                  ),
                if (order.canConvert) const SizedBox(height: 10),
                if (!order.isDraft)
                  OutlinedButton(
                    onPressed: () => _recordQuantities(context, order),
                    child: const Text('Record received quantities'),
                  ),
                if (!order.isDraft) const SizedBox(height: 10),
                if (order.canEdit)
                  OutlinedButton(
                    onPressed: controller.openEdit,
                    child: const Text('Edit'),
                  ),
                if (order.canEdit) const SizedBox(height: 10),
                if (order.canCancel)
                  OutlinedButton(
                    onPressed: () => _cancel(context),
                    child: const Text('Cancel purchase order'),
                  ),
                if (order.canCancel) const SizedBox(height: 10),
              ],
              OutlinedButton(
                onPressed: controller.printPdf,
                child: const Text('Print PDF'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: controller.savePdf,
                child: const Text('Save PDF'),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _recordQuantities(
    BuildContext context,
    PurchaseOrderModel order,
  ) async {
    final received = <int, TextEditingController>{
      for (final item in order.items)
        if (item.id != null)
          item.id!: TextEditingController(
            text: QuantityUtils.toInputValue(item.receivedQuantityScaled),
          ),
    };
    final returned = <int, TextEditingController>{
      for (final item in order.items)
        if (item.id != null)
          item.id!: TextEditingController(
            text: QuantityUtils.toInputValue(item.returnedQuantityScaled),
          ),
    };
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Record received quantities',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 12),
              for (final item in order.items)
                if (item.id != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(item.name, style: AppTextStyles.listName),
                  ),
                  Text(
                    '${l10n('Ordered')} ${QuantityUtils.toInputValue(item.orderedQuantityScaled)} ${item.unit}',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: received[item.id!]!,
                    label: 'Received',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: returned[item.id!]!,
                    label: 'Returned',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              AppButton(
                label: 'Save quantities',
                onPressed: () => Navigator.pop(sheetContext, true),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) {
      final updates = <PurchaseOrderQuantityUpdate>[];
      for (final item in order.items) {
        if (item.id == null) continue;
        updates.add(
          PurchaseOrderQuantityUpdate(
            itemId: item.id!,
            receivedQuantityScaled:
                QuantityUtils.parseScaled(received[item.id!]!.text) ??
                item.receivedQuantityScaled,
            returnedQuantityScaled:
                QuantityUtils.parseScaled(returned[item.id!]!.text) ??
                item.returnedQuantityScaled,
          ),
        );
      }
      await controller.recordQuantities(updates);
    }
    for (final field in [...received.values, ...returned.values]) {
      field.dispose();
    }
  }

  Future<void> _cancel(BuildContext context) async {
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel purchase order?'),
        content: AppTextField(
          controller: reason,
          label: 'Cancellation reason',
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Back'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.cancel(reason.text);
    }
    reason.dispose();
  }
}

class PurchaseOrderConvertScreen
    extends GetView<PurchaseOrderConvertController> {
  const PurchaseOrderConvertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final order = controller.order.value;
      if (order == null) {
        return Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(),
            title: const AppBarTitle('Convert to purchase bill'),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const AppBarTitle('Convert to purchase bill'),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: AppConstrainedAction(
              maxWidth: ResponsiveUtils.footerMaxWidth(context),
              child: AppButton(
                label: 'Convert remaining',
                isLoading: controller.isSaving.value,
                onPressed: controller.convert,
              ),
            ),
          ),
        ),
        body: ResponsiveContent(
          tabletMaxWidth: 640,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              AppTextField(
                controller: controller.billNumber,
                label: 'Supplier bill number',
              ),
              const SizedBox(height: 16),
              Text(
                'Remaining received quantity to bill',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 12),
              for (final item in order.items)
                if (item.id != null && item.remainingToBillScaled > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: AppTextStyles.listName),
                          Text(
                            '${l10n('Remaining')} ${QuantityUtils.toInputValue(item.remainingToBillScaled)} ${item.unit}',
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(height: 8),
                          AppTextField(
                            controller: controller.quantityInputs[item.id!]!,
                            label: 'Quantity to bill',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (value) =>
                                controller.setQuantity(item.id!, value),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (order.remainingToBillScaled <= 0)
                const AppCard(child: Text('No remaining quantity to bill.')),
            ],
          ),
        ),
      );
    });
  }
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
