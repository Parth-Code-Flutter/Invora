import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/enums/item_type.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../data/models/product_service_model.dart';
import '../../../data/models/scanned_invoice_line.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/product_repository.dart';

class InvoiceItemPickerArgs {
  const InvoiceItemPickerArgs({this.alreadyAddedIds = const {}});

  final Set<int> alreadyAddedIds;
}

class InvoiceItemPickerResult {
  const InvoiceItemPickerResult({
    required this.added,
    required this.removedIds,
  });

  final List<ProductServiceModel> added;
  final Set<int> removedIds;
}

class InvoiceItemPickerScreen extends StatefulWidget {
  const InvoiceItemPickerScreen({super.key});

  @override
  State<InvoiceItemPickerScreen> createState() =>
      _InvoiceItemPickerScreenState();
}

class _InvoiceItemPickerScreenState extends State<InvoiceItemPickerScreen> {
  final _repository = Get.find<ProductRepository>();
  final _businessRepository = Get.find<BusinessRepository>();
  final _search = TextEditingController();
  final Set<int> _selectedIds = {};
  final Map<int, ProductServiceModel> _knownItems = {};
  late final Set<int> _alreadyAdded;
  late Stream<List<ProductServiceModel>> _itemsStream;
  Timer? _searchDebounce;
  ItemType? _filter;
  String _currency = '₹';

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    _alreadyAdded = args is InvoiceItemPickerArgs
        ? Set<int>.from(args.alreadyAddedIds)
        : <int>{};
    _selectedIds.addAll(_alreadyAdded);
    _itemsStream = _repository.watchItems();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final profile = await _businessRepository.getProfile();
    if (!mounted) return;
    setState(() => _currency = profile?.currencySymbol ?? '₹');
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Add saved items'),
        actions: [
          IconButton(
            tooltip: 'Scan barcodes',
            onPressed: _scanItems,
            icon: const Icon(Icons.qr_code_scanner_rounded),
          ),
          IconButton(
            tooltip: 'Create product or service',
            onPressed: _createItem,
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            ResponsiveUtils.horizontalPadding(context),
            10,
            ResponsiveUtils.horizontalPadding(context),
            12,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: const Border(top: BorderSide(color: AppColors.border)),
          ),
          child: AppButton(
            label: !_hasChanges
                ? (_alreadyAdded.isEmpty
                      ? 'Select items to add'
                      : 'No item changes')
                : _alreadyAdded.isEmpty
                ? 'Add ${_addedIds.length} ${_addedIds.length == 1 ? 'item' : 'items'}'
                : 'Apply item changes',
            icon: Icons.add_shopping_cart_rounded,
            onPressed: !_hasChanges
                ? null
                : () => Get.back<InvoiceItemPickerResult>(
                    result: InvoiceItemPickerResult(
                      added: _addedIds
                          .map((id) => _knownItems[id])
                          .whereType<ProductServiceModel>()
                          .toList(growable: false),
                      removedIds: _alreadyAdded.difference(_selectedIds),
                    ),
                  ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveUtils.contentMaxWidth(context),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveUtils.horizontalPadding(context),
                  8,
                  ResponsiveUtils.horizontalPadding(context),
                  0,
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _search,
                      onChanged: (_) {
                        _searchDebounce?.cancel();
                        _searchDebounce = Timer(
                          const Duration(milliseconds: 220),
                          _refreshItems,
                        );
                        setState(() {});
                      },
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search name, description or HSN/SAC',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _searchDebounce?.cancel();
                                  _search.clear();
                                  _refreshItems();
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _FilterChip(
                                  label: 'All',
                                  selected: _filter == null,
                                  onTap: () => _setFilter(null),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Products',
                                  icon: Icons.inventory_2_outlined,
                                  selected: _filter == ItemType.product,
                                  onTap: () => _setFilter(ItemType.product),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Services',
                                  icon: Icons.design_services_outlined,
                                  selected: _filter == ItemType.service,
                                  onTap: () => _setFilter(ItemType.service),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: StreamBuilder<List<ProductServiceModel>>(
                  stream: _itemsStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = snapshot.data!;
                    for (final item in items) {
                      if (item.id != null) _knownItems[item.id!] = item;
                    }
                    if (items.isEmpty) return _emptyState();
                    final selectable = items
                        .where((item) => item.id != null)
                        .toList(growable: false);
                    final allVisibleSelected =
                        selectable.isNotEmpty &&
                        selectable.every(
                          (item) => _selectedIds.contains(item.id),
                        );
                    final selectedVisibleCount = selectable
                        .where((item) => _selectedIds.contains(item.id))
                        .length;
                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.horizontalPadding(
                              context,
                            ),
                            vertical: 5,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${items.length} ${items.length == 1 ? 'result' : 'results'}${_selectedIds.isEmpty ? '' : ' · ${_selectedIds.length} selected'}',
                                  style: AppTextStyles.small.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              if (selectable.isNotEmpty)
                                Tooltip(
                                  message: allVisibleSelected
                                      ? 'Deselect visible items'
                                      : 'Select visible items',
                                  child: Checkbox(
                                    tristate: true,
                                    value: allVisibleSelected
                                        ? true
                                        : selectedVisibleCount > 0
                                        ? null
                                        : false,
                                    onChanged: (_) => setState(() {
                                      if (allVisibleSelected) {
                                        for (final item in selectable) {
                                          _selectedIds.remove(item.id);
                                        }
                                      } else {
                                        for (final item in selectable) {
                                          _selectedIds.add(item.id!);
                                        }
                                      }
                                    }),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                              ResponsiveUtils.horizontalPadding(context),
                              4,
                              ResponsiveUtils.horizontalPadding(context),
                              24,
                            ),
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 9),
                            itemBuilder: (context, index) =>
                                _itemTile(items[index]),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemTile(ProductServiceModel item) {
    final id = item.id;
    final alreadyAdded = id != null && _alreadyAdded.contains(id);
    final selected = id != null && _selectedIds.contains(id);
    return Semantics(
      button: id != null,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : null,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: id == null
                ? null
                : () => setState(() {
                    if (selected) {
                      _selectedIds.remove(id);
                    } else {
                      _selectedIds.add(id);
                    }
                  }),
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: item.type == ItemType.product
                          ? AppColors.primaryLight
                          : AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      item.type == ItemType.product
                          ? Icons.inventory_2_outlined
                          : Icons.design_services_outlined,
                      color: item.type == ItemType.product
                          ? AppColors.primary
                          : AppColors.secondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardTitle,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${item.type.label} · ${CurrencyUtils.formatMinor(item.salePriceMinor, symbol: _currency)} / ${item.unit}${item.taxRateBasisPoints > 0 ? ' · GST ${item.taxRateBasisPoints / 100}%' : ''}${alreadyAdded ? (selected ? ' · On invoice' : ' · Will remove') : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Checkbox(
                    value: selected,
                    onChanged: id == null
                        ? null
                        : (_) => setState(() {
                            if (selected) {
                              _selectedIds.remove(id);
                            } else {
                              _selectedIds.add(id);
                            }
                          }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: 14),
          Text(
            _search.text.isEmpty ? 'No saved items yet' : 'No matching items',
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: 6),
          Text(
            _search.text.isEmpty
                ? 'Create a reusable product or service to add it here.'
                : 'Try another search or change the item type filter.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          if (_search.text.isEmpty) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _createItem,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create item'),
            ),
          ],
        ],
      ),
    ),
  );

  Future<void> _scanItems() async {
    final result = await Get.toNamed<dynamic>(AppRoutes.productScan);
    if (!mounted || result is! List<ScannedInvoiceLine>) return;
    setState(() {
      for (final line in result) {
        final id = line.product.id;
        if (id == null) continue;
        _knownItems[id] = line.product;
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _createItem() async {
    final result = await Get.toNamed<dynamic>(AppRoutes.productAdd);
    if (!mounted || result is! ProductServiceModel || result.id == null) return;
    setState(() {
      _knownItems[result.id!] = result;
      _selectedIds.add(result.id!);
    });
  }

  Set<int> get _addedIds => _selectedIds.difference(_alreadyAdded);

  bool get _hasChanges =>
      _addedIds.isNotEmpty || _alreadyAdded.difference(_selectedIds).isNotEmpty;

  void _setFilter(ItemType? value) {
    _filter = value;
    _refreshItems();
  }

  void _refreshItems() {
    setState(() {
      _itemsStream = _repository.watchItems(query: _search.text, type: _filter);
    });
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    selected: selected,
    onSelected: (_) => onTap(),
    avatar: icon == null ? null : Icon(icon, size: 17),
    label: Text(label),
  );
}
