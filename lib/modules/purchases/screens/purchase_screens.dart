import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/routes/shell_args.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/quantity_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/utils/validation_utils.dart';
import '../../../app/widgets/app_amount_text.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_bottom_sheet.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_dialog.dart';
import '../../../app/widgets/app_snapshot_visuals.dart';
import '../../../app/widgets/app_dropdown_field.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../app/widgets/app_filter_chip.dart';
import '../../../app/widgets/app_grouped_tile.dart';
import '../../../app/widgets/app_list_motion.dart';
import '../../../app/widgets/app_main_navigation.dart';
import '../../../app/widgets/app_shell.dart';
import '../../../app/widgets/app_form_grid.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../app/widgets/app_search_app_bar.dart';
import '../../../app/widgets/app_unit_field.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/models/product_service_model.dart';
import '../../../data/models/purchase_models.dart';
import '../../../data/models/debit_note_model.dart';
import '../../../data/models/scanned_invoice_line.dart';
import '../../../data/models/cash_book_models.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/debit_note_repository.dart';
import '../../../data/repositories/purchase_repository.dart';
import '../../../data/repositories/cash_book_repository.dart';
import '../../../data/services/purchase_attachment_service.dart';
import '../../../data/services/unit_service.dart';
import '../../invoices/screens/invoice_item_picker_screen.dart';
import '../../invoices/scan/product_scan_screen.dart';
import 'purchase_bill_pdf_screen.dart';

String _money(int minor) => CurrencyUtils.formatMinor(minor, symbol: '₹');
int _minor(String value) =>
    ((double.tryParse(value.trim()) ?? 0) * 100).round();
String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
String _qty(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);
String _shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
String _compactDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${value.day} ${months[value.month - 1]}';
}

Color _billStatusColor(String status) => switch (status) {
  'paid' => AppColors.success,
  'overdue' => AppColors.error,
  'cancelled' => AppColors.textTertiary,
  _ => AppColors.warning,
};

String _billStatusLabel(String status) => switch (status) {
  'paid' => 'Paid',
  'overdue' => 'Overdue',
  'partially_paid' => 'Part paid',
  'cancelled' => 'Cancelled',
  _ => 'Unpaid',
};

class PurchaseBillListScreen extends StatefulWidget {
  const PurchaseBillListScreen({
    this.embedded = false,
    this.belowTitle,
    super.key,
  });

  /// Applied once when Documents opens with a bill status filter.
  static String? pendingFilter;

  final bool embedded;
  final Widget? belowTitle;

  @override
  State<PurchaseBillListScreen> createState() => _PurchaseBillListScreenState();
}

class _PurchaseBillListScreenState extends State<PurchaseBillListScreen> {
  String query = '';
  String filter = 'all';

  @override
  void initState() {
    super.initState();
    final pending = PurchaseBillListScreen.pendingFilter;
    if (pending != null) {
      filter = pending;
      PurchaseBillListScreen.pendingFilter = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = Get.find<PurchaseRepository>();
    final searchBar = AppSearchAppBar(
      title: 'Purchase bills',
      hint: 'Bill number or supplier',
      onChanged: (value) => setState(() => query = value),
      primary: !widget.embedded,
    );
    final body = StreamBuilder<PurchaseDashboardSummary>(
      stream: repo.watchDashboard(),
      builder: (context, dashboard) {
        return StreamBuilder<List<PurchaseBillSummary>>(
          stream: repo.watchBills(query: query),
          builder: (context, snapshot) {
            final bills = snapshot.data;
            if (bills == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final visible = filter == 'all'
                ? bills
                : bills.where((bill) => bill.status == filter).toList();
            final searching = query.isNotEmpty || filter != 'all';
            return Column(
              children: [
                if (dashboard.data != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      ResponsiveUtils.horizontalPadding(context),
                      10,
                      ResponsiveUtils.horizontalPadding(context),
                      0,
                    ),
                    child: PurchaseOverviewCard(
                      data: dashboard.data!,
                      compact: true,
                    ),
                  ),
                SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.fromLTRB(
                      ResponsiveUtils.horizontalPadding(context),
                      10,
                      ResponsiveUtils.horizontalPadding(context),
                      4,
                    ),
                    children: [
                      for (final option in const [
                        ('all', 'All'),
                        ('unpaid', 'Unpaid'),
                        ('partially_paid', 'Part paid'),
                        ('overdue', 'Overdue'),
                        ('paid', 'Paid'),
                        ('cancelled', 'Cancelled'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AppFilterChip(
                            label: option.$2,
                            selected: filter == option.$1,
                            count: option.$1 == 'all'
                                ? bills.length
                                : bills
                                      .where((bill) => bill.status == option.$1)
                                      .length,
                            onSelected: (_) =>
                                setState(() => filter = option.$1),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? AppEmptyState(
                          illustration: searching
                              ? AppEmptyIllustration.search
                              : AppEmptyIllustration.invoice,
                          title: searching
                              ? 'No matching bills'
                              : 'No purchase bills yet',
                          message: searching
                              ? 'Try a different bill number, supplier or status.'
                              : 'Record supplier bills and track what you need to pay.',
                          actionLabel: searching
                              ? null
                              : 'Create purchase bill',
                          onAction: searching
                              ? null
                              : () => Get.toNamed<void>(
                                  AppRoutes.purchaseBillCreate,
                                ),
                        )
                      : ListView(
                          padding: EdgeInsets.fromLTRB(
                            ResponsiveUtils.horizontalPadding(context),
                            4,
                            ResponsiveUtils.horizontalPadding(context),
                            90,
                          ),
                          children: [
                            AppResponsiveCards(
                              itemCount: visible.length,
                              itemBuilder: (_, i) =>
                                  PurchaseBillRow(bill: visible[i], index: i),
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        );
      },
    );
    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: searchBar.preferredSize.height, child: searchBar),
          if (widget.belowTitle != null) widget.belowTitle!,
          Expanded(child: body),
        ],
      );
    }
    return AppShell(
      destination: MainDestination.documents,
      appBar: searchBar,
      body: body,
    );
  }
}

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({this.embedded = false, this.belowTitle, super.key});
  final bool embedded;
  final Widget? belowTitle;
  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final searchBar = AppSearchAppBar(
      title: 'Suppliers',
      hint: 'Name, mobile or GSTIN',
      onChanged: (value) => setState(() => query = value),
      primary: !widget.embedded,
    );
    final body = StreamBuilder<List<PurchaseBillSummary>>(
      stream: Get.find<PurchaseRepository>().watchBills(),
      builder: (context, billsSnapshot) {
        return StreamBuilder<List<SupplierModel>>(
          stream: Get.find<PurchaseRepository>().watchSuppliers(query: query),
          builder: (context, snapshot) {
            final suppliers = snapshot.data;
            if (suppliers == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (suppliers.isEmpty) {
              return AppEmptyState(
                illustration: query.isEmpty
                    ? AppEmptyIllustration.store
                    : AppEmptyIllustration.search,
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
            final bills = billsSnapshot.data ?? const <PurchaseBillSummary>[];
            return ListView(
              padding: EdgeInsets.fromLTRB(
                ResponsiveUtils.horizontalPadding(context),
                12,
                ResponsiveUtils.horizontalPadding(context),
                90,
              ),
              children: [
                AppResponsiveCards(
                  itemCount: suppliers.length,
                  itemBuilder: (_, index) {
                    final supplier = suppliers[index];
                    final own = bills
                        .where((bill) => bill.supplierId == supplier.id)
                        .toList(growable: false);
                    return AppListEntrance(
                      index: index,
                      child: SupplierSummaryCard(
                        supplier: supplier,
                        billCount: own.length,
                        billedMinor: own.fold(
                          0,
                          (sum, bill) => sum + bill.totalMinor,
                        ),
                        payableMinor: own.fold(
                          0,
                          (sum, bill) => sum + bill.balanceMinor,
                        ),
                        onNewBill: () => Get.toNamed<void>(
                          AppRoutes.purchaseBillCreate,
                          arguments: supplier,
                        ),
                        onStatement: () => Get.toNamed<void>(
                          AppRoutes.supplierStatement,
                          arguments: supplier,
                        ),
                        onEdit: () => Get.toNamed<void>(
                          AppRoutes.supplierAdd,
                          arguments: supplier,
                        ),
                        onConfirmDelete: () =>
                            _confirmDeleteSupplier(context, supplier),
                        onDelete: () => Get.find<PurchaseRepository>()
                            .deleteSupplier(supplier.id!),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: searchBar.preferredSize.height, child: searchBar),
          if (widget.belowTitle != null) widget.belowTitle!,
          Expanded(child: body),
        ],
      );
    }
    return AppShell(
      destination: MainDestination.parties,
      appBar: searchBar,
      body: body,
    );
  }

  Future<bool> _confirmDeleteSupplier(
    BuildContext context,
    SupplierModel supplier,
  ) => showAppConfirmDialog(
    context: context,
    destructive: true,
    icon: Icons.storefront_outlined,
    title: 'Delete supplier?',
    message:
        '${supplier.name} will be hidden from supplier lists. Historical purchase bills will remain unchanged.',
    confirmLabel: 'Delete',
  );
}

class SupplierStatementScreen extends StatefulWidget {
  const SupplierStatementScreen({super.key});

  @override
  State<SupplierStatementScreen> createState() =>
      _SupplierStatementScreenState();
}

class _SupplierStatementScreenState extends State<SupplierStatementScreen> {
  late final SupplierModel supplier = Get.arguments as SupplierModel;
  DateTime? from;
  DateTime? to;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: AppBarTitle(supplier.name, subtitle: 'Supplier statement'),
      actions: [
        AppBarIconButton(
          tooltip: 'New purchase bill',
          icon: Icons.add_rounded,
          onPressed: () => Get.toNamed<void>(
            AppRoutes.purchaseBillCreate,
            arguments: supplier,
          ),
        ),
      ],
    ),
    body: FutureBuilder<List<SupplierStatementEntry>>(
      future: Get.find<PurchaseRepository>().supplierStatement(
        supplier.id!,
        from: from,
        to: to,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = snapshot.data ?? const <SupplierStatementEntry>[];
        final payable = entries.isEmpty ? 0 : entries.last.balanceMinor;
        return ResponsiveContent(
          tabletMaxWidth: 720,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.secondary, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current payable',
                            style: AppTextStyles.small.copyWith(
                              color: Colors.white.withValues(alpha: .78),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _money(payable),
                            style: AppTextStyles.pageTitle.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatementDateFilter(
                      label: 'From',
                      value: from,
                      onTap: () => _pick(true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatementDateFilter(
                      label: 'To',
                      value: to,
                      onTap: () => _pick(false),
                    ),
                  ),
                  if (from != null || to != null)
                    IconButton(
                      tooltip: 'Clear dates',
                      onPressed: () => setState(() {
                        from = null;
                        to = null;
                      }),
                      icon: const Icon(Icons.close_rounded),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text('Activity', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 8),
              if (entries.isEmpty)
                const AppEmptyState(
                  illustration: AppEmptyIllustration.coins,
                  title: 'No statement activity',
                  message: 'Bills and supplier payments will appear here.',
                )
              else
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var index = 0; index < entries.length; index++)
                        _StatementEntryTile(
                          entry: entries[index],
                          showDivider: index != entries.length - 1,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );

  Future<void> _pick(bool start) async {
    final value = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDate: (start ? from : to) ?? DateTime.now(),
    );
    if (value != null) setState(() => start ? from = value : to = value);
  }
}

class _StatementDateFilter extends StatelessWidget {
  const _StatementDateFilter({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Row(
      children: [
        const Icon(Icons.calendar_today_outlined, size: 17),
        const SizedBox(width: 8),
        Expanded(child: Text(value == null ? label : _date(value!))),
      ],
    ),
  );
}

class _StatementEntryTile extends StatelessWidget {
  const _StatementEntryTile({required this.entry, required this.showDivider});
  final SupplierStatementEntry entry;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final isPayment = entry.creditMinor > 0;
    final isReversal = entry.type == 'reversal';
    final color = isReversal
        ? AppColors.error
        : isPayment
        ? AppColors.success
        : AppColors.secondary;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            )
          : null,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isReversal
                  ? Icons.undo_rounded
                  : isPayment
                  ? Icons.south_west_rounded
                  : Icons.receipt_long_outlined,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title, style: AppTextStyles.listName),
                Text(
                  '${entry.reference} · ${_date(entry.date)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isPayment
                    ? '-${_money(entry.creditMinor)}'
                    : '+${_money(entry.debitMinor)}',
                style: AppTextStyles.listAmount.copyWith(color: color),
              ),
              Text(
                'Bal ${_money(entry.balanceMinor)}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
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
  late String gstRegistrationType;
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
    gstRegistrationType = existing?.gstRegistrationType ?? 'unregistered';
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
      title: AppBarTitle(
        existing == null ? 'New supplier' : existing!.name,
        subtitle: 'Supplier',
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: AppConstrainedAction(
          child: AppButton(
            label: existing == null ? 'Save supplier' : 'Update supplier',
            icon: Icons.check_rounded,
            onPressed: _save,
          ),
        ),
      ),
    ),
    body: ResponsiveContent(
      tabletMaxWidth: 660,
      child: Form(
        key: key,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
          children: [
            AppCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SupplierFormCardHeader(
                    icon: Icons.storefront_outlined,
                    title: 'Supplier essentials',
                    subtitle: 'Only the supplier name is required',
                    badge: '1 required',
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
                  const _SupplierFormDivider(label: 'Contact (optional)'),
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
                            onPressed: isImportingContact
                                ? null
                                : _importContact,
                            icon: isImportingContact
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
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
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SupplierFormCardHeader(
                    icon: Icons.receipt_long_outlined,
                    title: 'GST & billing',
                    subtitle: 'Optional purchase record details',
                    badge: 'Optional',
                  ),
                  const SizedBox(height: 14),
                  AppDropdownField<String>(
                    label: 'GST registration',
                    sheetTitle: 'Select GST registration',
                    value: gstRegistrationType,
                    prefixIcon: Icons.account_balance_outlined,
                    options: const [
                      AppDropdownOption(
                        value: 'unregistered',
                        label: 'Unregistered / no GST',
                        icon: Icons.person_outline_rounded,
                      ),
                      AppDropdownOption(
                        value: 'regular',
                        label: 'Regular GST',
                        icon: Icons.verified_outlined,
                      ),
                      AppDropdownOption(
                        value: 'composition',
                        label: 'Composition scheme',
                        icon: Icons.store_outlined,
                      ),
                      AppDropdownOption(
                        value: 'sez',
                        label: 'SEZ',
                        icon: Icons.apartment_outlined,
                      ),
                    ],
                    onChanged: (value) => setState(() {
                      gstRegistrationType = value;
                      if (value == 'unregistered') gstin.clear();
                    }),
                  ),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: gstRegistrationType == 'unregistered'
                        ? const _GstHint(key: ValueKey('gst-hint'))
                        : KeyedSubtree(
                            key: const ValueKey('gstin-field'),
                            child: _field(
                              gstin,
                              'GSTIN *',
                              validator: _validateGstin,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(15),
                                FilteringTextInputFormatter.allow(
                                  RegExp('[0-9a-zA-Z]'),
                                ),
                              ],
                            ),
                          ),
                  ),
                  _field(address, 'Billing address', lines: 3),
                ],
              ),
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
        gstRegistrationType: gstRegistrationType,
        gstin: gstRegistrationType == 'unregistered'
            ? null
            : _null(gstin.text.toUpperCase()),
        address: _null(address.text),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );
    Get.back<void>();
  }

  String? _validateGstin(String? value) {
    final normalized = value?.trim().toUpperCase() ?? '';
    if (gstRegistrationType == 'unregistered') return null;
    if (normalized.isEmpty) return 'GSTIN is required for this registration.';
    return RegExp(
          r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$',
        ).hasMatch(normalized)
        ? null
        : 'Enter a valid GSTIN (for example, 24ABCDE1234F1Z5).';
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

class _SupplierFormCardHeader extends StatelessWidget {
  const _SupplierFormCardHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  final IconData icon;
  final String title, subtitle, badge;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.listName),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: .7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          badge,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _SupplierFormDivider extends StatelessWidget {
  const _SupplierFormDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 2, 2, 12),
    child: Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    ),
  );
}

class _GstHint extends StatelessWidget {
  const _GstHint({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(2, 0, 2, 12),
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Row(
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 18,
          color: AppColors.primary,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            'Select a registered GST type when you need to store a GSTIN.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
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
  final placeOfSupply = TextEditingController();
  final discount = TextEditingController();
  final additionalCharges = TextEditingController();
  SupplierModel? supplier;
  DateTime billDate = DateTime.now();
  DateTime? dueDate;
  final items = <PurchaseItemModel>[];
  PurchaseBillModel? existing;
  bool loading = true;
  String supplierQuery = '';
  String taxMode = 'cgst_sgst';
  bool reverseCharge = false;
  bool itcEligible = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    number.dispose();
    notes.dispose();
    placeOfSupply.dispose();
    discount.dispose();
    additionalCharges.dispose();
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
      placeOfSupply.text = e.placeOfSupply ?? '';
      taxMode = e.taxMode;
      reverseCharge = e.reverseCharge;
      itcEligible = e.itcEligible;
      discount.text = e.discountMinor == 0
          ? ''
          : (e.discountMinor / 100).toStringAsFixed(2);
      additionalCharges.text = e.additionalChargesMinor == 0
          ? ''
          : (e.additionalChargesMinor / 100).toStringAsFixed(2);
      items.addAll(e.items);
      final suppliers = await Get.find<PurchaseRepository>()
          .watchSuppliers()
          .first;
      supplier = suppliers.where((s) => s.id == e.supplierId).firstOrNull;
    } else {
      number.text =
          'PB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      if (arg is SupplierModel) supplier = arg;
    }
    if (mounted) setState(() => loading = false);
  }

  int get itemSubtotal => items.fold(0, (s, i) => s + i.subtotalMinor);
  int get taxTotal => items.fold(0, (s, i) => s + i.taxMinor);
  int get itemsTotal => itemSubtotal + taxTotal;
  int get discountMinor => _minor(discount.text);
  int get additionalChargesMinor => _minor(additionalCharges.text);
  int get total =>
      (itemsTotal - discountMinor + additionalChargesMinor).clamp(0, 1 << 62);
  @override
  Widget build(BuildContext context) {
    final ready = !loading && (existing != null || supplier != null);
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: AppBarTitle(
          existing == null ? 'New purchase bill' : 'Edit purchase bill',
          subtitle: 'Purchase',
        ),
        actions: [
          AppBarIconButton(
            tooltip: l10n('Preview PDF'),
            onPressed: ready && items.isNotEmpty ? _previewPdf : null,
            icon: Icons.picture_as_pdf_outlined,
          ),
        ],
      ),
      bottomNavigationBar: ready ? _billFormFooter(context) : null,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : existing == null && supplier == null
          ? _supplierSelectionStep()
          : ResponsiveContent(
              tabletMaxWidth: 720,
              child: Form(
                key: key,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    AppCard(
                      padding: EdgeInsets.zero,
                      borderColor: AppColors.secondary.withValues(alpha: .16),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: _chooseSupplier,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                14,
                                14,
                                14,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: .14),
                                    AppColors.secondary.withValues(alpha: .10),
                                  ],
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.secondary,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: supplier == null
                                        ? const Icon(
                                            Icons.storefront_outlined,
                                            color: Colors.white,
                                          )
                                        : Text(
                                            supplier!.name.characters.first
                                                .toUpperCase(),
                                            style: AppTextStyles.cardTitle
                                                .copyWith(color: Colors.white),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          supplier?.name ?? 'Choose a supplier',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.cardTitle,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          supplier == null
                                              ? 'Required for this purchase bill'
                                              : () {
                                                  final caption =
                                                      [
                                                            supplier!
                                                                .companyName,
                                                            supplier!.mobile,
                                                            supplier!.gstin,
                                                          ]
                                                          .whereType<String>()
                                                          .where(
                                                            (value) => value
                                                                .trim()
                                                                .isNotEmpty,
                                                          )
                                                          .join(' · ');
                                                  return caption.isEmpty
                                                      ? 'Supplier'
                                                      : caption;
                                                }(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.small.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(
                                        color: AppColors.secondary.withValues(
                                          alpha: .18,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          supplier == null
                                              ? 'Select'
                                              : 'Change',
                                          style: AppTextStyles.small.copyWith(
                                            color: AppColors.secondary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          size: 18,
                                          color: AppColors.secondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                            child: Column(
                              children: [
                                _field(
                                  number,
                                  'Supplier bill number *',
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Bill number is required'
                                      : null,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceSoft,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _BillMetaCell(
                                          icon: Icons.calendar_today_outlined,
                                          label: 'Bill date',
                                          value: _shortDate(billDate),
                                          onTap: () async {
                                            final d = await showDatePicker(
                                              context: context,
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime(2100),
                                              initialDate: billDate,
                                            );
                                            if (d != null) {
                                              setState(() => billDate = d);
                                            }
                                          },
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 32,
                                        color: AppColors.border,
                                      ),
                                      Expanded(
                                        child: _BillMetaCell(
                                          icon: Icons.event_available_outlined,
                                          label: 'Due date',
                                          value: dueDate == null
                                              ? 'Add date'
                                              : _shortDate(dueDate!),
                                          muted: dueDate == null,
                                          onTap: () async {
                                            final d = await showDatePicker(
                                              context: context,
                                              firstDate: billDate,
                                              lastDate: DateTime(2100),
                                              initialDate: dueDate ?? billDate,
                                            );
                                            if (d != null) {
                                              setState(() => dueDate = d);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                'Purchased items',
                                style: AppTextStyles.sectionTitle,
                              ),
                              if (items.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    '${items.length}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (items.isNotEmpty)
                          FilledButton.tonalIcon(
                            onPressed: _showAddItemOptions,
                            icon: const Icon(Icons.add_rounded, size: 19),
                            label: const Text('Add'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 40),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (items.isEmpty)
                      _PurchaseEmptyItemsCard(onAdd: _showAddItemOptions)
                    else
                      for (var i = 0; i < items.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryLight,
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      child: Text(
                                        '${i + 1}',
                                        style: AppTextStyles.small.copyWith(
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            items[i].name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.cardTitle,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_money(items[i].rateMinor)} / ${items[i].unit}${items[i].taxRate > 0 ? ' • GST ${_qty(items[i].taxRate)}%' : ''}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.small.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: l10n('Edit item details'),
                                      onPressed: () => _editItem(i),
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppColors.primaryLight,
                                        foregroundColor: AppColors.primary,
                                        minimumSize: const Size(36, 36),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _PurchaseQuantityStepper(
                                      value: _qty(items[i].quantity),
                                      canDecrease: items[i].quantity > 1,
                                      onDecrease: () => _setItemQuantity(
                                        i,
                                        items[i].quantity <= 2
                                            ? 1
                                            : items[i].quantity - 1,
                                      ),
                                      onRemove: () => _confirmRemoveItem(i),
                                      onIncrease: () => _setItemQuantity(
                                        i,
                                        items[i].quantity + 1,
                                      ),
                                      onEdit: () => _editItemQuantity(i),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _money(items[i].totalMinor),
                                      style: AppTextStyles.cardTitle.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    const SizedBox(height: 4),
                    if (items.isNotEmpty) ...[
                      _PurchaseLiveTotalCard(
                        subtotalMinor: itemSubtotal,
                        taxMinor: taxTotal,
                        discountMinor: discountMinor,
                        chargesMinor: additionalChargesMinor,
                        totalMinor: total,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _PurchaseTaxEvidenceCard(
                      placeOfSupply: placeOfSupply,
                      discount: discount,
                      additionalCharges: additionalCharges,
                      taxMode: taxMode,
                      reverseCharge: reverseCharge,
                      itcEligible: itcEligible,
                      onTaxModeChanged: (value) =>
                          setState(() => taxMode = value),
                      onReverseChargeChanged: (value) =>
                          setState(() => reverseCharge = value),
                      onItcEligibleChanged: (value) =>
                          setState(() => itcEligible = value),
                      onAmountChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    _PurchaseNotesCard(controller: notes),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _billFormFooter(BuildContext context) {
    final actionWidth = (MediaQuery.sizeOf(context).width * .56)
        .clamp(168.0, 240.0)
        .toDouble();
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: AppConstrainedAction(
          maxWidth: ResponsiveUtils.footerMaxWidth(context),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      items.isEmpty ? 'NO ITEMS YET' : 'PURCHASE TOTAL',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _money(total),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sectionTitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: actionWidth,
                child: AppButton(
                  label: items.isEmpty
                      ? 'Add item'
                      : existing == null
                      ? 'Save bill'
                      : 'Update bill',
                  icon: items.isEmpty ? Icons.add_rounded : Icons.check_rounded,
                  onPressed: items.isEmpty ? _showAddItemOptions : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _supplierSelectionStep() => ResponsiveContent(
    tabletMaxWidth: 720,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: .13),
                  AppColors.secondary.withValues(alpha: .08),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const _Intro(
              icon: Icons.storefront_outlined,
              title: 'Who supplied this purchase?',
              subtitle:
                  'We will prepare the bill with this supplier’s details.',
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          onChanged: (value) => setState(() => supplierQuery = value),
          decoration: const InputDecoration(
            hintText: 'Search supplier, mobile or GSTIN',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 14),
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
            stream: Get.find<PurchaseRepository>().watchSuppliers(
              query: supplierQuery,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final suppliers = snapshot.data!;
              if (suppliers.isEmpty) {
                return AppEmptyState(
                  illustration: supplierQuery.isEmpty
                      ? AppEmptyIllustration.store
                      : AppEmptyIllustration.search,
                  title: supplierQuery.isEmpty
                      ? 'No suppliers yet'
                      : 'No matching supplier',
                  message: supplierQuery.isEmpty
                      ? 'Create your first supplier, then continue with the purchase bill.'
                      : 'Try another name, mobile number or GSTIN.',
                  actionLabel: supplierQuery.isEmpty ? 'Create supplier' : null,
                  onAction: supplierQuery.isEmpty
                      ? () => Get.toNamed<void>(AppRoutes.supplierAdd)
                      : null,
                );
              }
              return ListView.separated(
                itemCount: suppliers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final value = suppliers[index];
                  return AppGroupedTile(
                    onTap: () => setState(() => supplier = value),
                    padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
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
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 17,
                            color: AppColors.primary,
                          ),
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
    final chosen = await showAppBottomSheet<SupplierModel>(
      context: context,
      title: 'Select supplier',
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .62,
        child: StreamBuilder<List<SupplierModel>>(
          stream: Get.find<PurchaseRepository>().watchSuppliers(),
          builder: (_, snapshot) {
            final suppliers = snapshot.data ?? [];
            if (snapshot.connectionState == ConnectionState.waiting &&
                suppliers.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              children: [
                Expanded(
                  child: suppliers.isEmpty
                      ? AppEmptyState(
                          illustration: AppEmptyIllustration.store,
                          title: 'No suppliers yet',
                          message:
                              'Create a supplier, then continue this bill.',
                          actionLabel: 'Create supplier',
                          onAction: () {
                            Navigator.pop(context);
                            Get.toNamed<void>(AppRoutes.supplierAdd);
                          },
                        )
                      : ListView.separated(
                          itemCount: suppliers.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, index) {
                            final value = suppliers[index];
                            return AppGroupedTile(
                              onTap: () => Navigator.pop(context, value),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          value.name,
                                          style: AppTextStyles.listName,
                                        ),
                                        Text(
                                          value.companyName ??
                                              value.mobile ??
                                              'Supplier',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Create supplier',
                  icon: Icons.person_add_alt_1_rounded,
                  onPressed: () {
                    Navigator.pop(context);
                    Get.toNamed<void>(AppRoutes.supplierAdd);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
    if (chosen != null) setState(() => supplier = chosen);
  }

  Future<void> _showAddItemOptions() async {
    final choice = await showModalBottomSheet<_PurchaseAddItemChoice>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Add an item', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 6),
                Text(
                  'Choose how you want to add this purchase line.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _PurchaseAddItemOption(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Scan barcodes',
                  subtitle: 'Add saved products by scanning their codes',
                  onTap: () =>
                      Navigator.pop(sheetContext, _PurchaseAddItemChoice.scan),
                ),
                const SizedBox(height: 10),
                _PurchaseAddItemOption(
                  icon: Icons.inventory_2_outlined,
                  title: 'Choose saved item',
                  subtitle: 'Use a product or service from your catalog',
                  onTap: () =>
                      Navigator.pop(sheetContext, _PurchaseAddItemChoice.saved),
                ),
                const SizedBox(height: 10),
                _PurchaseAddItemOption(
                  icon: Icons.edit_note_rounded,
                  title: 'Create custom item',
                  subtitle: 'Enter a one-time item for this purchase bill',
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _PurchaseAddItemChoice.custom,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case _PurchaseAddItemChoice.scan:
        await _scanCatalogItems();
      case _PurchaseAddItemChoice.saved:
        await _selectSavedItems();
      case _PurchaseAddItemChoice.custom:
        await _addCustomItem();
    }
  }

  Future<void> _selectSavedItems() async {
    final selected = await Get.toNamed<dynamic>(
      AppRoutes.invoiceItemPicker,
      arguments: InvoiceItemPickerArgs(
        alreadyAddedIds: items
            .map((item) => item.productId)
            .whereType<int>()
            .toSet(),
        alreadyAddedLabel: 'On this bill',
      ),
    );
    if (!mounted || selected is! InvoiceItemPickerResult) return;
    setState(() {
      if (selected.removedIds.isNotEmpty) {
        items.removeWhere(
          (item) =>
              item.productId != null &&
              selected.removedIds.contains(item.productId),
        );
      }
      for (final product in selected.added) {
        _addOrIncrementCatalog(product);
      }
    });
  }

  Future<void> _scanCatalogItems() async {
    final result = await Get.toNamed<dynamic>(
      AppRoutes.productScan,
      arguments: const ProductScanArgs(),
    );
    if (!mounted || result is! List<ScannedInvoiceLine>) return;
    setState(() {
      for (final line in result) {
        _addOrIncrementCatalog(
          line.product,
          quantity: line.quantityScaled / QuantityUtils.scale,
        );
      }
    });
  }

  void _addOrIncrementCatalog(
    ProductServiceModel product, {
    double quantity = 1,
  }) {
    final existingIndex = items.indexWhere(
      (item) => product.id != null && item.productId == product.id,
    );
    if (existingIndex >= 0) {
      items[existingIndex] = items[existingIndex].copyWith(
        quantity: items[existingIndex].quantity + quantity,
      );
      return;
    }
    items.add(PurchaseItemModel.fromCatalog(product, quantity: quantity));
  }

  Future<void> _addCustomItem() async {
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

  void _setItemQuantity(int index, double quantity) {
    if (quantity <= 0) return;
    setState(() => items[index] = items[index].copyWith(quantity: quantity));
  }

  Future<void> _editItemQuantity(int index) async {
    final quantity = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PurchaseQuantitySheet(
        value: items[index].quantity,
        unit: items[index].unit,
      ),
    );
    if (quantity != null) _setItemQuantity(index, quantity);
  }

  Future<void> _confirmRemoveItem(int index) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      destructive: true,
      icon: Icons.delete_outline_rounded,
      title: 'Remove item?',
      message: 'This item will be removed from this purchase bill.',
      confirmLabel: 'Remove item',
      cancelLabel: 'Keep item',
    );
    if (confirmed) setState(() => items.removeAt(index));
  }

  PurchaseBillModel _draftBill() {
    final now = DateTime.now();
    return PurchaseBillModel(
      id: existing?.id,
      billNumber: number.text.trim().isEmpty ? 'PB-DRAFT' : number.text.trim(),
      supplierId: supplier?.id,
      supplierName: supplier?.name ?? 'Supplier',
      billDate: billDate,
      dueDate: dueDate,
      items: List.of(items),
      paidMinor: existing?.paidMinor ?? 0,
      notes: _null(notes.text),
      placeOfSupply: _null(placeOfSupply.text),
      taxMode: taxMode,
      reverseCharge: reverseCharge,
      itcEligible: itcEligible,
      discountMinor: discountMinor,
      additionalChargesMinor: additionalChargesMinor,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
  }

  Future<void> _previewPdf() async {
    if (supplier == null) {
      _message('Select a supplier before saving.');
      return;
    }
    if (items.isEmpty) {
      _message('Add at least one purchased item.');
      return;
    }
    if (!(key.currentState?.validate() ?? false)) return;
    final profile = await Get.find<BusinessRepository>().getProfile();
    if (profile == null || profile.businessName.trim().isEmpty) {
      AppNotification.warning(
        'Business details needed',
        'Complete business setup before generating a PDF.',
      );
      return;
    }
    await Get.toNamed<void>(
      AppRoutes.purchaseBillPdf,
      arguments: PurchaseBillPdfArgs.draft(_draftBill()),
    );
  }

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
        .isBillNumberAvailable(
          number.text,
          excludingId: existing?.id,
          supplierId: supplier!.id,
          billDate: billDate,
        );
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
        placeOfSupply: _null(placeOfSupply.text),
        taxMode: taxMode,
        reverseCharge: reverseCharge,
        itcEligible: itcEligible,
        discountMinor: discountMinor,
        additionalChargesMinor: additionalChargesMinor,
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
  List<DebitNoteSummaryModel> debitNotes = const [];
  List<DebitNoteSummaryModel> unappliedCredit = const [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await Get.find<PurchaseRepository>().getBill(id);
    final notes = value == null
        ? const <DebitNoteSummaryModel>[]
        : await Get.find<DebitNoteRepository>().listForBill(id);
    final unapplied = value?.supplierId == null
        ? const <DebitNoteSummaryModel>[]
        : await Get.find<DebitNoteRepository>().unappliedForSupplier(
            value!.supplierId!,
          );
    if (!mounted) return;
    setState(() {
      bill = value;
      debitNotes = notes;
      unappliedCredit = unapplied;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = bill;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: AppBarTitle(
          current?.billNumber ?? 'Purchase bill',
          subtitle: current == null ? null : 'Purchase bill',
        ),
        actions: [
          AppBarIconButton(
            tooltip: l10n('Preview PDF'),
            onPressed: current == null ? null : _openPdf,
            icon: Icons.picture_as_pdf_outlined,
          ),
          AppBarIconButton(
            tooltip: l10n('Bill actions'),
            onPressed: _showBillActions,
            icon: Icons.more_vert_rounded,
          ),
        ],
      ),
      bottomNavigationBar:
          current != null &&
              current.balanceMinor > 0 &&
              current.status != 'cancelled'
          ? SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: const Border(
                    top: BorderSide(color: AppColors.border),
                  ),
                ),
                child: AppConstrainedAction(
                  child: AppButton(
                    label: 'Record payment',
                    icon: Icons.payments_outlined,
                    onPressed: () => _payment(current),
                  ),
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
                  _PurchaseBillHero(bill: current),
                  if (debitNotes.isNotEmpty || unappliedCredit.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _PurchaseDebitNotesCard(
                      notes: debitNotes,
                      unapplied: unappliedCredit,
                      canApply:
                          current.balanceMinor > 0 &&
                          current.status != 'cancelled',
                      onOpen: (note) async {
                        await Get.toNamed<void>(
                          AppRoutes.debitNoteDetails,
                          arguments: note.id,
                        );
                        if (mounted) await _load();
                      },
                      onApply: _applySupplierCredit,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _PurchasePaymentCard(
                    bill: current,
                    billId: id,
                    onChanged: _load,
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Items',
                            style: AppTextStyles.listName.copyWith(
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Text(
                          '${current.items.length} ${current.items.length == 1 ? 'item' : 'items'}',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < current.items.length; i++)
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                            decoration: i == current.items.length - 1
                                ? null
                                : const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: AppColors.border,
                                      ),
                                    ),
                                  ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Text(
                                    '${i + 1}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        current.items[i].name,
                                        style: AppTextStyles.listName,
                                      ),
                                      Text(
                                        '${_qty(current.items[i].quantity)} ${current.items[i].unit} × ${_money(current.items[i].rateMinor)} · GST ${_qty(current.items[i].taxRate)}%',
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
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.secondaryLight,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(
                                Icons.account_balance_outlined,
                                size: 18,
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tax & GST',
                                    style: AppTextStyles.listName,
                                  ),
                                  Text(
                                    'Purchase tax treatment',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 22),
                        _EvidenceRow('Tax treatment', switch (current.taxMode) {
                          'igst' => 'IGST',
                          'exempt' => 'Exempt / no GST',
                          _ => 'CGST + SGST',
                        }),
                        _EvidenceRow(
                          'Place of supply',
                          current.placeOfSupply ?? 'Not recorded',
                        ),
                        _EvidenceRow(
                          'Input tax credit',
                          current.itcEligible ? 'Eligible' : 'Not eligible',
                        ),
                        if (current.reverseCharge)
                          const _EvidenceRow('Reverse charge', 'Applicable'),
                        if (current.discountMinor > 0)
                          _EvidenceRow(
                            'Bill discount',
                            '-${_money(current.discountMinor)}',
                          ),
                        if (current.additionalChargesMinor > 0)
                          _EvidenceRow(
                            'Other charges',
                            _money(current.additionalChargesMinor),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _PurchaseAttachmentsCard(
                    billId: id,
                    onAdd: _addAttachment,
                    onDelete: _deleteAttachment,
                  ),
                  if (current.status == 'cancelled') ...[
                    const SizedBox(height: 16),
                    AppCard(
                      color: AppColors.error.withValues(alpha: .06),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.block_rounded,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cancelled bill',
                                  style: AppTextStyles.listName.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                                Text(
                                  current.cancellationReason ??
                                      'No reason recorded.',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if ((current.notes ?? '').isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Notes',
                      style: AppTextStyles.listName.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    AppCard(child: Text(current.notes!)),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Future<void> _openPdf() async {
    final current = bill;
    if (current == null) return;
    final profile = await Get.find<BusinessRepository>().getProfile();
    if (profile == null || profile.businessName.trim().isEmpty) {
      AppNotification.warning(
        'Business details needed',
        'Complete business setup before generating a PDF.',
      );
      return;
    }
    await Get.toNamed<void>(
      AppRoutes.purchaseBillPdf,
      arguments: PurchaseBillPdfArgs.saved(id),
    );
  }

  Future<void> _addAttachment() async {
    try {
      final stored = await Get.find<PurchaseAttachmentService>().pickAndStore();
      if (stored == null) return;
      await Get.find<PurchaseRepository>().addAttachment(
        PurchaseBillAttachmentModel(
          purchaseBillId: id,
          fileName: stored.fileName,
          localPath: stored.relativePath,
          mimeType: stored.mimeType,
          sizeBytes: stored.sizeBytes,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      _message(e.toString());
    }
  }

  Future<void> _deleteAttachment(PurchaseBillAttachmentModel attachment) async {
    await Get.find<PurchaseAttachmentService>().delete(attachment.localPath);
    await Get.find<PurchaseRepository>().deleteAttachment(attachment.id!);
  }

  Future<void> _showBillActions() => showAppBottomSheet<void>(
    context: context,
    title: 'Purchase bill actions',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionTile(
          icon: Icons.picture_as_pdf_outlined,
          title: 'Generate PDF',
          subtitle: 'Preview, share, save or print this purchase bill.',
          onTap: () {
            Navigator.pop(context);
            _openPdf();
          },
        ),
        if (debitNotes.isEmpty)
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
          icon: Icons.copy_all_outlined,
          title: 'Duplicate bill',
          subtitle: 'Create a new draft with the same supplier and items.',
          onTap: () async {
            Navigator.pop(context);
            try {
              final copyId = await Get.find<PurchaseRepository>().duplicateBill(
                id,
              );
              Get.toNamed<void>(
                AppRoutes.purchaseBillCreate,
                arguments: copyId,
              );
            } catch (e) {
              _message(e.toString());
            }
          },
        ),
        if (bill?.status != 'cancelled')
          _ActionTile(
            icon: Icons.assignment_return_outlined,
            title: 'Debit note / Purchase return',
            subtitle: 'Return items or value without rewriting this bill.',
            onTap: () async {
              Navigator.pop(context);
              await Get.toNamed<void>(AppRoutes.debitNoteCreate, arguments: id);
              if (mounted) await _load();
            },
          ),
        if (bill?.status != 'cancelled' && debitNotes.isEmpty)
          _ActionTile(
            icon: Icons.block_outlined,
            title: 'Cancel bill',
            subtitle: 'Keep an audit record without counting it in totals.',
            destructive: true,
            onTap: () async {
              Navigator.pop(context);
              final reason = await _askReason(
                context,
                title: 'Why are you cancelling this bill?',
                hint: 'Cancellation reason *',
                action: 'Cancel bill',
              );
              if (reason == null) return;
              try {
                await Get.find<PurchaseRepository>().cancelBill(
                  id,
                  reason: reason,
                );
                await _load();
              } catch (e) {
                _message(e.toString());
              }
            },
          ),
        if (debitNotes.isEmpty)
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
              try {
                final repository = Get.find<PurchaseRepository>();
                final files = await repository.watchAttachments(id).first;
                await repository.deleteBill(id);
                for (final file in files) {
                  await Get.find<PurchaseAttachmentService>().delete(
                    file.localPath,
                  );
                }
                Get.offAllNamed<void>(
                  AppRoutes.documents,
                  arguments: const DocumentsOpenArgs(purchases: true),
                );
              } catch (e) {
                _message(e.toString());
              }
            },
          ),
      ],
    ),
  );

  Future<void> _applySupplierCredit(DebitNoteSummaryModel note) async {
    final current = bill;
    if (current == null || current.balanceMinor <= 0) return;
    final amount = note.unappliedMinor < current.balanceMinor
        ? note.unappliedMinor
        : current.balanceMinor;
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Apply supplier credit?',
      message:
          'Apply ${CurrencyUtils.formatMinor(amount, symbol: '₹')} from ${note.debitNoteNumber} to this bill.',
      confirmLabel: 'Apply credit',
    );
    if (!confirmed) return;
    try {
      await Get.find<DebitNoteRepository>().applyUnapplied(
        debitNoteId: note.id,
        billId: id,
        amountMinor: amount,
      );
      AppNotification.success(
        'Credit applied',
        '${note.debitNoteNumber} was applied.',
      );
      await _load();
    } catch (e) {
      _message(e.toString());
    }
  }

  Future<void> _payment(PurchaseBillModel current) async {
    final result = await showAppBottomSheet<_PaymentResult>(
      context: context,
      title: 'Record supplier payment',
      child: _PaymentSheet(balanceMinor: current.balanceMinor),
    );
    if (result == null) return;
    try {
      await Get.find<PurchaseRepository>().recordPayment(
        id,
        result.amountMinor,
        method: result.method,
        reference: result.reference,
        note: result.note,
        paidAt: result.date,
        accountId: result.accountId,
      );
      await _load();
    } catch (e) {
      _message(e.toString());
    }
  }
}

class PurchaseOverviewCard extends StatelessWidget {
  const PurchaseOverviewCard({
    required this.data,
    this.onPayableTap,
    this.onOverdueTap,
    this.compact = false,
    super.key,
  });

  final PurchaseDashboardSummary data;
  final VoidCallback? onPayableTap;
  final VoidCallback? onOverdueTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!compact) {
      final progress = data.totalSpendMinor <= 0
          ? 0.0
          : (data.paidMinor / data.totalSpendMinor).clamp(0.0, 1.0);
      return AppCard(
        padding: EdgeInsets.zero,
        color: isDark ? const Color(0xFF3B2038) : Colors.white,
        borderColor: isDark ? AppColors.darkBorder : const Color(0xFFE9DFF0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSnapshotHero(
              title: 'Payables snapshot',
              trailing: AppSnapshotBadge(
                label: data.overdueMinor > 0 ? 'Action needed' : 'On track',
              ),
              subtitle:
                  '${data.billCount} ${data.billCount == 1 ? 'bill' : 'bills'} · ${data.supplierCount} ${data.supplierCount == 1 ? 'supplier' : 'suppliers'}',
              amountCaption: 'Amount to pay',
              amountMinor: data.payableMinor,
              symbol: '₹',
              progress: progress,
              ringCaption: 'Paid',
              onAmountTap: data.payableMinor > 0 ? onPayableTap : null,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Row(
                children: [
                  Expanded(
                    child: AppMetricChip(
                      label: 'Purchased',
                      amountMinor: data.totalSpendMinor,
                      symbol: '₹',
                      color: AppColors.secondary,
                      icon: Icons.shopping_bag_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppMetricChip(
                      label: 'Paid',
                      amountMinor: data.paidMinor,
                      symbol: '₹',
                      color: AppColors.success,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppMetricChip(
                      label: 'Overdue',
                      amountMinor: data.overdueMinor,
                      symbol: '₹',
                      color: AppColors.error,
                      icon: Icons.error_outline_rounded,
                      onTap: data.overdueMinor > 0 ? onOverdueTap : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final metrics = [
      (
        label: 'Paid',
        amount: data.paidMinor,
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.success,
        onTap: null,
      ),
      (
        label: 'Payable',
        amount: data.payableMinor,
        icon: Icons.schedule_rounded,
        color: AppColors.warning,
        onTap: onPayableTap,
      ),
      (
        label: 'Overdue',
        amount: data.overdueMinor,
        icon: Icons.error_outline_rounded,
        color: AppColors.error,
        onTap: onOverdueTap,
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: metrics[i].onTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 25,
                                  height: 25,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: metrics[i].color.withValues(
                                      alpha: 0.11,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    metrics[i].icon,
                                    size: 15,
                                    color: metrics[i].color,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    metrics[i].label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 9.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            AppAmountText(
                              amountMinor: metrics[i].amount,
                              symbol: '₹',
                              color: metrics[i].color,
                              textAlign: TextAlign.start,
                              style: AppTextStyles.listAmount.copyWith(
                                fontSize: 13,
                                color: metrics[i].color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (i != metrics.length - 1)
                  Container(
                    width: 1,
                    height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class PurchaseBillRow extends StatelessWidget {
  const PurchaseBillRow({required this.bill, this.index = 0, super.key});
  final PurchaseBillSummary bill;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = _billStatusColor(bill.status);
    final statusLabel = _billStatusLabel(bill.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final dateHint = bill.dueDate == null
        ? 'Bill ${_compactDate(bill.billDate)}'
        : 'Due ${_compactDate(bill.dueDate!)}';
    return AppListEntrance(
      index: index,
      child: AppGroupedTile(
        accentColor: color,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        onTap: () => Get.toNamed<void>(
          AppRoutes.purchaseBillDetails,
          arguments: bill.id,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    bill.billNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.listName.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.22 : 0.11),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: color,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  flex: 7,
                  child: Row(
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 13,
                        color: secondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          bill.supplierName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: AppAmountText(
                    amountMinor: bill.totalMinor,
                    symbol: '₹',
                    textAlign: TextAlign.end,
                    style: AppTextStyles.listAmount.copyWith(fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 11,
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          dateHint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (bill.balanceMinor > 0)
                  AppAmountText(
                    amountMinor: bill.balanceMinor,
                    symbol: '₹',
                    suffix: ' due',
                    textAlign: TextAlign.end,
                    color: color,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseBillHero extends StatelessWidget {
  const _PurchaseBillHero({required this.bill});
  final PurchaseBillModel bill;

  String get _status {
    if (bill.status == 'cancelled') return 'cancelled';
    if (bill.balanceMinor <= 0) return 'paid';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (bill.dueDate != null && bill.dueDate!.isBefore(today)) return 'overdue';
    return 'unpaid';
  }

  List<Color> get _colors => switch (_status) {
    'paid' => const [AppColors.secondary, AppColors.success],
    'overdue' => const [AppColors.secondary, AppColors.error],
    'cancelled' => const [AppColors.textSecondary, AppColors.textTertiary],
    _ => const [AppColors.secondary, AppColors.primary],
  };

  @override
  Widget build(BuildContext context) {
    final colors = _colors;
    final status = _status;
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .14)),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: .2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -40,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${bill.items.length} ${bill.items.length == 1 ? 'item' : 'items'}  •  ${_date(bill.billDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: .78),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      _billStatusLabel(status),
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .2),
                      ),
                    ),
                    child: Text(
                      bill.supplierName.trim().isEmpty
                          ? '?'
                          : bill.supplierName.characters.first.toUpperCase(),
                      style: AppTextStyles.listName.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Supplier',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: .7),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          bill.supplierName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.listName.copyWith(
                            color: Colors.white,
                            fontSize: 14.5,
                          ),
                        ),
                        if (bill.dueDate != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            'Due ${_date(bill.dueDate!)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: .78),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        bill.balanceMinor > 0 ? 'Balance due' : 'Bill total',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: .72),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AppAmountText(
                        amountMinor: bill.balanceMinor > 0
                            ? bill.balanceMinor
                            : bill.totalMinor,
                        symbol: '₹',
                        textAlign: TextAlign.end,
                        color: Colors.white,
                        style: AppTextStyles.sectionTitle.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PurchaseAttachmentsCard extends StatelessWidget {
  const _PurchaseAttachmentsCard({
    required this.billId,
    required this.onAdd,
    required this.onDelete,
  });
  final int billId;
  final VoidCallback onAdd;
  final Future<void> Function(PurchaseBillAttachmentModel) onDelete;

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<List<PurchaseBillAttachmentModel>>(
    stream: Get.find<PurchaseRepository>().watchAttachments(billId),
    builder: (context, snapshot) {
      final files = snapshot.data ?? const <PurchaseBillAttachmentModel>[];
      return AppCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.attach_file_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Original bill files',
                    style: AppTextStyles.listName,
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Attach original bill',
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded, size: 19),
                ),
              ],
            ),
            if (files.isEmpty)
              Text(
                'Attach the supplier PDF or photo for future verification.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else
              for (final file in files)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  minVerticalPadding: 6,
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      file.mimeType == 'application/pdf'
                          ? Icons.picture_as_pdf_outlined
                          : Icons.image_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    file.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    file.sizeBytes < 1024 * 1024
                        ? '${(file.sizeBytes / 1024).ceil()} KB'
                        : '${(file.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                    style: AppTextStyles.caption,
                  ),
                  onTap: () async {
                    try {
                      await Get.find<PurchaseAttachmentService>().share(
                        file.localPath,
                        fileName: file.fileName,
                      );
                    } catch (e) {
                      _message(e.toString());
                    }
                  },
                  trailing: IconButton(
                    tooltip: 'Remove attachment',
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () async {
                      final confirmed = await showAppConfirmDialog(
                        context: context,
                        title: 'Remove attachment?',
                        message:
                            'The stored copy will be removed from this device.',
                        confirmLabel: 'Remove',
                        destructive: true,
                      );
                      if (confirmed) await onDelete(file);
                    },
                  ),
                ),
          ],
        ),
      );
    },
  );
}

class _PurchasePaymentCard extends StatelessWidget {
  const _PurchasePaymentCard({
    required this.bill,
    required this.billId,
    required this.onChanged,
  });
  final PurchaseBillModel bill;
  final int billId;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final remainingColor = bill.balanceMinor > 0
        ? AppColors.warning
        : AppColors.success;
    final remainingFill = bill.balanceMinor > 0
        ? AppColors.warningLight
        : AppColors.successLight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'Payment activity',
            style: AppTextStyles.listName.copyWith(fontSize: 15),
          ),
        ),
        AppCard(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _PayMetric(
                      'Total',
                      bill.totalMinor,
                      AppColors.secondary,
                      AppColors.secondaryLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PayMetric(
                      'Paid',
                      bill.paidMinor,
                      AppColors.success,
                      AppColors.successLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PayMetric(
                      'Remaining',
                      bill.balanceMinor,
                      remainingColor,
                      remainingFill,
                    ),
                  ),
                ],
              ),
              StreamBuilder<List<PurchasePaymentModel>>(
                stream: Get.find<PurchaseRepository>().watchPayments(billId),
                builder: (_, snapshot) {
                  final payments = snapshot.data ?? [];
                  if (payments.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'No payments recorded yet.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      const Divider(height: 24),
                      for (var i = 0; i < payments.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onLongPress: payments[i].entryType == 'payment'
                              ? () => _reverse(context, payments[i])
                              : null,
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: payments[i].entryType == 'reversal'
                                      ? AppColors.error.withValues(alpha: .1)
                                      : AppColors.successLight,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Icon(
                                  payments[i].entryType == 'reversal'
                                      ? Icons.undo_rounded
                                      : Icons.payments_outlined,
                                  color: payments[i].entryType == 'reversal'
                                      ? AppColors.error
                                      : AppColors.success,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      payments[i].entryType == 'reversal'
                                          ? 'Payment reversal'
                                          : payments[i].method ?? 'Payment',
                                      style: AppTextStyles.listName,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_date(payments[i].paidAt)}${payments[i].reference == null ? '' : ' · ${payments[i].reference}'}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              AppAmountText(
                                amountMinor: payments[i].amountMinor.abs(),
                                symbol: payments[i].entryType == 'reversal'
                                    ? '-₹'
                                    : '₹',
                                textAlign: TextAlign.end,
                                color: payments[i].entryType == 'reversal'
                                    ? AppColors.error
                                    : AppColors.success,
                                style: AppTextStyles.listAmount.copyWith(
                                  color: payments[i].entryType == 'reversal'
                                      ? AppColors.error
                                      : AppColors.success,
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
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _reverse(
    BuildContext context,
    PurchasePaymentModel payment,
  ) async {
    final reason = await _askReason(
      context,
      title: 'Reverse this supplier payment?',
      hint: 'Reversal reason *',
      action: 'Reverse payment',
    );
    if (reason == null) return;
    try {
      await Get.find<PurchaseRepository>().reversePayment(
        payment.id,
        reason: reason,
      );
      await onChanged();
      AppNotification.success(
        'Payment reversed',
        'The payable balance and audit trail were updated.',
      );
    } catch (e) {
      _message(e.toString());
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: .18) : fill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          AppAmountText(
            amountMinor: amount,
            symbol: '₹',
            color: color,
            textAlign: TextAlign.start,
            style: AppTextStyles.listAmount.copyWith(
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _BillMetaCell extends StatelessWidget {
  const _BillMetaCell({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.muted = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: AppColors.primary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(fontSize: 9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.small.copyWith(
                color: muted
                    ? AppColors.textTertiary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PurchaseEmptyItemsCard extends StatelessWidget {
  const _PurchaseEmptyItemsCard({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onAdd,
    padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
    child: Column(
      children: [
        const AppEmptyArt(
          illustration: AppEmptyIllustration.package,
          width: 120,
          height: 90,
          semanticLabel: 'No items yet',
        ),
        const SizedBox(height: 8),
        Text('No items yet', style: AppTextStyles.listName),
        const SizedBox(height: 4),
        Text(
          'Add a saved product, scan a barcode, or enter a one-time item.',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        AppButton(
          label: 'Add an item',
          icon: Icons.add_rounded,
          onPressed: onAdd,
        ),
      ],
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

class _PurchaseItemSheet extends StatefulWidget {
  const _PurchaseItemSheet({this.initial});
  final PurchaseItemModel? initial;
  @override
  State<_PurchaseItemSheet> createState() => _PurchaseItemSheetState();
}

class _PurchaseItemSheetState extends State<_PurchaseItemSheet> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name, qty, rate, tax, hsnSac;
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
    hsnSac = TextEditingController(text: initial?.hsnSac);
  }

  @override
  void dispose() {
    name.dispose();
    qty.dispose();
    rate.dispose();
    tax.dispose();
    hsnSac.dispose();
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
                  _field(
                    hsnSac,
                    'HSN / SAC',
                    keyboard: TextInputType.text,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(8),
                      FilteringTextInputFormatter.allow(RegExp('[0-9a-zA-Z]')),
                    ],
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
        productId: widget.initial?.productId,
        name: name.text.trim(),
        quantity: q,
        unit: unit,
        hsnSac: _null(hsnSac.text.toUpperCase()),
        rateMinor: (r * 100).round(),
        taxRate: t,
      ),
    );
  }
}

class _PurchaseNotesCard extends StatelessWidget {
  const _PurchaseNotesCard({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    child: ExpansionTile(
      initiallyExpanded: controller.text.trim().isNotEmpty,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 10),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.notes_rounded,
          size: 19,
          color: AppColors.primary,
        ),
      ),
      title: Text('Notes', style: AppTextStyles.listName),
      subtitle: Text(
        controller.text.trim().isEmpty
            ? 'Optional details for your records'
            : 'Notes added to this purchase bill',
        style: AppTextStyles.caption,
      ),
      children: [
        TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Add delivery, reference or internal notes',
          ),
        ),
      ],
    ),
  );
}

class _PurchaseLiveTotalCard extends StatelessWidget {
  const _PurchaseLiveTotalCard({
    required this.subtotalMinor,
    required this.taxMinor,
    required this.discountMinor,
    required this.chargesMinor,
    required this.totalMinor,
  });

  final int subtotalMinor;
  final int taxMinor;
  final int discountMinor;
  final int chargesMinor;
  final int totalMinor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.secondary.withValues(alpha: .09),
          AppColors.primary.withValues(alpha: .07),
        ],
      ),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.secondary.withValues(alpha: .14)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.calculate_outlined,
                size: 19,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Bill summary', style: AppTextStyles.listName),
            ),
            Text(
              _money(totalMinor),
              style: AppTextStyles.sectionTitle.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _CompactTotalMetric(
                label: 'Subtotal',
                amount: subtotalMinor,
              ),
            ),
            Expanded(
              child: _CompactTotalMetric(label: 'GST', amount: taxMinor),
            ),
            if (discountMinor > 0)
              Expanded(
                child: _CompactTotalMetric(
                  label: 'Discount',
                  amount: -discountMinor,
                ),
              ),
            if (chargesMinor > 0)
              Expanded(
                child: _CompactTotalMetric(
                  label: 'Charges',
                  amount: chargesMinor,
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _CompactTotalMetric extends StatelessWidget {
  const _CompactTotalMetric({required this.label, required this.amount});
  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.caption.copyWith(fontSize: 9.5)),
      const SizedBox(height: 2),
      Text(
        _money(amount),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _PurchaseTaxEvidenceCard extends StatelessWidget {
  const _PurchaseTaxEvidenceCard({
    required this.placeOfSupply,
    required this.discount,
    required this.additionalCharges,
    required this.taxMode,
    required this.reverseCharge,
    required this.itcEligible,
    required this.onTaxModeChanged,
    required this.onReverseChargeChanged,
    required this.onItcEligibleChanged,
    required this.onAmountChanged,
  });

  final TextEditingController placeOfSupply;
  final TextEditingController discount;
  final TextEditingController additionalCharges;
  final String taxMode;
  final bool reverseCharge;
  final bool itcEligible;
  final ValueChanged<String> onTaxModeChanged;
  final ValueChanged<bool> onReverseChargeChanged;
  final ValueChanged<bool> onItcEligibleChanged;
  final VoidCallback onAmountChanged;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
    child: ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.secondaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.verified_outlined, color: AppColors.secondary),
      ),
      title: Text('Tax & bill evidence', style: AppTextStyles.cardTitle),
      subtitle: Text(
        'GST treatment, ITC and final adjustments',
        style: AppTextStyles.caption,
      ),
      children: [
        const SizedBox(height: 10),
        TextField(
          controller: placeOfSupply,
          decoration: const InputDecoration(
            labelText: 'Place of supply',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
        const SizedBox(height: 10),
        AppDropdownField<String>(
          label: 'Tax treatment',
          sheetTitle: 'Choose tax treatment',
          value: taxMode,
          prefixIcon: Icons.account_balance_outlined,
          options: const [
            AppDropdownOption(
              value: 'cgst_sgst',
              label: 'Intra-state · CGST + SGST',
              icon: Icons.call_split_rounded,
            ),
            AppDropdownOption(
              value: 'igst',
              label: 'Inter-state · IGST',
              icon: Icons.swap_horiz_rounded,
            ),
            AppDropdownOption(
              value: 'exempt',
              label: 'Exempt / no GST',
              icon: Icons.money_off_csred_outlined,
            ),
          ],
          onChanged: onTaxModeChanged,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: discount,
                onChanged: (_) => onAmountChanged(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Bill discount',
                  prefixText: '₹ ',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: additionalCharges,
                onChanged: (_) => onAmountChanged(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Other charges',
                  prefixText: '₹ ',
                ),
              ),
            ),
          ],
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Eligible for input tax credit'),
          subtitle: const Text('Include this bill in your ITC evidence'),
          value: itcEligible,
          onChanged: onItcEligibleChanged,
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Reverse charge applies'),
          subtitle: const Text('Tax is payable under reverse charge'),
          value: reverseCharge,
          onChanged: onReverseChargeChanged,
        ),
      ],
    ),
  );
}

class _PaymentResult {
  const _PaymentResult({
    required this.amountMinor,
    required this.method,
    required this.date,
    this.reference,
    this.note,
    this.accountId,
  });
  final int amountMinor;
  final String method;
  final DateTime date;
  final String? reference, note;
  final int? accountId;
}

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({required this.balanceMinor});
  final int balanceMinor;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  late final TextEditingController amount;
  final reference = TextEditingController();
  final note = TextEditingController();
  String method = 'Bank transfer';
  DateTime date = DateTime.now();
  int? accountId;
  List<MoneyAccountModel> accounts = const [];

  @override
  void initState() {
    super.initState();
    amount = TextEditingController();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    if (!Get.isRegistered<CashBookRepository>()) return;
    final rows = await Get.find<CashBookRepository>().activeAccounts();
    if (!mounted) return;
    setState(() {
      accounts = rows;
      accountId = rows
          .where(
            (account) =>
                account.accountType == MoneyAccountTypeX.fromMethod(method),
          )
          .firstOrNull
          ?.id;
      accountId ??= rows.firstOrNull?.id;
    });
  }

  @override
  void dispose() {
    amount.dispose();
    reference.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: const EdgeInsets.only(bottom: 2),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Intro(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Payment due ${_money(widget.balanceMinor)}',
          subtitle: 'Record only the amount already paid to your supplier.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: amount,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount paid *',
            prefixIcon: Icon(Icons.currency_rupee_rounded),
          ),
        ),
        const SizedBox(height: 10),
        AppDropdownField<String>(
          label: 'Payment method',
          sheetTitle: 'Choose payment method',
          value: method,
          prefixIcon: Icons.account_balance_wallet_outlined,
          options: const [
            AppDropdownOption(
              value: 'Bank transfer',
              label: 'Bank transfer',
              icon: Icons.account_balance_outlined,
            ),
            AppDropdownOption(
              value: 'UPI',
              label: 'UPI',
              icon: Icons.qr_code_2_rounded,
            ),
            AppDropdownOption(
              value: 'Cash',
              label: 'Cash',
              icon: Icons.payments_outlined,
            ),
            AppDropdownOption(
              value: 'Cheque',
              label: 'Cheque',
              icon: Icons.receipt_long_outlined,
            ),
            AppDropdownOption(
              value: 'Card',
              label: 'Card',
              icon: Icons.credit_card_rounded,
            ),
            AppDropdownOption(
              value: 'Other',
              label: 'Other',
              icon: Icons.more_horiz_rounded,
            ),
          ],
          onChanged: (value) => setState(() {
            method = value;
            accountId = accounts
                .where(
                  (account) =>
                      account.accountType ==
                      MoneyAccountTypeX.fromMethod(value),
                )
                .firstOrNull
                ?.id;
            accountId ??= accounts.firstOrNull?.id;
          }),
        ),
        if (accounts.length > 1) ...[
          const SizedBox(height: 10),
          AppDropdownField<int>(
            label: 'Account',
            sheetTitle: 'Cash-book account',
            value: accountId ?? accounts.first.id!,
            options: [
              for (final account in accounts)
                AppDropdownOption(
                  value: account.id!,
                  label: account.name,
                  icon: account.accountType.icon,
                ),
            ],
            onChanged: (value) => setState(() => accountId = value),
          ),
        ],
        const SizedBox(height: 10),
        TextField(
          controller: reference,
          decoration: const InputDecoration(
            labelText: 'Reference / transaction ID',
            prefixIcon: Icon(Icons.tag_rounded),
          ),
        ),
        const SizedBox(height: 10),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: const Icon(Icons.event_available_outlined),
          title: const Text('Payment date'),
          subtitle: Text(_date(date)),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () async {
            final value = await showDatePicker(
              context: context,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
              initialDate: date,
            );
            if (value != null) setState(() => date = value);
          },
        ),
        TextField(
          controller: note,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Payment note'),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'Record payment',
          icon: Icons.check_rounded,
          onPressed: () {
            final value = double.tryParse(amount.text);
            final minor = value == null ? 0 : (value * 100).round();
            if (minor <= 0 || minor > widget.balanceMinor) {
              AppNotification.warning(
                'Check payment amount',
                'Enter an amount between ₹0.01 and ${_money(widget.balanceMinor)}.',
              );
              return;
            }
            Navigator.pop(
              context,
              _PaymentResult(
                amountMinor: minor,
                method: method,
                date: date,
                reference: _null(reference.text),
                note: _null(note.text),
                accountId: accountId,
              ),
            );
          },
        ),
      ],
    ),
  );
}

class _PurchaseDebitNotesCard extends StatelessWidget {
  const _PurchaseDebitNotesCard({
    required this.notes,
    required this.unapplied,
    required this.canApply,
    required this.onOpen,
    required this.onApply,
  });

  final List<DebitNoteSummaryModel> notes;
  final List<DebitNoteSummaryModel> unapplied;
  final bool canApply;
  final ValueChanged<DebitNoteSummaryModel> onOpen;
  final ValueChanged<DebitNoteSummaryModel> onApply;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty && unapplied.isEmpty) return const SizedBox.shrink();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Debit notes', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          for (final note in notes)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(note.debitNoteNumber),
              subtitle: Text(note.reason),
              trailing: Text(
                CurrencyUtils.formatMinor(note.grandTotalMinor, symbol: '₹'),
              ),
              onTap: () => onOpen(note),
            ),
          if (canApply && unapplied.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Supplier credit', style: AppTextStyles.cardTitle),
            for (final note in unapplied)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(note.debitNoteNumber),
                subtitle: Text(
                  'Available ${CurrencyUtils.formatMinor(note.unappliedMinor, symbol: '₹')}',
                ),
                trailing: TextButton(
                  onPressed: () => onApply(note),
                  child: const Text('Apply'),
                ),
              ),
          ],
        ],
      ),
    );
  }
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

enum _PurchaseAddItemChoice { scan, saved, custom }

class _PurchaseAddItemOption extends StatelessWidget {
  const _PurchaseAddItemOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.cardTitle),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    ),
  );
}

class _PurchaseQuantityStepper extends StatelessWidget {
  const _PurchaseQuantityStepper({
    required this.value,
    required this.canDecrease,
    required this.onDecrease,
    required this.onRemove,
    required this.onIncrease,
    required this.onEdit,
  });

  final String value;
  final bool canDecrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;
  final VoidCallback onIncrease;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Container(
    height: 34,
    decoration: BoxDecoration(
      color: AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: canDecrease ? 'Decrease quantity' : 'Remove item',
          onPressed: canDecrease ? onDecrease : onRemove,
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          padding: EdgeInsets.zero,
          icon: Icon(
            canDecrease ? Icons.remove_rounded : Icons.delete_outline_rounded,
            size: 17,
            color: canDecrease ? null : AppColors.error,
          ),
        ),
        Container(width: 1, height: 22, color: AppColors.border),
        Tooltip(
          message: 'Enter quantity',
          child: InkWell(
            onTap: onEdit,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 34),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.small.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(width: 1, height: 22, color: AppColors.border),
        IconButton(
          tooltip: l10n('Increase quantity'),
          onPressed: onIncrease,
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.add_rounded, size: 17),
        ),
      ],
    ),
  );
}

class _PurchaseQuantitySheet extends StatefulWidget {
  const _PurchaseQuantitySheet({required this.value, required this.unit});
  final double value;
  final String unit;

  @override
  State<_PurchaseQuantitySheet> createState() => _PurchaseQuantitySheetState();
}

class _PurchaseQuantitySheetState extends State<_PurchaseQuantitySheet> {
  late final TextEditingController input = TextEditingController(
    text: _qty(widget.value),
  );
  String? error;

  @override
  void initState() {
    super.initState();
    input.selection = TextSelection(
      baseOffset: 0,
      extentOffset: input.text.length,
    );
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  void _save() {
    final value = double.tryParse(input.text.trim());
    if (value == null || value <= 0) {
      setState(() => error = 'Enter a quantity greater than 0.');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Enter quantity', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 4),
        Text(
          'Type the exact quantity instead of tapping + repeatedly.',
          style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: input,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
          ],
          decoration: InputDecoration(
            labelText: l10n('Quantity *'),
            suffixText: widget.unit,
            errorText: error,
            prefixIcon: const Icon(Icons.numbers_rounded),
          ),
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Update quantity'),
        ),
      ],
    ),
  );
}

class SupplierSummaryCard extends StatelessWidget {
  const SupplierSummaryCard({
    required this.supplier,
    required this.onNewBill,
    required this.onStatement,
    required this.onEdit,
    required this.onConfirmDelete,
    required this.onDelete,
    required this.billedMinor,
    required this.payableMinor,
    required this.billCount,
    super.key,
  });

  final SupplierModel supplier;
  final VoidCallback onNewBill;
  final VoidCallback onStatement;
  final VoidCallback onEdit;
  final Future<bool> Function() onConfirmDelete;
  final Future<void> Function() onDelete;
  final int billedMinor;
  final int payableMinor;
  final int billCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusLabel = billCount == 0
        ? 'No bills'
        : payableMinor > 0
        ? 'Payable'
        : 'Paid';
    final statusColor = payableMinor > 0
        ? AppColors.warning
        : billCount == 0
        ? AppColors.textTertiary
        : AppColors.success;
    return Dismissible(
      key: ValueKey('supplier-${supplier.id}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit();
          return false;
        }
        return onConfirmDelete();
      },
      onDismissed: (_) => onDelete(),
      background: const _SupplierSwipeBackground(
        alignment: Alignment.centerLeft,
        color: AppColors.accent,
        icon: Icons.edit_rounded,
        label: 'Edit',
      ),
      secondaryBackground: const _SupplierSwipeBackground(
        alignment: Alignment.centerRight,
        color: AppColors.error,
        icon: Icons.delete_outline_rounded,
        label: 'Delete',
      ),
      child: GestureDetector(
        onLongPress: () => _showActions(context),
        child: AppGroupedTile(
          accentColor: statusColor,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          onTap: onStatement,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  supplier.name.characters.first.toUpperCase(),
                  style: AppTextStyles.listName.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            supplier.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.listName,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(
                              alpha: isDark ? 0.22 : 0.11,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusLabel,
                            style: AppTextStyles.caption.copyWith(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            billCount == 0
                                ? (supplier.mobile ?? 'Ready for a new bill')
                                : payableMinor > 0
                                ? '$billCount ${billCount == 1 ? 'bill' : 'bills'} payable'
                                : '$billCount ${billCount == 1 ? 'bill' : 'bills'} settled',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 108,
                          child: AppAmountText(
                            amountMinor: payableMinor > 0
                                ? payableMinor
                                : billedMinor,
                            symbol: '₹',
                            textAlign: TextAlign.end,
                            color: payableMinor == 0 && billCount > 0
                                ? (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textTertiary)
                                : null,
                            style: AppTextStyles.listAmount.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(supplier.name, style: AppTextStyles.sectionTitle),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('New bill'),
                subtitle: const Text('Start a purchase bill for this supplier'),
                onTap: () => Navigator.pop(context, 'bill'),
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('View statement'),
                subtitle: const Text('Bills, payments and running balance'),
                onTap: () => Navigator.pop(context, 'statement'),
              ),
              ListTile(
                leading: const Icon(Icons.savings_outlined),
                title: const Text('Record supplier advance'),
                subtitle: const Text('Pay now and apply to bills later'),
                onTap: () => Navigator.pop(context, 'advance'),
              ),
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Edit supplier'),
                subtitle: const Text('Update contact and GST details'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                textColor: AppColors.error,
                iconColor: AppColors.error,
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Delete supplier'),
                subtitle: const Text('Bills already recorded stay unchanged'),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == 'bill') {
      onNewBill();
    } else if (action == 'statement') {
      onStatement();
    } else if (action == 'advance') {
      Get.toNamed<void>(
        AppRoutes.cashBookAdvance,
        arguments: CashBookAdvanceArgs(
          partyType: PartyKind.supplier,
          partyId: supplier.id,
          partyName: supplier.name,
        ),
      );
    } else if (action == 'edit') {
      onEdit();
    } else if (action == 'delete' && await onConfirmDelete()) {
      await onDelete();
    }
  }
}

class _SupplierSwipeBackground extends StatelessWidget {
  const _SupplierSwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    alignment: alignment,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (alignment == Alignment.centerRight)
          Text(label, style: const TextStyle(color: Colors.white)),
        if (alignment == Alignment.centerRight) const SizedBox(width: 8),
        Icon(icon, color: Colors.white),
        if (alignment == Alignment.centerLeft) const SizedBox(width: 8),
        if (alignment == Alignment.centerLeft)
          Text(label, style: const TextStyle(color: Colors.white)),
      ],
    ),
  );
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
Future<String?> _askReason(
  BuildContext context, {
  required String title,
  required String hint,
  required String action,
}) async {
  final controller = TextEditingController();
  final result = await showAppBottomSheet<String>(
    context: context,
    title: title,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          maxLength: 240,
          decoration: InputDecoration(
            labelText: hint,
            prefixIcon: const Icon(Icons.edit_note_rounded),
          ),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: action,
          icon: Icons.check_rounded,
          onPressed: () {
            final value = controller.text.trim();
            if (value.isEmpty) {
              AppNotification.warning(
                'Reason required',
                'Add a short reason to keep the audit trail complete.',
              );
              return;
            }
            Navigator.pop(context, value);
          },
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

void _message(String value) =>
    AppNotification.warning('Complete required details', value);
