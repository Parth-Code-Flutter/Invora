import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../themes/app_text_styles.dart';
import '../utils/app_focus.dart';
import 'app_back_button.dart';

class AppSearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  const AppSearchAppBar({
    required this.title,
    required this.hint,
    required this.onChanged,
    this.leading,
    this.titleSuffix,
    this.actions = const [],
    this.onScan,
    this.scanTooltip = 'Scan to search',
    this.primary = true,
    super.key,
  });

  final String title;
  final String hint;
  final ValueChanged<String> onChanged;
  final Widget? leading;
  final Widget? titleSuffix;
  final List<Widget> actions;

  /// Opens a scanner and returns decoded text to apply as the search query.
  ///
  /// Leave null when the host screen owns a different scan action, such as
  /// catalog open-or-create on Products & services.
  final Future<String?> Function()? onScan;
  final String scanTooltip;

  /// Nested list hosts pass false so the bar does not add status-bar padding.
  final bool primary;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  State<AppSearchAppBar> createState() => _AppSearchAppBarState();
}

class _AppSearchAppBarState extends State<AppSearchAppBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _searching = false;

  void _openSearch() {
    setState(() => _searching = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  Future<void> _closeSearch() async {
    _controller.clear();
    widget.onChanged('');
    await AppFocus.dismissKeyboard();
    if (!mounted) return;
    setState(() => _searching = false);
  }

  void _clearQuery() {
    _controller.clear();
    widget.onChanged('');
    _focusNode.requestFocus();
    setState(() {});
  }

  Future<void> _handleScan() async {
    final onScan = widget.onScan;
    if (onScan == null) return;
    await AppFocus.dismissKeyboard();
    if (!mounted) return;
    final value = await onScan();
    if (!mounted || value == null) return;
    final query = value.trim();
    if (query.isEmpty) return;
    _controller.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    widget.onChanged(query);
    setState(() => _searching = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    return AppBar(
      primary: widget.primary,
      automaticallyImplyLeading: widget.leading == null && !_searching,
      leading: _searching
          ? AppBackButton(
              tooltip: l10n('Close search'),
              onPressed: () {
                _closeSearch();
              },
            )
          : widget.leading,
      titleSpacing: _searching
          ? 8
          : widget.leading == null
          ? 16
          : 12,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _searching
            ? _SearchField(
                controller: _controller,
                focusNode: _focusNode,
                hint: widget.hint,
                isDark: isDark,
                iconColor: iconColor,
                onChanged: (value) {
                  widget.onChanged(value);
                  setState(() {});
                },
                onClear: _clearQuery,
                onSubmitted: (_) => _focusNode.unfocus(),
              )
            : Row(
                key: const ValueKey('app-bar-title'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.titleSuffix != null) ...[
                    const SizedBox(width: 5),
                    widget.titleSuffix!,
                  ],
                ],
              ),
      ),
      actions: [
        if (!_searching)
          AppBarIconButton(
            tooltip: l10n('Search'),
            onPressed: _openSearch,
            icon: Icons.search_rounded,
          ),
        if (!_searching && widget.onScan != null)
          AppBarIconButton(
            tooltip: l10n(widget.scanTooltip),
            onPressed: _handleScan,
            icon: Icons.qr_code_scanner_rounded,
          ),
        ...widget.actions,
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.isDark,
    required this.iconColor,
    required this.onChanged,
    required this.onClear,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final bool isDark;
  final Color iconColor;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
      borderSide: BorderSide(
        color: isDark ? AppColors.darkBorder : AppColors.border,
      ),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
      borderSide: BorderSide(
        color: isDark ? AppColors.darkTextSecondary : AppColors.secondary,
        width: 1.2,
      ),
    );
    final showClear = controller.text.isNotEmpty;
    return SizedBox(
      key: const ValueKey('app-bar-search-field'),
      height: 46,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onTapOutside: (_) => focusNode.unfocus(),
        textInputAction: TextInputAction.search,
        keyboardType: TextInputType.text,
        style: AppTextStyles.body.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          fontSize: 14,
        ),
        cursorColor: AppColors.secondary,
        decoration: InputDecoration(
          isDense: true,
          hintText: l10n(hint),
          hintStyle: AppTextStyles.body.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textTertiary,
            fontSize: 14,
          ),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: iconColor),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          suffixIcon: showClear
              ? _SearchFieldIcon(
                  tooltip: l10n('Clear search'),
                  icon: Icons.close_rounded,
                  color: iconColor,
                  onPressed: onClear,
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          filled: true,
          fillColor: isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.surfaceMuted,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 10,
          ),
          border: border,
          enabledBorder: border,
          focusedBorder: focusedBorder,
        ),
      ),
    );
  }
}

class _SearchFieldIcon extends StatelessWidget {
  const _SearchFieldIcon({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      style: IconButton.styleFrom(
        minimumSize: const Size(36, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: color,
      ),
      icon: Icon(icon, size: 18),
    );
  }
}
