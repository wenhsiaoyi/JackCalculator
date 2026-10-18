import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/engine/calc_settings.dart';
import 'package:jack_calculator/engine/calculator_engine.dart';

CalculatorEngine _e() =>
    CalculatorEngine()..applySettings(CalcSettings.defaults);

void main() {
  group('livePreview', () {
    test('剛按運算子、尚未輸入第二運算元 → null', () {
      final e = _e()
        ..inputDigit('6')
        ..inputDigit('5')
        ..applyOperator(CalcOp.multiply);
      expect(e.livePreview, isNull);
    });

    test('第二運算元輸入中：65 × 4 → 260', () {
      final e = _e()
        ..inputDigit('6')
        ..inputDigit('5')
        ..applyOperator(CalcOp.multiply)
        ..inputDigit('4');
      expect(e.livePreview, '260');
    });

    test('加法：10 + 3 → 13', () {
      final e = _e()
        ..inputDigit('1')
        ..inputDigit('0')
        ..applyOperator(CalcOp.add)
        ..inputDigit('3');
      expect(e.livePreview, '13');
    });

    test('減法：10 − 3 → 7', () {
      final e = _e()
        ..inputDigit('1')
        ..inputDigit('0')
        ..applyOperator(CalcOp.subtract)
        ..inputDigit('3');
      expect(e.livePreview, '7');
    });

    test('除法走同一捨入路徑：1 ÷ 3 → 0.33（5/4、2 位）', () {
      final e = _e()
        ..inputDigit('1')
        ..applyOperator(CalcOp.divide)
        ..inputDigit('3');
      expect(e.livePreview, '0.33');
    });

    test('÷ 0 → null 且不进 error', () {
      final e = _e()
        ..inputDigit('5')
        ..applyOperator(CalcOp.divide)
        ..inputDigit('0');
      expect(e.livePreview, isNull);
      expect(e.hasError, isFalse);
    });

    test('± 只翻第二運算元：65 × 4 ± → -260', () {
      final e = _e()
        ..inputDigit('6')
        ..inputDigit('5')
        ..applyOperator(CalcOp.multiply)
        ..inputDigit('4')
        ..toggleSign();
      expect(e.livePreview, '-260');
    });

    test('= 之後 → null', () {
      final e = _e()
        ..inputDigit('6')
        ..inputDigit('5')
        ..applyOperator(CalcOp.multiply)
        ..inputDigit('4')
        ..equals();
      expect(e.livePreview, isNull);
    });

    test('C 清 entry 後 → null', () {
      final e = _e()
        ..inputDigit('6')
        ..inputDigit('5')
        ..applyOperator(CalcOp.multiply)
        ..inputDigit('4')
        ..clearEntry();
      expect(e.livePreview, isNull);
    });

    test('AC 之後 → null', () {
      final e = _e()
        ..inputDigit('6')
        ..inputDigit('5')
        ..applyOperator(CalcOp.multiply)
        ..inputDigit('4')
        ..allClear();
      expect(e.livePreview, isNull);
    });

    test('error 狀態 → null', () {
      final e = _e()
        ..inputDigit('5')
        ..applyOperator(CalcOp.divide)
        ..inputDigit('0')
        ..equals();
      expect(e.hasError, isTrue);
      expect(e.livePreview, isNull);
    });

    test('預覽值與 = 結果一致：65 × 4 預覽 260，= 後顯示 260', () {
      final e = _e()
        ..inputDigit('6')
        ..inputDigit('5')
        ..applyOperator(CalcOp.multiply)
        ..inputDigit('4');
      expect(e.livePreview, '260');
      e.equals();
      expect(e.display, '260');
    });
  });
}
