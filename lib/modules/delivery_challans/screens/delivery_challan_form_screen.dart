import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/quantity_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../app/widgets/app_dropdown_field.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../app/widgets/app_form_grid.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../app/widgets/unsaved_changes_scope.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/delivery_challan_model.dart';
import '../../customers/controllers/customer_form_controller.dart';
import '../../invoices/screens/invoice_item_picker_screen.dart';
import '../controllers/delivery_challan_controller.dart';

class DeliveryChallanFormScreen extends StatefulWidget {
  const DeliveryChallanFormScreen({super.key});

  @override
  State<DeliveryChallanFormScreen> createState() =>
      _DeliveryChallanFormScreenState();
}

class _DeliveryChallanFormScreenState extends State<DeliveryChallanFormScreen> {
  late final DeliveryChallanFormController controller = Get.find();
  bool _customerPromptScheduled = false;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (!_customerPromptScheduled && controller.shouldPromptForCustomer) {
        _customerPromptScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _selectCustomer(context, controller);
        });
      }
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final itemCount = controller.items.length;
      return UnsavedChangesScope(
        hasChanges: () => controller.hasUnsavedChanges,
        onSaveDraft: () => controller.save(asDraft: true, pop: false),
        child: Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(),
            title: AppBarTitle(
              controller.isEditing
                  ? 'Edit delivery challan'
                  : 'Create delivery challan',
            ),
            actions: [
              if (!controller.isEditing)
                TextButton.icon(
                  onPressed: controller.isSaving.value
                      ? null
                      : () => controller.save(asDraft: true),
                  icon: const Icon(Icons.bookmark_border_rounded, size: 19),
                  label: const Text('Draft'),
                ),
              const SizedBox(width: 8),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
              ),
              child: AppConstrainedAction(
                maxWidth: ResponsiveUtils.footerMaxWidth(context),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itemCount == 0 ? 'NO ITEMS YET' : 'ITEMS',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            itemCount == 0
                                ? 'Add goods to dispatch'
                                : '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.sectionTitle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: (MediaQuery.sizeOf(context).width * .56)
                          .clamp(210.0, 300.0)
                          .toDouble(),
                      child: AppButton(
                        isLoading: controller.isSaving.value,
                        icon: itemCount == 0 ? Icons.add_rounded : null,
                        trailingIcon: itemCount == 0
                            ? null
                            : Icons.arrow_forward_rounded,
                        label: itemCount == 0
                            ? 'Add first item'
                            : controller.isEditing
                            ? 'Update challan'
                            : 'Issue challan',
                        onPressed: itemCount == 0
                            ? () => _addItem(context, controller)
                            : () => controller.save(asDraft: false),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: ResponsiveContent(
            tabletMaxWidth: 640,
            child: ListView(
              padding: const EdgeInsets.only(top: 12),
              children: [
                AppCard(
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => _selectCustomer(context, controller),
                        borderRadius: BorderRadius.circular(14),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: controller.customer.value == null
                                    ? AppColors.primaryLight
                                    : AppColors.successLight,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: controller.customer.value == null
                                  ? const Icon(
                                      Icons.person_search_outlined,
                                      color: AppColors.primary,
                                    )
                                  : Text(
                                      _customerInitial(
                                        controller.customer.value!.name,
                                      ),
                                      style: AppTextStyles.cardTitle.copyWith(
                                        color: AppColors.success,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    controller.customer.value?.name ??
                                        'Choose a customer',
                                    style: AppTextStyles.cardTitle,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    controller.customer.value?.companyName ??
                                        controller.customer.value?.mobile ??
                                        'Required to create this challan',
                                    style: AppTextStyles.small.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              controller.customer.value == null
                                  ? 'Select'
                                  : 'Change',
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.secondary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _MetaCell(
                                icon: Icons.tag_rounded,
                                label: 'Challan',
                                value: controller.challanNumber.isEmpty
                                    ? 'DC-—'
                                    : controller.challanNumber,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.border,
                            ),
                            Expanded(
                              child: _MetaCell(
                                icon: Icons.calendar_today_outlined,
                                label: 'Date',
                                value: _date(controller.challanDate.value),
                                onTap: () async {
                                  final selected = await showDatePicker(
                                    context: context,
                                    initialDate: controller.challanDate.value,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (selected != null) {
                                    controller.setDate(selected);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (controller.sourceCaption != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.secondaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            controller.sourceCaption!,
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      AppDropdownField<MovementReason>(
                        label: 'Movement reason',
                        sheetTitle: 'Movement reason',
                        prefixIcon: Icons.swap_horiz_rounded,
                        enabled: !controller.isAgainstInvoice,
                        value: controller.movementReason.value,
                        options: [
                          for (final value in MovementReason.values)
                            AppDropdownOption(
                              value: value,
                              label: DeliveryChallanLabels.reason(value),
                            ),
                        ],
                        onChanged: controller.setReason,
                      ),
                      if (controller.movementReason.value ==
                          MovementReason.other) ...[
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: controller.movementReasonNote,
                          label: 'Reason note',
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text('Items', style: AppTextStyles.sectionTitle),
                    ),
                    if (itemCount > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.all(Radius.circular(99)),
                        ),
                        child: Text(
                          '$itemCount',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    if (itemCount > 0)
                      FilledButton.tonalIcon(
                        onPressed: () => _addItem(context, controller),
                        icon: const Icon(Icons.add_rounded, size: 19),
                        label: const Text('Add'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                        ),
                      )
                    else
                      TextButton.icon(
                        onPressed: () => _addItem(context, controller),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add item'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (itemCount == 0)
                  AppCard(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
                    color: isDark
                        ? AppColors.darkSurface
                        : const Color(0xFFFFFBFA),
                    borderColor: AppColors.primary.withValues(alpha: .14),
                    child: Column(
                      children: [
                        const AppEmptyArt(
                          illustration: AppEmptyIllustration.package,
                          width: 132,
                          height: 100,
                          semanticLabel: 'No items yet',
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No items yet',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.sectionTitle,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Add at least one item with a dispatched quantity.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20),
                        AppButton(
                          icon: Icons.add_rounded,
                          label: 'Add an item',
                          onPressed: () => _addItem(context, controller),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      for (var index = 0; index < itemCount; index++) ...[
                        if (index > 0) const SizedBox(height: 10),
                        AppCard(
                          padding: const EdgeInsets.fromLTRB(12, 11, 8, 11),
                          child: _ItemRow(
                            index: index,
                            item: controller.items[index],
                            controller: controller,
                          ),
                        ),
                      ],
                    ],
                  ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: controller.showAddresses.toggle,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurfaceVariant
                                      : AppColors.secondaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.place_outlined,
                                  color: AppColors.secondary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Delivery address',
                                      style: AppTextStyles.listName,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      controller.showAddresses.value
                                          ? 'Hide address fields'
                                          : controller.addressSummary,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                controller.showAddresses.value
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (controller.showAddresses.value) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: controller.copyDeliveryFromCustomer,
                            child: const Text('Copy from customer'),
                          ),
                        ),
                        AppTextField(
                          controller: controller.deliveryAddress,
                          label: 'Address',
                          prefixIcon: Icons.home_outlined,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        AppFormGrid(
                          children: [
                            AppTextField(
                              controller: controller.deliveryCity,
                              label: 'City',
                            ),
                            AppTextField(
                              controller: controller.deliveryState,
                              label: 'State',
                            ),
                            AppTextField(
                              controller: controller.deliveryPinCode,
                              label: 'PIN code',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Dispatch from',
                                style: AppTextStyles.listName,
                              ),
                            ),
                            TextButton(
                              onPressed: controller.copyDispatchFromCustomer,
                              child: const Text('Copy from customer'),
                            ),
                          ],
                        ),
                        AppTextField(
                          controller: controller.dispatchAddress,
                          label: 'Address',
                          prefixIcon: Icons.warehouse_outlined,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        AppFormGrid(
                          children: [
                            AppTextField(
                              controller: controller.dispatchCity,
                              label: 'City',
                            ),
                            AppTextField(
                              controller: controller.dispatchState,
                              label: 'State',
                            ),
                            AppTextField(
                              controller: controller.dispatchPinCode,
                              label: 'PIN code',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: controller.showTransport.toggle,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurfaceVariant
                                      : AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.local_shipping_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Transport',
                                      style: AppTextStyles.listName,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      controller.showTransport.value
                                          ? 'Hide transport fields'
                                          : controller.transportSummary,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                controller.showTransport.value
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (controller.showTransport.value) ...[
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: controller.transporterName,
                          label: 'Transporter',
                          prefixIcon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 12),
                        AppFormGrid(
                          children: [
                            AppTextField(
                              controller: controller.vehicleNumber,
                              label: 'Vehicle number',
                              prefixIcon: Icons.directions_car_outlined,
                              textCapitalization: TextCapitalization.characters,
                            ),
                            AppTextField(
                              controller: controller.transporterId,
                              label: 'Transporter GSTIN',
                              prefixIcon: Icons.qr_code_2_rounded,
                              textCapitalization: TextCapitalization.characters,
                            ),
                            AppTextField(
                              controller: controller.transportDocumentNumber,
                              label: 'Transport document',
                              prefixIcon: Icons.description_outlined,
                            ),
                            AppTextField(
                              controller: controller.distanceKm,
                              label: 'Distance (km)',
                              prefixIcon: Icons.straighten_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: controller.showNotes.toggle,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.notes_rounded,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  controller.notes.text.trim().isEmpty
                                      ? 'Add a note'
                                      : 'Notes',
                                  style: AppTextStyles.listName,
                                ),
                              ),
                              Icon(
                                controller.showNotes.value
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (controller.showNotes.value) ...[
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: controller.notes,
                          label: 'Notes',
                          maxLines: 3,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _MetaCell extends StatelessWidget {
  const _MetaCell({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.small.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: child,
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.index,
    required this.item,
    required this.controller,
  });
  final int index;
  final DeliveryChallanItemModel item;
  final DeliveryChallanFormController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                '${index + 1}',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.sourceItemId == null
                        ? '${item.unit} · ${CurrencyUtils.formatMinor(item.rateMinor, symbol: '₹')}'
                        : '${l10n('Ordered')} ${QuantityUtils.toInputValue(item.orderedQuantityScaled)} ${item.unit} · ${l10n('Dispatched')} ${QuantityUtils.toInputValue(item.dispatchedQuantityScaled)}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n('Remove item'),
              onPressed: () => controller.removeItem(item),
              icon: const Icon(Icons.close_rounded, size: 18),
              style: IconButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _QuantityStepper(
              value: QuantityUtils.toInputValue(item.dispatchedQuantityScaled),
              canDecrease: item.dispatchedQuantityScaled > 1000,
              onDecrease: () => controller.setDispatched(
                item,
                item.dispatchedQuantityScaled - 1000,
              ),
              onRemove: () => controller.removeItem(item),
              onIncrease: () => controller.setDispatched(
                item,
                item.dispatchedQuantityScaled + 1000,
              ),
              onEdit: () => _editQuantity(context, item, controller),
            ),
            const SizedBox(width: 8),
            Text('Dispatched', style: AppTextStyles.caption),
          ],
        ),
      ],
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.value,
    required this.canDecrease,
    required this.onDecrease,
    required this.onRemove,
    required this.onIncrease,
    required this.onEdit,
  });

  final String value;
  final bool canDecrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;
  final VoidCallback onIncrease;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: canDecrease ? 'Decrease quantity' : 'Remove item',
            onPressed: canDecrease ? onDecrease : onRemove,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
            icon: Icon(
              canDecrease ? Icons.remove_rounded : Icons.delete_outline_rounded,
              size: 17,
              color: canDecrease ? null : AppColors.error,
            ),
          ),
          Container(
            width: 1,
            height: 22,
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
          Tooltip(
            message: l10n('Enter quantity'),
            child: InkWell(
              onTap: onEdit,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 34),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.small.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 22,
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
          IconButton(
            tooltip: l10n('Increase quantity'),
            onPressed: onIncrease,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.add_rounded, size: 17),
          ),
        ],
      ),
    );
  }
}

Future<void> _editQuantity(
  BuildContext context,
  DeliveryChallanItemModel item,
  DeliveryChallanFormController controller,
) async {
  final input = TextEditingController(
    text: QuantityUtils.toInputValue(item.dispatchedQuantityScaled),
  );
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Dispatched quantity'),
      content: AppTextField(
        controller: input,
        label: 'Quantity',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Back'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    final parsed = QuantityUtils.parseScaled(input.text);
    if (parsed != null && parsed > 0) {
      controller.setDispatched(item, parsed);
    }
  }
  input.dispose();
}

Future<void> _selectCustomer(
  BuildContext context,
  DeliveryChallanFormController controller,
) async {
  final selected = await showModalBottomSheet<CustomerModel>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => FutureBuilder<List<CustomerModel>>(
      future: controller.customers(),
      builder: (context, snapshot) {
        final customers = snapshot.data ?? const <CustomerModel>[];
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .7,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Who is this challan for?',
                        style: AppTextStyles.sectionTitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose the party receiving these goods.',
                        style: AppTextStyles.secondaryBody,
                      ),
                    ],
                  ),
                ),
                if (customers.isEmpty)
                  Expanded(
                    child: AppEmptyState(
                      illustration: AppEmptyIllustration.people,
                      title: 'No customers yet',
                      message:
                          'Create your first customer to start this challan.',
                      actionLabel: 'Create new customer',
                      onAction: () async {
                        final result = await Get.toNamed<dynamic>(
                          AppRoutes.customerAdd,
                          arguments: const CustomerFormArgs(
                            returnToInvoice: true,
                          ),
                        );
                        if (result is CustomerModel && context.mounted) {
                          Navigator.pop(sheetContext, result);
                        }
                      },
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: customers.length + 1,
                      itemBuilder: (context, index) {
                        if (index == customers.length) {
                          return ListTile(
                            leading: const Icon(Icons.person_add_alt_1_rounded),
                            title: const Text('Create new customer'),
                            onTap: () async {
                              final result = await Get.toNamed<dynamic>(
                                AppRoutes.customerAdd,
                                arguments: const CustomerFormArgs(
                                  returnToInvoice: true,
                                ),
                              );
                              if (result is CustomerModel && context.mounted) {
                                Navigator.pop(sheetContext, result);
                              }
                            },
                          );
                        }
                        final customer = customers[index];
                        return ListTile(
                          title: Text(customer.name),
                          subtitle: Text(
                            [customer.companyName, customer.mobile]
                                .whereType<String>()
                                .where((value) => value.trim().isNotEmpty)
                                .join(' • '),
                          ),
                          onTap: () => Navigator.pop(sheetContext, customer),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
  if (selected != null) controller.selectCustomer(selected);
}

Future<void> _addItem(
  BuildContext context,
  DeliveryChallanFormController controller,
) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Choose saved item'),
              onTap: () => Navigator.pop(sheetContext, 'saved'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note_rounded),
              title: const Text('Create custom item'),
              onTap: () => Navigator.pop(sheetContext, 'custom'),
            ),
          ],
        ),
      ),
    ),
  );
  if (!context.mounted || choice == null) return;
  if (choice == 'saved') {
    final selected = await Get.toNamed<dynamic>(
      AppRoutes.invoiceItemPicker,
      arguments: InvoiceItemPickerArgs(
        alreadyAddedIds: controller.items
            .map((item) => item.productId)
            .whereType<int>()
            .toSet(),
        alreadyAddedLabel: 'On challan',
      ),
    );
    if (selected is InvoiceItemPickerResult) {
      controller.applyCatalogSelection(
        added: selected.added,
        removedProductIds: selected.removedIds,
      );
    }
    return;
  }
  final name = TextEditingController();
  final quantity = TextEditingController(text: '1');
  final unit = TextEditingController(text: 'pcs');
  final rate = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Custom item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(controller: name, label: 'Item name'),
          const SizedBox(height: 12),
          AppTextField(
            controller: quantity,
            label: 'Quantity',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          AppTextField(controller: unit, label: 'Unit'),
          const SizedBox(height: 12),
          AppTextField(
            controller: rate,
            label: 'Rate',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Back'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Add item'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    final quantityScaled = QuantityUtils.parseScaled(quantity.text) ?? 0;
    final rateMinor = CurrencyUtils.parseMinor(rate.text) ?? 0;
    if (name.text.trim().isNotEmpty && quantityScaled > 0) {
      controller.addCustomItem(
        name: name.text,
        quantityScaled: quantityScaled,
        unit: unit.text,
        rateMinor: rateMinor,
      );
    }
  }
  name.dispose();
  quantity.dispose();
  unit.dispose();
  rate.dispose();
}

String _customerInitial(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.characters.first.toUpperCase();
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
