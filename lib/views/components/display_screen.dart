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
    this.onSettingsTap,
  });

  /// raw 字串（無逗號、不補零），格式化在此元件內發生。
  final String display;
  final CalcSettings settings;
  final bool hasError;
  final bool hasGT;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 24),
      alignment: Alignment.centerRight,
      color: hasError ? scheme.errorContainer : scheme.surfaceContainerHighest,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            height: 32,
            child: Row(
              children: [
                if (onSettingsTap != null)
                  IconButton(
                    key: const Key('openSettings'),
                    onPressed: onSettingsTap,
                    icon: const Icon(Icons.settings),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints.tightFor(width: 32, height: 32),
                    visualDensity: VisualDensity.compact,
                    color: hasError
                        ? scheme.onErrorContainer
                        : scheme.onSurfaceVariant,
                  ),
                const Spacer(),
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
              ],
            ),
          ),
          const SizedBox(height: 4),
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
