import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/engine/calculator_engine.dart';

void main() {
  group('entry', () {
    test('digit replaces leading zero', () {
      final e = CalculatorEngine()
        ..inputDigit('0')
        ..inputDigit('5');
      expect(e.display, '5');
    });

    test('accumulates digits', () {
      final e = CalculatorEngine()
        ..inputDigit('1')
        ..inputDigit('2')
        ..inputDigit('3');
      expect(e.display, '123');
    });

    test('single decimal point only', () {
      final e = CalculatorEngine()
        ..inputDigit('1')
        ..inputDecimalPoint()
        ..inputDecimalPoint()
        ..inputDigit('5');
      expect(e.display, '1.5');
    });

    test('decimal point from fresh entry starts with 0.', () {
      final e = CalculatorEngine()
        ..inputDecimalPoint()
        ..inputDigit('5');
      expect(e.display, '0.5');
    });

    test('backspace removes last char', () {
      final e = CalculatorEngine()
        ..inputDigit('1')
        ..inputDigit('2')
        ..backspace();
      expect(e.display, '1');
    });

    test('backspace to last char becomes 0', () {
      final e = CalculatorEngine()
        ..inputDigit('1')
        ..backspace();
      expect(e.display, '0');
    });

    test('toggleSign flips sign', () {
      final e = CalculatorEngine()..inputDigit('5');
      e.toggleSign();
      expect(e.display, '-5');
      e.toggleSign();
      expect(e.display, '5');
    });
  });

  group('arithmetic', () {
    test('0.1 + 0.2 == 0.3 (no float error)', () {
      final e = CalculatorEngine()
        ..inputDigit('0')
        ..inputDecimalPoint()
        ..inputDigit('1')
        ..applyOperator(CalcOp.add)
        ..inputDigit('0')
        ..inputDecimalPoint()
        ..inputDigit('2')
        ..equals();
      expect(e.display, '0.3');
    });

    test('immediate execution: 2 + 3 x 4 = 20', () {
      final e = CalculatorEngine()
        ..inputDigit('2')
        ..applyOperator(CalcOp.add)
        ..inputDigit('3')
        ..applyOperator(CalcOp.multiply)
        ..inputDigit('4')
        ..equals();
      expect(e.display, '20');
    });

    test('6 / 3 = 2', () {
      final e = CalculatorEngine()
        ..inputDigit('6')
        ..applyOperator(CalcOp.divide)
        ..inputDigit('3')
        ..equals();
      expect(e.display, '2');
    });

    test('1 / 4 = 0.25', () {
      final e = CalculatorEngine()
        ..inputDigit('1')
        ..applyOperator(CalcOp.divide)
        ..inputDigit('4')
        ..equals();
      expect(e.display, '0.25');
    });

    test('1 / 3 truncates to 10 decimal places', () {
      final e = CalculatorEngine()
        ..inputDigit('1')
        ..applyOperator(CalcOp.divide)
        ..inputDigit('3')
        ..equals();
      expect(e.display, '0.3333333333');
    });
  });
}
