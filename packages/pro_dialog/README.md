# Pro Dialog

Reusable Flutter dialogs with a centered type-colored icon, semantic action
colors, entry motion, and outlined plus filled buttons. The card stays a
neutral white/dark surface so tone color does not wash the background. No
GetX, no app-specific theme, no extra dependencies.

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

Tones color the circular icon and the **filled** confirm action. The card
stays a neutral white or dark surface. Outlined cancel/continue actions stay
plum unless the button sets its own tone (for example a red Discard on a
warning dialog).

| Tone | Icon | Filled action | Motion |
| --- | --- | --- | --- |
| `success` | Teal | Teal gradient | Bounce |
| `error` | Red | Red gradient | Shake |
| `warning` | Warm orange | Coral → orange | Pulse |
| `info` | Teal | Teal → plum | Fade |
| `question` | Plum | Coral → plum | Rotate |

Form dialogs (`form: true`) keep the same chrome and left-align fields.
Two short actions sit side by side; long labels or three-or-more actions
stack full-width so the text is not truncated. Dark mode follows the host
`ThemeData`. Reduced-motion settings skip entry animation.
