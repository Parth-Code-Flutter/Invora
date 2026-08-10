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
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.secondary,
                  AppColors.primary,
                  AppColors.accent,
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
                const SizedBox(height: 18),
                Text(
                  invoice.calculation.balanceDueMinor > 0
                      ? 'Balance due'
                      : 'Invoice total',
                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
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
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _HeroDate(
                          label: 'ISSUED',
                          value: _date(invoice.invoiceDate),
                        ),
                      ),
                      Container(width: 1, height: 30, color: Colors.white24),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _HeroDate(
                          label: 'DUE',
                          value: invoice.dueDate == null
                              ? 'Not set'
                              : _date(invoice.dueDate!),
                        ),
                      ),
                    ],
                  ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        invoice.customer.name.trim().isEmpty
                            ? '?'
                            : invoice.customer.name.characters.first
                                  .toUpperCase(),
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
                          if (invoice.customer.companyName != null)
                            Text(
                              invoice.customer.companyName!,
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
                if (invoice.customer.mobile != null ||
                    invoice.customer.gstin != null) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (invoice.customer.mobile != null)
                        _InfoPill(
                          icon: Icons.phone_outlined,
                          label: invoice.customer.mobile!,
                        ),
                      if (invoice.customer.gstin != null)
                        _InfoPill(
                          icon: Icons.receipt_long_outlined,
                          label: invoice.customer.gstin!,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Items', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 8),
                ...invoice.items.asMap().entries.map((entry) {
                  final item = entry.value;
                  final total = invoice.calculation.items[entry.key].totalMinor;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
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
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _row(
                  'Grand total',
                  invoice.calculation.grandTotalMinor,
                  symbol,
                ),
                _row('Paid', invoice.calculation.paidAmountMinor, symbol),
                const Divider(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: invoice.calculation.balanceDueMinor > 0
                        ? AppColors.warningLight
                        : AppColors.successLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _row(
                    invoice.calculation.balanceDueMinor > 0
                        ? 'Balance due'
                        : 'Fully paid',
                    invoice.calculation.balanceDueMinor,
                    symbol,
                    color: invoice.calculation.balanceDueMinor > 0
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                ),
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

class _PaymentSheetState extends State<_PaymentSheet> {
  late final TextEditingController input;
  String? error;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    input = TextEditingController(
      text: CurrencyUtils.toInputValue(
        widget.invoice.calculation.paidAmountMinor,
      ),
    );
  }

  @override
  void dispose() {
    input.dispose();
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
              'Update the total amount received for this invoice.',
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
                labelText: 'Total amount paid',
                prefixText: '$symbol ',
                helperText: 'Enter the total received so far.',
                errorText: error,
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isSaving
                  ? null
                  : () {
                      input.text = CurrencyUtils.toInputValue(
                        invoice.calculation.grandTotalMinor,
                      );
                      setState(() => error = null);
                    },
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Mark as fully paid'),
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
                  child: FilledButton(
                    onPressed: isSaving ? null : _save,
                    child: isSaving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save payment'),
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
    final validation = await widget.controller.updatePayment(input.text);
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
  const _HeroDate({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white60)),
      const SizedBox(height: 3),
      Text(value, style: AppTextStyles.cardTitle.copyWith(color: Colors.white)),
    ],
  );
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.secondary),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.small),
      ],
    ),
  );
}

Widget _row(String label, int value, String symbol, {Color? color}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 7),
  child: Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: color == null ? null : TextStyle(color: color),
        ),
      ),
      Text(
        CurrencyUtils.formatMinor(value, symbol: symbol),
        style: AppTextStyles.cardTitle.copyWith(color: color),
      ),
    ],
  ),
);

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

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
