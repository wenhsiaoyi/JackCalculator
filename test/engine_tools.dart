import 'package:decimal/decimal.dart';
import 'package:jack_calculator/engine/calc_settings.dart';
import 'package:jack_calculator/engine/calculator_engine.dart';

/// 依捨入模式與小數位建立 engine（稅率預設 5%、不分位）。
CalculatorEngine engineWith(
  RoundingMode rounding,
  int decimalPlaces, {
  Decimal? taxRate,
  bool grouping = false,
}) {
  final engine = CalculatorEngine()
    ..applySettings(CalcSettings(
      taxRate: taxRate ?? Decimal.fromInt(5),
      rounding: rounding,
      decimalPlaces: decimalPlaces,
      grouping: grouping,
    ));
  return engine;
}

/// 逐字輸入一個數。負值請用 `toggleSign()`，不要傳 '-' 進來。
CalculatorEngine enter(CalculatorEngine engine, String text) {
  assert(!text.contains('-'), '負值請用 toggleSign()');
  for (final ch in text.split('')) {
    if (ch == '.') {
      engine.inputDecimalPoint();
    } else {
      engine.inputDigit(ch);
    }
  }
  return engine;
}

/// 算一筆 `a op b =` 並回傳 display。
String compute(
  String a,
  CalcOp op,
  String b, {
  RoundingMode rounding = RoundingMode.float,
  int decimalPlaces = 2,
}) {
  final engine = engineWith(rounding, decimalPlaces);
  enter(engine, a);
  engine.applyOperator(op);
  enter(engine, b);
  engine.equals();
  return engine.display;
}
