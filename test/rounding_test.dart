import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/engine/calc_settings.dart';
import 'package:jack_calculator/engine/calculator_engine.dart';

import 'engine_tools.dart';

void main() {
  group('非除法路徑的捨入', () {
    test('F 不捨入：1.234 × 1 保持 1.234', () {
      expect(compute('1.234', CalcOp.multiply, '1', rounding: RoundingMode.float),
          '1.234');
    });

    test('CUT 向零截斷：1.234 × 1 @2 → 1.23', () {
      expect(compute('1.234', CalcOp.multiply, '1', rounding: RoundingMode.cut),
          '1.23');
    });

    test('UP 向遠離零進位：1.234 × 1 @2 → 1.24', () {
      expect(compute('1.234', CalcOp.multiply, '1', rounding: RoundingMode.up),
          '1.24');
    });

    test('5/4：1.234 → 1.23、1.235 → 1.24（half away from zero）', () {
      expect(compute('1.234', CalcOp.multiply, '1', rounding: RoundingMode.halfUp),
          '1.23');
      expect(compute('1.235', CalcOp.multiply, '1', rounding: RoundingMode.halfUp),
          '1.24');
    });

    test('負值方向：-1.239 @2 → CUT -1.23、UP -1.24、5/4 -1.24', () {
      for (final (mode, expected) in [
        (RoundingMode.cut, '-1.23'),
        (RoundingMode.up, '-1.24'),
        (RoundingMode.halfUp, '-1.24'),
      ]) {
        final engine = engineWith(mode, 2);
        enter(engine, '1.239');
        engine.toggleSign();
        engine.applyOperator(CalcOp.multiply);
        enter(engine, '1');
        engine.equals();
        expect(engine.display, expected, reason: '$mode');
      }
    });

    test('加減也走同一條捨入：0.005 + 0 @2 → CUT 0、UP 0.01、5/4 0.01', () {
      expect(compute('0.005', CalcOp.add, '0', rounding: RoundingMode.cut), '0');
      expect(compute('0.005', CalcOp.add, '0', rounding: RoundingMode.up), '0.01');
      expect(
        compute('0.005', CalcOp.add, '0', rounding: RoundingMode.halfUp),
        '0.01',
      );
    });

    test('小數位 0／3／4 各一（CUT）', () {
      expect(
        compute('1.239', CalcOp.multiply, '1',
            rounding: RoundingMode.cut, decimalPlaces: 0),
        '1',
      );
      expect(
        compute('1.2395', CalcOp.multiply, '1',
            rounding: RoundingMode.cut, decimalPlaces: 3),
        '1.239',
      );
      expect(
        compute('1.2395', CalcOp.multiply, '1',
            rounding: RoundingMode.cut, decimalPlaces: 4),
        '1.2395',
      );
    });

    test('鏈捨入：每一步的出口就是捨入後的值', () {
      final engine = engineWith(RoundingMode.cut, 2);
      enter(engine, '1.234');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '1');
      engine.equals(); // 1.234 → 1.23
      expect(engine.display, '1.23');
      engine.applyOperator(CalcOp.add);
      enter(engine, '0.005');
      engine.equals(); // 1.23 + 0.005 = 1.235 → 1.23（上一筆已是 1.23，不是 1.234）
      expect(engine.display, '1.23');
    });

    test('engine 預設是 raw：Phase 1 語意不受影響', () {
      final engine = CalculatorEngine();
      enter(engine, '1.234');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '1');
      engine.equals();
      expect(engine.display, '1.234');
    });
  });
}
