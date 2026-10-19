import 'package:flutter/material.dart';

enum CalcButtonVariant { number, operator, function, equals }

enum CalcButtonShape { circle, capsule }

/// 鍵與鍵之間的留白。留白在觸控區內側，所以這不縮小觸控範圍。
const double _buttonGap = 4;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        // 4dp 鍵距留白放在觸控框「內側」：InkWell 撐滿整格，相鄰鍵的觸控區相接、
        // 零死區（手機上 8dp 的鍵間死區是誤按主因）。視覺尺寸仍按扣掉留白後計算，
        // 所以外觀不變；扣完夾到 0 以維持極矮視窗不 overflow。
        final maxW =
            (constraints.maxWidth - _buttonGap * 2).clamp(0.0, double.infinity);
        final maxH = constraints.maxHeight.isFinite
            ? (constraints.maxHeight - _buttonGap * 2)
                .clamp(0.0, double.infinity)
            : 64.0;
        // 膠囊高上限 0.80×欄寬：0.62（量自參考圖）在手機上讓面板鍵只有 48dp 高、
        // 不敷觸控；提到 0.80 後圓鍵僅縮 3.4dp，換得面板鍵 62.6dp。
        // 仍必須 < 欄寬，否則列高 ≥ 欄寬時 StadiumBorder 會退化成圓。
        final double visualH = switch (shape) {
          CalcButtonShape.circle => maxW < maxH ? maxW : maxH,
          CalcButtonShape.capsule => maxW * 0.80 < maxH ? maxW * 0.80 : maxH,
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
            child: Padding(
              padding: const EdgeInsets.all(_buttonGap),
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
    );
  }
}
