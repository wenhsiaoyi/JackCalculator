import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/bloc/calculator_cubit.dart';

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
}
