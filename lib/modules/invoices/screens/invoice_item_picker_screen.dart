import 'dart:async';

import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/enums/item_type.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../app/widgets/app_filter_chip.dart';
import '../../../app/widgets/app_form_grid.dart';
import '../../../data/models/product_service_model.dart';
import '../../../data/models/scanned_invoice_line.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/product_repository.dart';

class InvoiceItemPickerArgs {
  const InvoiceItemPickerArgs({
    this.alreadyAddedIds = const {},
    this.alreadyAddedLabel = 'On invoice',
  });

  final Set<int> alreadyAddedIds;
  final String alreadyAddedLabel;
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
  late final String _alreadyAddedLabel;
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
    _alreadyAddedLabel = args is InvoiceItemPickerArgs
        ? args.alreadyAddedLabel
        : 'On invoice';
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
        title: const AppBarTitle('Add saved items'),
        actions: [
          AppBarIconButton(
            tooltip: l10n('Scan barcodes'),
            onPressed: _scanItems,
            icon: Icons.qr_code_scanner_rounded,
          ),
          AppBarIconButton(
            tooltip: l10n('Create product or service'),
            onPressed: _createItem,
            icon: Icons.add_rounded,
          ),
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
          child: AppConstrainedAction(
            child: AppButton(
              label: _actionLabel,
              icon: _hasChanges
                  ? Icons.check_circle_outline_rounded
                  : Icons.playlist_add_check_rounded,
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
                        hintText: l10n('Search saved items'),
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: l10n('Clear search'),
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          AppFilterChip(
                            label: 'All',
                            selected: _filter == null,
                            onSelected: (_) => _setFilter(null),
                          ),
                          const SizedBox(width: 8),
                          AppFilterChip(
                            label: 'Products',
                            icon: Icons.inventory_2_outlined,
                            selected: _filter == ItemType.product,
                            onSelected: (_) => _setFilter(ItemType.product),
                          ),
                          const SizedBox(width: 8),
                          AppFilterChip(
                            label: 'Services',
                            icon: Icons.design_services_outlined,
                            selected: _filter == ItemType.service,
                            onSelected: (_) => _setFilter(ItemType.service),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: StreamBuilder<List<ProductServiceModel>>(
                  stream: _itemsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _loadErrorState();
                    }
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
                          padding: EdgeInsets.fromLTRB(
                            ResponsiveUtils.horizontalPadding(context),
                            4,
                            ResponsiveUtils.horizontalPadding(context),
                            8,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${items.length} ${items.length == 1 ? 'saved item' : 'saved items'}',
                                      style: AppTextStyles.small.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectionSummary,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selectable.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                Semantics(
                                  button: true,
                                  checked: allVisibleSelected,
                                  label: allVisibleSelected
                                      ? 'Deselect all visible items'
                                      : 'Select all visible items',
                                  child: Tooltip(
                                    message: allVisibleSelected
                                        ? 'Deselect visible items'
                                        : 'Select visible items',
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: allVisibleSelected
                                            ? AppColors.primaryLight
                                            : Theme.of(
                                                context,
                                              ).colorScheme.surface,
                                        borderRadius: BorderRadius.circular(13),
                                        border: Border.all(
                                          color: allVisibleSelected
                                              ? AppColors.primary
                                              : AppColors.border,
                                        ),
                                      ),
                                      child: Checkbox(
                                        tristate: true,
                                        value: allVisibleSelected
                                            ? true
                                            : selectedVisibleCount > 0
                                            ? null
                                            : false,
                                        onChanged: (_) =>
                                            _toggleVisibleSelection(
                                              selectable,
                                              allVisibleSelected:
                                                  allVisibleSelected,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Expanded(
                          child: ResponsiveUtils.isTablet(context)
                              ? ListView(
                                  padding: EdgeInsets.fromLTRB(
                                    ResponsiveUtils.horizontalPadding(context),
                                    4,
                                    ResponsiveUtils.horizontalPadding(context),
                                    24,
                                  ),
                                  children: [
                                    AppResponsiveCards(
                                      itemCount: items.length,
                                      itemBuilder: (context, index) =>
                                          _itemTile(items[index]),
                                    ),
                                  ],
                                )
                              : ListView.separated(
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
    final newlyAdded = selected && !alreadyAdded;
    final markedForRemoval = alreadyAdded && !selected;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stateTone = markedForRemoval
        ? AppColors.error
        : newlyAdded
        ? AppColors.primary
        : alreadyAdded
        ? AppColors.success
        : AppColors.border;
    final stateSurface = markedForRemoval
        ? AppColors.errorLight
        : newlyAdded
        ? AppColors.primaryLight
        : alreadyAdded
        ? AppColors.successLight.withValues(alpha: .42)
        : isDark
        ? AppColors.darkSurface
        : AppColors.surface;
    return Semantics(
      button: id != null,
      selected: selected,
      label:
          '${item.name}, ${CurrencyUtils.formatMinor(item.salePriceMinor, symbol: _currency)} per ${item.unit}, ${_itemStateLabel(alreadyAdded: alreadyAdded, selected: selected)}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: stateSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: stateTone,
            width: newlyAdded || markedForRemoval ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: id == null
                ? null
                : () => _toggleItem(id, selected: selected),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
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
                  const SizedBox(width: 11),
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
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '${CurrencyUtils.formatMinor(item.salePriceMinor, symbol: _currency)} / ${item.unit}${item.taxRateBasisPoints > 0 ? ' · GST ${item.taxRateBasisPoints / 100}%' : ''}',
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (alreadyAdded || newlyAdded || markedForRemoval)
                              _ItemStateBadge(
                                label: _itemStateLabel(
                                  alreadyAdded: alreadyAdded,
                                  selected: selected,
                                ),
                                color: stateTone,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Checkbox(
                    value: selected,
                    activeColor: alreadyAdded && selected
                        ? AppColors.success
                        : AppColors.primary,
                    onChanged: id == null
                        ? null
                        : (_) => _toggleItem(id, selected: selected),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _itemStateLabel({required bool alreadyAdded, required bool selected}) {
    if (alreadyAdded && selected) return _alreadyAddedLabel;
    if (alreadyAdded) return 'Will remove';
    if (selected) return 'Will add';
    return 'Not selected';
  }

  void _toggleItem(int id, {required bool selected}) {
    setState(() {
      if (selected) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleVisibleSelection(
    List<ProductServiceModel> selectable, {
    required bool allVisibleSelected,
  }) {
    setState(() {
      for (final item in selectable) {
        final id = item.id;
        if (id == null) continue;
        if (allVisibleSelected) {
          _selectedIds.remove(id);
        } else {
          _selectedIds.add(id);
        }
      }
    });
  }

  Widget _loadErrorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.sync_problem_rounded,
            size: 44,
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          Text('Could not load saved items', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 6),
          Text(
            'Your invoice is unchanged. Try loading the catalog again.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _refreshItems,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );

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

  Set<int> get _removedIds => _alreadyAdded.difference(_selectedIds);

  String get _selectionSummary {
    if (!_hasChanges) {
      return _selectedIds.isEmpty
          ? 'Tap an item to add it'
          : '${_selectedIds.length} on this invoice · no pending changes';
    }
    final changes = <String>[];
    if (_addedIds.isNotEmpty) changes.add('${_addedIds.length} to add');
    if (_removedIds.isNotEmpty) changes.add('${_removedIds.length} to remove');
    return changes.join(' · ');
  }

  String get _actionLabel {
    if (!_hasChanges) return 'No changes to apply';
    final changeCount = _addedIds.length + _removedIds.length;
    if (_alreadyAdded.isEmpty && _removedIds.isEmpty) {
      return 'Add ${_addedIds.length} ${_addedIds.length == 1 ? 'item' : 'items'}';
    }
    return 'Apply $changeCount ${changeCount == 1 ? 'change' : 'changes'}';
  }

  bool get _hasChanges => _addedIds.isNotEmpty || _removedIds.isNotEmpty;

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

class _ItemStateBadge extends StatelessWidget {
  const _ItemStateBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: AppTextStyles.caption.copyWith(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
