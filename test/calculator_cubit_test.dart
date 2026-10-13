import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/bloc/calculator_cubit.dart';
import 'package:jack_calculator/bloc/calculator_state.dart';

void main() {
  test('cubit emits 5 after 2 + 3 =', () {
    final c = CalculatorCubit();
    expect(c.state.display, '0');
    c.onDigit('2');
    c.applyOperator(CalcOp.add);
    c.onDigit('3');
    c.equals();
    expect(c.state.display, '5');
    expect(c.state.hasError, false);
  });

  test('cubit reflects error state', () {
    final c = CalculatorCubit();
    c.onDigit('5');
    c.applyOperator(CalcOp.divide);
    c.onDigit('0');
    c.equals();
    expect(c.state.hasError, true);
    expect(c.state.display, 'Error');
  });

  test('applySettings 後引擎依設定捨入', () {
    final c = CalculatorCubit();
    c.applySettings(CalcSettings(
      taxRate: Decimal.fromInt(5),
      rounding: RoundingMode.halfUp,
      decimalPlaces: 2,
      grouping: false,
    ));
    c.onDigit('1');
    c.applyOperator(CalcOp.divide);
    c.onDigit('3');
    c.equals();
    expect(c.state.display, '0.33');
  });

  test('預設設定（App 用）是 5/4·2 位', () {
    final c = CalculatorCubit();
    c.onDigit('1');
    c.applyOperator(CalcOp.divide);
    c.onDigit('3');
    c.equals();
    expect(c.state.display, '0.33'); // 不是 0.3333333333
  });

  test('onGrandTotal 帶回總和並標記 hasGT', () {
    final c = CalculatorCubit();
    c.onDigit('7');
    c.applyOperator(CalcOp.add);
    c.onDigit('8');
    c.equals();
    expect(c.state.hasGT, true);
    c.onGrandTotal();
    expect(c.state.display, '15');
  });

  test('onTaxPlus 對 entry 含稅', () {
    final c = CalculatorCubit();
    c.onDigit('1');
    c.onDigit('0');
    c.onDigit('0');
    c.onDigit('0');
    c.onTaxPlus();
    expect(c.state.display, '1050');
  });

  test('onMu 產出售價', () {
    final c = CalculatorCubit();
    c.onDigit('1');
    c.onDigit('0');
    c.onDigit('0');
    c.applyOperator(CalcOp.multiply);
    c.onDigit('2');
    c.onDigit('0');
    c.onMu();
    expect(c.state.display, '125');
  });

  test('等價 state 不重複發送（== 生效）', () async {
    final c = CalculatorCubit();
    final seen = <CalculatorState>[];
    final sub = c.stream.listen(seen.add);
    c.onDigit('0'); // state 與初始值等價；但「首次 emit」不受 == 去重（bloc 規則）
    await pumpEventQueue();
    expect(seen.length, 1);
    c.allClear(); // 仍等價 → 這次應被 == 擋下
    await pumpEventQueue();
    expect(seen.length, 1);
    c.onDigit('5'); // 不等價 → 應再送一次
    await pumpEventQueue();
    expect(seen.length, 2);
    await sub.cancel();
  });
}
