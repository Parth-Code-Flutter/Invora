import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_storage_key_const.dart';
import '../../../app/constants/app_colors.dart';
import '../../../app/constants/documents_icons.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/routes/shell_args.dart';
import '../../../app/widgets/app_list_create_fab.dart';
import '../../../app/widgets/app_main_navigation.dart';
import '../../../app/widgets/app_pair_tabs.dart';
import '../../../app/widgets/app_shell.dart';
import '../../../data/services/app_storage.dart';
import '../../../data/models/invoice_model.dart';
import '../../invoices/controllers/invoice_list_controller.dart';
import '../../invoices/screens/invoice_list_screen.dart';
import '../../purchases/screens/purchase_screens.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({this.purchases = false, super.key});

  final bool purchases;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late int _index;
  var _salesEmptyCreate = true;
  var _purchasesEmptyCreate = true;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    final storage = Get.isRegistered<AppStorage>()
        ? Get.find<AppStorage>()
        : null;
    var purchases = widget.purchases;
    InvoiceListFilter? invoiceFilter;
    String? billFilter;
    if (args is DocumentsOpenArgs) {
      purchases = args.purchases;
      invoiceFilter = args.invoiceFilter;
      billFilter = args.billFilter;
    } else if (args is InvoiceListFilter) {
      purchases = false;
      invoiceFilter = args;
    } else if (!widget.purchases) {
      purchases =
          storage?.getString(AppStorageKeyConst.documentsTab) == 'purchases';
    }
    _index = purchases ? 1 : 0;
    if (invoiceFilter != null && Get.isRegistered<InvoiceListController>()) {
      Get.find<InvoiceListController>().selectFilter(invoiceFilter);
    }
    if (billFilter != null) {
      PurchaseBillListScreen.pendingFilter = billFilter;
    }
    storage?.setString(
      AppStorageKeyConst.documentsTab,
      _index == 1 ? 'purchases' : 'sales',
    );
  }

  void _select(int index) {
    if (index == _index) return;
    _onPageChanged(index);
  }

  void _onPageChanged(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    if (Get.isRegistered<AppStorage>()) {
      Get.find<AppStorage>().setString(
        AppStorageKeyConst.documentsTab,
        index == 1 ? 'purchases' : 'sales',
      );
    }
  }

  Widget get _pairTabs => AppPairTabs(
    left: 'Sales',
    right: 'Purchases',
    index: _index,
    onChanged: _select,
    leftIcon: Icons.receipt_long_outlined,
    rightIcon: Icons.shopping_bag_outlined,
    inkSelected: true,
    leadingIcons: [
      SvgPicture.asset(
        DocumentsIcons.sales,
        width: 16,
        height: 16,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(
          _index == 0 ? AppColors.primary : const Color(0xFF6B7280),
          BlendMode.srcIn,
        ),
      ),
      SvgPicture.asset(
        DocumentsIcons.purchases,
        width: 16,
        height: 16,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(
          _index == 1 ? AppColors.secondary : const Color(0xFF6B7280),
          BlendMode.srcIn,
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final invoices = Get.isRegistered<InvoiceListController>()
        ? Get.find<InvoiceListController>()
        : null;
    return Obx(() {
      final hideSales =
          invoices == null || invoices.isLoading.value || _salesEmptyCreate;
      final hide = _index == 0 ? hideSales : _purchasesEmptyCreate;
      return AppShell(
        destination: MainDestination.documents,
        floatingActionButton: appListCreateFab(
          emptyCreateVisible: hide,
          tooltip: l10n(
            _index == 0 ? 'Create invoice' : 'Create purchase bill',
          ),
          onPressed: () => Get.toNamed<void>(
            _index == 0
                ? AppRoutes.invoiceCreate
                : AppRoutes.purchaseBillCreate,
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: AppSwipeTabs(
            index: _index,
            length: 2,
            onChanged: _select,
            child: IndexedStack(
              index: _index,
              children: [
                AppKeepAlive(
                  child: InvoiceListScreen(
                    embedded: true,
                    belowTitle: _pairTabs,
                    onEmptyCreateVisible: (visible) {
                      if (_salesEmptyCreate == visible) return;
                      setState(() => _salesEmptyCreate = visible);
                    },
                  ),
                ),
                AppKeepAlive(
                  child: PurchaseBillListScreen(
                    embedded: true,
                    belowTitle: _pairTabs,
                    onEmptyCreateVisible: (visible) {
                      if (_purchasesEmptyCreate == visible) return;
                      setState(() => _purchasesEmptyCreate = visible);
                    },
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
