import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/enums/invoice_status.dart';
import '../../../app/enums/tax_type.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/app_focus.dart';
import '../../../app/utils/quantity_utils.dart';
import '../../../app/utils/product_attribute_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_amount_text.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_outlined_button.dart';
import '../../../app/widgets/app_dropdown_field.dart';
import '../../../app/widgets/app_dialog.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../app/widgets/app_status_chip.dart';
import '../../../data/models/credit_note_model.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/invoice_payment_model.dart';
import '../../../data/models/cash_book_models.dart';
import '../../../data/repositories/cash_book_repository.dart';
import '../../../data/services/invoice_defaults_service.dart';
import '../../../data/services/product_settings_service.dart';
import '../controllers/invoice_details_controller.dart';
import '../controllers/payment_receipt_controller.dart';

class InvoiceDetailsScreen extends GetView<InvoiceDetailsController> {
  const InvoiceDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Obx(() {
          final invoice = controller.invoice.value;
          final number = invoice?.invoiceNumber;
          final isQuotation = invoice?.documentType == DocumentType.quotation;
          if (number == null || number.isEmpty) {
            return AppBarTitle(
              isQuotation ? 'Quotation details' : 'Invoice details',
            );
          }
          return AppBarTitle(
            number,
            subtitle: isQuotation ? 'Quotation' : 'Invoice',
          );
        }),
        actions: [
          AppBarIconButton(
            tooltip: l10n('Preview PDF'),
            onPressed: controller.openPreview,
            icon: Icons.picture_as_pdf_outlined,
          ),
          Obx(() {
            final isQuotation =
                controller.invoice.value?.documentType ==
                DocumentType.quotation;
            return AppBarIconButton(
              tooltip: isQuotation ? 'Quotation actions' : 'Invoice actions',
              onPressed: () =>
                  _showDocumentActions(context, isQuotation: isQuotation),
              icon: Icons.more_vert_rounded,
            );
          }),
        ],
      ),
      bottomNavigationBar: Obx(() {
        final invoice = controller.invoice.value;
        if (controller.isLoading.value || invoice == null) {
          return const SizedBox.shrink();
        }
        return _InvoiceDetailsFooter(
          invoice: invoice,
          onRecordPayment: () => _showPaymentDialog(context),
          onShare: controller.share,
          onShareOrPrint: () => _showSharePrint(context),
        );
      }),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final invoice = controller.invoice.value;
        if (invoice == null) {
          return const Center(child: Text('Invoice not found.'));
        }
        final symbol = controller.currencySymbol.value;
        final sections = [
          _InvoiceDetailsHero(invoice: invoice),
          if (invoice.documentType == DocumentType.invoice)
            _PaymentHistoryCard(
              payments: controller.payments,
              paidMinor: invoice.calculation.paidAmountMinor,
              creditedMinor: invoice.calculation.creditedAmountMinor,
              balanceMinor: invoice.calculation.balanceDueMinor,
              totalMinor: invoice.calculation.grandTotalMinor,
              symbol: symbol,
              onReverse: (payment) => _showReversalDialog(context, payment),
              onReceipt: (payment) => Get.toNamed<void>(
                AppRoutes.paymentReceipt,
                arguments: PaymentReceiptArgs(
                  invoiceId: invoice.id!,
                  paymentId: payment.id!,
                ),
              ),
            ),
          if (invoice.documentType == DocumentType.invoice)
            _CreditNotesCard(
              notes: controller.creditNotes,
              unapplied: controller.unappliedCredits
                  .where((note) => note.invoiceId != invoice.id)
                  .toList(),
              symbol: symbol,
              canApply: invoice.calculation.balanceDueMinor > 0,
              onOpen: (note) => Get.toNamed<void>(
                AppRoutes.creditNoteDetails,
                arguments: note.id,
              ),
              onApply: (note) => _applyCredit(context, note),
            ),
          _InvoiceItemsCard(invoice: invoice, symbol: symbol),
          if (invoice.notes != null || invoice.terms != null)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (invoice.notes != null) ...[
                    Text(
                      'Notes',
                      style: AppTextStyles.listName.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      invoice.notes!,
                      style: AppTextStyles.body.copyWith(height: 1.45),
                    ),
                  ],
                  if (invoice.terms != null) ...[
                    if (invoice.notes != null) const SizedBox(height: 16),
                    Text(
                      'Terms',
                      style: AppTextStyles.listName.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      invoice.terms!,
                      style: AppTextStyles.body.copyWith(height: 1.45),
                    ),
                  ],
                ],
              ),
            ),
        ];
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveUtils.isTablet(context) ? 820 : 680,
            ),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                ResponsiveUtils.horizontalPadding(context),
                8,
                ResponsiveUtils.horizontalPadding(context),
                16,
              ),
              itemCount: sections.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, index) => sections[index],
            ),
          ),
        );
      }),
    );
  }

  Future<void> _handleAction(BuildContext context, String action) async {
    switch (action) {
      case 'edit':
        await controller.edit();
        return;
      case 'duplicate':
        await controller.duplicate();
        return;
      case 'credit':
        if (!controller.canIssueCreditNote) {
          AppNotification.warning(
            'Cannot issue credit note',
            'Credit notes can only be issued for posted invoices.',
          );
          return;
        }
        await Get.toNamed<void>(
          AppRoutes.creditNoteCreate,
          arguments: controller.invoice.value?.id,
        );
        await controller.reload();
        return;
      case 'payment':
        await _showPaymentDialog(context);
        return;
      case 'cancel':
        final confirmed = await showAppConfirmDialog(
          context: context,
          tone: AppDialogTone.warning,
          confirmIcon: Icons.block_rounded,
          title: 'Cancel invoice?',
          message: 'The invoice remains in your records but cannot be edited.',
          confirmLabel: 'Cancel invoice',
          cancelLabel: 'Back',
        );
        if (confirmed) await controller.cancel();
        return;
      case 'sent':
        await controller.setQuotationStatus(InvoiceStatus.sent);
        return;
      case 'accepted':
        await controller.setQuotationStatus(InvoiceStatus.accepted);
        return;
      case 'rejected':
        await controller.setQuotationStatus(InvoiceStatus.rejected);
        return;
      case 'convert':
        await controller.convertToInvoice();
        return;
      case 'challan':
        await controller.createDeliveryChallan();
        return;
      case 'delete':
        final confirmed = await showAppConfirmDialog(
          context: context,
          destructive: true,
          title: 'Delete invoice?',
          message: 'This permanently removes the invoice and its saved items.',
          confirmLabel: 'Delete',
          cancelLabel: 'Back',
        );
        if (confirmed) await controller.delete();
        return;
    }
  }

  Future<void> _showSharePrint(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Share / print', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.ios_share_rounded),
              title: const Text('Share PDF'),
              subtitle: const Text(
                'Send this invoice from the device share sheet.',
              ),
              onTap: () => Navigator.pop(sheetContext, 'share'),
            ),
            ListTile(
              leading: const Icon(Icons.print_outlined),
              title: const Text('Print'),
              subtitle: const Text('Send this invoice to a printer.'),
              onTap: () => Navigator.pop(sheetContext, 'print'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || selected == null) return;
    if (selected == 'share') {
      await controller.share();
    } else {
      await controller.print();
    }
  }

  Future<void> _showDocumentActions(
    BuildContext context, {
    required bool isQuotation,
  }) async {
    final actions = isQuotation
        ? const [
            ('duplicate', Icons.copy_outlined, 'Duplicate', false),
            ('sent', Icons.send_outlined, 'Mark as sent', false),
            ('accepted', Icons.check_circle_outline, 'Mark accepted', false),
            ('rejected', Icons.cancel_outlined, 'Mark rejected', false),
            (
              'convert',
              Icons.receipt_long_outlined,
              'Convert to invoice',
              false,
            ),
            (
              'challan',
              Icons.local_shipping_outlined,
              'Create delivery challan',
              false,
            ),
            ('delete', Icons.delete_outline_rounded, 'Delete quotation', true),
          ]
        : const [
            ('edit', Icons.edit_outlined, 'Edit invoice', false),
            ('duplicate', Icons.copy_outlined, 'Duplicate invoice', false),
            (
              'credit',
              Icons.assignment_return_outlined,
              'Credit note / Sales return',
              false,
            ),
            (
              'challan',
              Icons.local_shipping_outlined,
              'Create delivery for remaining quantity',
              false,
            ),
            ('payment', Icons.payments_outlined, 'Update payment', false),
            ('cancel', Icons.block_outlined, 'Cancel invoice', true),
            ('delete', Icons.delete_outline_rounded, 'Delete invoice', true),
          ];
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isQuotation ? 'Quotation actions' : 'Invoice actions',
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 8),
            ...actions.map(
              (action) => ListTile(
                textColor: action.$4 ? AppColors.error : null,
                iconColor: action.$4 ? AppColors.error : null,
                leading: Icon(action.$2),
                title: Text(action.$3),
                onTap: () => Navigator.pop(sheetContext, action.$1),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null && context.mounted) {
      await _handleAction(context, selected);
    }
  }

  Future<void> _showPaymentDialog(BuildContext context) async {
    final invoice = controller.invoice.value;
    if (invoice == null || invoice.status == InvoiceStatus.cancelled) return;
    final payment = await showModalBottomSheet<InvoicePaymentModel>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PaymentSheet(invoice: invoice, controller: controller),
    );
    // Re-read after the modal route is fully removed so the visible route
    // always paints the latest status, balance, and payment activity.
    await controller.reload();
    if (payment?.id != null && context.mounted) {
      await Get.toNamed<void>(
        AppRoutes.paymentReceipt,
        arguments: PaymentReceiptArgs(
          invoiceId: invoice.id!,
          paymentId: payment!.id!,
        ),
      );
    }
  }

  Future<void> _showReversalDialog(
    BuildContext context,
    InvoicePaymentModel payment,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _PaymentReversalDialog(payment: payment),
    );
    if (result == null) return;
    final error = await controller.reversePayment(payment, result);
    if (error != null) {
      AppNotification.warning('Cannot reverse payment', error);
    } else {
      AppNotification.success(
        'Payment reversed',
        'The invoice balance and status were updated.',
      );
    }
  }

  Future<void> _applyCredit(
    BuildContext context,
    CreditNoteSummaryModel note,
  ) async {
    final invoice = controller.invoice.value;
    if (invoice == null) return;
    final amount = note.unappliedMinor < invoice.calculation.balanceDueMinor
        ? note.unappliedMinor
        : invoice.calculation.balanceDueMinor;
    if (amount <= 0) return;
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Apply customer credit?',
      message:
          'Apply ${CurrencyUtils.formatMinor(amount, symbol: controller.currencySymbol.value)} from ${note.creditNoteNumber} to this invoice.',
      confirmLabel: 'Apply credit',
      confirmIcon: Icons.assignment_return_outlined,
    );
    if (!confirmed) return;
    final error = await controller.applyCustomerCredit(note, amount);
    if (error != null) {
      AppNotification.warning('Cannot apply credit', error);
    } else {
      AppNotification.success(
        'Credit applied',
        'The invoice balance was updated.',
      );
    }
  }
}

class _InvoiceDetailsFooter extends StatelessWidget {
  const _InvoiceDetailsFooter({
    required this.invoice,
    required this.onRecordPayment,
    required this.onShare,
    required this.onShareOrPrint,
  });

  final InvoiceModel invoice;
  final VoidCallback onRecordPayment;
  final VoidCallback onShare;
  final VoidCallback onShareOrPrint;

  bool get _canRecordPayment =>
      invoice.documentType == DocumentType.invoice &&
      invoice.status != InvoiceStatus.cancelled &&
      invoice.calculation.balanceDueMinor > 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: AppConstrainedAction(
          maxWidth: ResponsiveUtils.footerMaxWidth(context),
          child: Row(
            children: [
              if (_canRecordPayment) ...[
                Expanded(
                  flex: 3,
                  child: AppButton(
                    label: l10n('Record payment'),
                    icon: Icons.payments_outlined,
                    onPressed: onRecordPayment,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: _canRecordPayment ? 2 : 3,
                child: _canRecordPayment
                    ? AppOutlinedButton(
                        label: l10n('Share'),
                        icon: Icons.ios_share_rounded,
                        onPressed: onShare,
                      )
                    : AppButton(
                        label: l10n('Share / print'),
                        icon: Icons.ios_share_rounded,
                        onPressed: onShareOrPrint,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceDetailsHero extends StatelessWidget {
  const _InvoiceDetailsHero({required this.invoice});

  final InvoiceModel invoice;

  bool get _isQuotation => invoice.documentType == DocumentType.quotation;

  List<Color> get _colors {
    if (_isQuotation) {
      return switch (invoice.status) {
        InvoiceStatus.accepted => const [
          AppColors.secondary,
          AppColors.success,
        ],
        InvoiceStatus.rejected ||
        InvoiceStatus.expired => const [AppColors.secondary, AppColors.error],
        _ => const [AppColors.secondary, AppColors.primary],
      };
    }
    return switch (invoice.status) {
      InvoiceStatus.paid => const [AppColors.secondary, AppColors.success],
      InvoiceStatus.overdue => const [AppColors.secondary, AppColors.error],
      InvoiceStatus.cancelled => const [Color(0xFF4A2A45), AppColors.secondary],
      _ => const [AppColors.secondary, AppColors.primary],
    };
  }

  String get _taxLabel => switch (invoice.taxType) {
    TaxType.none => 'No GST',
    TaxType.cgstSgst => 'CGST + SGST',
    TaxType.igst => 'IGST',
  };

  String? get _dueCaption {
    final due = invoice.dueDate;
    if (due == null) return null;
    if (invoice.status == InvoiceStatus.paid ||
        invoice.status == InvoiceStatus.accepted ||
        invoice.status == InvoiceStatus.cancelled) {
      return null;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final days = dueDay.difference(today).inDays;
    if (days < 0) {
      final overdue = days.abs();
      return overdue == 1 ? '1 day overdue' : '$overdue days overdue';
    }
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return '${l10n('Due in')} $days ${l10n('days')}';
  }

  void _openCustomer() {
    final customerId = invoice.customer.customerId;
    if (customerId == null) return;
    Get.toNamed<void>(AppRoutes.customerDetails, arguments: customerId);
  }

  @override
  Widget build(BuildContext context) {
    final customer = invoice.customer;
    final subtitle = [
      if (customer.companyName != null) customer.companyName!,
      if (customer.mobile != null) customer.mobile!,
      if (customer.gstin != null) 'GSTIN ${customer.gstin!}',
    ].join(' • ');
    final canOpen = customer.customerId != null;
    final dueCaption = _dueCaption;
    final meta = [
      l10n(_taxLabel),
      '${invoice.items.length} ${invoice.items.length == 1 ? l10n('item') : l10n('items')}',
    ].join('  •  ');
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .14)),
        boxShadow: [
          BoxShadow(
            color: _colors.first.withValues(alpha: .2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -40,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: .78),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AppStatusChip(status: invoice.status, compact: true),
                ],
              ),
              const SizedBox(height: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: canOpen ? _openCustomer : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .16),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .2),
                            ),
                          ),
                          child: Text(
                            customer.name.trim().isEmpty
                                ? '?'
                                : customer.name.characters.first.toUpperCase(),
                            style: AppTextStyles.listName.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Billed to',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white.withValues(alpha: .7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                customer.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.listName.copyWith(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                ),
                              ),
                              if (subtitle.isNotEmpty) ...[
                                const SizedBox(height: 1),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white.withValues(alpha: .78),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (canOpen)
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: Colors.white.withValues(alpha: .8),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _HeroMeta(
                      icon: Icons.calendar_today_outlined,
                      label: l10n('Issued'),
                      value: _date(invoice.invoiceDate),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _HeroMeta(
                      icon: Icons.event_available_outlined,
                      label: l10n(_isQuotation ? 'Valid until' : 'Due'),
                      value: invoice.dueDate == null
                          ? 'Not set'
                          : _date(invoice.dueDate!),
                    ),
                  ),
                ],
              ),
              if (dueCaption != null) ...[
                const SizedBox(height: 8),
                Text(
                  dueCaption,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: .88),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: .14)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: .9)),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withValues(alpha: .7),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.small.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _InvoiceItemsCard extends StatelessWidget {
  const _InvoiceItemsCard({required this.invoice, required this.symbol});

  final InvoiceModel invoice;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final result = invoice.calculation;
    final showAttributes =
        Get.find<ProductSettingsService>().showAttributesOnInvoice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Line items',
                  style: AppTextStyles.listName.copyWith(fontSize: 15),
                ),
              ),
              Text(
                '${invoice.items.length} ${invoice.items.length == 1 ? 'item' : 'items'}',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              if (invoice.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    'No items yet',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                ...invoice.items.asMap().entries.map((entry) {
                  final item = entry.value;
                  final total = result.items[entry.key].totalMinor;
                  final isLast = entry.key == invoice.items.length - 1;
                  return Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    decoration: isLast
                        ? null
                        : const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppColors.border),
                            ),
                          ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            '${entry.key + 1}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: AppTextStyles.listName),
                              if (showAttributes &&
                                  item.attributes.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  ProductAttributeUtils.compact(
                                    item.attributes,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.small.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                '${QuantityUtils.toInputValue(item.quantityScaled)} ${item.unit} × ${CurrencyUtils.formatMinor(item.rateMinor, symbol: symbol)}',
                                style: AppTextStyles.small.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        AppAmountColumn(
                          maxWidth: 128,
                          children: [
                            AppAmountText(
                              amountMinor: total,
                              symbol: symbol,
                              style: AppTextStyles.listAmount,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.surfaceSoft,
                  border: const Border(
                    top: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Column(
                  children: [
                    _TotalsRow(
                      label: l10n('Subtotal'),
                      amount: result.subtotalMinor,
                      symbol: symbol,
                    ),
                    if (result.itemDiscountTotalMinor > 0)
                      _TotalsRow(
                        label: l10n('Item discounts'),
                        amount: -result.itemDiscountTotalMinor,
                        symbol: symbol,
                      ),
                    if (result.invoiceDiscountMinor > 0)
                      _TotalsRow(
                        label: l10n('Invoice discount'),
                        amount: -result.invoiceDiscountMinor,
                        symbol: symbol,
                      ),
                    if (result.cgstMinor > 0)
                      _TotalsRow(
                        label: l10n('CGST'),
                        amount: result.cgstMinor,
                        symbol: symbol,
                      ),
                    if (result.sgstMinor > 0)
                      _TotalsRow(
                        label: l10n('SGST'),
                        amount: result.sgstMinor,
                        symbol: symbol,
                      ),
                    if (result.igstMinor > 0)
                      _TotalsRow(
                        label: l10n('IGST'),
                        amount: result.igstMinor,
                        symbol: symbol,
                      ),
                    if (invoice.charges.isNotEmpty)
                      ...invoice.charges
                          .where((charge) => charge.amountMinor != 0)
                          .map(
                            (charge) => _TotalsRow(
                              label: charge.title,
                              amount: charge.amountMinor,
                              symbol: symbol,
                            ),
                          )
                    else if (result.additionalChargeTotalMinor > 0)
                      _TotalsRow(
                        label: l10n('Additional charges'),
                        amount: result.additionalChargeTotalMinor,
                        symbol: symbol,
                      ),
                    if (result.roundOffMinor != 0)
                      _TotalsRow(
                        label: l10n('Round off'),
                        amount: result.roundOffMinor,
                        symbol: symbol,
                      ),
                    const SizedBox(height: 8),
                    _TotalsRow(
                      label: l10n('Grand total'),
                      amount: result.grandTotalMinor,
                      symbol: symbol,
                      prominent: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({
    required this.label,
    required this.amount,
    required this.symbol,
    this.prominent = false,
  });

  final String label;
  final int amount;
  final String symbol;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: prominent
                  ? AppTextStyles.listName
                  : AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
            ),
          ),
          AppAmountColumn(
            maxWidth: 148,
            children: [
              AppAmountText(
                amountMinor: amount,
                symbol: symbol,
                style: prominent
                    ? AppTextStyles.listAmount
                    : AppTextStyles.small.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({required this.invoice, required this.controller});

  final InvoiceModel invoice;
  final InvoiceDetailsController controller;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentHistoryCard extends StatelessWidget {
  const _PaymentHistoryCard({
    required this.payments,
    required this.paidMinor,
    required this.creditedMinor,
    required this.balanceMinor,
    required this.totalMinor,
    required this.symbol,
    required this.onReverse,
    required this.onReceipt,
  });

  final List<InvoicePaymentModel> payments;
  final int paidMinor;
  final int creditedMinor;
  final int balanceMinor;
  final int totalMinor;
  final String symbol;
  final ValueChanged<InvoicePaymentModel> onReverse;
  final ValueChanged<InvoicePaymentModel> onReceipt;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveUtils.isTablet(context);
    final remainingColor = balanceMinor > 0
        ? AppColors.warning
        : AppColors.success;
    final remainingFill = balanceMinor > 0
        ? AppColors.warningLight
        : AppColors.successLight;
    final metrics = [
      _PaymentMetricCard(
        label: l10n('Total'),
        amount: totalMinor,
        symbol: symbol,
        color: AppColors.secondary,
        fill: AppColors.secondaryLight,
      ),
      _PaymentMetricCard(
        label: l10n('Paid'),
        amount: paidMinor,
        symbol: symbol,
        color: AppColors.success,
        fill: AppColors.successLight,
      ),
      if (creditedMinor > 0)
        _PaymentMetricCard(
          label: l10n('Credited'),
          amount: creditedMinor,
          symbol: symbol,
          color: AppColors.secondary,
          fill: AppColors.secondaryLight,
        ),
      _PaymentMetricCard(
        label: l10n('Remaining'),
        amount: balanceMinor,
        symbol: symbol,
        color: remainingColor,
        fill: remainingFill,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Payment activity',
                  style: AppTextStyles.listName.copyWith(fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${payments.length} ${payments.length == 1 ? 'entry' : 'entries'}',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        AppCard(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            children: [
              if (isTablet)
                Row(
                  children: [
                    for (var i = 0; i < metrics.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: metrics[i]),
                    ],
                  ],
                )
              else ...[
                metrics[0],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: metrics[1]),
                    const SizedBox(width: 10),
                    Expanded(child: metrics[2]),
                  ],
                ),
                if (metrics.length > 3) ...[
                  const SizedBox(height: 10),
                  metrics[3],
                ],
              ],
              if (payments.isNotEmpty) ...[
                const SizedBox(height: 4),
                const Divider(height: 20),
                ...payments.map(
                  (payment) => _PaymentHistoryRow(
                    payment: payment,
                    symbol: symbol,
                    onReverse: payment.canReverse
                        ? () => onReverse(payment)
                        : null,
                    onReceipt: payment.amountMinor > 0 && !payment.isReversed
                        ? () => onReceipt(payment)
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentMetricCard extends StatelessWidget {
  const _PaymentMetricCard({
    required this.label,
    required this.amount,
    required this.symbol,
    required this.color,
    required this.fill,
  });

  final String label;
  final int amount;
  final String symbol;
  final Color color;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: .18) : fill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          AppAmountText(
            amountMinor: amount,
            symbol: symbol,
            color: color,
            textAlign: TextAlign.start,
            style: AppTextStyles.listAmount.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _PaymentHistoryRow extends StatelessWidget {
  const _PaymentHistoryRow({
    required this.payment,
    required this.symbol,
    this.onReverse,
    this.onReceipt,
  });

  final InvoicePaymentModel payment;
  final String symbol;
  final VoidCallback? onReverse;
  final VoidCallback? onReceipt;

  @override
  Widget build(BuildContext context) {
    final detail = [
      if (payment.reference?.isNotEmpty ?? false) 'Ref ${payment.reference}',
      if (payment.note?.isNotEmpty ?? false) payment.note!,
    ].join(' • ');
    final isCorrection = payment.isReversal;
    return Padding(
      padding: const EdgeInsets.only(top: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isCorrection
                  ? AppColors.errorLight
                  : AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCorrection ? Icons.undo_rounded : Icons.payments_outlined,
              size: 17,
              color: isCorrection ? AppColors.error : AppColors.success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.entryType == InvoicePaymentEntryType.reversal
                      ? 'Payment reversal'
                      : payment.entryType == InvoicePaymentEntryType.opening
                      ? 'Opening payment'
                      : payment.entryType == InvoicePaymentEntryType.imported
                      ? 'Previous payment'
                      : payment.entryType == InvoicePaymentEntryType.advance
                      ? 'Applied from advance'
                      : payment.method ?? 'Payment',
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  _dateTime(payment.paidAt),
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyUtils.formatMinor(payment.amountMinor, symbol: symbol),
                style: AppTextStyles.cardTitle.copyWith(
                  fontSize: 14,
                  color: isCorrection ? AppColors.error : AppColors.success,
                ),
              ),
              if (onReceipt != null || onReverse != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onReceipt != null)
                      IconButton(
                        tooltip: l10n('Open receipt'),
                        visualDensity: VisualDensity.compact,
                        onPressed: onReceipt,
                        icon: const Icon(Icons.receipt_long_outlined, size: 18),
                      ),
                    if (onReverse != null)
                      IconButton(
                        tooltip: l10n('Reverse payment'),
                        visualDensity: VisualDensity.compact,
                        onPressed: onReverse,
                        icon: const Icon(Icons.undo_rounded, size: 18),
                      ),
                  ],
                ),
            ],
          ),
          if (payment.isReversed)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text(
                'REVERSED',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentReversalDialog extends StatefulWidget {
  const _PaymentReversalDialog({required this.payment});

  final InvoicePaymentModel payment;

  @override
  State<_PaymentReversalDialog> createState() => _PaymentReversalDialogState();
}

class _PaymentReversalDialogState extends State<_PaymentReversalDialog> {
  final reason = TextEditingController();
  String? error;

  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  void _submit() {
    final value = reason.text.trim();
    if (value.isEmpty) {
      setState(() => error = 'A reason is required for the audit history.');
      return;
    }
    AppFocus.pop(context, value);
  }

  @override
  Widget build(BuildContext context) => AppDialog(
    tone: AppDialogTone.warning,
    icon: Icons.undo_rounded,
    form: true,
    scrollable: true,
    title: const Text('Reverse payment?'),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'This keeps the original payment and adds a linked reversal. The invoice balance and status will be recalculated.',
        ),
        const SizedBox(height: 14),
        TextField(
          controller: reason,
          autofocus: true,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n('Reversal reason *'),
            hintText: l10n('e.g. Payment entered twice'),
            errorText: error,
          ),
        ),
      ],
    ),
    actions: [
      AppDialogButton(
        label: l10n('Keep payment'),
        variant: AppDialogButtonVariant.outlined,
        onPressed: () => AppFocus.pop(context),
      ),
      AppDialogButton(
        label: l10n('Reverse payment'),
        icon: Icons.undo_rounded,
        onPressed: _submit,
      ),
    ],
  );
}

class _PaymentSheetState extends State<_PaymentSheet> {
  late final TextEditingController input;
  late final TextEditingController reference;
  late final TextEditingController note;
  String method = 'UPI';
  int? accountId;
  List<MoneyAccountModel> accounts = const [];
  String? error;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    method = Get.isRegistered<InvoiceDefaultsService>()
        ? Get.find<InvoiceDefaultsService>().paymentMethod
        : 'UPI';
    input = TextEditingController();
    reference = TextEditingController();
    note = TextEditingController();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    if (!Get.isRegistered<CashBookRepository>()) return;
    final rows = await Get.find<CashBookRepository>().activeAccounts();
    if (!mounted) return;
    setState(() {
      accounts = rows;
      accountId = rows
          .where(
            (account) =>
                account.accountType == MoneyAccountTypeX.fromMethod(method),
          )
          .firstOrNull
          ?.id;
      accountId ??= rows.firstOrNull?.id;
    });
  }

  @override
  void dispose() {
    input.dispose();
    reference.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    final symbol = widget.controller.currencySymbol.value;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Record payment', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 6),
            Text(
              'Add the payment received now. Previous entries stay in history.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _PaymentRow(
              label: l10n('Invoice total'),
              amount: invoice.calculation.grandTotalMinor,
              symbol: symbol,
            ),
            _PaymentRow(
              label: l10n('Already paid'),
              amount: invoice.calculation.paidAmountMinor,
              symbol: symbol,
            ),
            if (invoice.calculation.creditedAmountMinor > 0)
              _PaymentRow(
                label: l10n('Credited'),
                amount: invoice.calculation.creditedAmountMinor,
                symbol: symbol,
              ),
            _PaymentRow(
              label: l10n('Balance due'),
              amount: invoice.calculation.balanceDueMinor,
              symbol: symbol,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: input,
              autofocus: true,
              enabled: !isSaving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n('Amount received now'),
                prefixText: '$symbol ',
                helperText: l10n(
                  'Remaining: ${CurrencyUtils.formatMinor(invoice.calculation.balanceDueMinor, symbol: symbol)}',
                ),
                errorText: error,
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            AppDropdownField<String>(
              label: l10n('Payment method'),
              sheetTitle: 'How was this payment received?',
              prefixIcon: Icons.account_balance_wallet_outlined,
              value: method,
              enabled: !isSaving,
              options: [
                AppDropdownOption(
                  value: 'UPI',
                  label: l10n('UPI'),
                  icon: Icons.qr_code_2_rounded,
                ),
                AppDropdownOption(
                  value: 'Cash',
                  label: l10n('Cash'),
                  icon: Icons.payments_outlined,
                ),
                AppDropdownOption(
                  value: 'Bank transfer',
                  label: l10n('Bank transfer'),
                  icon: Icons.account_balance_outlined,
                ),
                AppDropdownOption(
                  value: 'Card',
                  label: l10n('Card'),
                  icon: Icons.credit_card_rounded,
                ),
                AppDropdownOption(
                  value: 'Cheque',
                  label: l10n('Cheque'),
                  icon: Icons.receipt_long_outlined,
                ),
                AppDropdownOption(
                  value: 'Other',
                  label: l10n('Other'),
                  icon: Icons.more_horiz_rounded,
                ),
              ],
              onChanged: (value) => setState(() {
                method = value;
                accountId = accounts
                    .where(
                      (account) =>
                          account.accountType ==
                          MoneyAccountTypeX.fromMethod(value),
                    )
                    .firstOrNull
                    ?.id;
                accountId ??= accounts.firstOrNull?.id;
              }),
            ),
            if (accounts.length > 1) ...[
              const SizedBox(height: 12),
              AppDropdownField<int>(
                label: l10n('Account'),
                sheetTitle: 'Cash-book account',
                value: accountId ?? accounts.first.id!,
                options: [
                  for (final account in accounts)
                    AppDropdownOption(
                      value: account.id!,
                      label: account.name,
                      icon: account.accountType.icon,
                    ),
                ],
                onChanged: (value) => setState(() => accountId = value),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: reference,
              enabled: !isSaving,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n('Reference number (optional)'),
                prefixIcon: Icon(Icons.tag_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              enabled: !isSaving,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n('Note (optional)'),
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isSaving
                  ? null
                  : () {
                      final remaining = CurrencyUtils.toInputValue(
                        invoice.calculation.balanceDueMinor,
                      );
                      input.value = TextEditingValue(
                        text: remaining,
                        selection: TextSelection.collapsed(
                          offset: remaining.length,
                        ),
                      );
                      setState(() => error = null);
                    },
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text(
                'Mark as fully paid • ${CurrencyUtils.formatMinor(invoice.calculation.balanceDueMinor, symbol: symbol)}',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: isSaving ? null : () => AppFocus.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    onPressed: isSaving ? null : _save,
                    label: l10n('Save payment'),
                    isLoading: isSaving,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      isSaving = true;
      error = null;
    });
    final validation = await widget.controller.recordPayment(
      input.text,
      method: method,
      accountId: accountId,
      reference: reference.text,
      note: note.text,
    );
    if (!mounted) return;
    if (validation == null) {
      await AppFocus.pop(context, widget.controller.lastRecordedPayment.value);
      return;
    }
    setState(() {
      isSaving = false;
      error = validation;
    });
  }
}

class _CreditNotesCard extends StatelessWidget {
  const _CreditNotesCard({
    required this.notes,
    required this.unapplied,
    required this.symbol,
    required this.canApply,
    required this.onOpen,
    required this.onApply,
  });

  final List<CreditNoteSummaryModel> notes;
  final List<CreditNoteSummaryModel> unapplied;
  final String symbol;
  final bool canApply;
  final ValueChanged<CreditNoteSummaryModel> onOpen;
  final ValueChanged<CreditNoteSummaryModel> onApply;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty && unapplied.isEmpty) return const SizedBox.shrink();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Credit notes', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          for (final note in notes)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(note.creditNoteNumber),
              subtitle: Text(note.reason),
              trailing: Text(
                CurrencyUtils.formatMinor(note.grandTotalMinor, symbol: symbol),
              ),
              onTap: () => onOpen(note),
            ),
          if (canApply && unapplied.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Customer credit', style: AppTextStyles.cardTitle),
            for (final note in unapplied)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(note.creditNoteNumber),
                subtitle: Text(
                  'Available ${CurrencyUtils.formatMinor(note.unappliedMinor, symbol: symbol)}',
                ),
                trailing: TextButton(
                  onPressed: () => onApply(note),
                  child: const Text('Apply'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _dateTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '${_date(value)} • $hour:$minute $period';
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.label,
    required this.amount,
    required this.symbol,
  });
  final String label;
  final int amount;
  final String symbol;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          CurrencyUtils.formatMinor(amount, symbol: symbol),
          style: AppTextStyles.cardTitle,
        ),
      ],
    ),
  );
}
