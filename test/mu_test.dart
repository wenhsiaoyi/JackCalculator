import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/engine/calc_settings.dart';
import 'package:jack_calculator/engine/calculator_engine.dart';

import 'engine_tools.dart';

void main() {
  group('MU', () {
    test('100 × 20 MU → 售價 125', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '100');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '20');
      engine.mu();
      expect(engine.display, '125');
    });

    test('再按一次 MU → 利潤額 25', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '100');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '20');
      engine.mu();
      engine.mu();
      expect(engine.display, '25');
    });

    test('第三次 MU（成本已清、pendingOp 已清）→ no-op', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '100');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '20');
      engine.mu(); // 125
      engine.mu(); // 25
      engine.mu(); // no-op
      expect(engine.display, '25');
    });

    test('MU 吃掉 pendingOp：售價不會被後續 = 再乘一次', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '100');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '20');
      engine.mu();
      engine.equals(); // pendingOp 已清 → no-op
      expect(engine.display, '125');
    });

    test('MU 不進 GT', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '100');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '20');
      engine.mu();
      engine.equals();
      expect(engine.hasGT, false);
    });

    test('100 + 20 MU（pendingOp 非 multiply）→ no-op', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '100');
      engine.applyOperator(CalcOp.add);
      enter(engine, '20');
      engine.mu();
      expect(engine.display, '20');
      expect(engine.hasError, false);
    });

    test('利潤率 100% → 除零 Error', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '100');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '100');
      engine.mu();
      expect(engine.hasError, true);
    });

    test('利潤率 > 100% → 負售價（不攔截）', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '100');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '120');
      engine.mu();
      expect(engine.display, '-500');
    });

    test('5/4·2 位時售價套用一次捨入：100 × 33 MU → 149.25', () {
      final engine = engineWith(RoundingMode.halfUp, 2);
      enter(engine, '100');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '33');
      engine.mu();
      expect(engine.display, '149.25');
    });

    test('AC 清掉 _muCost：下一筆不會沿用上一筆成本', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '100');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '20');
      engine.mu(); // 125
      engine.allClear();
      enter(engine, '3');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '4');
      engine.mu(); // 3 ÷ 0.96 = 3.125
      expect(engine.display, '3.125');
    });
  });
}
