import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/engine/calc_settings.dart';

void main() {
  group('CalcSettings', () {
    test('defaults 為 5%／5-4／2 位／千分位 on', () {
      expect(CalcSettings.defaults.taxRate, Decimal.fromInt(5));
      expect(CalcSettings.defaults.rounding, RoundingMode.halfUp);
      expect(CalcSettings.defaults.decimalPlaces, 2);
      expect(CalcSettings.defaults.grouping, true);
    });

    test('raw 為不捨入、不分位（engine 預設值）', () {
      expect(CalcSettings.raw.rounding, RoundingMode.float);
      expect(CalcSettings.raw.grouping, false);
      expect(CalcSettings.raw.effectiveDecimalPlaces, isNull);
    });

    test('effectiveDecimalPlaces 只在非 F 時回位數', () {
      final s = CalcSettings.defaults;
      expect(s.effectiveDecimalPlaces, 2);
      expect(s.copyWith(rounding: RoundingMode.cut).effectiveDecimalPlaces, 2);
      expect(
        s.copyWith(rounding: RoundingMode.float).effectiveDecimalPlaces,
        isNull,
      );
    });

    test('值相等性：欄位全同即相等，任一欄位不同即不等', () {
      final a = CalcSettings.defaults;
      final b = CalcSettings.defaults.copyWith();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(a.copyWith(grouping: false))));
      expect(a, isNot(equals(a.copyWith(decimalPlaces: 3))));
      expect(a, isNot(equals(a.copyWith(rounding: RoundingMode.cut))));
      expect(a, isNot(equals(a.copyWith(taxRate: Decimal.fromInt(8)))));
    });
  });

  group('RoundingMode', () {
    test('code 可 round-trip', () {
      for (final mode in RoundingMode.values) {
        expect(RoundingMode.fromCode(mode.code), mode);
      }
    });

    test('未知 code 退回 halfUp（半壞資料不炸）', () {
      expect(RoundingMode.fromCode(99), RoundingMode.halfUp);
      expect(RoundingMode.fromCode(-1), RoundingMode.halfUp);
    });
  });
}
