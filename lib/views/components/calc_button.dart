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

  /// 字級 = 字高基準 × fontScale（行動版面 v2：主鍵 0.60、面板鍵 0.44）。
  /// 圓形的字高基準是整格高（維持 v2 前比例）；膠囊的字高基準是膠囊視覺高。
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
          final maxW = constraints.maxWidth;
          final maxH =
              constraints.maxHeight.isFinite ? constraints.maxHeight : 64.0;
          // 膠囊高上限 0.80×欄寬：0.62（量自參考圖）在手機上讓面板鍵只有 48dp 高、
          // 不敷觸控；提到 0.80 後圓鍵僅縮 3.4dp，換得面板鍵 62.6dp。
          // 仍必須 < 欄寬，否則列高 ≥ 欄寬時 StadiumBorder 會退化成圓。
          // 觸控範圍維持整格（L2），視覺縮小為已知項。
          final double visualH = switch (shape) {
            CalcButtonShape.circle => maxW < maxH ? maxW : maxH,
            CalcButtonShape.capsule =>
              maxW * 0.80 < maxH ? maxW * 0.80 : maxH,
          };
          final fontSize =
              (shape == CalcButtonShape.circle ? maxH : visualH) * fontScale;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              splashColor: fg.withValues(alpha: 0.25),
              customBorder: switch (shape) {
                CalcButtonShape.circle => const CircleBorder(),
                CalcButtonShape.capsule => RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(visualH / 2),
                  ),
              },
              child: SizedBox(
                width: maxW,
                height: maxH,
                child: Center(
                  child: SizedBox(
                    width: maxW,
                    height: visualH,
                    child: DecoratedBox(
                      decoration: switch (shape) {
                        CalcButtonShape.circle => ShapeDecoration(
                            color: bg,
                            shape: const CircleBorder(),
                          ),
                        CalcButtonShape.capsule => BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(visualH / 2),
                          ),
                      },
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            style: TextStyle(fontSize: fontSize, color: fg),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
