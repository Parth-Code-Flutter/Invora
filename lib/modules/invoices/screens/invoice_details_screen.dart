import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/enums/invoice_status.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/app_focus.dart';
import '../../../app/utils/quantity_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_status_chip.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/invoice_payment_model.dart';
import '../controllers/invoice_details_controller.dart';

class InvoiceDetailsScreen extends GetView<InvoiceDetailsController> {
  const InvoiceDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Obx(
          () => Text(
            controller.invoice.value?.documentType == DocumentType.quotation
                ? 'Quotation details'
                : 'Invoice details',
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Preview PDF',
            onPressed: controller.openPreview,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          Obx(() {
            final isQuotation =
                controller.invoice.value?.documentType ==
                DocumentType.quotation;
            return PopupMenuButton<String>(
              onSelected: (action) => _handleAction(context, action),
              itemBuilder: (_) => isQuotation
                  ? const [
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Text('Duplicate'),
                      ),
                      PopupMenuItem(value: 'sent', child: Text('Mark sent')),
                      PopupMenuItem(
                        value: 'accepted',
                        child: Text('Mark accepted'),
                      ),
                      PopupMenuItem(
                        value: 'rejected',
                        child: Text('Mark rejected'),
                      ),
                      PopupMenuItem(
                        value: 'convert',
                        child: Text('Convert to invoice'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete quotation'),
                      ),
                    ]
                  : const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Text('Duplicate'),
                      ),
                      PopupMenuItem(
                        value: 'payment',
                        child: Text('Update payment'),
                      ),
                      PopupMenuItem(
                        value: 'cancel',
                        child: Text('Cancel invoice'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete invoice'),
                      ),
                    ],
            );
          }),
        ],
      ),
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
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.secondary,
                  AppColors.primaryDark,
                  Color(0xFF176F69),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x285B5CE2),
                  blurRadius: 22,
                  offset: Offset(0, 9),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        invoice.invoiceNumber,
                        style: AppTextStyles.pageTitle.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    AppStatusChip(status: invoice.status),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  invoice.calculation.balanceDueMinor > 0
                      ? 'Balance due'
                      : 'Invoice total',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: .84),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  CurrencyUtils.formatMinor(
                    invoice.calculation.balanceDueMinor > 0
                        ? invoice.calculation.balanceDueMinor
                        : invoice.calculation.grandTotalMinor,
                    symbol: symbol,
                  ),
                  style: AppTextStyles.displayAmount.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${CurrencyUtils.formatMinor(invoice.calculation.grandTotalMinor, symbol: symbol)} total  •  ${CurrencyUtils.formatMinor(invoice.calculation.paidAmountMinor, symbol: symbol)} paid',
                  style: AppTextStyles.small.copyWith(
                    color: Colors.white.withValues(alpha: .9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _HeroDate(
                        icon: Icons.calendar_today_outlined,
                        label: 'Issued',
                        value: _date(invoice.invoiceDate),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroDate(
                        icon: Icons.event_available_outlined,
                        label: 'Due',
                        value: invoice.dueDate == null
                            ? 'Not set'
                            : _date(invoice.dueDate!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child:
                    invoice.documentType == DocumentType.invoice &&
                        invoice.status != InvoiceStatus.cancelled &&
                        invoice.calculation.balanceDueMinor > 0
                    ? AppButton(
                        label: 'Record payment',
                        icon: Icons.payments_outlined,
                        onPressed: () => _showPaymentDialog(context),
                      )
                    : AppButton(
                        label: 'Share / print',
                        icon: Icons.ios_share_rounded,
                        onPressed: controller.openPreview,
                      ),
              ),
              if (invoice.documentType == DocumentType.invoice &&
                  invoice.status != InvoiceStatus.cancelled &&
                  invoice.calculation.balanceDueMinor > 0) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.openPreview,
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ],
          ),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    invoice.customer.name.trim().isEmpty
                        ? '?'
                        : invoice.customer.name.characters.first.toUpperCase(),
                    style: AppTextStyles.cardTitle.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.customer.name,
                        style: AppTextStyles.cardTitle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (invoice.customer.companyName != null)
                            invoice.customer.companyName!,
                          if (invoice.customer.mobile != null)
                            invoice.customer.mobile!,
                          if (invoice.customer.gstin != null)
                            'GSTIN ${invoice.customer.gstin!}',
                        ].join(' • '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.person_outline_rounded,
                  size: 21,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
          if (invoice.documentType == DocumentType.invoice &&
              (controller.payments.isNotEmpty ||
                  invoice.calculation.paidAmountMinor > 0))
            _PaymentHistoryCard(
              payments: controller.payments,
              paidMinor: invoice.calculation.paidAmountMinor,
              balanceMinor: invoice.calculation.balanceDueMinor,
              totalMinor: invoice.calculation.grandTotalMinor,
              symbol: symbol,
            ),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Items', style: AppTextStyles.sectionTitle),
                    ),
                    Text(
                      '${invoice.items.length} ${invoice.items.length == 1 ? 'item' : 'items'}',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ...invoice.items.asMap().entries.map((entry) {
                  final item = entry.value;
                  final total = invoice.calculation.items[entry.key].totalMinor;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: entry.key == invoice.items.length - 1
                        ? null
                        : const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppColors.border),
                            ),
                          ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${entry.key + 1}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: AppTextStyles.cardTitle),
                              const SizedBox(height: 3),
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
                        Text(
                          CurrencyUtils.formatMinor(total, symbol: symbol),
                          style: AppTextStyles.cardTitle,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          if (invoice.notes != null || invoice.terms != null)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (invoice.notes != null) ...[
                    Text('Notes', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 6),
                    Text(invoice.notes!),
                  ],
                  if (invoice.terms != null) ...[
                    const SizedBox(height: 16),
                    Text('Terms', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 6),
                    Text(invoice.terms!),
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
                12,
                ResponsiveUtils.horizontalPadding(context),
                28,
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
      case 'payment':
        await _showPaymentDialog(context);
        return;
      case 'cancel':
        final confirmed = await _confirm(
          context,
          title: 'Cancel invoice?',
          message: 'The invoice remains in your records but cannot be edited.',
          action: 'Cancel invoice',
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
      case 'delete':
        final confirmed = await _confirm(
          context,
          title: 'Delete invoice?',
          message: 'This permanently removes the invoice and its saved items.',
          action: 'Delete',
        );
        if (confirmed) await controller.delete();
        return;
    }
  }

  Future<void> _showPaymentDialog(BuildContext context) async {
    final invoice = controller.invoice.value;
    if (invoice == null || invoice.status == InvoiceStatus.cancelled) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PaymentSheet(invoice: invoice, controller: controller),
    );
    // Re-read after the modal route is fully removed so the visible route
    // always paints the latest status, balance, and payment activity.
    await controller.reload();
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Back'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
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
    required this.balanceMinor,
    required this.totalMinor,
    required this.symbol,
  });

  final List<InvoicePaymentModel> payments;
  final int paidMinor;
  final int balanceMinor;
  final int totalMinor;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final progress = totalMinor <= 0
        ? 0.0
        : (paidMinor / totalMinor).clamp(0.0, 1.0);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Payment activity',
                  style: AppTextStyles.sectionTitle,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${payments.length} ${payments.length == 1 ? 'payment' : 'payments'}',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PaymentMetric(
                  label: 'Paid',
                  value: CurrencyUtils.formatMinor(paidMinor, symbol: symbol),
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PaymentMetric(
                  label: 'Remaining',
                  value: CurrencyUtils.formatMinor(
                    balanceMinor,
                    symbol: symbol,
                  ),
                  color: balanceMinor > 0
                      ? AppColors.warning
                      : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: AppColors.surfaceMuted,
              color: AppColors.success,
            ),
          ),
          if (payments.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            ...payments.map(
              (payment) => _PaymentHistoryRow(payment: payment, symbol: symbol),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentMetric extends StatelessWidget {
  const _PaymentMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.cardTitle.copyWith(color: color),
        ),
      ],
    ),
  );
}

class _PaymentHistoryRow extends StatelessWidget {
  const _PaymentHistoryRow({required this.payment, required this.symbol});

  final InvoicePaymentModel payment;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final detail = [
      if (payment.reference?.isNotEmpty ?? false) 'Ref ${payment.reference}',
      if (payment.note?.isNotEmpty ?? false) payment.note!,
    ].join(' • ');
    final isCorrection = payment.amountMinor < 0;
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
                  payment.method ?? 'Payment',
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
          const SizedBox(width: 10),
          Text(
            CurrencyUtils.formatMinor(payment.amountMinor, symbol: symbol),
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: 14,
              color: isCorrection ? AppColors.error : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSheetState extends State<_PaymentSheet> {
  late final TextEditingController input;
  late final TextEditingController reference;
  late final TextEditingController note;
  String method = 'UPI';
  String? error;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    input = TextEditingController();
    reference = TextEditingController();
    note = TextEditingController();
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
              label: 'Invoice total',
              amount: invoice.calculation.grandTotalMinor,
              symbol: symbol,
            ),
            _PaymentRow(
              label: 'Already paid',
              amount: invoice.calculation.paidAmountMinor,
              symbol: symbol,
            ),
            _PaymentRow(
              label: 'Balance due',
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
                labelText: 'Amount received now',
                prefixText: '$symbol ',
                helperText:
                    'Remaining: ${CurrencyUtils.formatMinor(invoice.calculation.balanceDueMinor, symbol: symbol)}',
                errorText: error,
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: method,
              decoration: const InputDecoration(
                labelText: 'Payment method',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                DropdownMenuItem(
                  value: 'Bank transfer',
                  child: Text('Bank transfer'),
                ),
                DropdownMenuItem(value: 'Card', child: Text('Card')),
                DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: isSaving
                  ? null
                  : (value) => setState(() => method = value ?? 'Other'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reference,
              enabled: !isSaving,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Reference number (optional)',
                prefixIcon: Icon(Icons.tag_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              enabled: !isSaving,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
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
                    label: 'Save payment',
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
      reference: reference.text,
      note: note.text,
    );
    if (!mounted) return;
    if (validation == null) {
      await AppFocus.pop(context);
      return;
    }
    setState(() {
      isSaving = false;
      error = validation;
    });
  }
}

class _HeroDate extends StatelessWidget {
  const _HeroDate({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: .88)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.small.copyWith(
                  color: Colors.white.withValues(alpha: .78),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    ),
  );
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
