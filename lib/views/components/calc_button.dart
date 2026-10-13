import 'package:flutter/material.dart';

enum CalcButtonVariant { number, operator, function, equals }

class CalcButton extends StatelessWidget {
  const CalcButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CalcButtonVariant.number,
  });

  final String label;
  final VoidCallback onPressed;
  final CalcButtonVariant variant;

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
          // 64dp 的硬下限是 Phase 1 的 overflow 來源；改成跟著可用高度走。
          // 44dp 只是設計參考：真的不夠高時以「不 overflow」優先。
          final available =
              constraints.maxHeight.isFinite ? constraints.maxHeight : 64.0;
          final fontSize = (available * 0.38).clamp(12.0, 24.0).toDouble();
          return TextButton(
            style: TextButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              padding: EdgeInsets.zero,
              minimumSize: Size(0, available),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
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
