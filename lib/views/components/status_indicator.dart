import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../engine/calc_settings.dart';

/// 顯示屏與鍵盤之間的細列：稅率 ｜ 捨入模式 ｜ 小數位 ｜ 千分位。
class StatusIndicator extends StatelessWidget {
  const StatusIndicator({super.key, required this.settings});

  final CalcSettings settings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strings = AppStrings.of(Localizations.localeOf(context));
    final style = TextStyle(fontSize: 13, color: scheme.onSurfaceVariant);
    final isFloat = settings.rounding == RoundingMode.float;
    final separator = Text(strings.indicatorSeparator, style: style);
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerRight,
      child: Row(
        children: [
          const Spacer(),
          Text('${settings.taxRate}%', key: const Key('indTax'), style: style),
          separator,
          Text(
            switch (settings.rounding) {
              RoundingMode.float => 'F',
              RoundingMode.cut => 'CUT',
              RoundingMode.up => 'UP',
              RoundingMode.halfUp => '5/4',
            },
            key: const Key('indRounding'),
            style: style,
          ),
          if (!isFloat) ...[
            separator,
            Text('${settings.decimalPlaces}${strings.placesSuffix}',
                key: const Key('indPlaces'), style: style),
          ],
          if (settings.grouping) ...[
            separator,
            Text(',', key: const Key('indGrouping'), style: style),
          ],
        ],
      ),
    );
  }
}
