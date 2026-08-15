import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../data/services/business_workspace_service.dart';
import '../constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../themes/app_text_styles.dart';
import 'app_bottom_sheet.dart';

Future<void> showWorkspaceSwitcher(BuildContext context) async {
  final service = Get.find<BusinessWorkspaceService>();
  await showAppBottomSheet<void>(
    context: context,
    title: 'Switch workspace',
    child: Obx(
      () => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _WorkspaceTile(
            icon: Icons.trending_up_rounded,
            title: 'Sales',
            subtitle: 'Invoices, customers and money to receive',
            selected: service.isSales,
            onTap: () => _select(context, service, BusinessWorkspace.sales),
          ),
          const SizedBox(height: 8),
          _WorkspaceTile(
            icon: Icons.shopping_bag_outlined,
            title: 'Purchases',
            subtitle: 'Supplier bills and money to pay',
            selected: service.isPurchases,
            onTap: () => _select(context, service, BusinessWorkspace.purchases),
          ),
          const SizedBox(height: 8),
          Text(
            'Switching changes the workspace only. Your records remain separate and safe.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _select(
  BuildContext context,
  BusinessWorkspaceService service,
  BusinessWorkspace workspace,
) async {
  if (service.activeWorkspace.value == workspace) {
    Navigator.pop(context);
    return;
  }
  await service.select(workspace);
  if (!context.mounted) return;
  Navigator.pop(context);
  Get.offAllNamed<void>(
    workspace == BusinessWorkspace.sales
        ? AppRoutes.dashboard
        : AppRoutes.purchases,
  );
}

class _WorkspaceTile extends StatelessWidget {
  const _WorkspaceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: 72,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: selected ? AppColors.secondary : AppColors.border,
      ),
    ),
    tileColor: selected ? AppColors.primaryLight : null,
    leading: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: selected ? AppColors.secondary : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: selected ? Colors.white : AppColors.primary),
    ),
    title: Text(title, style: AppTextStyles.listName),
    subtitle: Text(subtitle, style: AppTextStyles.caption),
    trailing: Icon(
      selected ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
      size: selected ? 22 : 16,
      color: selected ? AppColors.secondary : AppColors.textTertiary,
    ),
    onTap: onTap,
  );
}
