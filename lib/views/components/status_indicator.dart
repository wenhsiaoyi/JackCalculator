import 'package:flutter/material.dart';

import '../../engine/calc_settings.dart';

/// 顯示屏與鍵盤之間的細列：稅率 ｜ 捨入模式 ｜ 小數位 ｜ 千分位。
class StatusIndicator extends StatelessWidget {
  const StatusIndicator({super.key, required this.settings});

  final CalcSettings settings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = TextStyle(fontSize: 13, color: scheme.onSurfaceVariant);
    final isFloat = settings.rounding == RoundingMode.float;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerRight,
      child: Row(
        children: [
          const Spacer(),
          Text('${settings.taxRate}%',
              key: const Key('indTax'), style: style),
          Text('  ｜  ', style: style),
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
            Text('  ｜  ', style: style),
            Text('${settings.decimalPlaces}位',
                key: const Key('indPlaces'), style: style),
          ],
          if (settings.grouping) ...[
            Text('  ｜  ', style: style),
            Text(',', key: const Key('indGrouping'), style: style),
          ],
        ],
      ),
    );
  }
}
