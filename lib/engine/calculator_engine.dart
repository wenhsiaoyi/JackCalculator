import 'package:decimal/decimal.dart';

enum CalcOp { add, subtract, multiply, divide }

/// 純 Dart 計算引擎，全程 Decimal，不 import Flutter。
class CalculatorEngine {
  static const int _divisionScale = 10;
  static const int _maxDigits = 16;

  Decimal _accumulator = Decimal.zero;
  CalcOp? _pendingOp;
  String _entry = '0';
  bool _startNewEntry = true;
  bool _hasError = false;

  String get display => _hasError ? 'Error' : _entry;
  bool get hasError => _hasError;

  Decimal get _entryValue => Decimal.tryParse(_entry) ?? Decimal.zero;

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

  void applyOperator(CalcOp op) {
    if (_hasError) return;
    if (_pendingOp != null && !_startNewEntry) {
      if (!_compute()) return;
    } else {
      _accumulator = _entryValue;
    }
    _pendingOp = op;
    _startNewEntry = true;
    _entry = _clean(_accumulator);
  }

  void equals() {
    if (_hasError || _pendingOp == null) return;
    if (!_compute()) return;
    _pendingOp = null;
    _startNewEntry = true;
    _entry = _clean(_accumulator);
  }

  bool _compute() {
    final op = _pendingOp!;
    final rhs = _entryValue;
    if (op == CalcOp.divide) {
      if (rhs == Decimal.zero) {
        _hasError = true;
        return false;
      }
      _accumulator = _divide(_accumulator, rhs);
    } else {
      _accumulator = switch (op) {
        CalcOp.add => _accumulator + rhs,
        CalcOp.subtract => _accumulator - rhs,
        CalcOp.multiply => _accumulator * rhs,
        CalcOp.divide => _accumulator, // 於上方處理，此分支不可達
      };
    }
    return true;
  }

  static Decimal _divide(Decimal a, Decimal b) {
    final shifted = a.shift(_divisionScale);
    final quotient = shifted ~/ b; // BigInt，截斷除法
    return Decimal.fromBigInt(quotient).shift(-_divisionScale);
  }

  static String _clean(Decimal d) {
    var s = d.toString();
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    if (s.isEmpty || s == '-') s = '0';
    return s;
  }

  // Task 4 會補完整 allClear 並加入 clearEntry。
  void allClear() {
    _accumulator = Decimal.zero;
    _pendingOp = null;
    _entry = '0';
    _startNewEntry = true;
    _hasError = false;
  }
}
