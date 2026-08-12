import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_dialog.dart';
import '../utils/app_focus.dart';

typedef UnsavedChangesCheck = bool Function();
typedef SaveDraftCallback = Future<bool> Function();

class UnsavedChangesScope extends StatefulWidget {
  const UnsavedChangesScope({
    required this.hasChanges,
    required this.child,
    this.onSaveDraft,
    super.key,
  });

  final UnsavedChangesCheck hasChanges;
  final SaveDraftCallback? onSaveDraft;
  final Widget child;

  @override
  State<UnsavedChangesScope> createState() => _UnsavedChangesScopeState();
}

class _UnsavedChangesScopeState extends State<UnsavedChangesScope> {
  bool _allowPop = false;
  bool _handlingPop = false;

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: _allowPop,
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop || _handlingPop) return;
      _handlingPop = true;
      try {
        if (!widget.hasChanges()) {
          _completePop();
          return;
        }
        await AppFocus.dismissKeyboard();
        if (!mounted) return;
        final action = await _showConfirmation();
        if (!mounted) return;
        if (action == _UnsavedAction.discard) {
          _completePop();
        } else if (action == _UnsavedAction.saveDraft) {
          final saved = await widget.onSaveDraft?.call() ?? false;
          if (saved && mounted) _completePop();
        }
      } finally {
        _handlingPop = false;
      }
    },
    child: widget.child,
  );

  void _completePop() {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<_UnsavedAction?> _showConfirmation() => showDialog<_UnsavedAction>(
    context: context,
    builder: (dialogContext) => AppDialog(
      icon: Icons.edit_note_rounded,
      stackedActions: true,
      title: const Text('Keep your changes?'),
      content: Text(
        widget.onSaveDraft == null
            ? 'You have unsaved changes. Continue editing or discard them before leaving.'
            : 'This document has unsaved changes. Save it as a draft, continue editing, or discard the changes.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Continue editing'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, _UnsavedAction.discard),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Discard'),
        ),
        if (widget.onSaveDraft != null)
          FilledButton.icon(
            onPressed: () =>
                Navigator.pop(dialogContext, _UnsavedAction.saveDraft),
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('Save draft'),
          ),
      ],
    ),
  );
}

enum _UnsavedAction { discard, saveDraft }
