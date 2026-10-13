import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/engine/calc_settings.dart';
import 'package:jack_calculator/engine/calculator_engine.dart';

import 'engine_tools.dart';

void main() {
  group('Tax', () {
    test('Tax+：1000 → 1050（t=5%）', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '1000');
      engine.taxPlus();
      expect(engine.display, '1050');
    });

    test('Tax−：2100 → 2000（反推未稅，不是 1995）', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '2100');
      engine.taxMinus();
      expect(engine.display, '2000');
    });

    test('Tax+ 與 Tax− 互為反函數：1000 → 1050 → 1000', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '1000');
      engine.taxPlus();
      expect(engine.display, '1050');
      engine.taxMinus();
      expect(engine.display, '1000');
    });

    test('小數稅率：t=8.5、100 → 108.5', () {
      final engine = engineWith(RoundingMode.float, 2, taxRate: Decimal.parse('8.5'));
      enter(engine, '100');
      engine.taxPlus();
      expect(engine.display, '108.5');
    });

    test('t=0 時 Tax+ 不改變值', () {
      final engine = engineWith(RoundingMode.float, 2, taxRate: Decimal.zero);
      enter(engine, '100');
      engine.taxPlus();
      expect(engine.display, '100');
    });

    test('作用對象是 entry，不是 accumulator：5 + 3 Tax+ = → 8.15', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '5');
      engine.applyOperator(CalcOp.add);
      enter(engine, '3');
      engine.taxPlus(); // 只有 3 被含稅
      engine.equals();
      expect(engine.display, '8.15');
    });

    test('5/4·2 位時 Tax+ 的出口套用一次捨入', () {
      final engine = engineWith(RoundingMode.halfUp, 2);
      enter(engine, '1000');
      engine.taxPlus(); // 1050.00 → 1050
      expect(engine.display, '1050');
    });

    test('錯誤態下 Tax 為 no-op', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '5');
      engine.applyOperator(CalcOp.divide);
      enter(engine, '0');
      engine.equals(); // Error
      engine.taxPlus();
      expect(engine.display, 'Error');
      expect(engine.hasError, true);
    });

    test('t 超出設定範圍（-100）時 Tax− 報錯，防呆', () {
      final engine = engineWith(RoundingMode.float, 2, taxRate: Decimal.fromInt(-100));
      enter(engine, '100');
      engine.taxMinus();
      expect(engine.hasError, true);
    });
  });
}
