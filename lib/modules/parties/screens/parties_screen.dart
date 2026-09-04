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
import '../../customers/screens/customer_list_screen.dart';
import '../../purchases/screens/purchase_screens.dart';

class PartiesScreen extends StatefulWidget {
  const PartiesScreen({this.suppliers = false, super.key});

  final bool suppliers;

  @override
  State<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends State<PartiesScreen> {
  late int _index;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    final storage = Get.isRegistered<AppStorage>()
        ? Get.find<AppStorage>()
        : null;
    var suppliers = widget.suppliers;
    if (args is PartiesOpenArgs) {
      suppliers = args.suppliers;
    } else if (!widget.suppliers) {
      suppliers =
          storage?.getString(AppStorageKeyConst.partiesTab) == 'suppliers';
    }
    _index = suppliers ? 1 : 0;
    storage?.setString(
      AppStorageKeyConst.partiesTab,
      _index == 1 ? 'suppliers' : 'customers',
    );
  }

  void _select(int index) {
    setState(() => _index = index);
    if (Get.isRegistered<AppStorage>()) {
      Get.find<AppStorage>().setString(
        AppStorageKeyConst.partiesTab,
        index == 1 ? 'suppliers' : 'customers',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      destination: MainDestination.parties,
      floatingActionButton: FloatingActionButton(
        tooltip: l10n(_index == 0 ? 'Add customer' : 'Add supplier'),
        onPressed: () => Get.toNamed<void>(
          _index == 0 ? AppRoutes.customerAdd : AppRoutes.supplierAdd,
        ),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppPairTabs(
              left: 'Customers',
              right: 'Suppliers',
              index: _index,
              onChanged: _select,
            ),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: const [
                  CustomerListScreen(embedded: true),
                  SupplierListScreen(embedded: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
