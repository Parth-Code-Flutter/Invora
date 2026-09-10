import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

const _fabSize = 44.0;
const _fabIconSize = 20.0;

/// List FAB used when the empty-state Create/Add button is not on screen.
Widget? appListCreateFab({
  required bool emptyCreateVisible,
  required String tooltip,
  required VoidCallback onPressed,
}) {
  if (emptyCreateVisible) return null;
  return AppListCreateFab(tooltip: tooltip, onPressed: onPressed);
}

class AppListCreateFab extends StatelessWidget {
  const AppListCreateFab({
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: SizedBox(
          width: _fabSize,
          height: _fabSize,
          child: Material(
            type: MaterialType.circle,
            color: Colors.transparent,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              overlayColor: WidgetStatePropertyAll(
                Colors.white.withValues(alpha: .12),
              ),
              child: Ink(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.brandedGradient,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: _fabIconSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
