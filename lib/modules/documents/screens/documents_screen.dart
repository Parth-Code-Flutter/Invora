import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_storage_key_const.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/routes/shell_args.dart';
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
  late final PageController _pages;

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
    _pages = PageController(initialPage: _index);
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

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index == _index) return;
    _onPageChanged(index);
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
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
  );

  @override
  Widget build(BuildContext context) {
    return AppShell(
      destination: MainDestination.documents,
      floatingActionButton: FloatingActionButton(
        tooltip: l10n(_index == 0 ? 'Create invoice' : 'Create purchase bill'),
        onPressed: () => Get.toNamed<void>(
          _index == 0 ? AppRoutes.invoiceCreate : AppRoutes.purchaseBillCreate,
        ),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        bottom: false,
        child: PageView(
          controller: _pages,
          onPageChanged: _onPageChanged,
          children: [
            AppKeepAlive(
              child: InvoiceListScreen(embedded: true, belowTitle: _pairTabs),
            ),
            AppKeepAlive(
              child: PurchaseBillListScreen(
                embedded: true,
                belowTitle: _pairTabs,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
