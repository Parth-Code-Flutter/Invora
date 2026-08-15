import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/validation_utils.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_bottom_sheet.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_dialog.dart';
import '../../../app/widgets/app_purchase_navigation.dart';
import '../../../app/widgets/app_unit_field.dart';
import '../../../app/widgets/app_workspace_switch.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/models/purchase_models.dart';
import '../../../data/repositories/purchase_repository.dart';
import '../../../data/services/unit_service.dart';

String _money(int minor) => CurrencyUtils.formatMinor(minor, symbol: '₹');
String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
String _qty(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);

class WorkspaceSwitchButton extends StatelessWidget {
  const WorkspaceSwitchButton({super.key});
  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => showWorkspaceSwitcher(context),
    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
    label: const Text('Purchases'),
  );
}

class PurchaseBillListScreen extends StatefulWidget {
  const PurchaseBillListScreen({super.key});
  @override
  State<PurchaseBillListScreen> createState() => _PurchaseBillListScreenState();
}

class _PurchaseBillListScreenState extends State<PurchaseBillListScreen> {
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Purchase bills'),
      actions: const [WorkspaceSwitchButton()],
    ),
    bottomNavigationBar: const AppPurchaseNavigation(
      current: PurchaseDestination.bills,
    ),
    body: ResponsiveContent(
      tabletMaxWidth: 760,
      child: Column(
        children: [
          _Search(
            controller: search,
            hint: 'Search bill number or supplier',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<PurchaseBillSummary>>(
              stream: Get.find<PurchaseRepository>().watchBills(
                query: search.text,
              ),
              builder: (context, snapshot) {
                final bills = snapshot.data;
                if (bills == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (bills.isEmpty) {
                  return _Empty(
                    icon: Icons.receipt_long_outlined,
                    title: 'No purchase bills yet',
                    subtitle:
                        'Record supplier bills and track what you need to pay.',
                    action: 'Create purchase bill',
                    onTap: () =>
                        Get.toNamed<void>(AppRoutes.purchaseBillCreate),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: bills.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 9),
                  itemBuilder: (_, i) => _BillCard(bill: bills[i]),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});
  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Suppliers'),
      actions: const [WorkspaceSwitchButton()],
    ),
    bottomNavigationBar: const AppPurchaseNavigation(
      current: PurchaseDestination.suppliers,
    ),
    body: ResponsiveContent(
      tabletMaxWidth: 760,
      child: Column(
        children: [
          _Search(
            controller: search,
            hint: 'Search name, mobile or GSTIN',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<SupplierModel>>(
              stream: Get.find<PurchaseRepository>().watchSuppliers(
                query: search.text,
              ),
              builder: (context, snapshot) {
                final suppliers = snapshot.data;
                if (suppliers == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (suppliers.isEmpty) {
                  return _Empty(
                    icon: Icons.storefront_outlined,
                    title: 'No suppliers yet',
                    subtitle:
                        'Keep vendors separate from your sales customers.',
                    action: 'Add supplier',
                    onTap: () => Get.toNamed<void>(AppRoutes.supplierAdd),
                  );
                }
                return ListView.separated(
                  itemCount: suppliers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 9),
                  itemBuilder: (_, index) {
                    final supplier = suppliers[index];
                    return AppCard(
                      onTap: () => Get.toNamed<void>(
                        AppRoutes.supplierAdd,
                        arguments: supplier,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.secondaryLight,
                            child: Text(
                              supplier.name.substring(0, 1).toUpperCase(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  supplier.name,
                                  style: AppTextStyles.listName,
                                ),
                                if ((supplier.companyName ?? '').isNotEmpty)
                                  Text(
                                    supplier.companyName!,
                                    style: AppTextStyles.caption,
                                  ),
                                if ((supplier.mobile ?? '').isNotEmpty)
                                  Text(
                                    supplier.mobile!,
                                    style: AppTextStyles.caption,
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class SupplierFormScreen extends StatefulWidget {
  const SupplierFormScreen({super.key});
  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final key = GlobalKey<FormState>();
  late final SupplierModel? existing;
  late final TextEditingController name, company, mobile, email, gstin, address;
  bool isImportingContact = false;
  @override
  void initState() {
    super.initState();
    existing = Get.arguments is SupplierModel
        ? Get.arguments as SupplierModel
        : null;
    name = TextEditingController(text: existing?.name);
    company = TextEditingController(text: existing?.companyName);
    mobile = TextEditingController(text: existing?.mobile);
    email = TextEditingController(text: existing?.email);
    gstin = TextEditingController(text: existing?.gstin);
    address = TextEditingController(text: existing?.address);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(existing == null ? 'Add supplier' : 'Edit supplier'),
    ),
    body: ResponsiveContent(
      tabletMaxWidth: 660,
      child: Form(
        key: key,
        child: ListView(
          children: [
            const _Intro(
              icon: Icons.storefront_outlined,
              title: 'Supplier details',
              subtitle: 'Used only for purchase bills and payables.',
            ),
            const SizedBox(height: 14),
            _field(
              name,
              'Supplier name *',
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Supplier name is required'
                  : null,
            ),
            _field(company, 'Business / company name'),
            _field(
              mobile,
              'Mobile number',
              keyboard: TextInputType.phone,
              validator: ValidationUtils.optionalIndianMobile,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              suffixIcon: existing == null
                  ? IconButton(
                      tooltip: 'Import from phone contacts',
                      onPressed: isImportingContact ? null : _importContact,
                      icon: isImportingContact
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.contacts_rounded,
                              color: AppColors.secondary,
                            ),
                    )
                  : null,
            ),
            _field(
              email,
              'Email address',
              keyboard: TextInputType.emailAddress,
              validator: ValidationUtils.optionalEmail,
              inputFormatters: [
                LengthLimitingTextInputFormatter(254),
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
            ),
            _field(
              gstin,
              'GSTIN',
              validator: _validateGstin,
              inputFormatters: [
                LengthLimitingTextInputFormatter(15),
                FilteringTextInputFormatter.allow(RegExp('[0-9a-zA-Z]')),
              ],
            ),
            _field(address, 'Address', lines: 3),
            const SizedBox(height: 20),
            AppButton(
              label: existing == null ? 'Save supplier' : 'Update supplier',
              icon: Icons.check_rounded,
              onPressed: _save,
            ),
          ],
        ),
      ),
    ),
  );
  Future<void> _save() async {
    if (!(key.currentState?.validate() ?? false)) return;
    final now = DateTime.now();
    await Get.find<PurchaseRepository>().saveSupplier(
      SupplierModel(
        id: existing?.id,
        name: name.text.trim(),
        companyName: _null(company.text),
        mobile: _null(mobile.text),
        email: _null(email.text),
        gstin: _null(gstin.text.toUpperCase()),
        address: _null(address.text),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );
    Get.back<void>();
  }

  String? _validateGstin(String? value) {
    final normalized = value?.trim().toUpperCase() ?? '';
    if (normalized.isEmpty) return null;
    return RegExp(r'^[0-9A-Z]{15}$').hasMatch(normalized)
        ? null
        : 'Enter a valid 15-character GSTIN.';
  }

  Future<void> _importContact() async {
    setState(() => isImportingContact = true);
    try {
      final permission = await FlutterContacts.permissions.request(
        PermissionType.read,
      );
      if (permission != PermissionStatus.granted &&
          permission != PermissionStatus.limited) {
        AppNotification.warning(
          'Contacts permission needed',
          'Allow contact access to import a supplier from your phone.',
        );
        return;
      }
      final contact = await FlutterContacts.native.showPicker(
        properties: const {ContactProperty.phone},
      );
      if (contact == null) return;
      if (contact.phones.isEmpty) {
        AppNotification.info(
          'No mobile number',
          'The selected contact does not have a phone number.',
        );
        return;
      }
      final importedMobile = _normalizeIndianMobile(
        contact.phones.first.number,
      );
      if (importedMobile.isEmpty) {
        AppNotification.warning(
          'Unsupported number',
          'Choose a contact with a valid 10-digit Indian mobile number.',
        );
        return;
      }
      final importedName = contact.displayName?.trim() ?? '';
      if (importedName.isNotEmpty) name.text = importedName;
      mobile.text = importedMobile;
      AppNotification.success(
        'Contact imported',
        importedName.isEmpty
            ? 'Mobile number added. Enter the supplier name to continue.'
            : '$importedName is ready to save.',
      );
    } on PlatformException {
      AppNotification.error(
        'Could not open contacts',
        'Check contact permission in device settings and try again.',
      );
    } finally {
      if (mounted) setState(() => isImportingContact = false);
    }
  }

  String _normalizeIndianMobile(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return RegExp(r'^[6-9]\d{9}$').hasMatch(digits) ? digits : '';
  }
}

class PurchaseBillFormScreen extends StatefulWidget {
  const PurchaseBillFormScreen({super.key});
  @override
  State<PurchaseBillFormScreen> createState() => _PurchaseBillFormScreenState();
}

class _PurchaseBillFormScreenState extends State<PurchaseBillFormScreen> {
  final key = GlobalKey<FormState>();
  final number = TextEditingController();
  final notes = TextEditingController();
  SupplierModel? supplier;
  DateTime billDate = DateTime.now();
  DateTime? dueDate;
  final items = <PurchaseItemModel>[];
  PurchaseBillModel? existing;
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final arg = Get.arguments;
    if (arg is int) {
      existing = await Get.find<PurchaseRepository>().getBill(arg);
      final e = existing!;
      number.text = e.billNumber;
      notes.text = e.notes ?? '';
      billDate = e.billDate;
      dueDate = e.dueDate;
      items.addAll(e.items);
      final suppliers = await Get.find<PurchaseRepository>()
          .watchSuppliers()
          .first;
      supplier = suppliers.where((s) => s.id == e.supplierId).firstOrNull;
    } else {
      number.text =
          'PB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }
    if (mounted) setState(() => loading = false);
  }

  int get total => items.fold(0, (s, i) => s + i.totalMinor);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        existing == null ? 'New purchase bill' : 'Edit purchase bill',
      ),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : existing == null && supplier == null
        ? _supplierSelectionStep()
        : ResponsiveContent(
            tabletMaxWidth: 720,
            child: Form(
              key: key,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  _Intro(
                    icon: Icons.receipt_long_outlined,
                    title: 'Bill details',
                    subtitle:
                        'Record the supplier invoice without affecting sales.',
                  ),
                  const SizedBox(height: 14),
                  AppCard(
                    onTap: _chooseSupplier,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.storefront_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                supplier?.name ?? 'Select supplier *',
                                style: AppTextStyles.listName,
                              ),
                              Text(
                                supplier == null
                                    ? 'Required for a purchase bill'
                                    : supplier!.companyName ?? 'Supplier',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    number,
                    'Supplier bill number *',
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Bill number is required'
                        : null,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _DateTile(
                          label: 'Bill date',
                          value: billDate,
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              initialDate: billDate,
                            );
                            if (d != null) setState(() => billDate = d);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DateTile(
                          label: 'Due date',
                          value: dueDate,
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              firstDate: billDate,
                              lastDate: DateTime(2100),
                              initialDate: dueDate ?? billDate,
                            );
                            if (d != null) setState(() => dueDate = d);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Purchased items',
                          style: AppTextStyles.sectionTitle,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add item'),
                      ),
                    ],
                  ),
                  if (items.isEmpty)
                    AppCard(
                      onTap: _addItem,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_shopping_cart_rounded,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 9),
                            Text('Add your first purchased item'),
                          ],
                        ),
                      ),
                    ),
                  ...items.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.value.name,
                                    style: AppTextStyles.listName,
                                  ),
                                  Text(
                                    '${_qty(entry.value.quantity)} ${entry.value.unit} × ${_money(entry.value.rateMinor)} • GST ${_qty(entry.value.taxRate)}%',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _money(entry.value.totalMinor),
                              style: AppTextStyles.listName,
                            ),
                            IconButton(
                              tooltip: 'Item actions',
                              onPressed: () => _showItemActions(entry.key),
                              icon: const Icon(Icons.more_horiz_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _field(notes, 'Notes', lines: 3),
                  AppCard(
                    child: Row(
                      children: [
                        const Expanded(child: Text('Purchase total')),
                        Text(_money(total), style: AppTextStyles.sectionTitle),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppButton(
                    label: existing == null
                        ? 'Save purchase bill'
                        : 'Update purchase bill',
                    icon: Icons.check_rounded,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),
  );

  Widget _supplierSelectionStep() => ResponsiveContent(
    tabletMaxWidth: 720,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Intro(
          icon: Icons.storefront_outlined,
          title: 'Who supplied this purchase?',
          subtitle:
              'Select a supplier first. Bill details and items come next.',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text('Select supplier', style: AppTextStyles.sectionTitle),
            ),
            TextButton.icon(
              onPressed: () => Get.toNamed<void>(AppRoutes.supplierAdd),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('New supplier'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: StreamBuilder<List<SupplierModel>>(
            stream: Get.find<PurchaseRepository>().watchSuppliers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final suppliers = snapshot.data!;
              if (suppliers.isEmpty) {
                return _Empty(
                  icon: Icons.storefront_outlined,
                  title: 'No suppliers yet',
                  subtitle:
                      'Create your first supplier, then continue with the purchase bill.',
                  action: 'Create supplier',
                  onTap: () => Get.toNamed<void>(AppRoutes.supplierAdd),
                );
              }
              return ListView.separated(
                itemCount: suppliers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final value = suppliers[index];
                  return AppCard(
                    onTap: () => setState(() => supplier = value),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.secondaryLight,
                          child: Text(value.name.substring(0, 1).toUpperCase()),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(value.name, style: AppTextStyles.listName),
                              Text(
                                value.companyName ?? value.mobile ?? 'Supplier',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );

  Future<void> _chooseSupplier() async {
    final chosen = await showModalBottomSheet<SupplierModel>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: StreamBuilder<List<SupplierModel>>(
            stream: Get.find<PurchaseRepository>().watchSuppliers(),
            builder: (_, snapshot) => Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Select supplier',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: (snapshot.data ?? [])
                        .map(
                          (s) => ListTile(
                            leading: const Icon(Icons.storefront_outlined),
                            title: Text(s.name),
                            subtitle: Text(s.companyName ?? s.mobile ?? ''),
                            onTap: () => Navigator.pop(context, s),
                          ),
                        )
                        .toList(),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Get.toNamed<void>(AppRoutes.supplierAdd);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create supplier'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (chosen != null) setState(() => supplier = chosen);
  }

  Future<void> _addItem() async {
    final result = await showAppBottomSheet<PurchaseItemModel>(
      context: context,
      title: 'Add purchased item',
      child: const _PurchaseItemSheet(),
    );
    if (result != null) setState(() => items.add(result));
  }

  Future<void> _editItem(int index) async {
    final result = await showAppBottomSheet<PurchaseItemModel>(
      context: context,
      title: 'Edit purchased item',
      child: _PurchaseItemSheet(initial: items[index]),
    );
    if (result != null) setState(() => items[index] = result);
  }

  Future<void> _showItemActions(int index) => showAppBottomSheet<void>(
    context: context,
    title: items[index].name,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionTile(
          icon: Icons.edit_rounded,
          title: 'Edit item',
          subtitle: 'Change quantity, unit, price or GST.',
          onTap: () {
            Navigator.pop(context);
            _editItem(index);
          },
        ),
        _ActionTile(
          icon: Icons.delete_outline_rounded,
          title: 'Remove item',
          subtitle: 'Remove this item from the purchase bill.',
          destructive: true,
          onTap: () {
            Navigator.pop(context);
            setState(() => items.removeAt(index));
          },
        ),
      ],
    ),
  );

  Future<void> _save() async {
    if (!(key.currentState?.validate() ?? false)) return;
    if (supplier == null) {
      _message('Select a supplier before saving.');
      return;
    }
    if (items.isEmpty) {
      _message('Add at least one purchased item.');
      return;
    }
    if (dueDate != null && dueDate!.isBefore(billDate)) {
      _message('Due date cannot be before the bill date.');
      return;
    }
    final numberAvailable = await Get.find<PurchaseRepository>()
        .isBillNumberAvailable(number.text, excludingId: existing?.id);
    if (!numberAvailable) {
      _message('This supplier bill number already exists.');
      return;
    }
    final now = DateTime.now();
    final id = await Get.find<PurchaseRepository>().saveBill(
      PurchaseBillModel(
        id: existing?.id,
        billNumber: number.text,
        supplierId: supplier!.id,
        supplierName: supplier!.name,
        billDate: billDate,
        dueDate: dueDate,
        items: items,
        paidMinor: existing?.paidMinor ?? 0,
        notes: _null(notes.text),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );
    Get.offNamed<void>(AppRoutes.purchaseBillDetails, arguments: id);
  }
}

class PurchaseBillDetailsScreen extends StatefulWidget {
  const PurchaseBillDetailsScreen({super.key});
  @override
  State<PurchaseBillDetailsScreen> createState() =>
      _PurchaseBillDetailsScreenState();
}

class _PurchaseBillDetailsScreenState extends State<PurchaseBillDetailsScreen> {
  late final int id = Get.arguments as int;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Purchase bill'),
      actions: [
        IconButton(
          tooltip: 'Bill actions',
          onPressed: _showBillActions,
          icon: const Icon(Icons.more_horiz_rounded),
        ),
      ],
    ),
    body: FutureBuilder<PurchaseBillModel?>(
      future: Get.find<PurchaseRepository>().getBill(id),
      builder: (_, snapshot) {
        final bill = snapshot.data;
        if (bill == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ResponsiveContent(
          tabletMaxWidth: 720,
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.billNumber,
                      style: AppTextStyles.pageTitle.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      bill.supplierName,
                      style: AppTextStyles.secondaryBody.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _money(bill.balanceMinor),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Payable • ${_money(bill.totalMinor)} total',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (bill.balanceMinor > 0)
                AppButton(
                  label: 'Record supplier payment',
                  icon: Icons.account_balance_wallet_outlined,
                  onPressed: () => _payment(bill),
                ),
              const SizedBox(height: 14),
              Text('Items', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 8),
              ...bill.items.map(
                (i) => AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(i.name, style: AppTextStyles.listName),
                            Text(
                              '${_qty(i.quantity)} ${i.unit} × ${_money(i.rateMinor)}',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      Text(_money(i.totalMinor), style: AppTextStyles.listName),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Payment history', style: AppTextStyles.sectionTitle),
              StreamBuilder<List<PurchasePaymentModel>>(
                stream: Get.find<PurchaseRepository>().watchPayments(id),
                builder: (_, p) => Column(
                  children: (p.data ?? [])
                      .map(
                        (x) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            child: Icon(Icons.payments_outlined),
                          ),
                          title: Text(_money(x.amountMinor)),
                          subtitle: Text(
                            '${x.method ?? 'Payment'} • ${_date(x.paidAt)}',
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    ),
  );

  Future<void> _showBillActions() => showAppBottomSheet<void>(
    context: context,
    title: 'Purchase bill actions',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionTile(
          icon: Icons.edit_note_rounded,
          title: 'Edit bill',
          subtitle: 'Update supplier, items, dates or notes.',
          onTap: () async {
            Navigator.pop(context);
            await Get.toNamed<void>(
              AppRoutes.purchaseBillCreate,
              arguments: id,
            );
            if (mounted) setState(() {});
          },
        ),
        _ActionTile(
          icon: Icons.delete_outline_rounded,
          title: 'Delete bill',
          subtitle: 'Permanently remove this bill and its payments.',
          destructive: true,
          onTap: () async {
            Navigator.pop(context);
            final confirmed = await showAppConfirmDialog(
              context: context,
              title: 'Delete purchase bill?',
              message:
                  'This permanently removes the bill, its items and payment history.',
              confirmLabel: 'Delete bill',
              destructive: true,
            );
            if (!confirmed) return;
            await Get.find<PurchaseRepository>().deleteBill(id);
            Get.offAllNamed<void>(AppRoutes.purchaseBills);
          },
        ),
      ],
    ),
  );

  Future<void> _payment(PurchaseBillModel bill) async {
    final amount = TextEditingController();
    final result = await showAppBottomSheet<int>(
      context: context,
      title: 'Record supplier payment',
      child: _PaymentSheet(controller: amount, balanceMinor: bill.balanceMinor),
    );
    if (result != null) {
      try {
        await Get.find<PurchaseRepository>().recordPayment(
          id,
          result,
          method: 'Cash',
        );
        setState(() {});
      } catch (e) {
        _message(e.toString());
      }
    }
  }
}

class _BillCard extends StatelessWidget {
  const _BillCard({required this.bill});
  final PurchaseBillSummary bill;
  @override
  Widget build(BuildContext context) {
    final color = bill.status == 'paid'
        ? AppColors.success
        : bill.status == 'overdue'
        ? AppColors.error
        : AppColors.warning;
    return AppCard(
      onTap: () =>
          Get.toNamed<void>(AppRoutes.purchaseBillDetails, arguments: bill.id),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 52,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        bill.billNumber,
                        style: AppTextStyles.listName,
                      ),
                    ),
                    _Pill(bill.status, color),
                  ],
                ),
                Text(bill.supplierName, style: AppTextStyles.secondaryBody),
                Text(
                  'Bill ${_date(bill.billDate)}${bill.dueDate == null ? '' : ' • Due ${_date(bill.dueDate!)}'}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_money(bill.totalMinor), style: AppTextStyles.listName),
              if (bill.balanceMinor > 0)
                Text(
                  '${_money(bill.balanceMinor)} due',
                  style: AppTextStyles.caption.copyWith(color: color),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label.capitalizeFirst!,
      style: AppTextStyles.caption.copyWith(color: color),
    ),
  );
}

class _Search extends StatelessWidget {
  const _Search({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    decoration: InputDecoration(
      prefixIcon: const Icon(Icons.search_rounded),
      hintText: hint,
      suffixIcon: controller.text.isEmpty
          ? null
          : IconButton(
              onPressed: () {
                controller.clear();
                onChanged('');
              },
              icon: const Icon(Icons.close_rounded),
            ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
  });
  final IconData icon;
  final String title, subtitle, action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.sectionTitle),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.secondaryBody,
          ),
          const SizedBox(height: 18),
          AppButton(label: action, icon: Icons.add_rounded, onPressed: onTap),
        ],
      ),
    ),
  );
}

class _Intro extends StatelessWidget {
  const _Intro({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.sectionTitle),
              Text(subtitle, style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today_outlined),
      ),
      child: Text(value == null ? 'Not set' : _date(value!)),
    ),
  );
}

class _PurchaseItemSheet extends StatefulWidget {
  const _PurchaseItemSheet({this.initial});
  final PurchaseItemModel? initial;
  @override
  State<_PurchaseItemSheet> createState() => _PurchaseItemSheetState();
}

class _PurchaseItemSheetState extends State<_PurchaseItemSheet> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name, qty, rate, tax;
  late String unit;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    name = TextEditingController(text: initial?.name);
    qty = TextEditingController(
      text: initial == null ? '1' : _qty(initial.quantity),
    );
    unit = initial?.unit ?? Get.find<UnitService>().defaultUnit;
    rate = TextEditingController(
      text: initial == null ? '' : (initial.rateMinor / 100).toStringAsFixed(2),
    );
    tax = TextEditingController(
      text: initial == null ? '0' : _qty(initial.taxRate),
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .72,
    child: Form(
      key: formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Intro(
                    icon: Icons.inventory_2_outlined,
                    title: 'Purchase item details',
                    subtitle: 'Add what you bought and the supplier price.',
                  ),
                  const SizedBox(height: 16),
                  _field(
                    name,
                    'Item name *',
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Item name is required.'
                        : null,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _field(
                          qty,
                          'Quantity *',
                          keyboard: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            final parsed = double.tryParse(value ?? '');
                            return parsed == null || parsed <= 0
                                ? 'Enter a valid quantity.'
                                : null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppUnitField(
                          value: unit,
                          unitService: Get.find<UnitService>(),
                          onChanged: (value) => setState(() => unit = value),
                        ),
                      ),
                    ],
                  ),
                  _field(
                    rate,
                    'Purchase price (₹) *',
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      final parsed = double.tryParse(value ?? '');
                      return parsed == null || parsed <= 0
                          ? 'Enter a valid purchase price.'
                          : null;
                    },
                  ),
                  _field(
                    tax,
                    'GST %',
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      final parsed = double.tryParse(value ?? '');
                      return parsed == null || parsed < 0 || parsed > 100
                          ? 'GST must be between 0 and 100.'
                          : null;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: widget.initial == null ? 'Add item' : 'Update item',
            icon: Icons.check_rounded,
            onPressed: _submit,
          ),
        ],
      ),
    ),
  );

  void _submit() {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final q = double.tryParse(qty.text);
    final r = double.tryParse(rate.text);
    final t = double.tryParse(tax.text) ?? 0;
    if (q == null || r == null) return;
    Navigator.pop(
      context,
      PurchaseItemModel(
        id: widget.initial?.id,
        name: name.text.trim(),
        quantity: q,
        unit: unit,
        rateMinor: (r * 100).round(),
        taxRate: t,
      ),
    );
  }
}

class _PaymentSheet extends StatelessWidget {
  const _PaymentSheet({required this.controller, required this.balanceMinor});
  final TextEditingController controller;
  final int balanceMinor;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Intro(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Payment due ${_money(balanceMinor)}',
        subtitle: 'Record only the amount already paid to your supplier.',
      ),
      const SizedBox(height: 16),
      TextField(
        controller: controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Amount paid *',
          prefixIcon: Icon(Icons.currency_rupee_rounded),
        ),
      ),
      const SizedBox(height: 16),
      AppButton(
        label: 'Record payment',
        icon: Icons.check_rounded,
        onPressed: () {
          final value = double.tryParse(controller.text);
          final minor = value == null ? 0 : (value * 100).round();
          if (minor <= 0 || minor > balanceMinor) {
            AppNotification.warning(
              'Check payment amount',
              'Enter an amount between ₹0.01 and ${_money(balanceMinor)}.',
            );
            return;
          }
          Navigator.pop(context, minor);
        },
      ),
    ],
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.secondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: onTap,
        color: destructive ? AppColors.error.withValues(alpha: .05) : null,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.listName.copyWith(color: color),
                  ),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }
}

Widget _field(
  TextEditingController controller,
  String label, {
  String? Function(String?)? validator,
  TextInputType? keyboard,
  int lines = 1,
  List<TextInputFormatter>? inputFormatters,
  Widget? suffixIcon,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboard,
    maxLines: lines,
    inputFormatters: inputFormatters,
    decoration: InputDecoration(labelText: label, suffixIcon: suffixIcon),
  ),
);
String? _null(String value) => value.trim().isEmpty ? null : value.trim();
void _message(String value) =>
    AppNotification.warning('Complete required details', value);
