import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Semantic dialog roles. Each tone owns a color, icon, and entry motion.
enum ProDialogTone { success, error, warning, info, question }

enum ProDialogButtonVariant { filled, outlined, text }

class _ToneStyle {
  const _ToneStyle({
    required this.color,
    required this.fill,
    required this.icon,
    required this.motion,
  });

  /// Icon and outlined-border color for this dialog type.
  final Color color;

  /// Filled action background, matching Creovo primary CTAs (coral → plum)
  /// or a type-tinted pair for success, warning, error, and info.
  final List<Color> fill;
  final IconData icon;
  final _Motion motion;

  static _ToneStyle of(ProDialogTone tone) => switch (tone) {
    ProDialogTone.success => const _ToneStyle(
      color: Color(0xFF218C7F),
      fill: [Color(0xFF2AAFA3), Color(0xFF218C7F)],
      icon: Icons.check_rounded,
      motion: _Motion.bounce,
    ),
    ProDialogTone.error => const _ToneStyle(
      color: Color(0xFFDC2626),
      fill: [Color(0xFFE11D48), Color(0xFFDC2626)],
      icon: Icons.priority_high_rounded,
      motion: _Motion.shake,
    ),
    ProDialogTone.warning => const _ToneStyle(
      color: Color(0xFFE58A3A),
      fill: [Color(0xFFF36F62), Color(0xFFE58A3A)],
      icon: Icons.warning_rounded,
      motion: _Motion.pulse,
    ),
    ProDialogTone.info => const _ToneStyle(
      color: Color(0xFF2AAFA3),
      fill: [Color(0xFF2AAFA3), Color(0xFF6A315F)],
      icon: Icons.info_rounded,
      motion: _Motion.fade,
    ),
    ProDialogTone.question => const _ToneStyle(
      color: Color(0xFF6A315F),
      fill: [Color(0xFFF36F62), Color(0xFF6A315F)],
      icon: Icons.help_rounded,
      motion: _Motion.rotate,
    ),
  };
}

enum _Motion { bounce, shake, pulse, fade, rotate }

/// Provides tone and brightness to [ProDialogButton] descendants.
class ProDialogTheme extends InheritedWidget {
  const ProDialogTheme({
    required this.tone,
    required this.color,
    required this.isDark,
    required super.child,
    super.key,
  });

  final ProDialogTone tone;
  final Color color;
  final bool isDark;

  static ProDialogTheme of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<ProDialogTheme>();
    assert(theme != null, 'ProDialogButton must be used inside ProDialog.');
    return theme!;
  }

  @override
  bool updateShouldNotify(ProDialogTheme oldWidget) =>
      tone != oldWidget.tone ||
      color != oldWidget.color ||
      isDark != oldWidget.isDark;
}

class ProDialogButton extends StatelessWidget {
  const ProDialogButton({
    required this.label,
    required this.onPressed,
    this.variant = ProDialogButtonVariant.filled,
    this.icon,
    this.tone,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final ProDialogButtonVariant variant;
  final IconData? icon;
  final ProDialogTone? tone;

  @override
  Widget build(BuildContext context) {
    final dialog = ProDialogTheme.of(context);
    final isFilled = variant == ProDialogButtonVariant.filled;
    final resolvedTone =
        tone ?? (isFilled ? dialog.tone : ProDialogTone.question);
    final style = _ToneStyle.of(resolvedTone);
    final color = style.color;
    final foreground = switch (variant) {
      ProDialogButtonVariant.filled => Colors.white,
      ProDialogButtonVariant.outlined => color,
      ProDialogButtonVariant.text => color,
    };
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: foreground,
      fontWeight: FontWeight.w600,
      fontSize: 15,
    );
    final outlinedFill = dialog.isDark
        ? color.withValues(alpha: .16)
        : const Color(0xFFFFFCF8);

    return Semantics(
      button: true,
      label: label,
      enabled: onPressed != null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              decoration: BoxDecoration(
                gradient: isFilled
                    ? LinearGradient(
                        colors: style.fill,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                color: isFilled
                    ? null
                    : variant == ProDialogButtonVariant.outlined
                    ? outlinedFill
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: variant == ProDialogButtonVariant.outlined
                    ? Border.all(color: color, width: 1.4)
                    : null,
                boxShadow: isFilled
                    ? const [
                        BoxShadow(
                          color: Color(0x1A321D30),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: foreground),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                        softWrap: true,
                        textAlign: TextAlign.center,
                        style: textStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Centered type-icon dialog. Use [ProDialog.confirm] and [ProDialog.notice]
/// for the common flows, or construct this widget for custom content.
class ProDialog extends StatefulWidget {
  const ProDialog({
    required this.title,
    this.content,
    this.actions = const [],
    this.tone = ProDialogTone.question,
    this.icon,
    this.iconColor,
    this.scrollable = false,
    this.stackedActions = false,
    this.form = false,
    super.key,
  });

  final Widget title;
  final Widget? content;
  final List<Widget> actions;
  final ProDialogTone tone;
  final IconData? icon;
  final Color? iconColor;
  final bool scrollable;
  final bool stackedActions;
  final bool form;

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    bool destructive = false,
    ProDialogTone? tone,
    IconData? icon,
    IconData? confirmIcon,
    bool barrierDismissible = true,
  }) async {
    final resolvedTone =
        tone ?? (destructive ? ProDialogTone.error : ProDialogTone.question);
    return await showDialog<bool>(
          context: context,
          barrierDismissible: barrierDismissible,
          builder: (dialogContext) => ProDialog(
            tone: resolvedTone,
            icon: icon,
            title: Text(title),
            content: Text(message),
            actions: [
              ProDialogButton(
                label: cancelLabel,
                variant: ProDialogButtonVariant.outlined,
                onPressed: () => Navigator.pop(dialogContext, false),
              ),
              ProDialogButton(
                label: confirmLabel,
                icon:
                    confirmIcon ??
                    (destructive ? Icons.delete_outline_rounded : null),
                tone: destructive ? ProDialogTone.error : resolvedTone,
                onPressed: () => Navigator.pop(dialogContext, true),
              ),
            ],
            stackedActions: _labelsNeedStack(cancelLabel, confirmLabel),
          ),
        ) ??
        false;
  }

  static Future<void> notice(
    BuildContext context, {
    required String title,
    required String message,
    String actionLabel = 'OK',
    ProDialogTone tone = ProDialogTone.success,
    IconData? icon,
    bool barrierDismissible = true,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => ProDialog(
        tone: tone,
        icon: icon,
        title: Text(title),
        content: Text(message),
        actions: [
          ProDialogButton(
            label: actionLabel,
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }

  @override
  State<ProDialog> createState() => _ProDialogState();
}

class _ProDialogState extends State<ProDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final style = _ToneStyle.of(widget.tone);
    final color = widget.iconColor ?? style.color;
    final icon = widget.icon ?? style.icon;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final titleColor = scheme.onSurface;
    final bodyColor = isDark
        ? scheme.onSurface.withValues(alpha: .78)
        : scheme.onSurface.withValues(alpha: .68);
    final align = widget.form ? TextAlign.start : TextAlign.center;

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: widget.form
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.center,
      children: [
        Center(
          child: _ToneIcon(icon: icon, color: color),
        ),
        const SizedBox(height: 18),
        DefaultTextStyle.merge(
          style:
              theme.textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ) ??
              TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
          textAlign: align,
          child: widget.title,
        ),
        if (widget.content != null) ...[
          const SizedBox(height: 8),
          DefaultTextStyle.merge(
            style:
                theme.textTheme.bodyMedium?.copyWith(
                  color: bodyColor,
                  height: 1.45,
                ) ??
                TextStyle(fontSize: 14, color: bodyColor, height: 1.45),
            textAlign: align,
            child: widget.content!,
          ),
        ],
        if (widget.actions.isNotEmpty) ...[
          const SizedBox(height: 22),
          _ActionRow(actions: widget.actions, stacked: widget.stackedActions),
        ],
      ],
    );

    final card = Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: isDark ? scheme.surface : Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: isDark ? scheme.surface : Colors.white,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: .10)
                  : const Color(0xFFEEDFD8),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A321D30),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
            child: widget.scrollable
                ? SingleChildScrollView(child: body)
                : body,
          ),
        ),
      ),
    );

    final themed = ProDialogTheme(
      tone: widget.tone,
      color: color,
      isDark: isDark,
      child: card,
    );

    if (reduceMotion) return themed;

    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final t = _progress.value.clamp(0.0, 1.0);
        final bounce = switch (style.motion) {
          _Motion.bounce => 0.82 + (0.18 * t) + (math.sin(t * math.pi) * 0.06),
          _Motion.pulse => 0.94 + (0.06 * t),
          _ => 0.96 + (0.04 * t),
        };
        final dx = style.motion == _Motion.shake
            ? math.sin(t * math.pi * 6) * (1 - t) * 10
            : 0.0;
        final angle = style.motion == _Motion.rotate ? (1 - t) * -0.12 : 0.0;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.rotate(
              angle: angle,
              child: Transform.scale(scale: bounce, child: child),
            ),
          ),
        );
      },
      child: themed,
    );
  }
}

class _ToneIcon extends StatelessWidget {
  const _ToneIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.actions, required this.stacked});

  final List<Widget> actions;
  final bool stacked;

  bool get _stack {
    if (stacked || actions.length != 2) return true;
    return actions.whereType<ProDialogButton>().any(_isLongAction);
  }

  static bool _isLongAction(ProDialogButton button) =>
      button.label.trim().length > 10 ||
      (button.icon != null && button.label.trim().length > 7);

  @override
  Widget build(BuildContext context) {
    if (_stack) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < actions.length; index++) ...[
            if (index > 0) const SizedBox(height: 10),
            actions[index],
          ],
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: actions[0]),
        const SizedBox(width: 10),
        Expanded(child: actions[1]),
      ],
    );
  }
}

bool _labelsNeedStack(String cancelLabel, String confirmLabel) =>
    cancelLabel.trim().length > 10 ||
    confirmLabel.trim().length > 10 ||
    cancelLabel.trim().length + confirmLabel.trim().length > 16;
