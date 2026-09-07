import 'package:flutter/material.dart' hide Text;
import 'package:flutter_svg/flutter_svg.dart';

import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../themes/app_text_styles.dart';
import '../utils/app_focus.dart';
import 'app_back_button.dart';

const _appBarSearchIconAsset = 'assets/icons/more/search.svg';
const _appBarChromeSize = 36.0;
const _appBarChromeIconSize = 16.0;

Widget appBarSearchIcon({double size = _appBarChromeIconSize}) {
  return SvgPicture.asset(
    _appBarSearchIconAsset,
    width: size,
    height: size,
    fit: BoxFit.contain,
  );
}

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
    this.largeTitle = false,
    this.largeSearchChrome,
    this.searchIcon,
    this.scanIcon,
    this.backgroundColor,
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

  /// List headers and [AppBarTitle] both use the 20px AppBar title.
  final bool largeTitle;

  /// More uses white search chrome. Documents lists can keep muted chrome.
  /// Defaults to [largeTitle] when omitted.
  final bool? largeSearchChrome;
  final Widget? searchIcon;
  final Widget? scanIcon;
  final Color? backgroundColor;

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
    final largeSearch =
        (widget.largeSearchChrome ?? widget.largeTitle) && !_searching;
    return AppBar(
      backgroundColor: widget.backgroundColor,
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
          ? (widget.largeTitle ? 20 : 16)
          : 12,
      actionsPadding: largeSearch
          ? const EdgeInsets.only(right: 16)
          : const EdgeInsets.only(right: 8),
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
                      style: AppTextStyles.appBarTitle.copyWith(
                        fontSize: 20,
                        height: 28 / 20,
                        letterSpacing: -0.4,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : const Color(0xFF1C1917),
                      ),
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
          _AppBarChromeButton(
            tooltip: l10n('Search'),
            icon: widget.searchIcon ?? appBarSearchIcon(),
            onPressed: _openSearch,
          ),
        if (!_searching && widget.onScan != null)
          _AppBarChromeButton(
            tooltip: l10n(widget.scanTooltip),
            icon:
                widget.scanIcon ??
                const Icon(Icons.qr_code_scanner_rounded, size: 16),
            onPressed: _handleScan,
          ),
        ...widget.actions,
      ],
    );
  }
}

class _AppBarChromeButton extends StatelessWidget {
  const _AppBarChromeButton({
    required this.tooltip,
    required this.onPressed,
    this.icon,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A161118),
              blurRadius: 10,
              offset: Offset(0, 1),
              spreadRadius: -2,
            ),
          ],
        ),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            fixedSize: const Size.square(_appBarChromeSize),
            minimumSize: const Size.square(_appBarChromeSize),
            padding: EdgeInsets.zero,
            backgroundColor: isDark
                ? AppColors.darkSurfaceVariant
                : Colors.white,
            foregroundColor: isDark
                ? AppColors.darkTextPrimary
                : const Color(0xFF44403C),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : const Color(0xB3E7E5E4),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: SizedBox(
            width: _appBarChromeIconSize,
            height: _appBarChromeIconSize,
            child: icon ?? appBarSearchIcon(),
          ),
        ),
      ),
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
        textAlignVertical: TextAlignVertical.center,
        style: AppTextStyles.body.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          fontSize: 14,
        ),
        cursorColor: AppColors.secondary,
        decoration: InputDecoration(
          isDense: true,
          hintText: l10n(hint),
          hintStyle: AppTextStyles.hintFor(context),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(10),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              child: appBarSearchIcon(),
            ),
          ),
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
