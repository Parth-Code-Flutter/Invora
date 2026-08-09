import 'package:flutter/material.dart';

import '../themes/app_text_styles.dart';
import '../utils/currency_utils.dart';

class AppAmountText extends StatelessWidget {
  const AppAmountText({
    required this.amountMinor,
    required this.symbol,
    this.hero = false,
    this.color,
    super.key,
  });
  final int amountMinor;
  final String symbol;
  final bool hero;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      CurrencyUtils.formatMinor(amountMinor, symbol: symbol),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: (hero ? AppTextStyles.displayAmount : AppTextStyles.cardTitle)
          .copyWith(color: color),
    );
  }
}
