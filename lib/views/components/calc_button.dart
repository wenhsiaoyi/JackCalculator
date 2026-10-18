import 'package:flutter/material.dart';

enum CalcButtonVariant { number, operator, function, equals }

enum CalcButtonShape { circle, capsule }

class CalcButton extends StatelessWidget {
  const CalcButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CalcButtonVariant.number,
    this.shape = CalcButtonShape.circle,
    this.fontScale = 0.60,
  });

  final String label;
  final VoidCallback onPressed;
  final CalcButtonVariant variant;
  final CalcButtonShape shape;

  /// 字級 = 可用高度 × fontScale（行動版面 v2：主鍵 0.60、面板鍵 0.34）。
  /// 外層 FittedBox(scaleDown) 保證窄窗不 overflow。
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (variant) {
      CalcButtonVariant.number => (
          scheme.surfaceContainerHighest,
          scheme.onSurface
        ),
      CalcButtonVariant.operator => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer
        ),
      CalcButtonVariant.function => (scheme.surface, scheme.primary),
      CalcButtonVariant.equals => (scheme.primary, scheme.onPrimary),
    };
    return Padding(
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available =
              constraints.maxHeight.isFinite ? constraints.maxHeight : 64.0;
          final fontSize = available * fontScale;
          return TextButton(
            style: TextButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              padding: EdgeInsets.zero,
              minimumSize: Size(0, available),
              shape: switch (shape) {
                CalcButtonShape.circle => const CircleBorder(),
                CalcButtonShape.capsule => const StadiumBorder(),
              },
            ),
            onPressed: onPressed,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: TextStyle(fontSize: fontSize)),
            ),
          );
        },
      ),
    );
  }
}
