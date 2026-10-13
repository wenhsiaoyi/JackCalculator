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
}
