import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';

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
      tone: AppDialogTone.warning,
      stackedActions: widget.onSaveDraft != null,
      title: const Text('Unsaved Changes'),
      content: Text(
        widget.onSaveDraft == null
            ? 'You have unsaved changes in this document. Leaving now will permanently discard all recent edits.'
            : 'This document has unsaved changes. Save it as a draft, continue editing, or discard the changes.',
      ),
      actions: [
        AppDialogButton(
          label: 'Continue editing',
          variant: AppDialogButtonVariant.outlined,
          onPressed: () => Navigator.pop(dialogContext),
        ),
        AppDialogButton(
          label: 'Discard',
          variant: widget.onSaveDraft == null
              ? AppDialogButtonVariant.filled
              : AppDialogButtonVariant.outlined,
          tone: AppDialogTone.error,
          icon: Icons.delete_outline_rounded,
          onPressed: () => Navigator.pop(dialogContext, _UnsavedAction.discard),
        ),
        if (widget.onSaveDraft != null)
          AppDialogButton(
            label: 'Save draft',
            icon: Icons.bookmark_add_outlined,
            onPressed: () =>
                Navigator.pop(dialogContext, _UnsavedAction.saveDraft),
          ),
      ],
    ),
  );
}

enum _UnsavedAction { discard, saveDraft }
