import 'package:flutter/material.dart';
import 'package:pro_dialog/pro_dialog.dart';

export 'package:pro_dialog/pro_dialog.dart';

/// Creovo aliases for the reusable `pro_dialog` package.
typedef AppDialog = ProDialog;
typedef AppDialogTone = ProDialogTone;
typedef AppDialogButton = ProDialogButton;
typedef AppDialogButtonVariant = ProDialogButtonVariant;

Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
  AppDialogTone? tone,
  IconData? icon,
  IconData? confirmIcon,
}) {
  return ProDialog.confirm(
    context,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    destructive: destructive,
    tone: tone,
    icon: icon,
    confirmIcon: confirmIcon,
  );
}

Future<void> showAppNoticeDialog({
  required BuildContext context,
  required String title,
  required String message,
  String actionLabel = 'OK',
  AppDialogTone tone = AppDialogTone.success,
  IconData? icon,
  bool barrierDismissible = true,
}) {
  return ProDialog.notice(
    context,
    title: title,
    message: message,
    actionLabel: actionLabel,
    tone: tone,
    icon: icon,
    barrierDismissible: barrierDismissible,
  );
}
