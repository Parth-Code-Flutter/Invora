import 'package:flutter/material.dart';

/// List FAB used when the empty-state Create/Add button is not on screen.
FloatingActionButton? appListCreateFab({
  required bool emptyCreateVisible,
  required String tooltip,
  required VoidCallback onPressed,
}) {
  if (emptyCreateVisible) return null;
  return FloatingActionButton(
    tooltip: tooltip,
    onPressed: onPressed,
    child: const Icon(Icons.add_rounded),
  );
}
