import 'package:flutter/material.dart';

import '../themes/app_text_styles.dart';
import '../utils/currency_utils.dart';

/// Renders a currency amount that shrinks to fit instead of clipping.
///
/// Place this inside a width-bounded parent (`Flexible`, `Expanded`,
/// [AppAmountColumn], or a stretched [Column]). Neighboring names and labels
/// should ellipsize; amounts never do.
class AppAmountText extends StatelessWidget {
  const AppAmountText({
    required this.amountMinor,
    required this.symbol,
    this.hero = false,
    this.color,
    this.style,
    this.suffix,
    this.textAlign = TextAlign.end,
    super.key,
  });

  final int amountMinor;
  final String symbol;
  final bool hero;
  final Color? color;
  final TextStyle? style;
  final String? suffix;
  final TextAlign textAlign;

  Alignment get _alignment => switch (textAlign) {
    TextAlign.left || TextAlign.start => Alignment.centerLeft,
    TextAlign.center => Alignment.center,
    _ => Alignment.centerRight,
  };

  @override
  Widget build(BuildContext context) {
    final resolved =
        (style ??
                (hero
                    ? AppTextStyles.displayAmount
                    : AppTextStyles.cardTitle.copyWith(
                        fontWeight: FontWeight.w800,
                      )))
            .copyWith(color: color);
    final label =
        '${CurrencyUtils.formatMinor(amountMinor, symbol: symbol)}${suffix ?? ''}';
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: _alignment,
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        textAlign: textAlign,
        style: resolved,
      ),
    );
  }
}

/// Caps a right-side money column so identity text keeps a readable share
/// of the row. Children stretch so [AppAmountText] receives a max width.
class AppAmountColumn extends StatelessWidget {
  const AppAmountColumn({
    required this.children,
    this.maxWidth = 148,
    super.key,
  });

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
