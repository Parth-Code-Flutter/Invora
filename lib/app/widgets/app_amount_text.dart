import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';

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
    this.compact = false,
    this.color,
    this.style,
    this.suffix,
    this.textAlign = TextAlign.end,
    super.key,
  });

  final int amountMinor;
  final String symbol;
  final bool hero;

  /// Catalog-style `99` / `1k` / `4.5k` / `4 lakh` via
  /// [CurrencyUtils.compactShopDisplay]. VoiceOver still speaks the full rupee
  /// amount.
  final bool compact;
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
    final full =
        '${CurrencyUtils.formatMinor(amountMinor, symbol: symbol)}${suffix ?? ''}';
    final label = compact
        ? '${CurrencyUtils.compactShopDisplay(amountMinor, localize: l10n)}${suffix ?? ''}'
        : full;
    final text = FittedBox(
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
    if (!compact) return text;
    return Semantics(label: full, child: text);
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
