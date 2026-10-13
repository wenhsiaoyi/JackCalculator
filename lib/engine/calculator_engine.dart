import 'package:decimal/decimal.dart';

enum CalcOp { add, subtract, multiply, divide }

/// 純 Dart 計算引擎，全程 Decimal，不 import Flutter。
class CalculatorEngine {
  static const int _maxDigits = 16;

  Decimal _accumulator = Decimal.zero;
  String _entry = '0';
  bool _startNewEntry = true;
  bool _hasError = false;

  String get display => _hasError ? 'Error' : _entry;
  bool get hasError => _hasError;

  void inputDigit(String digit) {
    if (_hasError) allClear();
    if (_startNewEntry) {
      _entry = digit;
      _startNewEntry = false;
    } else {
      if (_entry.replaceAll(RegExp(r'[^0-9]'), '').length >= _maxDigits) return;
      _entry = _entry == '0' ? digit : _entry + digit;
    }
  }

  void inputDecimalPoint() {
    if (_hasError) allClear();
    if (_startNewEntry) {
      _entry = '0.';
      _startNewEntry = false;
    } else if (!_entry.contains('.')) {
      _entry += '.';
    }
  }

  void backspace() {
    if (_hasError || _startNewEntry) return;
    final s = _entry;
    _entry = (s.length <= 1 || (s.length == 2 && s.startsWith('-')))
        ? '0'
        : s.substring(0, s.length - 1);
  }

  void toggleSign() {
    if (_hasError) return;
    if (_entry == '0' || _entry == '0.') return;
    if (_startNewEntry) _accumulator = -_accumulator;
    _entry = _entry.startsWith('-') ? _entry.substring(1) : '-$_entry';
  }

  // Task 4 會補完整 allClear 並加入 clearEntry / applyOperator / equals。
  void allClear() {
    _entry = '0';
    _startNewEntry = true;
    _hasError = false;
  }
}
