import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../data/models/payment_receipt_model.dart';
import '../controllers/payment_receipt_controller.dart';

class PaymentReceiptScreen extends GetView<PaymentReceiptController> {
  const PaymentReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Payment receipt'),
      actions: [
        IconButton(
          onPressed: controller.save,
          icon: const Icon(Icons.download_outlined),
        ),
        IconButton(
          onPressed: controller.share,
          icon: const Icon(Icons.share_outlined),
        ),
        IconButton(
          onPressed: controller.print,
          icon: const Icon(Icons.print_outlined),
        ),
      ],
    ),
    body: Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error.value != null) {
        return Center(child: Text(controller.error.value!));
      }
      return _ReceiptRollExperience(controller: controller);
    }),
  );
}

class _ReceiptRollExperience extends StatefulWidget {
  const _ReceiptRollExperience({required this.controller});
  final PaymentReceiptController controller;

  @override
  State<_ReceiptRollExperience> createState() => _ReceiptRollExperienceState();
}

class _ReceiptRollExperienceState extends State<_ReceiptRollExperience>
    with SingleTickerProviderStateMixin {
  late final animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..forward();

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final receipt = widget.controller.receipt.value!;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final paper = CurvedAnimation(
          parent: animation,
          curve: const Interval(.08, .68, curve: Curves.easeOutCubic),
        ).value;
        final success = CurvedAnimation(
          parent: animation,
          curve: const Interval(.62, 1, curve: Curves.easeOutBack),
        ).value;
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Text(
              'Receipt print',
              textAlign: TextAlign.center,
              style: AppTextStyles.displayAmount,
            ),
            Text(
              'Animation',
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: SizedBox(
                width: 310,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: paper,
                          child: _AnimatedReceiptPaper(receipt: receipt),
                        ),
                      ),
                    ),
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFE2A0),
                            Color(0xFFD59C32),
                            Color(0xFFFFE8B2),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x44302000),
                            blurRadius: 12,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Opacity(
              opacity: success.clamp(0, 1),
              child: Transform.translate(
                offset: Offset(0, 18 * (1 - success)),
                child: Column(
                  children: [
                    const SizedBox(height: 22),
                    Text(
                      'Payment successful',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You’re all set—your receipt is ready.',
                      style: AppTextStyles.secondaryBody,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              animation.forward(from: 0);
                            },
                            icon: const Icon(Icons.print_outlined),
                            label: const Text('Re-print receipt'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _preview(context),
                            icon: const Icon(Icons.receipt_long_outlined),
                            label: const Text('View receipt'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _preview(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => PdfPreview(
      build: (_) => widget.controller.build(),
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
      allowPrinting: true,
      allowSharing: true,
    ),
  );
}

class _AnimatedReceiptPaper extends StatelessWidget {
  const _AnimatedReceiptPaper({required this.receipt});
  final PaymentReceiptModel receipt;

  @override
  Widget build(BuildContext context) => Container(
    height: 390,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
    decoration: const BoxDecoration(
      color: Color(0xFFFFFEFB),
      boxShadow: [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 18,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          receipt.business.businessName.toUpperCase(),
          style: AppTextStyles.cardTitle.copyWith(letterSpacing: 1.2),
        ),
        Text(
          'PAYMENT RECEIPT · ${receipt.receiptNumber}',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 24),
        Text(
          CurrencyUtils.formatMinor(
            receipt.payment.amountMinor,
            symbol: receipt.business.currencySymbol,
          ),
          style: AppTextStyles.displayAmount,
        ),
        const SizedBox(height: 4),
        Text(
          '${receipt.invoice.invoiceNumber} · ${receipt.payment.method ?? 'Payment'}',
          style: AppTextStyles.small,
        ),
        const Divider(height: 30),
        _paperRow('Received from', receipt.invoice.customer.name),
        _paperRow('Reference', receipt.payment.reference ?? '—'),
        _paperRow(
          'Balance remaining',
          CurrencyUtils.formatMinor(
            receipt.balanceAfterMinor,
            symbol: receipt.business.currencySymbol,
          ),
        ),
        const Spacer(),
        const Divider(),
        Center(
          child: Text(
            'THANK YOU FOR YOUR PAYMENT',
            style: AppTextStyles.caption.copyWith(letterSpacing: 1.1),
          ),
        ),
      ],
    ),
  );

  Widget _paperRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.small)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.cardTitle.copyWith(fontSize: 13),
          ),
        ),
      ],
    ),
  );
}
