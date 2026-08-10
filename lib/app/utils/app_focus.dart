import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Coordinates keyboard dismissal with route/widget removal.
///
/// EditableText schedules caret visibility work for the next frame. Removing a
/// focused field in the same frame can leave that callback pointing at a
/// detached RenderEditable. Waiting for the dismissal frame prevents that
/// scheduler assertion throughout dialogs, sheets, and route navigation.
abstract final class AppFocus {
  static Future<void> dismissKeyboard() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    await WidgetsBinding.instance.endOfFrame;
  }

  static Future<void> pop<T>(BuildContext context, [T? result]) async {
    await dismissKeyboard();
    if (context.mounted) Navigator.of(context).pop<T>(result);
  }

  static Future<void> maybePop(BuildContext context) async {
    await dismissKeyboard();
    if (context.mounted) await Navigator.of(context).maybePop();
  }
}
