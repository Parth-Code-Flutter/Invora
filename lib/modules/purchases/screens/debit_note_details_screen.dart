import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/quantity_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../app/widgets/app_outlined_button.dart';
import '../../../app/widgets/responsive_content.dart';
import '../controllers/debit_note_details_controller.dart';

class DebitNoteDetailsScreen extends GetView<DebitNoteDetailsController> {
  const DebitNoteDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Obx(() {
          final number = controller.note.value?.debitNoteNumber;
          return AppBarTitle(
            number == null || number.isEmpty ? 'Debit note' : number,
            subtitle: 'Purchase return',
          );
        }),
      ),
      bottomNavigationBar: Obx(() {
        if (controller.note.value == null) return const SizedBox.shrink();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: AppConstrainedAction(
              maxWidth: ResponsiveUtils.footerMaxWidth(context),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Share',
                      icon: Icons.ios_share_rounded,
                      onPressed: controller.share,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppOutlinedButton(
                      label: 'Print',
                      icon: Icons.print_outlined,
                      onPressed: controller.printPdf,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final note = controller.note.value;
        if (note == null) {
          return const Center(child: Text('Debit note not found.'));
        }
        final symbol = controller.currencySymbol.value;
        return ResponsiveContent(
          tabletMaxWidth: 640,
          child: ListView(
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(note.debitNoteNumber, style: AppTextStyles.pageTitle),
                    const SizedBox(height: 6),
                    Text('Against ${note.billNumber}'),
                    Text(note.supplierName, style: AppTextStyles.small),
                    const SizedBox(height: 8),
                    Text('Reason: ${note.reason}'),
                    TextButton(
                      onPressed: () => Get.toNamed<void>(
                        AppRoutes.purchaseBillDetails,
                        arguments: note.purchaseBillId,
                      ),
                      child: const Text('Open original bill'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Returned items', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 8),
                    for (final item in note.items) ...[
                      Text(item.name, style: AppTextStyles.cardTitle),
                      Text(
                        '${QuantityUtils.toInputValue(item.quantityScaled)} ${item.unit} · ${CurrencyUtils.formatMinor(item.totalMinor, symbol: symbol)}',
                        style: AppTextStyles.small,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Settlement', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 8),
                    Text(
                      'Total ${CurrencyUtils.formatMinor(note.grandTotalMinor, symbol: symbol)}',
                    ),
                    Text(
                      'Applied ${CurrencyUtils.formatMinor(note.appliedMinor, symbol: symbol)}',
                    ),
                    if (note.refundedMinor > 0)
                      Text(
                        'Refunded ${CurrencyUtils.formatMinor(note.refundedMinor, symbol: symbol)}',
                      ),
                    if (note.unappliedMinor > 0)
                      Text(
                        'Supplier credit ${CurrencyUtils.formatMinor(note.unappliedMinor, symbol: symbol)}',
                      ),
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
