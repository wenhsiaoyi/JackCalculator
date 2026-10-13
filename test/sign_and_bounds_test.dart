import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/engine/calc_settings.dart';
import 'package:jack_calculator/engine/calculator_engine.dart';

import 'engine_tools.dart';

void main() {
  group('± 真值表', () {
    test('5 + ± 3 = → 2（只作用於 entry，不回溯 accumulator）', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '5');
      engine.applyOperator(CalcOp.add);
      engine.toggleSign();
      enter(engine, '3');
      expect(engine.display, '-3');
      engine.equals();
      expect(engine.display, '2');
    });

    test('5 + = → 10（echo 不變項，改 ± 不得弄壞）', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '5');
      engine.applyOperator(CalcOp.add);
      engine.equals();
      expect(engine.display, '10');
    });

    test('5 ± = → -5', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '5');
      engine.toggleSign();
      expect(engine.display, '-5');
      engine.equals(); // pendingOp 為 null → no-op
      expect(engine.display, '-5');
    });

    test('± 兩次回到正號', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '5');
      engine.toggleSign();
      engine.toggleSign();
      expect(engine.display, '5');
    });

    test('空 entry 上按 ±：顯示不變，下一個輸入的數字帶負號', () {
      final engine = engineWith(RoundingMode.float, 2);
      // spec D9：_startNewEntry 時 ± 只翻 _pendingSign，不改顯示。
      engine.toggleSign();
      expect(engine.display, '0');
      enter(engine, '7');
      expect(engine.display, '-7');
    });

    test('pendingSign 不跨運算子洩漏：± + 3 = → 0 + 3 = 3', () {
      final engine = engineWith(RoundingMode.float, 2);
      engine.toggleSign(); // 空 entry 上按，_pendingSign 翻 true
      engine.applyOperator(CalcOp.add);
      enter(engine, '3');
      engine.equals();
      expect(engine.display, '3');
    });

    test('± 之後打小數點：-0.5', () {
      final engine = engineWith(RoundingMode.float, 2);
      engine.applyOperator(CalcOp.add); // 讓 _startNewEntry = true
      engine.toggleSign();
      engine.inputDecimalPoint();
      engine.inputDigit('5');
      expect(engine.display, '-0.5');
    });
  });

  group('引擎邊界（Phase 1 延後項 #3）', () {
    test('輸入上限 16 位，第 17 位被忽略', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '1234567890123456'); // 16 位
      expect(engine.display, '1234567890123456');
      engine.inputDigit('7');
      expect(engine.display, '1234567890123456');
    });

    test('負值退格：-5 退成 0', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '5');
      engine.toggleSign();
      engine.backspace();
      expect(engine.display, '0');
    });

    test('尾點退格：1. 退成 1', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '1');
      engine.inputDecimalPoint();
      expect(engine.display, '1.');
      engine.backspace();
      expect(engine.display, '1');
    });

    test('運算子重按：2 + + 3 = → 5', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '2');
      engine.applyOperator(CalcOp.add);
      engine.applyOperator(CalcOp.add); // 重按，2 被重新當成左運算元
      enter(engine, '3');
      engine.equals();
      expect(engine.display, '5');
    });

    test('5 + 3 × 4 = → 20（立即執行不變項）', () {
      expect(
        compute('5', CalcOp.add, '3', rounding: RoundingMode.float),
        '8',
      );
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '2');
      engine.applyOperator(CalcOp.add);
      enter(engine, '3');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '4');
      engine.equals();
      expect(engine.display, '20');
    });

    test('trunc-vs-round：CUT 不進位、UP 一定進位', () {
      expect(compute('0.001', CalcOp.multiply, '1', rounding: RoundingMode.cut), '0');
      expect(compute('0.001', CalcOp.multiply, '1', rounding: RoundingMode.up), '0.01');
    });
  });
}
