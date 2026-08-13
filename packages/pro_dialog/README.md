# Pro Dialog

Reusable Flutter dialogs with a centered glow icon, semantic colors, entry
motion, and paired outlined + filled actions. No GetX, no app-specific theme,
no extra dependencies.

## Use in another project

Copy the whole `packages/pro_dialog` folder into the other repo, then add a
path dependency:

```yaml
dependencies:
  pro_dialog:
    path: packages/pro_dialog
```

If the folder sits next to the app instead of inside it:

```yaml
dependencies:
  pro_dialog:
    path: ../pro_dialog
```

Then:

```dart
import 'package:pro_dialog/pro_dialog.dart';

final confirmed = await ProDialog.confirm(
  context,
  title: 'Delete account?',
  message: 'This cannot be undone.',
  confirmLabel: 'Delete Forever',
  destructive: true,
);

await ProDialog.notice(
  context,
  title: 'Saved',
  message: 'Your changes are stored on this device.',
);

showDialog<void>(
  context: context,
  builder: (context) => ProDialog(
    tone: ProDialogTone.question,
    title: const Text('Enable notifications?'),
    content: const Text('Stay up to date with alerts and reminders.'),
    actions: [
      ProDialogButton(
        label: 'No Thanks',
        variant: ProDialogButtonVariant.outlined,
        onPressed: () => Navigator.pop(context),
      ),
      ProDialogButton(
        label: 'Enable',
        icon: Icons.notifications_outlined,
        onPressed: () => Navigator.pop(context, true),
      ),
    ],
  ),
);
```

## Tones

| Tone | Color | Motion |
| --- | --- | --- |
| `success` | Green | Bounce |
| `error` | Red | Shake |
| `warning` | Amber | Pulse |
| `info` | Blue | Fade |
| `question` | Purple | Rotate |

Form dialogs (`form: true`) keep the same chrome and left-align fields.
Two actions sit side by side; three or more stack. Dark mode follows the host
`ThemeData`. Reduced-motion settings skip entry animation.
