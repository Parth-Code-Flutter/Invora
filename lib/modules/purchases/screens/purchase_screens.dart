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
import '../../../app/widgets/app_amount_text.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_bottom_sheet.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_dialog.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../app/widgets/app_grouped_tile.dart';
import '../../../app/widgets/app_purchase_navigation.dart';
import '../../../app/widgets/app_search_app_bar.dart';
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
  Widget build(BuildContext context) => IconButton(
    tooltip: l10n('Switch workspace'),
    onPressed: () => showWorkspaceSwitcher(context),
    icon: const Icon(Icons.swap_horiz_rounded),
  );
}

class PurchaseBillListScreen extends StatefulWidget {
  const PurchaseBillListScreen({super.key});
  @override
  State<PurchaseBillListScreen> createState() => _PurchaseBillListScreenState();
}

class _PurchaseBillListScreenState extends State<PurchaseBillListScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppSearchAppBar(
      title: 'Purchase bills',
      hint: 'Bill number or supplier',
      onChanged: (value) => setState(() => query = value),
      actions: const [WorkspaceSwitchButton()],
    ),
    bottomNavigationBar: const AppPurchaseNavigation(
      current: PurchaseDestination.bills,
    ),
    body: ResponsiveContent(
      tabletMaxWidth: 760,
      child: StreamBuilder<List<PurchaseBillSummary>>(
        stream: Get.find<PurchaseRepository>().watchBills(query: query),
        builder: (context, snapshot) {
          final bills = snapshot.data;
          if (bills == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (bills.isEmpty) {
            return AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: query.isEmpty
                  ? 'No purchase bills yet'
                  : 'No matching bills',
              message: query.isEmpty
                  ? 'Record supplier bills and track what you need to pay.'
                  : 'Try a different bill number or supplier name.',
              actionLabel: query.isEmpty ? 'Create purchase bill' : null,
              onAction: query.isEmpty
                  ? () => Get.toNamed<void>(AppRoutes.purchaseBillCreate)
                  : null,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: bills.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => PurchaseBillRow(bill: bills[i]),
          );
        },
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
  String query = '';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppSearchAppBar(
      title: 'Suppliers',
      hint: 'Name, mobile or GSTIN',
      onChanged: (value) => setState(() => query = value),
      actions: const [WorkspaceSwitchButton()],
    ),
    bottomNavigationBar: const AppPurchaseNavigation(
      current: PurchaseDestination.suppliers,
    ),
    body: ResponsiveContent(
      tabletMaxWidth: 760,
      child: StreamBuilder<List<SupplierModel>>(
        stream: Get.find<PurchaseRepository>().watchSuppliers(query: query),
        builder: (context, snapshot) {
          final suppliers = snapshot.data;
          if (suppliers == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (suppliers.isEmpty) {
            return AppEmptyState(
              icon: Icons.storefront_outlined,
              title: query.isEmpty
                  ? 'No suppliers yet'
                  : 'No matching suppliers',
              message: query.isEmpty
                  ? 'Keep vendors separate from your sales customers.'
                  : 'Try a different name, mobile or GSTIN.',
              actionLabel: query.isEmpty ? 'Add supplier' : null,
              onAction: query.isEmpty
                  ? () => Get.toNamed<void>(AppRoutes.supplierAdd)
                  : null,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: suppliers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final supplier = suppliers[index];
              final caption = (supplier.companyName ?? '').trim().isNotEmpty
                  ? supplier.companyName!
                  : (supplier.mobile ?? supplier.gstin ?? 'Supplier');
              return AppGroupedTile(
                onTap: () => Get.toNamed<void>(
                  AppRoutes.supplierAdd,
                  arguments: supplier,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        supplier.name.substring(0, 1).toUpperCase(),
                        style: AppTextStyles.listName.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supplier.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.listName,
                          ),
                          Text(
                            caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              );
            },
          );
        },
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
  void dispose() {
    name.dispose();
    company.dispose();
    mobile.dispose();
    email.dispose();
    gstin.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
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
            const SizedBox(height: 16),
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

  @override
  void dispose() {
    number.dispose();
    notes.dispose();
    super.dispose();
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
      leading: const AppBackButton(),
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
                  AppGroupedTile(
                    onTap: _chooseSupplier,
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryLight,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.storefront_outlined,
                            color: AppColors.secondary,
                            size: 20,
                          ),
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
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textTertiary,
                        ),
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
                          style: AppTextStyles.listName.copyWith(fontSize: 15),
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
                    AppGroupedTile(
                      onTap: _addItem,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_shopping_cart_rounded,
                              color: AppColors.secondary,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Add your first purchased item',
                                style: AppTextStyles.listName,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      AppGroupedTile(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    items[i].name,
                                    style: AppTextStyles.listName,
                                  ),
                                  Text(
                                    '${_qty(items[i].quantity)} ${items[i].unit} × ${_money(items[i].rateMinor)} · GST ${_qty(items[i].taxRate)}%',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _money(items[i].totalMinor),
                              style: AppTextStyles.listName,
                            ),
                            IconButton(
                              tooltip: 'Item actions',
                              onPressed: () => _showItemActions(i),
                              icon: const Icon(Icons.more_horiz_rounded),
                            ),
                          ],
                        ),
                      ),
                    ],
                  const SizedBox(height: 12),
                  _field(notes, 'Notes', lines: 3),
                  AppGroupedTile(
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Purchase total',
                            style: AppTextStyles.listName,
                          ),
                        ),
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
                return AppEmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'No suppliers yet',
                  message:
                      'Create your first supplier, then continue with the purchase bill.',
                  actionLabel: 'Create supplier',
                  onAction: () => Get.toNamed<void>(AppRoutes.supplierAdd),
                );
              }
              return ListView.separated(
                itemCount: suppliers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final value = suppliers[index];
                  return AppGroupedTile(
                    onTap: () => setState(() => supplier = value),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryLight,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            value.name.substring(0, 1).toUpperCase(),
                            style: AppTextStyles.listName.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(value.name, style: AppTextStyles.listName),
                              Text(
                                value.companyName ?? value.mobile ?? 'Supplier',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textTertiary,
                        ),
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
  PurchaseBillModel? bill;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await Get.find<PurchaseRepository>().getBill(id);
    if (!mounted) return;
    setState(() {
      bill = value;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = bill;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(current?.billNumber ?? 'Purchase bill'),
        actions: [
          IconButton(
            tooltip: 'Bill actions',
            onPressed: _showBillActions,
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      bottomNavigationBar: current != null && current.balanceMinor > 0
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: AppButton(
                  label: 'Record supplier payment',
                  icon: Icons.account_balance_wallet_outlined,
                  onPressed: () => _payment(current),
                ),
              ),
            )
          : null,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : current == null
          ? const Center(child: Text('This purchase bill was not found.'))
          : ResponsiveContent(
              tabletMaxWidth: 720,
              child: ListView(
                children: [
                  AppCard(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.surfaceSoft,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          current.supplierName,
                          style: AppTextStyles.sectionTitle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bill ${_date(current.billDate)}${current.dueDate == null ? '' : ' · Due ${_date(current.dueDate!)}'}',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          current.balanceMinor > 0 ? 'Payable' : 'Paid',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        AppAmountText(
                          amountMinor: current.balanceMinor > 0
                              ? current.balanceMinor
                              : current.totalMinor,
                          symbol: '₹',
                          hero: true,
                          textAlign: TextAlign.start,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Payment activity',
                    style: AppTextStyles.listName.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _PayMetric(
                          'Total',
                          current.totalMinor,
                          AppColors.secondary,
                          AppColors.secondaryLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PayMetric(
                          'Paid',
                          current.paidMinor,
                          AppColors.success,
                          AppColors.successLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PayMetric(
                          'Remaining',
                          current.balanceMinor,
                          current.balanceMinor > 0
                              ? AppColors.warning
                              : AppColors.success,
                          current.balanceMinor > 0
                              ? AppColors.warningLight
                              : AppColors.successLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Items',
                    style: AppTextStyles.listName.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < current.items.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    AppGroupedTile(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  current.items[i].name,
                                  style: AppTextStyles.listName,
                                ),
                                Text(
                                  '${_qty(current.items[i].quantity)} ${current.items[i].unit} × ${_money(current.items[i].rateMinor)}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _money(current.items[i].totalMinor),
                            style: AppTextStyles.listName,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    'Payment history',
                    style: AppTextStyles.listName.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<PurchasePaymentModel>>(
                    stream: Get.find<PurchaseRepository>().watchPayments(id),
                    builder: (_, p) {
                      final payments = p.data ?? [];
                      if (payments.isEmpty) {
                        return AppGroupedTile(
                          child: Text(
                            'No payments recorded yet.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: [
                          for (var i = 0; i < payments.length; i++) ...[
                            if (i > 0) const SizedBox(height: 8),
                            AppGroupedTile(
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.successLight,
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: const Icon(
                                      Icons.payments_outlined,
                                      color: AppColors.success,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _money(payments[i].amountMinor),
                                          style: AppTextStyles.listName,
                                        ),
                                        Text(
                                          '${payments[i].method ?? 'Payment'} · ${_date(payments[i].paidAt)}',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  if ((current.notes ?? '').isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Notes',
                      style: AppTextStyles.listName.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    AppGroupedTile(child: Text(current.notes!)),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

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
            if (mounted) await _load();
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

  Future<void> _payment(PurchaseBillModel current) async {
    final amount = TextEditingController();
    try {
      final result = await showAppBottomSheet<int>(
        context: context,
        title: 'Record supplier payment',
        child: _PaymentSheet(
          controller: amount,
          balanceMinor: current.balanceMinor,
        ),
      );
      if (result != null) {
        try {
          await Get.find<PurchaseRepository>().recordPayment(
            id,
            result,
            method: 'Cash',
          );
          await _load();
        } catch (e) {
          _message(e.toString());
        }
      }
    } finally {
      amount.dispose();
    }
  }
}

class _PayMetric extends StatelessWidget {
  const _PayMetric(this.label, this.amount, this.color, this.fill);
  final String label;
  final int amount;
  final Color color;
  final Color fill;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        AppAmountText(
          amountMinor: amount,
          symbol: '₹',
          color: color,
          textAlign: TextAlign.start,
          style: AppTextStyles.listAmount.copyWith(fontSize: 13, color: color),
        ),
      ],
    ),
  );
}

class PurchaseBillRow extends StatelessWidget {
  const PurchaseBillRow({required this.bill, super.key});
  final PurchaseBillSummary bill;

  @override
  Widget build(BuildContext context) {
    final color = bill.status == 'paid'
        ? AppColors.success
        : bill.status == 'overdue'
        ? AppColors.error
        : AppColors.warning;
    final statusLabel = bill.status == 'paid'
        ? 'Paid'
        : bill.status == 'overdue'
        ? 'Overdue'
        : 'Unpaid';
    return AppGroupedTile(
      accentColor: color,
      onTap: () =>
          Get.toNamed<void>(AppRoutes.purchaseBillDetails, arguments: bill.id),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.billNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.listName,
                ),
                const SizedBox(height: 2),
                Text(
                  '${bill.supplierName} · $statusLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppAmountText(
                amountMinor: bill.totalMinor,
                symbol: '₹',
                style: AppTextStyles.listAmount,
              ),
              if (bill.balanceMinor > 0)
                Text(
                  '${_money(bill.balanceMinor)} due',
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.secondary.withValues(alpha: .16)
                : AppColors.secondaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.secondary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.listName.copyWith(fontSize: 15)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
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
  void dispose() {
    name.dispose();
    qty.dispose();
    rate.dispose();
    tax.dispose();
    super.dispose();
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
