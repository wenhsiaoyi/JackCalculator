import 'package:flutter/material.dart';

import '../../core/number_format.dart';
import '../../engine/calc_settings.dart';

class DisplayScreen extends StatelessWidget {
  const DisplayScreen({
    super.key,
    required this.display,
    this.hasError = false,
  });

  final String display;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      alignment: Alignment.centerRight,
      color: hasError ? scheme.errorContainer : scheme.surfaceContainerHighest,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          formatForDisplay(display, CalcSettings.raw),
          key: const Key('displayValue'),
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w300,
            color: hasError ? scheme.onErrorContainer : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
