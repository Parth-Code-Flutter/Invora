import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../app/widgets/responsive_content.dart';
import '../controllers/stock_opening_controller.dart';

class StockOpeningScreen extends GetView<StockOpeningController> {
  const StockOpeningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const AppBarTitle('Opening stock'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ResponsiveContent(
          tabletMaxWidth: 560,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Track product stock from this date',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Enter on-hand quantity for each product. Leave blank for zero. Past invoices are not backfilled.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Opening as of'),
                      subtitle: Text(_formatDate(controller.openingAsOf.value)),
                      trailing: const Icon(Icons.event_outlined),
                      onTap: () => _pickDate(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (controller.products.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  child: Text(
                    'No products yet. You can turn tracking on now and add quantities later with an adjustment.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                )
              else
                for (final product in controller.products) ...[
                  AppTextField(
                    controller: controller.qtyByProduct[product.id!]!,
                    label: product.name,
                    hint: '0 ${product.unit}',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      }),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Obx(
            () => AppConstrainedAction(
              child: AppButton(
                onPressed: controller.isSaving.value ? null : controller.save,
                label: 'Turn on stock tracking',
                isLoading: controller.isSaving.value,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: controller.openingAsOf.value,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selected != null) controller.openingAsOf.value = selected;
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}
