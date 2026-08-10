import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../themes/app_text_styles.dart';
import '../utils/app_focus.dart';

class AppSearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  const AppSearchAppBar({
    required this.title,
    required this.hint,
    required this.onChanged,
    this.leading,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String hint;
  final ValueChanged<String> onChanged;
  final Widget? leading;
  final List<Widget> actions;

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

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      leading: widget.leading,
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
            ? TextField(
                key: const ValueKey('app-bar-search-field'),
                controller: _controller,
                focusNode: _focusNode,
                onChanged: (value) {
                  widget.onChanged(value);
                  setState(() {});
                },
                textInputAction: TextInputAction.search,
                style: AppTextStyles.body.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _controller.clear();
                            widget.onChanged('');
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.surfaceSoft,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              )
            : Text(widget.title, key: const ValueKey('app-bar-title')),
      ),
      actions: [
        IconButton(
          tooltip: _searching ? 'Close search' : 'Search',
          onPressed: _searching ? _closeSearch : _openSearch,
          style: IconButton.styleFrom(
            backgroundColor: _searching
                ? AppColors.primaryLight
                : Colors.transparent,
            foregroundColor: _searching
                ? AppColors.primaryDark
                : Theme.of(context).colorScheme.onSurface,
          ),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              _searching ? Icons.close_rounded : Icons.search_rounded,
              key: ValueKey(_searching),
            ),
          ),
        ),
        ...widget.actions,
      ],
    );
  }
}
