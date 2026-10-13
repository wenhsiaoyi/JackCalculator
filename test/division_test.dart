import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/engine/calc_settings.dart';
import 'package:jack_calculator/engine/calculator_engine.dart';

import 'engine_tools.dart';

void main() {
  group('餘數法除法：單次捨入', () {
    test('UP 不被截斷抹掉餘數（本專案的回歸照妖鏡）', () {
      // 真實商 5.000000000001；先截到 10 位會變成恰好 5，UP 会誤判成整數。
      expect(
        compute('5000000000001', CalcOp.divide, '1000000000000',
            rounding: RoundingMode.up, decimalPlaces: 2),
        '5.01',
      );
      expect(
        compute('5000000000001', CalcOp.divide, '1000000000000',
            rounding: RoundingMode.cut, decimalPlaces: 2),
        '5',
      );
      expect(
        compute('5000000000001', CalcOp.divide, '1000000000000',
            rounding: RoundingMode.halfUp, decimalPlaces: 2),
        '5',
      );
    });

    test('1 ÷ 3 @2：CUT 0.33、UP 0.34、5/4 0.33', () {
      expect(compute('1', CalcOp.divide, '3', rounding: RoundingMode.cut), '0.33');
      expect(compute('1', CalcOp.divide, '3', rounding: RoundingMode.up), '0.34');
      expect(
        compute('1', CalcOp.divide, '3', rounding: RoundingMode.halfUp),
        '0.33',
      );
    });

    test('2 ÷ 3 @2 × 四模式：CUT 0.66、UP 0.67、5/4 0.67、F 截斷 10 位', () {
      expect(compute('2', CalcOp.divide, '3', rounding: RoundingMode.cut), '0.66');
      expect(compute('2', CalcOp.divide, '3', rounding: RoundingMode.up), '0.67');
      expect(
        compute('2', CalcOp.divide, '3', rounding: RoundingMode.halfUp),
        '0.67',
      );
      expect(
        compute('2', CalcOp.divide, '3', rounding: RoundingMode.float),
        '0.6666666666',
      );
    });

    test('負方向由運算元符號決定：-1 ÷ 3 @0 UP → -1', () {
      final engine = engineWith(RoundingMode.up, 0);
      enter(engine, '1');
      engine.toggleSign();
      engine.applyOperator(CalcOp.divide);
      enter(engine, '3');
      engine.equals();
      expect(engine.display, '-1');
    });

    test('-1 ÷ 3 @2：CUT -0.33、UP -0.34', () {
      for (final (mode, expected) in [
        (RoundingMode.cut, '-0.33'),
        (RoundingMode.up, '-0.34'),
      ]) {
        final engine = engineWith(mode, 2);
        enter(engine, '1');
        engine.toggleSign();
        engine.applyOperator(CalcOp.divide);
        enter(engine, '3');
        engine.equals();
        expect(engine.display, expected, reason: '$mode');
      }
    });

    test('從含稅價反推也是同一條路：2100 ÷ 1.05 @2 5/4 → 2000', () {
      expect(
        compute('2100', CalcOp.divide, '1.05', rounding: RoundingMode.halfUp),
        '2000',
      );
    });

    test('F 模式維持 Phase 1 的截斷 10 位', () {
      expect(compute('1', CalcOp.divide, '3', rounding: RoundingMode.float),
          '0.3333333333');
    });

    test('除零仍走 hasError', () {
      final engine = engineWith(RoundingMode.halfUp, 2);
      enter(engine, '5');
      engine.applyOperator(CalcOp.divide);
      enter(engine, '0');
      engine.equals();
      expect(engine.hasError, true);
      expect(engine.display, 'Error');
    });
  });
}
