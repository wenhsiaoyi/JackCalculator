import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/engine/calc_settings.dart';
import 'package:jack_calculator/engine/calculator_engine.dart';

import 'engine_tools.dart';

void main() {
  group('GT 真值表', () {
    test('每按一次 = 累加一筆', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '1');
      engine.applyOperator(CalcOp.add);
      enter(engine, '2');
      engine.equals(); // 顯示 3，GT = 3
      engine.applyOperator(CalcOp.add);
      enter(engine, '4');
      engine.applyOperator(CalcOp.add); // 立即執行：3 + 4 = 7（不進 GT）
      enter(engine, '5');
      engine.equals(); // 顯示 12，GT = 3 + 12 = 15
      expect(engine.grandTotal.toString(), '15');
      expect(engine.hasGT, true);
    });

    test('立即執行的中間值不進 GT', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '2');
      engine.applyOperator(CalcOp.add);
      enter(engine, '3');
      engine.applyOperator(CalcOp.multiply); // 中間值 5 不進 GT
      enter(engine, '4');
      engine.equals(); // 20
      expect(engine.grandTotal.toString(), '20');
    });

    test('GT 鍵把總和帶入顯示，且不清空（可重複引用）', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '7');
      engine.applyOperator(CalcOp.add);
      enter(engine, '8');
      engine.equals(); // 15
      engine.showGrandTotal();
      expect(engine.display, '15');
      engine.showGrandTotal();
      expect(engine.display, '15'); // 再按一次仍是同一總和
      expect(engine.grandTotal.toString(), '15');
    });

    test('AC 清 GT', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '7');
      engine.applyOperator(CalcOp.add);
      enter(engine, '8');
      engine.equals();
      engine.allClear();
      expect(engine.hasGT, false);
      expect(engine.grandTotal.toString(), '0');
    });

    test('C（clearEntry）不清 GT', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '7');
      engine.applyOperator(CalcOp.add);
      enter(engine, '8');
      engine.equals(); // GT = 15
      engine.clearEntry();
      expect(engine.hasGT, true);
      expect(engine.grandTotal.toString(), '15');
    });

    test('重複按 = 不重複累加', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '5');
      engine.applyOperator(CalcOp.add);
      enter(engine, '5');
      engine.equals(); // 10
      engine.equals();
      engine.equals();
      expect(engine.grandTotal.toString(), '10');
    });

    test('錯誤態不進 GT', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '5');
      engine.applyOperator(CalcOp.divide);
      enter(engine, '0');
      engine.equals(); // Error
      expect(engine.hasGT, false);
    });

    test('總和為 0 時 hasGT 為 false（刻意的定義，不是 bug）', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '5');
      engine.applyOperator(CalcOp.subtract);
      enter(engine, '5');
      engine.equals(); // 0
      expect(engine.hasGT, false);
      expect(engine.grandTotal.toString(), '0');
    });
  });
}
