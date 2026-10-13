import 'package:decimal/decimal.dart';

import 'calc_settings.dart';

enum CalcOp { add, subtract, multiply, divide }

/// 純 Dart 計算引擎，全程 Decimal，不 import Flutter。
class CalculatorEngine {
  static const int _maxDigits = 16;

  /// 只在 [RoundingMode.float] 模式使用的除法截斷位（Phase 1 行為）。
  static const int _floatDivisionScale = 10;

  static final Decimal _two = Decimal.fromInt(2);

  CalcSettings _settings = CalcSettings.raw;

  Decimal _accumulator = Decimal.zero;
  CalcOp? _pendingOp;
  String _entry = '0';
  bool _startNewEntry = true;
  bool _hasError = false;
  Decimal _grandTotal = Decimal.zero;
  Decimal? _muCost;

  /// 由 [CalculatorCubit] 在啟動與設定變更時注入。
  void applySettings(CalcSettings settings) => _settings = settings;

  /// 非除法路徑唯一的捨入出口（`+ − ×`）。
  /// 除法在 `_divide()` 內用真實餘數一次到位，不得再經過這裡。
  Decimal _applyRounding(Decimal d) {
    final n = _settings.effectiveDecimalPlaces;
    if (n == null) return d; // F：不捨入
    return switch (_settings.rounding) {
      RoundingMode.cut => d.truncate(scale: n),
      RoundingMode.halfUp => d.round(scale: n),
      RoundingMode.up => d.sign < 0 ? -(-d).ceil(scale: n) : d.ceil(scale: n),
      RoundingMode.float => d,
    };
  }

  String get display => _hasError ? 'Error' : _entry;
  bool get hasError => _hasError;

  /// GT 總計（`=` 完成一筆時累加）。
  Decimal get grandTotal => _grandTotal;

  /// 定義是「總和不為 0」，不是「本 session 用過 GT」。
  /// 副作用：一筆 `X = 0` 進 GT 後總和仍是 0，indicator 不會亮 —— 刻意如此。
  bool get hasGT => _grandTotal != Decimal.zero;

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
    _setEntryResult(_accumulator);
  }

  void equals() {
    if (_hasError || _pendingOp == null) return;
    if (!_compute()) return;
    _grandTotal += _accumulator;
    _pendingOp = null;
    _setEntryResult(_accumulator);
  }

  void showGrandTotal() {
    if (_hasError) return;
    _setEntryResult(_grandTotal);
  }

  /// 含稅價：entry × (1 + t/100)。只作用於 entry，不碰 accumulator／pendingOp。
  void taxPlus() {
    if (_hasError) return;
    final result = _applyRounding(_entryValue * _taxFactor());
    _setEntryResult(result);
  }

  /// 未稅價（反推）：entry ÷ (1 + t/100)。除法走餘數法，只捨入一次。
  void taxMinus() {
    if (_hasError) return;
    final factor = _taxFactor();
    if (factor == Decimal.zero) {
      _hasError = true;
      return;
    }
    _setEntryResult(_divide(_entryValue, factor));
  }

  /// 1 + t/100。用 shift(-2) 而非 `/`，避免產生 Rational。
  Decimal _taxFactor() => Decimal.one + _settings.taxRate.shift(-2);

  void _setEntryResult(Decimal value) {
    _entry = _clean(value);
    _startNewEntry = true;
  }

  /// Casio 式二元 MU：讀取待執行運算子與兩個運算元。
  ///
  /// 第一次：`成本 × 利潤率% MU` → 售價 = 成本 ÷ (1 − 利潤率/100)。
  /// 第二次：顯示利潤額 = 售價 − 成本。
  /// 售價本身就是那場乘法的答案，所以完成時吃掉 `_pendingOp`
  /// （否則之後按 `=` 會變成 `成本 × 售價`），這也讓 MU 天然不進 GT。
  void mu() {
    if (_hasError) return;

    final cost = _muCost;
    if (cost != null) {
      final profit = _applyRounding(_entryValue - cost);
      _muCost = null;
      _accumulator = profit;
      _pendingOp = null;
      _setEntryResult(profit);
      return;
    }

    if (_pendingOp != CalcOp.multiply) return; // no-op

    final divisor = Decimal.one - _entryValue.shift(-2);
    if (divisor == Decimal.zero) {
      _hasError = true;
      return;
    }
    final sellingPrice = _divide(_accumulator, divisor);
    _muCost = _accumulator;
    _accumulator = sellingPrice;
    _pendingOp = null;
    _setEntryResult(sellingPrice);
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
      _accumulator = _applyRounding(switch (op) {
        CalcOp.add => _accumulator + rhs,
        CalcOp.subtract => _accumulator - rhs,
        CalcOp.multiply => _accumulator * rhs,
        CalcOp.divide => _accumulator, // 於上方處理，此分支不可達
      });
    }
    return true;
  }

  /// 除法是唯一會產生無限小數的運算。為避免「先截斷、再捨入」把餘數證據弄丟，
  /// 這裡直接除到目標位數，並用真實餘數決定是否進位 —— 全程只捨入一次。
  Decimal _divide(Decimal a, Decimal b) {
    final n = _settings.effectiveDecimalPlaces;
    if (n == null) {
      // F：不捨入，維持 Phase 1 的截斷 10 位。
      final quotient = a.shift(_floatDivisionScale) ~/ b;
      return Decimal.fromBigInt(quotient).shift(-_floatDivisionScale);
    }
    final scaled = a.shift(n);
    final q = scaled ~/ b; // BigInt，向零截斷
    final r = scaled.remainder(b); // 符號跟隨 a
    final negative = a.sign * b.sign < 0;
    final bump = switch (_settings.rounding) {
      RoundingMode.cut => false,
      RoundingMode.up => r != Decimal.zero,
      RoundingMode.halfUp => r.abs() * _two >= b.abs(),
      RoundingMode.float => false,
    };
    final value = bump ? (negative ? q - BigInt.one : q + BigInt.one) : q;
    return Decimal.fromBigInt(value).shift(-n);
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

  void allClear() {
    _accumulator = Decimal.zero;
    _pendingOp = null;
    _entry = '0';
    _startNewEntry = true;
    _grandTotal = Decimal.zero;
    _muCost = null;
    _hasError = false;
  }

  void clearEntry() {
    if (_hasError) {
      allClear();
      return;
    }
    _entry = '0';
    _startNewEntry = true;
  }
}
