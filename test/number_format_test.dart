import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/core/number_format.dart';
import 'package:jack_calculator/engine/calc_settings.dart';

CalcSettings fmt({
  RoundingMode rounding = RoundingMode.halfUp,
  int decimalPlaces = 2,
  bool grouping = true,
}) =>
    CalcSettings(
      taxRate: Decimal.fromInt(5),
      rounding: rounding,
      decimalPlaces: decimalPlaces,
      grouping: grouping,
    );

void main() {
  group('formatForDisplay', () {
    test('補零：5 @2 位 → 5.00', () {
      expect(formatForDisplay('5', fmt()), '5.00');
    });

    test('零 → 0.00', () {
      expect(formatForDisplay('0', fmt()), '0.00');
    });

    test('國際千分位', () {
      expect(formatForDisplay('1234567', fmt()), '1,234,567.00');
      expect(formatForDisplay('1234', fmt(decimalPlaces: 0)), '1,234');
    });

    test('不足四位不加逗號', () {
      expect(formatForDisplay('123', fmt()), '123.00');
      expect(formatForDisplay('999', fmt(decimalPlaces: 0)), '999');
    });

    test('分位關閉時不加逗號', () {
      expect(formatForDisplay('1234567', fmt(grouping: false)), '1234567.00');
    });

    test('負號保留在最前面', () {
      expect(formatForDisplay('-1234.5', fmt()), '-1,234.50');
    });

    test('F 模式不補零、不捨入顯示', () {
      expect(formatForDisplay('5', fmt(rounding: RoundingMode.float)), '5');
      expect(
        formatForDisplay('1.239', fmt(rounding: RoundingMode.float)),
        '1.239',
      );
    });

    test('輸入中的尾點保留、不補零', () {
      expect(formatForDisplay('0.', fmt()), '0.');
      expect(formatForDisplay('12.', fmt()), '12.');
    });

    test('Error 原樣返回、不加逗號', () {
      expect(formatForDisplay('Error', fmt()), 'Error');
    });

    test('小數段不分組', () {
      expect(formatForDisplay('1234.5678', fmt(decimalPlaces: 4)), '1,234.5678');
    });

    test('超過設定位數時只截顯示（engine 已先捨入，這裡是防禦）', () {
      expect(formatForDisplay('1.239', fmt(decimalPlaces: 2)), '1.23');
    });
  });
}
