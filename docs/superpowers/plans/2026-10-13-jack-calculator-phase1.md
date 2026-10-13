# Jack計算機 Phase 1（MVP 骨架）實作計畫

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 用 Cubit + `decimal` 建出能在 Windows 本機跑、加減乘除零浮點誤差的現代簡約計算機骨架。

**Architecture:** 純 Dart 的 `CalculatorEngine` 封裝全部運算狀態；`CalculatorCubit` 持有單一 engine 實例、把按鍵事件轉成 engine 呼叫後 `emit` 不可變 `CalculatorState`；UI 用 `BlocBuilder` 訂閱。engine 不 import Flutter，可獨立單元測試。

**Tech Stack:** Flutter 3.47.7 / Dart 3.13.5、`flutter_bloc`（Cubit）、`decimal`、Material 3。

**Spec:** `docs/superpowers/specs/2026-10-13-jack-calculator-phase1-design.md`

## Global Constraints

- Dart SDK 限制 `^3.13.5`（`pubspec.yaml`），`publish_to: 'none'`。
- 本計畫**只新增** `flutter_bloc`、`decimal` 兩個依賴；**不引入**持久化（Hive/Isar）、codegen（build_runner）、`test` 套件（一律用 `flutter_test`）。
- **禁止** `flutter pub upgrade`（`pubspec.lock` 進版控，會產生無關 diff）。
- 連算採**立即執行**（左到右，非運算子優先序）：`2 + 3 × 4 =` → `20`。
- 運算一律用 `Decimal`，**禁止**用 Dart `double` 做商業計算。
- 本機唯一可執行目標是 Windows；iOS/Linux 建置在本機必定失敗。
- 標準檢查順序：`flutter analyze` → `flutter test`。判成功看有無 `All tests passed!`，**不要**只看 shell exit code（Flutter 寫 stderr 會讓 PowerShell 誤報 exit 1）。
- App 顯示名稱統一為「Jack計算機」（含各平台原生設定）。

## File Structure

```
lib/
├── core/
│   ├── theme.dart              # 建立：Material 3 深/淺色
│   └── number_format.dart      # 建立：Phase 1 pass-through 顯示格式化
├── engine/
│   └── calculator_engine.dart  # 建立：純 Dart 計算引擎
├── bloc/
│   ├── calculator_state.dart   # 建立：不可變 state
│   └── calculator_cubit.dart   # 建立：Cubit 橋接 UI 與 engine
└── views/
    ├── calculator_screen.dart  # 建立：主畫面
    └── components/
        ├── calc_button.dart    # 建立：按鍵元件
        └── display_screen.dart # 建立：顯示屏
    main.dart                   # 修改：改掛計算機（移除 counter）
test/
├── calculator_engine_test.dart # 建立：引擎單元測試
├── calculator_cubit_test.dart  # 建立：Cubit 測試
└── widget_test.dart            # 修改：counter 煙霧測試 → 2+3=5
pubspec.yaml                    # 修改：加 flutter_bloc、decimal
windows/runner/main.cpp         # 修改：視窗標題
windows/runner/Runner.rc        # 修改：exe 中繼資料
android/app/src/main/AndroidManifest.xml  # 修改：android:label
ios/Runner/Info.plist           # 修改：CFBundleDisplayName
linux/runner/my_application.cc  # 修改：GTK 標題兩處
```

---

### Task 1: 加入依賴並解析

**Files:**
- Modify: `pubspec.yaml`（`dependencies` 區塊）

**Interfaces:**
- Consumes: 無
- Produces: 可用之 `package:flutter_bloc/flutter_bloc.dart`、`package:decimal/decimal.dart`

- [ ] **Step 1: 編輯 `pubspec.yaml`，在 `dependencies:` 的 `cupertino_icons: ^1.0.8` 下方加入兩列**

```yaml
  flutter_bloc: ^9.0.0
  decimal: ^3.2.0
```

- [ ] **Step 2: 解析依賴**

Run: `flutter pub get`
Expected: 出現 `Got dependencies!`，`pubspec.lock` 更新（新增 flutter_bloc、decimal、bloc、nested、provider(_bloc 相依)、rational）。stderr 可能有警告但仍成功——看 `Got dependencies!` 為準。

- [ ] **Step 3: 確認靜態分析乾淨**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add flutter_bloc and decimal dependencies"
```

---

### Task 2: 計算引擎 — 數字輸入（entry）

**Files:**
- Create: `lib/engine/calculator_engine.dart`
- Test: `test/calculator_engine_test.dart`

**Interfaces:**
- Consumes: `package:decimal/decimal.dart`（`Decimal`）
- Produces:
  - `enum CalcOp { add, subtract, multiply, divide }`
  - `class CalculatorEngine`：`String get display`、`bool get hasError`、`void inputDigit(String)`、`void inputDecimalPoint()`、`void backspace()`、`void toggleSign()`
  - （Task 3/4 會在同一檔案補 `applyOperator`/`equals`/`allClear`/`clearEntry`）

- [ ] **Step 1: 寫失敗測試 `test/calculator_engine_test.dart`**

```dart
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
```

- [ ] **Step 2: 執行確認失敗**

Run: `flutter test test/calculator_engine_test.dart`
Expected: 編譯錯誤 / FAIL（`CalculatorEngine` 未定義）。

- [ ] **Step 3: 寫入 `lib/engine/calculator_engine.dart`（entry 部分 + 共用欄位）**

```dart
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

  // Task 3/4 會補上 applyOperator / equals / allClear / clearEntry / _compute / _clean。
}
```

- [ ] **Step 4: 執行測試確認通過**

Run: `flutter test test/calculator_engine_test.dart`
Expected: `All tests passed!`（entry group 全綠）。若分析抱怨 `allClear` 未定義，代表 Task 4 尚未加入——本步驟先以 entry 測試通過為準；如編譯需要，暫不加 `allClear` 呼叫可先註解掉那行，Task 4 補回。**（實作提示：為避免未定義符號，Step 3 請保留 `if (_hasError) allClear();` 並在檔案內先建立佔位 `void allClear() { _entry = '0'; _startNewEntry = true; _hasError = false; }`，Task 4 再補完整。）**

- [ ] **Step 5: Commit**

```bash
git add lib/engine/calculator_engine.dart test/calculator_engine_test.dart
git commit -m "feat: add CalculatorEngine digit entry"
```

---

### Task 3: 計算引擎 — 四則運算與立即執行連算

**Files:**
- Modify: `lib/engine/calculator_engine.dart`（加入 `applyOperator`、`equals`、`_compute`、`_divide`、`_clean`）
- Test: `test/calculator_engine_test.dart`（加入 `arithmetic` group）

**Interfaces:**
- Consumes: Task 2 的欄位與 `CalcOp`
- Produces: `void applyOperator(CalcOp op)`、`void equals()`

- [ ] **Step 1: 加入失敗測試（在 `test/calculator_engine_test.dart` 的 `main()` 內新增 group）**

```dart
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
```

- [ ] **Step 2: 執行確認失敗**

Run: `flutter test test/calculator_engine_test.dart`
Expected: FAIL（`applyOperator`/`equals` 未定義）。

- [ ] **Step 3: 在 `CalculatorEngine` 加入運算方法（取代 Task 2 末尾的佔位註解）**

```dart
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
```

- [ ] **Step 4: 執行測試確認通過**

Run: `flutter test test/calculator_engine_test.dart`
Expected: `All tests passed!`（含 arithmetic group）。

- [ ] **Step 5: Commit**

```bash
git add lib/engine/calculator_engine.dart test/calculator_engine_test.dart
git commit -m "feat: add CalculatorEngine arithmetic with Decimal precision"
```

---

### Task 4: 計算引擎 — 清理與除以零錯誤

**Files:**
- Modify: `lib/engine/calculator_engine.dart`（把佔位 `allClear` 補完整、加入 `clearEntry`）
- Test: `test/calculator_engine_test.dart`（加入 `clear & error` group）

**Interfaces:**
- Consumes: Task 2/3 全部
- Produces: `void allClear()`、`void clearEntry()`

- [ ] **Step 1: 加入失敗測試**

```dart
  group('clear & error', () {
    test('divide by zero sets error and clears on next digit', () {
      final e = CalculatorEngine()
        ..inputDigit('5')
        ..applyOperator(CalcOp.divide)
        ..inputDigit('0')
        ..equals();
      expect(e.hasError, true);
      expect(e.display, 'Error');
      e.inputDigit('7');
      expect(e.hasError, false);
      expect(e.display, '7');
    });

    test('allClear resets to 0', () {
      final e = CalculatorEngine()
        ..inputDigit('9')
        ..applyOperator(CalcOp.add)
        ..inputDigit('9');
      e.allClear();
      expect(e.display, '0');
      expect(e.hasError, false);
    });

    test('clearEntry keeps pending op, resets entry', () {
      final e = CalculatorEngine()
        ..inputDigit('2')
        ..applyOperator(CalcOp.add)
        ..inputDigit('8')
        ..clearEntry()
        ..inputDigit('3')
        ..equals();
      expect(e.display, '5'); // 2 + 3 = 5（8 被清掉）
    });
  });
```

- [ ] **Step 2: 執行確認失敗**

Run: `flutter test test/calculator_engine_test.dart`
Expected: FAIL（`clearEntry` 未定義，或 `allClear` 佔位不足）。

- [ ] **Step 3: 用完整版取代 Task 2 的佔位 `allClear`，並加入 `clearEntry`**

```dart
  void allClear() {
    _accumulator = Decimal.zero;
    _pendingOp = null;
    _entry = '0';
    _startNewEntry = true;
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
```

- [ ] **Step 4: 執行測試確認通過**

Run: `flutter test test/calculator_engine_test.dart`
Expected: `All tests passed!`（三個 group 全綠）。

- [ ] **Step 5: Commit**

```bash
git add lib/engine/calculator_engine.dart test/calculator_engine_test.dart
git commit -m "feat: add CalculatorEngine clear and divide-by-zero handling"
```

---

### Task 5: CalculatorState 與 CalculatorCubit

**Files:**
- Create: `lib/bloc/calculator_state.dart`
- Create: `lib/bloc/calculator_cubit.dart`
- Test: `test/calculator_cubit_test.dart`

**Interfaces:**
- Consumes: `CalculatorEngine`、`CalcOp`（Task 2-4）
- Produces:
  - `class CalculatorState { final String display; final bool hasError; const CalculatorState({required this.display, required this.hasError}); }`
  - `class CalculatorCubit extends Cubit<CalculatorState>`：`onDigit`、`onDecimalPoint`、`applyOperator`、`equals`、`allClear`、`clearEntry`、`backspace`、`toggleSign`

- [ ] **Step 1: 寫失敗測試 `test/calculator_cubit_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/bloc/calculator_cubit.dart';
import 'package:jack_calculator/engine/calculator_engine.dart';

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
```

- [ ] **Step 2: 執行確認失敗**

Run: `flutter test test/calculator_cubit_test.dart`
Expected: FAIL（`CalculatorCubit` 未定義）。

- [ ] **Step 3: 建立 `lib/bloc/calculator_state.dart`**

```dart
import 'package:flutter/foundation.dart';

@immutable
class CalculatorState {
  final String display;
  final bool hasError;

  const CalculatorState({required this.display, required this.hasError});
}
```

- [ ] **Step 4: 建立 `lib/bloc/calculator_cubit.dart`**

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../engine/calculator_engine.dart';
import 'calculator_state.dart';

class CalculatorCubit extends Cubit<CalculatorState> {
  final CalculatorEngine _engine = CalculatorEngine();

  CalculatorCubit()
      : super(const CalculatorState(display: '0', hasError: false));

  void _sync() =>
      emit(CalculatorState(display: _engine.display, hasError: _engine.hasError));

  void onDigit(String d) {
    _engine.inputDigit(d);
    _sync();
  }

  void onDecimalPoint() {
    _engine.inputDecimalPoint();
    _sync();
  }

  void applyOperator(CalcOp op) {
    _engine.applyOperator(op);
    _sync();
  }

  void equals() {
    _engine.equals();
    _sync();
  }

  void allClear() {
    _engine.allClear();
    _sync();
  }

  void clearEntry() {
    _engine.clearEntry();
    _sync();
  }

  void backspace() {
    _engine.backspace();
    _sync();
  }

  void toggleSign() {
    _engine.toggleSign();
    _sync();
  }
}
```

- [ ] **Step 5: 執行測試確認通過**

Run: `flutter test test/calculator_cubit_test.dart`
Expected: `All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add lib/bloc/calculator_state.dart lib/bloc/calculator_cubit.dart test/calculator_cubit_test.dart
git commit -m "feat: add CalculatorCubit and CalculatorState"
```

---

### Task 6: core 主題與顯示格式化

**Files:**
- Create: `lib/core/theme.dart`
- Create: `lib/core/number_format.dart`

**Interfaces:**
- Consumes: `package:flutter/material.dart`
- Produces: `class AppTheme { static ThemeData get light; static ThemeData get dark; }`、`String formatForDisplay(String raw)`

- [ ] **Step 1: 建立 `lib/core/theme.dart`**

```dart
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _seed = Color(0xFF0066CC);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seed),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
      );
}
```

- [ ] **Step 2: 建立 `lib/core/number_format.dart`**

```dart
/// Phase 1：顯示格式化為 pass-through。
/// 千分位與國際/印度分位、捨入模式於 Phase 2 於此實作。
String formatForDisplay(String raw) => raw;
```

- [ ] **Step 3: 分析確認乾淨**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/core/theme.dart lib/core/number_format.dart
git commit -m "feat: add Material 3 theme and display format placeholder"
```

---

### Task 7: 按鍵與顯示屏元件

**Files:**
- Create: `lib/views/components/calc_button.dart`
- Create: `lib/views/components/display_screen.dart`

**Interfaces:**
- Consumes: `formatForDisplay`（Task 6）
- Produces:
  - `enum CalcButtonVariant { number, operator, function, equals }`
  - `class CalcButton extends StatelessWidget`（欄位 `label`、`onPressed`、`variant`）
  - `class DisplayScreen extends StatelessWidget`（欄位 `display`、`hasError`；內含 `Key('displayValue')` 的 Text）

- [ ] **Step 1: 建立 `lib/views/components/calc_button.dart`**

```dart
import 'package:flutter/material.dart';

enum CalcButtonVariant { number, operator, function, equals }

class CalcButton extends StatelessWidget {
  const CalcButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CalcButtonVariant.number,
  });

  final String label;
  final VoidCallback onPressed;
  final CalcButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (variant) {
      CalcButtonVariant.number => (
          scheme.surfaceContainerHighest,
          scheme.onSurface
        ),
      CalcButtonVariant.operator => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer
        ),
      CalcButtonVariant.function => (scheme.surface, scheme.primary),
      CalcButtonVariant.equals => (scheme.primary, scheme.onPrimary),
    };
    return Padding(
      padding: const EdgeInsets.all(4),
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 64),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}
```

- [ ] **Step 2: 建立 `lib/views/components/display_screen.dart`**

```dart
import 'package:flutter/material.dart';

import '../../core/number_format.dart';

class DisplayScreen extends StatelessWidget {
  const DisplayScreen({
    super.key,
    required this.display,
    this.hasError = false,
  });

  final String display;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      alignment: Alignment.centerRight,
      color: hasError ? scheme.errorContainer : scheme.surfaceContainerHighest,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          formatForDisplay(display),
          key: const Key('displayValue'),
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w300,
            color: hasError ? scheme.onErrorContainer : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: 分析確認乾淨**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/views/components/calc_button.dart lib/views/components/display_screen.dart
git commit -m "feat: add CalcButton and DisplayScreen widgets"
```

---

### Task 8: 主畫面、App 裝配與煙霧測試

**Files:**
- Create: `lib/views/calculator_screen.dart`
- Modify: `lib/main.dart`（整檔替換，移除 counter）
- Modify: `test/widget_test.dart`（整檔替換）

**Interfaces:**
- Consumes: `CalculatorCubit`、`CalcOp`（Task 5）、`AppTheme`（Task 6）、`CalcButton`/`DisplayScreen`（Task 7）
- Produces: `class JackCalculator extends StatelessWidget`、`class CalculatorScreen extends StatelessWidget`

- [ ] **Step 1: 改寫 `test/widget_test.dart`（移除原 counter 測試）**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jack_calculator/main.dart';

void main() {
  testWidgets('computes 2 + 3 = 5', (WidgetTester tester) async {
    await tester.pumpWidget(const JackCalculator());

    await tester.tap(find.text('2'));
    await tester.tap(find.text('+'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('='));
    await tester.pump();

    final display = find.byKey(const Key('displayValue'));
    expect(tester.widget<Text>(display).data, '5');
  });
}
```

- [ ] **Step 2: 執行確認失敗**

Run: `flutter test test/widget_test.dart`
Expected: FAIL（`JackCalculator` / `CalculatorScreen` 未定義）。

- [ ] **Step 3: 建立 `lib/views/calculator_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/calculator_cubit.dart';
import '../bloc/calculator_state.dart';
import '../engine/calculator_engine.dart';
import 'components/calc_button.dart';
import 'components/display_screen.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CalculatorCubit>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BlocBuilder<CalculatorCubit, CalculatorState>(
              builder: (_, s) =>
                  DisplayScreen(display: s.display, hasError: s.hasError),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    _row([
                      _btn('AC', cubit.allClear, CalcButtonVariant.function),
                      _btn('C', cubit.clearEntry, CalcButtonVariant.function),
                      _btn('⌫', cubit.backspace, CalcButtonVariant.function),
                      _btn('÷', () => cubit.applyOperator(CalcOp.divide),
                          CalcButtonVariant.operator),
                    ]),
                    _row([
                      _num('7', cubit), _num('8', cubit), _num('9', cubit),
                      _btn('×', () => cubit.applyOperator(CalcOp.multiply),
                          CalcButtonVariant.operator),
                    ]),
                    _row([
                      _num('4', cubit), _num('5', cubit), _num('6', cubit),
                      _btn('−', () => cubit.applyOperator(CalcOp.subtract),
                          CalcButtonVariant.operator),
                    ]),
                    _row([
                      _num('1', cubit), _num('2', cubit), _num('3', cubit),
                      _btn('+', () => cubit.applyOperator(CalcOp.add),
                          CalcButtonVariant.operator),
                    ]),
                    _row([
                      _btn('±', cubit.toggleSign, CalcButtonVariant.function),
                      _num('0', cubit),
                      _btn('.', cubit.onDecimalPoint, CalcButtonVariant.number),
                      _btn('=', cubit.equals, CalcButtonVariant.equals),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(List<Widget> buttons) =>
      Expanded(child: Row(children: buttons));

  Widget _btn(String label, VoidCallback onTap, CalcButtonVariant variant) =>
      Expanded(
        child: CalcButton(label: label, onPressed: onTap, variant: variant),
      );

  Widget _num(String digit, CalculatorCubit cubit) =>
      _btn(digit, () => cubit.onDigit(digit), CalcButtonVariant.number);
}
```

- [ ] **Step 4: 整檔替換 `lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/calculator_cubit.dart';
import 'core/theme.dart';
import 'views/calculator_screen.dart';

void main() => runApp(const JackCalculator());

class JackCalculator extends StatelessWidget {
  const JackCalculator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CalculatorCubit(),
      child: MaterialApp(
        title: 'Jack計算機',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const CalculatorScreen(),
      ),
    );
  }
}
```

- [ ] **Step 5: 執行全部檢查**

Run: `flutter analyze`
Expected: `No issues found!`
Run: `flutter test`
Expected: `All tests passed!`（engine、cubit、widget 三檔測試）。

- [ ] **Step 6: 在 Windows 本機跑起來驗證（手動）**

Run: `flutter run -d windows`
Expected: 視窗開啟、可點按計算。（PowerShell 若噴 `NativeCommandError`/exit 1 但 App 正常顯示即為成功；此為人工驗證步驟，跑完按 `q` 離開。）

- [ ] **Step 7: Commit**

```bash
git add lib/main.dart lib/views/calculator_screen.dart test/widget_test.dart
git commit -m "feat: assemble calculator UI and wire Cubit; replace counter template"
```

---

### Task 9: App 顯示名稱改為「Jack計算機」

**Files:**
- Modify: `windows/runner/main.cpp:30`
- Modify: `windows/runner/Runner.rc:93,95,97,98`
- Modify: `android/app/src/main/AndroidManifest.xml:3`
- Modify: `ios/Runner/Info.plist:10`
- Modify: `linux/runner/my_application.cc:48,52`

**Interfaces:** 無（僅字串常數）

- [ ] **Step 1: Windows 視窗標題**

`windows/runner/main.cpp`：將
```cpp
if (!window.Create(L"jack_calculator", origin, size)) {
```
改為
```cpp
if (!window.Create(L"Jack計算機", origin, size)) {
```

- [ ] **Step 2: Windows exe 中繼資料**

`windows/runner/Runner.rc`：把以下四列的值由 `jack_calculator` 改為 `Jack計算機`（`OriginalFilename` 保留 exe 檔名，僅把顯示用的 `FileDescription`/`ProductName`/`InternalName` 改名）：
```
VALUE "FileDescription", "Jack計算機" "\0"
VALUE "InternalName", "Jack計算機" "\0"
VALUE "OriginalFilename", "jack_calculator.exe" "\0"
VALUE "ProductName", "Jack計算機" "\0"
```

- [ ] **Step 3: Android label**

`android/app/src/main/AndroidManifest.xml`：將 `android:label="jack_calculator"` 改為 `android:label="Jack計算機"`。

- [ ] **Step 4: iOS 顯示名**

`ios/Runner/Info.plist`：將 `CFBundleDisplayName` 下方的 `<string>Jack Calculator</string>` 改為 `<string>Jack計算機</string>`（保留同檔 `CFBundleName` 的 `jack_calculator` 不動）。

- [ ] **Step 5: Linux GTK 標題（兩處）**

`linux/runner/my_application.cc`：將
```c
gtk_header_bar_set_title(header_bar, "jack_calculator");
```
與
```c
gtk_window_set_title(window, "jack_calculator");
```
的字串都改為 `"Jack計算機"`。

- [ ] **Step 6: 重新建置 Windows 驗證標題**

Run: `flutter build windows`
Expected: 出現 `√ Built build\windows\x64\runner\Release\jack_calculator.exe`（以 `√ Built` 為準，忽略 stderr 警告與 exit code）。

- [ ] **Step 7: Commit**

```bash
git add windows/runner/main.cpp windows/runner/Runner.rc android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist linux/runner/my_application.cc
git commit -m "chore: set app display name to Jack計算機 across platforms"
```

---

### Task 10: 最終驗證

- [ ] **Step 1:** Run `flutter analyze` → Expected `No issues found!`
- [ ] **Step 2:** Run `flutter test` → Expected `All tests passed!`
- [ ] **Step 3:** Run `flutter build windows` → Expected 有 `√ Built ...jack_calculator.exe`
- [ ] **Step 4:** 手動 `flutter run -d windows`，驗證 `0.1 + 0.2` 顯示 `0.3`、`2 + 3 × 4 =` 顯示 `20`、除以零顯示 `Error`。

## Self-Review（寫完計畫後的核對）

- **Spec 覆蓋**：Cubit+decimal（Task 1/5）、四則+AC/C/⌫/±（Task 2-4）、立即執行連算（Task 3 測試）、除以零錯誤（Task 4）、Material 3 深/淺色（Task 6）、現代简约鍵盤/顯示屏（Task 7/8）、App 名稱 Jack計算機（Task 9）、改寫 counter 測試（Task 8）、標準 analyze→test（Task 10）——皆有對應任務。
- **不在範圍**（持久化/稅率/GT/MU/歷史/匯出/擬真主題/音效）未出現於任何任務，符合 YAGNI。
- **型別一致性**：`CalcOp`、`CalculatorEngine.{display,hasError,inputDigit,inputDecimalPoint,backspace,toggleSign,applyOperator,equals,allClear,clearEntry}` 於 Task 2-4 定義、Task 5 Cubit 一一轉發、Task 8 畫面呼叫，命名相符。`CalculatorState.{display,hasError}`、`Key('displayValue')`、`AppTheme.light/dark`、`formatForDisplay` 跨任務一致。
- **除法**：因 `Decimal /` 回傳 `Rational` 且 `Rational` 無 `toDecimal`，改用 `shift` + `~/`（BigInt 截斷）+ `fromBigInt` + `shift(-scale)`，全部為 decimal 3.2.6 已核實 API；`1/3 → 0.3333333333`（截斷 10 位）與整除結果由 `_clean` 去尾零。
