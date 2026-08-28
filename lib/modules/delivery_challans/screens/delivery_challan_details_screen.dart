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
import '../../../data/models/delivery_challan_model.dart';
import '../../../data/repositories/delivery_challan_repository.dart';
import '../controllers/delivery_challan_controller.dart';

class DeliveryChallanDetailsScreen
    extends GetView<DeliveryChallanDetailsController> {
  const DeliveryChallanDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final challan = controller.challan.value;
      if (challan == null) {
        return Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(),
            title: const AppBarTitle('Delivery challan'),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: AppBarTitle(challan.challanNumber),
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
                      DeliveryChallanLabels.status(challan.status),
                      style: AppTextStyles.caption.copyWith(
                        color: challan.isCancelled
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(challan.customer.name, style: AppTextStyles.pageTitle),
                    const SizedBox(height: 4),
                    Text(
                      '${DeliveryChallanLabels.reason(challan.movementReason)}  ·  ${_date(challan.challanDate)}',
                      style: AppTextStyles.secondaryBody,
                    ),
                    if (challan.sourceCaption != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        challan.sourceCaption!,
                        style: AppTextStyles.caption,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      challan.ewayStatus == EwayStatus.generated &&
                              (challan.ewayNumber ?? '').isNotEmpty
                          ? 'E-way bill ${challan.ewayNumber} (imported acknowledgement)'
                          : DeliveryChallanLabels.eway(challan.ewayStatus),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
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
                    for (final item in challan.items) ...[
                      Text(item.name, style: AppTextStyles.listName),
                      Text(
                        '${l10n('Ordered')} ${QuantityUtils.toInputValue(item.orderedQuantityScaled)} · ${l10n('Dispatched')} ${QuantityUtils.toInputValue(item.dispatchedQuantityScaled)} ${item.unit}',
                        style: AppTextStyles.caption,
                      ),
                      Text(
                        challan.isAgainstInvoice
                            ? '${l10n('Delivered')} ${QuantityUtils.toInputValue(item.deliveredQuantityScaled)} · ${l10n('Returned')} ${QuantityUtils.toInputValue(item.returnedQuantityScaled)}'
                            : '${l10n('Delivered')} ${QuantityUtils.toInputValue(item.deliveredQuantityScaled)} · ${l10n('Returned')} ${QuantityUtils.toInputValue(item.returnedQuantityScaled)} · ${l10n('Invoiced')} ${QuantityUtils.toInputValue(item.invoicedQuantityScaled)}',
                        style: AppTextStyles.caption,
                      ),
                      if (!challan.isAgainstInvoice)
                        Text(
                          '${l10n('Remaining')} ${QuantityUtils.toInputValue(item.remainingToInvoiceScaled)}',
                          style: AppTextStyles.secondaryBody,
                        ),
                      const SizedBox(height: 10),
                    ],
                    if (challan.isAgainstInvoice)
                      Text(
                        'Already billed on this invoice. Remaining is for delivery, not another invoice.',
                        style: AppTextStyles.secondaryBody,
                      ),
                  ],
                ),
              ),
              if (challan.conversions.isNotEmpty) ...[
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Converted invoices',
                        style: AppTextStyles.sectionTitle,
                      ),
                      for (final conversion in challan.conversions)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(conversion.invoiceNumber),
                          subtitle: Text(_date(conversion.convertedAt)),
                          onTap: () => Get.toNamed<void>(
                            AppRoutes.invoiceDetails,
                            arguments: conversion.invoiceId,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (challan.isCancelled &&
                  (challan.cancellationReason ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                AppCard(
                  child: Text(
                    '${l10n('Cancelled')}: ${challan.cancellationReason}',
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (!challan.isCancelled) ...[
                if (challan.canConvert)
                  AppButton(
                    label: 'Convert to invoice',
                    icon: Icons.receipt_long_outlined,
                    onPressed: controller.openConvert,
                  ),
                if (challan.canConvert) const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => _recordQuantities(context, challan),
                  child: const Text('Record quantities'),
                ),
                const SizedBox(height: 10),
                if (challan.canEdit)
                  OutlinedButton(
                    onPressed: controller.openEdit,
                    child: const Text('Edit'),
                  ),
                if (challan.canEdit) const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: controller.prepareEway,
                  child: const Text('Prepare e-way'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => _importEway(context),
                  child: const Text('Import e-way acknowledgement'),
                ),
                const SizedBox(height: 10),
                if (challan.canCancel)
                  OutlinedButton(
                    onPressed: () => _cancel(context),
                    child: const Text('Cancel challan'),
                  ),
                if (challan.canCancel) const SizedBox(height: 10),
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
    DeliveryChallanModel challan,
  ) async {
    final delivered = <int, TextEditingController>{
      for (final item in challan.items)
        if (item.id != null)
          item.id!: TextEditingController(
            text: QuantityUtils.toInputValue(item.deliveredQuantityScaled),
          ),
    };
    final returned = <int, TextEditingController>{
      for (final item in challan.items)
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Record quantities', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            for (final item in challan.items)
              if (item.id != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(item.name, style: AppTextStyles.listName),
                ),
                Text(
                  '${l10n('Dispatched')} ${QuantityUtils.toInputValue(item.dispatchedQuantityScaled)} ${item.unit}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: delivered[item.id!]!,
                  label: 'Delivered',
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
    );
    if (confirmed == true) {
      final updates = <DeliveryChallanQuantityUpdate>[];
      for (final item in challan.items) {
        if (item.id == null) continue;
        updates.add(
          DeliveryChallanQuantityUpdate(
            itemId: item.id!,
            deliveredQuantityScaled:
                QuantityUtils.parseScaled(delivered[item.id!]!.text) ??
                item.deliveredQuantityScaled,
            returnedQuantityScaled:
                QuantityUtils.parseScaled(returned[item.id!]!.text) ??
                item.returnedQuantityScaled,
          ),
        );
      }
      await controller.recordQuantities(updates);
    }
    for (final value in [...delivered.values, ...returned.values]) {
      value.dispose();
    }
  }

  Future<void> _importEway(BuildContext context) async {
    final number = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import e-way acknowledgement'),
        content: AppTextField(
          controller: number,
          label: 'E-way bill number',
          hint: 'Paste the number from the portal response',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Back'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.importEway(number.text);
    }
    number.dispose();
  }

  Future<void> _cancel(BuildContext context) async {
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this challan?'),
        content: AppTextField(
          controller: reason,
          label: 'Reason',
          hint: 'Wrong party, goods not sent…',
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel challan'),
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

class DeliveryChallanConvertScreen
    extends GetView<DeliveryChallanConvertController> {
  const DeliveryChallanConvertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final challan = controller.challan.value;
      if (challan == null) {
        return Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(),
            title: const AppBarTitle('Convert to invoice'),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const AppBarTitle('Convert to invoice'),
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
              Text(
                'Remaining quantity to invoice',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 12),
              for (final item in challan.items)
                if (item.id != null && item.remainingToInvoiceScaled > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: AppTextStyles.listName),
                          Text(
                            '${l10n('Remaining')} ${QuantityUtils.toInputValue(item.remainingToInvoiceScaled)} ${item.unit}',
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(height: 8),
                          AppTextField(
                            controller: controller.quantityInputs[item.id!]!,
                            label: 'Quantity to invoice',
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
              if (challan.remainingToInvoiceScaled <= 0)
                const AppCard(child: Text('No remaining quantity to invoice.')),
            ],
          ),
        ),
      );
    });
  }
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
