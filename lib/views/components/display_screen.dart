import 'package:flutter/material.dart';

import '../../core/number_format.dart';
import '../../engine/calc_settings.dart';

class DisplayScreen extends StatelessWidget {
  const DisplayScreen({
    super.key,
    required this.display,
    required this.settings,
    this.hasError = false,
    this.hasGT = false,
  });

  /// raw 字串（無逗號、不補零），格式化在此元件內發生。
  final String display;
  final CalcSettings settings;
  final bool hasError;
  final bool hasGT;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      alignment: Alignment.centerRight,
      color: hasError ? scheme.errorContainer : scheme.surfaceContainerHighest,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (hasGT)
            Text(
              'GT',
              key: const Key('gtBadge'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              formatForDisplay(display, settings),
              key: const Key('displayValue'),
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w300,
                color: hasError ? scheme.onErrorContainer : scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
