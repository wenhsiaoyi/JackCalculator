# Jack計算機 Phase 2（商用核心）實作計畫

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 Phase 1 的四則運算骨架上加入商用計算機核心 —— GT、Tax+/Tax−、MU、F/CUT/UP/5-4 捨入＋小數位鎖定、千分位格式化，外加 `shared_preferences` 設定持久化與設定頁。

**Architecture:** 設定以不可變值物件 `CalcSettings` 注入 `CalculatorEngine`（engine 維持零 Flutter import）；`SettingsCubit` 持有 `CalcSettings`，經 `SettingsRepository`（`shared_preferences` 唯一接觸點）存取；`CalculatorCubit` 仍是 UI↔engine 的唯一橋。格式化**只存在於顯示層**（`DisplayScreen` → `core/number_format.dart`），`_entry`／`display` 永遠是 raw 字串。

**Tech Stack:** Flutter 3.47.7 / Dart 3.13.5、`flutter_bloc`（Cubit ×2）、`decimal` 3.2.6、`shared_preferences` 2.5.6（本專案第一個 plugin）、Material 3。

**Spec:** `docs/superpowers/specs/2026-10-13-jack-calculator-phase2-design.md`（含「修訂紀錄」一節，列出 2026-10-13 校稿改掉的 7 處）

## Global Constraints

- Dart SDK 限制 `^3.13.5`（`pubspec.yaml`），`publish_to: 'none'`。
- **只新增** `shared_preferences` 一個依賴。**不引入** `equatable`、`intl` 的 `NumberFormat`、`build_runner`/codegen、`hive`、Isar、path_provider。
- **禁止** `flutter pub upgrade`（`pubspec.lock` 進版控，會產生無關 diff）。
- `CalculatorEngine` 維持**零 Flutter import**；`lib/engine/` 與 `lib/data/` 內不得出現 `package:flutter/` 或 `package:flutter_bloc/`（`flutter_bloc` 只在 `lib/bloc/`、`lib/views/`、`lib/main.dart`）。
- **raw 邊界紀律**：`CalculatorEngine._entry` 與 `CalculatorState.display` 永遠不含逗號、不補零。`formatForDisplay()` 只准在 `DisplayScreen` 內呼叫。
- 連算維持**立即執行**（左到右）：`2 + 3 × 4 =` → `20`。不引入運算子優先順序。
- 運算一律 `Decimal`，**禁止**用 `double` 做商業計算（UI 的 `fontSize` 等排版數值不算）。
- 本機唯一可執行／可建置目標是 Windows；iOS／Linux 本機必定失敗（計畫中標「未實測」即可）。
- 標準檢查順序：`flutter analyze` → `flutter test`。判成功看有無 `All tests passed!`／`No issues found!`，**不要**只看 shell exit code（Flutter 寫 stderr 會讓 PowerShell 誤報 exit code 1）。
- 換行警告 `LF will be replaced by CRLF` 是正常現象（`core.autocrlf=true`），**不要**去「修正」。
- 每個 Task 結束要能 `flutter analyze`＋`flutter test` 全綠才 commit。
- **行號會漂移**：本計畫標的行號以 Phase 1 完成時（`49ed46d`）為準。動手改檔時以「程式碼區塊內容」比對定位，不要盲信行號。

## File Structure

```
lib/
├── core/
│   ├── theme.dart                    # 不動
│   └── number_format.dart            # 改（Task 13）：簽名加 CalcSettings，實作千分位＋補零
├── data/
│   └── settings_repository.dart      # 建立（Task 3）：shared_preferences 唯一接觸點
├── engine/
│   ├── calc_settings.dart            # 建立（Task 2）：CalcSettings ＋ RoundingMode（純 Dart）
│   └── calculator_engine.dart        # 改（Task 6-11）：注入設定、餘數法除法、GT／Tax／MU／±
├── bloc/
│   ├── calculator_state.dart         # 改（Task 12）：＋hasGT、手寫 ==／hashCode
│   ├── calculator_cubit.dart         # 改（Task 12）：＋applySettings／onGrandTotal／onTaxPlus／onTaxMinus／onMu
│   └── settings_cubit.dart           # 建立（Task 4）
└── views/
    ├── calculator_screen.dart        # 改（Task 15）：5×5 鍵盤、BlocListener、GT 與 indicator 接入
    ├── settings_screen.dart          # 建立（Task 5）：稅率／捨入／小數位／分位；`parseTaxRate` 純函式
    └── components/
        ├── calc_button.dart          # 改（Task 15）：LayoutBuilder 自適應高度、FittedBox 縮字
        ├── display_screen.dart       # 改（Task 13 過渡 patch、Task 14 整檔取代）：接 settings 與 hasGT
        └── status_indicator.dart     # 建立（Task 14）
main.dart                             # 改（Task 5）：MultiBlocProvider
test/
├── engine_tools.dart                 # 建立（Task 6）：共用測試工具（engineWith／enter／compute）
├── calc_settings_test.dart           # 建立（Task 2）
├── settings_repository_test.dart     # 建立（Task 3）
├── settings_cubit_test.dart          # 建立（Task 4）
├── settings_screen_test.dart         # 建立（Task 5）
├── rounding_test.dart                # 建立（Task 6）
├── division_test.dart                # 建立（Task 7）
├── grand_total_test.dart             # 建立（Task 8）
├── tax_test.dart                     # 建立（Task 9）
├── mu_test.dart                      # 建立（Task 10）
├── sign_and_bounds_test.dart         # 建立（Task 11）
├── number_format_test.dart           # 建立（Task 13）
├── calculator_cubit_test.dart        # 改（Task 12）
├── calculator_engine_test.dart       # 只在 Task 11 追加邊界測試（Phase 1 的 15 條不動）
└── widget_test.dart                  # 改（Task 14 改斷言、Task 15 加鍵盤與導航測試）
AGENTS.md                             # 改（Task 17）：路線圖／依賴／延後項對帳
```

---

## A 段｜設定基礎

### Task 1: 開分支並加入 `shared_preferences`

**Files:**
- Modify: `pubspec.yaml`

**Interfaces:**
- Consumes: 無
- Produces: 可用的 `package:shared_preferences/shared_preferences.dart`

- [ ] **Step 1: 開工作分支**（沿用 Phase 1 的 branch 慣例，不用 worktree）

```bash
git switch -c feat/phase2-commercial-core
```

- [ ] **Step 2: 在 `pubspec.yaml` 的 `decimal: ^3.2.0` 下加一行**

```yaml
  shared_preferences: ^2.5.6
```

- [ ] **Step 3: 解析依賴**

Run: `flutter pub get`
Expected: `Got dependencies!`；`pubspec.lock` 新增 `shared_preferences` 與其 federated 實作（`shared_preferences_android`、`shared_preferences_foundation`、`shared_preferences_linux`、`shared_preferences_web`、`shared_preferences_windows`、`path_provider_*` 等）。stderr 可能有警告，**判成功看 `Got dependencies!`**。

- [ ] **Step 4: 確認既有品質沒被動到**

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: `All tests passed!`（18 條）

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add shared_preferences dependency for settings persistence"
```

---

### Task 2: `CalcSettings` 值物件

**Files:**
- Create: `lib/engine/calc_settings.dart`
- Test: `test/calc_settings_test.dart`

**Interfaces:**
- Consumes: `package:decimal/decimal.dart`（`Decimal`）
- Produces:
  - `enum RoundingMode { float, cut, up, halfUp }`，帶 `final int code`、`static RoundingMode fromCode(int code)`（未知碼 → `halfUp`）
  - `class CalcSettings`：欄位 `Decimal taxRate`、`RoundingMode rounding`、`int decimalPlaces`、`bool grouping`
  - `int? get effectiveDecimalPlaces`（`float` 時回 `null`）
  - `static final CalcSettings defaults`（5%／halfUp／2／true）、`static final CalcSettings raw`（5%／float／2／false）
  - `CalcSettings copyWith({Decimal? taxRate, RoundingMode? rounding, int? decimalPlaces, bool? grouping})`
  - 手寫 `operator ==` 與 `hashCode`

> **注意**：`Decimal` 有 `late final` 欄位、`Decimal.zero/one/ten` 是 `static final`，所以**沒有** `const CalcSettings` 可用；`defaults`／`raw` 只能是 `static final`。

- [ ] **Step 1: 寫失敗測試 `test/calc_settings_test.dart`**

```dart
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
```

- [ ] **Step 2: 執行測試確認失敗**

Run: `flutter test test/calc_settings_test.dart`
Expected: FAIL —— `Error: Couldn't resolve the package 'jack_calculator' ...`／`Target of URI doesn't exist: 'package:jack_calculator/engine/calc_settings.dart'`

- [ ] **Step 3: 建立 `lib/engine/calc_settings.dart`**

```dart
import 'package:decimal/decimal.dart';

/// 捨入模式，對應 UI 標籤 F／CUT／UP／5/4。
enum RoundingMode {
  float(0),
  cut(1),
  up(2),
  halfUp(3);

  const RoundingMode(this.code);

  /// 持久化用的穩定整數碼（宣告順序若變動也不會毀掉舊設定）。
  final int code;

  static RoundingMode fromCode(int code) => RoundingMode.values
      .firstWhere((m) => m.code == code, orElse: () => RoundingMode.halfUp);
}

/// 計算機設定值物件。純 Dart，不 import Flutter。
class CalcSettings {
  CalcSettings({
    required this.taxRate,
    required this.rounding,
    required this.decimalPlaces,
    required this.grouping,
  });

  /// 稅率，存「百分之幾」的數值（5 = 5%）。範圍 0–100、最多一位小數。
  final Decimal taxRate;
  final RoundingMode rounding;

  /// 鎖定小數位：0／2／3／4。[rounding] 為 [RoundingMode.float] 時失效。
  final int decimalPlaces;
  final bool grouping;

  /// F 模式回傳 null —— engine 與 formatter 都讀這裡，不要各自判斷 F。
  int? get effectiveDecimalPlaces =>
      rounding == RoundingMode.float ? null : decimalPlaces;

  /// App 啟動預設值：5%／5-4／2 位／千分位 on。
  static final CalcSettings defaults = CalcSettings(
    taxRate: Decimal.fromInt(5),
    rounding: RoundingMode.halfUp,
    decimalPlaces: 2,
    grouping: true,
  );

  /// engine 自身的預設值：不捨入、不補零、不分位（＝Phase 1 語意）。
  static final CalcSettings raw = CalcSettings(
    taxRate: Decimal.fromInt(5),
    rounding: RoundingMode.float,
    decimalPlaces: 2,
    grouping: false,
  );

  CalcSettings copyWith({
    Decimal? taxRate,
    RoundingMode? rounding,
    int? decimalPlaces,
    bool? grouping,
  }) =>
      CalcSettings(
        taxRate: taxRate ?? this.taxRate,
        rounding: rounding ?? this.rounding,
        decimalPlaces: decimalPlaces ?? this.decimalPlaces,
        grouping: grouping ?? this.grouping,
      );

  @override
  bool operator ==(Object other) =>
      other is CalcSettings &&
      other.taxRate == taxRate &&
      other.rounding == rounding &&
      other.decimalPlaces == decimalPlaces &&
      other.grouping == grouping;

  @override
  int get hashCode => Object.hash(taxRate, rounding, decimalPlaces, grouping);
}
```

- [ ] **Step 4: 執行測試確認通過**

Run: `flutter test test/calc_settings_test.dart`
Expected: `All tests passed!`（6 條）

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/engine/calc_settings.dart test/calc_settings_test.dart
git commit -m "feat(engine): add CalcSettings value object and RoundingMode enum"
```

---

### Task 3: `SettingsRepository`（`shared_preferences` 唯一接觸點）

**Files:**
- Create: `lib/data/settings_repository.dart`
- Test: `test/settings_repository_test.dart`

**Interfaces:**
- Consumes: `CalcSettings`／`RoundingMode`（Task 2）
- Produces:
  - `class SettingsRepository`：`const SettingsRepository()`、`Future<CalcSettings> load()`、`Future<void> save(CalcSettings settings)`
  - 靜態鍵名常數：`taxRateKey`／`roundingKey`／`decimalPlacesKey`／`groupingKey`
  - `static const List<int> allowedDecimalPlaces = <int>[0, 2, 3, 4]`
  - 行為保證：任何讀取異常／壞值 → 回 `CalcSettings.defaults`，**不拋**

- [ ] **Step 1: 寫失敗測試 `test/settings_repository_test.dart`**

```dart
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/data/settings_repository.dart';
import 'package:jack_calculator/engine/calc_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SettingsRepository repo;

  setUp(() {
    repo = const SettingsRepository();
  });

  test('空資料 → 回 defaults', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await repo.load(), CalcSettings.defaults);
  });

  test('save → load round-trip', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = CalcSettings(
      taxRate: Decimal.parse('8.5'),
      rounding: RoundingMode.up,
      decimalPlaces: 3,
      grouping: false,
    );
    await repo.save(settings);
    expect(await repo.load(), settings);
  });

  test('壞稅率退回預設、不拋', () async {
    SharedPreferences.setMockInitialValues({
      SettingsRepository.taxRateKey: 'oops',
    });
    expect((await repo.load()).taxRate, CalcSettings.defaults.taxRate);
  });

  test('非法小數位（1）退回 2', () async {
    SharedPreferences.setMockInitialValues({
      SettingsRepository.decimalPlacesKey: 1,
    });
    expect((await repo.load()).decimalPlaces, 2);
  });

  test('未知捨入碼退回 5/4', () async {
    SharedPreferences.setMockInitialValues({
      SettingsRepository.roundingKey: 42,
    });
    expect((await repo.load()).rounding, RoundingMode.halfUp);
  });

  test('只寫 4 個純量鍵', () async {
    SharedPreferences.setMockInitialValues({});
    await repo.save(CalcSettings.defaults);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().length, 4);
  });
}
```

- [ ] **Step 2: 執行測試確認失敗**

Run: `flutter test test/settings_repository_test.dart`
Expected: FAIL —— `Target of URI doesn't exist: 'package:jack_calculator/data/settings_repository.dart'`

- [ ] **Step 3: 建立 `lib/data/settings_repository.dart`**

```dart
import 'package:decimal/decimal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/calc_settings.dart';

/// `shared_preferences` 在整個 repo 內唯一的接觸點。
///
/// 只存 4 個純量；稅率以字串存放以保留 Decimal 精度。
class SettingsRepository {
  const SettingsRepository();

  static const String taxRateKey = 'tax_rate';
  static const String roundingKey = 'rounding_mode';
  static const String decimalPlacesKey = 'decimal_places';
  static const String groupingKey = 'grouping';

  static const List<int> allowedDecimalPlaces = <int>[0, 2, 3, 4];

  /// 讀不到、壞值、平台異常一律退回 [CalcSettings.defaults]，不拋。
  Future<CalcSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final taxRate = Decimal.tryParse(prefs.getString(taxRateKey) ?? '') ??
          CalcSettings.defaults.taxRate;
      return CalcSettings(
        taxRate: taxRate,
        rounding: RoundingMode.fromCode(
          prefs.getInt(roundingKey) ?? CalcSettings.defaults.rounding.code,
        ),
        decimalPlaces: _normalizePlaces(
          prefs.getInt(decimalPlacesKey) ?? CalcSettings.defaults.decimalPlaces,
        ),
        grouping: prefs.getBool(groupingKey) ?? CalcSettings.defaults.grouping,
      );
    } catch (_) {
      return CalcSettings.defaults;
    }
  }

  Future<void> save(CalcSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(taxRateKey, settings.taxRate.toString());
    await prefs.setInt(roundingKey, settings.rounding.code);
    await prefs.setInt(decimalPlacesKey, settings.decimalPlaces);
    await prefs.setBool(groupingKey, settings.grouping);
  }

  static int _normalizePlaces(int value) => allowedDecimalPlaces.contains(value)
      ? value
      : CalcSettings.defaults.decimalPlaces;
}
```

- [ ] **Step 4: 執行測試確認通過**

Run: `flutter test test/settings_repository_test.dart`
Expected: `All tests passed!`（6 條）

- [ ] **Step 5: Commit**

```bash
git add lib/data/settings_repository.dart test/settings_repository_test.dart
git commit -m "feat(data): add SettingsRepository backed by shared_preferences"
```

---

### Task 4: `SettingsCubit`

**Files:**
- Create: `lib/bloc/settings_cubit.dart`
- Test: `test/settings_cubit_test.dart`

**Interfaces:**
- Consumes: `SettingsRepository`（Task 3）、`CalcSettings`（Task 2）
- Produces:
  - `class SettingsCubit extends Cubit<CalcSettings>`：`SettingsCubit(SettingsRepository repo)`（建構即 fire-and-forget `load()`，初始 state 為 `CalcSettings.defaults`）
  - `setTaxRate(Decimal)`／`setRounding(RoundingMode)`／`setDecimalPlaces(int)`／`setGrouping(bool)`
  - 載入完成後 `emit` 實際設定；`close()` 之後不 emit（`isClosed` 守衛）

- [ ] **Step 1: 寫失敗測試 `test/settings_cubit_test.dart`**

```dart
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/bloc/settings_cubit.dart';
import 'package:jack_calculator/data/settings_repository.dart';
import 'package:jack_calculator/engine/calc_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('初始 state 是 defaults（不等載入）', () async {
    SharedPreferences.setMockInitialValues({});
    final cubit = SettingsCubit(const SettingsRepository());
    expect(cubit.state, CalcSettings.defaults);
    await cubit.close();
  });

  test('載入完成後以實際設定取代初始值', () async {
    SharedPreferences.setMockInitialValues({
      SettingsRepository.roundingKey: RoundingMode.cut.code,
      SettingsRepository.decimalPlacesKey: 4,
      SettingsRepository.groupingKey: false,
    });
    final cubit = SettingsCubit(const SettingsRepository());
    // bloc 的 stream 是 broadcast 且「不 replay」：訂閱發生在 load 完成之前，
    // 所以這裡收到的第一個事件就是載入完成的那次 emit（用 `.first` 即可）。
    final loaded = await cubit.stream.first;
    expect(loaded.rounding, RoundingMode.cut);
    expect(loaded.decimalPlaces, 4);
    expect(loaded.grouping, false);
    await cubit.close();
  });

  test('setter 更新 state 並寫入 repo', () async {
    SharedPreferences.setMockInitialValues({});
    final cubit = SettingsCubit(const SettingsRepository());
    cubit.setTaxRate(Decimal.parse('12.5'));
    expect(cubit.state.taxRate, Decimal.parse('12.5'));
    cubit.setRounding(RoundingMode.up);
    cubit.setDecimalPlaces(0);
    cubit.setGrouping(false);
    await pumpEventQueue();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SettingsRepository.taxRateKey), '12.5');
    expect(prefs.getInt(SettingsRepository.roundingKey),
        RoundingMode.up.code);
    expect(prefs.getInt(SettingsRepository.decimalPlacesKey), 0);
    expect(prefs.getBool(SettingsRepository.groupingKey), false);
    await cubit.close();
  });

  test('close 之後載入完成不會 emit', () async {
    SharedPreferences.setMockInitialValues({
      SettingsRepository.groupingKey: false,
    });
    final cubit = SettingsCubit(const SettingsRepository());
    await cubit.close();
    await pumpEventQueue();
    // 若 isClosed 守衛失效，這裡會拋 StateError 讓測試失敗。
  });
}
```

- [ ] **Step 2: 執行測試確認失敗**

Run: `flutter test test/settings_cubit_test.dart`
Expected: FAIL —— `Target of URI doesn't exist: 'package:jack_calculator/bloc/settings_cubit.dart'`

- [ ] **Step 3: 建立 `lib/bloc/settings_cubit.dart`**

```dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/settings_repository.dart';
import '../engine/calc_settings.dart';

/// 設定的載入與儲存。state 直接就是 [CalcSettings]。
class SettingsCubit extends Cubit<CalcSettings> {
  SettingsCubit(this._repo) : super(CalcSettings.defaults) {
    _load();
  }

  final SettingsRepository _repo;

  Future<void> _load() async {
    final loaded = await _repo.load();
    if (isClosed) return;
    emit(loaded);
  }

  void setTaxRate(Decimal rate) => _update(state.copyWith(taxRate: rate));

  void setRounding(RoundingMode mode) =>
      _update(state.copyWith(rounding: mode));

  void setDecimalPlaces(int places) =>
      _update(state.copyWith(decimalPlaces: places));

  void setGrouping(bool grouping) =>
      _update(state.copyWith(grouping: grouping));

  void _update(CalcSettings next) {
    emit(next);
    unawaited(_repo.save(next)); // fire-and-forget：UI 不等寫入
  }
}
```

> `Decimal` 需要 import：檔案頂端加 `import 'package:decimal/decimal.dart';`（`setTaxRate` 的參數型別用到）。

- [ ] **Step 4: 執行測試確認通過**

Run: `flutter test test/settings_cubit_test.dart`
Expected: `All tests passed!`（4 條）

- [ ] **Step 5: Commit**

```bash
git add lib/bloc/settings_cubit.dart test/settings_cubit_test.dart
git commit -m "feat(bloc): add SettingsCubit with async load and fire-and-forget save"
```

---

### Task 5: 設定頁 + `MultiBlocProvider` 接線

**Files:**
- Create: `lib/views/settings_screen.dart`
- Modify: `lib/main.dart`（整檔取代）
- Test: `test/settings_screen_test.dart`、`test/widget_test.dart`（只加 mock，斷言 Task 14 才改）

**Interfaces:**
- Consumes: `SettingsCubit`（Task 4）
- Produces:
  - `class SettingsScreen extends StatefulWidget`（`const SettingsScreen({super.key})`）
  - 頂層純函式 `Decimal? parseTaxRate(String raw)`（非法回 `null`）
  - 穩定 widget key：`Key('taxRateField')`、`Key('groupingSwitch')`
  - `main.dart` 的 `JackCalculator` 改用 `MultiBlocProvider`（`SettingsCubit` + `CalculatorCubit`）

> 設定頁此段先「存在且可測」，`⚙` 導覽鍵在 C 段（Task 15）才接上主鍵盤。

- [ ] **Step 1: 寫失敗測試 `test/settings_screen_test.dart`**

```dart
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/bloc/settings_cubit.dart';
import 'package:jack_calculator/data/settings_repository.dart';
import 'package:jack_calculator/engine/calc_settings.dart';
import 'package:jack_calculator/views/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('parseTaxRate 只接受 0–100、最多一位小數', () {
    expect(parseTaxRate('5'), Decimal.fromInt(5));
    expect(parseTaxRate(' 7.5 '), Decimal.parse('7.5'));
    expect(parseTaxRate('5.'), Decimal.fromInt(5));
    expect(parseTaxRate(''), isNull);
    expect(parseTaxRate('abc'), isNull);
    expect(parseTaxRate('-1'), isNull);
    expect(parseTaxRate('101'), isNull);
    expect(parseTaxRate('5.25'), isNull);
  });

  testWidgets('切換捨入模式與千分位會寫回 Cubit 並持久化', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final cubit = SettingsCubit(const SettingsRepository());
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.tap(find.text('CUT'));
    await tester.pump();
    expect(cubit.state.rounding, RoundingMode.cut);

    await tester.tap(find.byKey(const Key('groupingSwitch')));
    await tester.pump();
    expect(cubit.state.grouping, false);

    await pumpEventQueue();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(SettingsRepository.roundingKey), RoundingMode.cut.code);
    expect(prefs.getBool(SettingsRepository.groupingKey), false);
  });

  testWidgets('合法稅率即時生效、非法稅率顯示錯誤且不寫入 state', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final cubit = SettingsCubit(const SettingsRepository());
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.enterText(find.byKey(const Key('taxRateField')), '7.5');
    await tester.pump();
    expect(cubit.state.taxRate, Decimal.parse('7.5'));

    await tester.enterText(find.byKey(const Key('taxRateField')), '150');
    await tester.pump();
    expect(cubit.state.taxRate, Decimal.parse('7.5')); // 未被寫入
    expect(find.text('請輸入 0–100、最多一位小數'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 執行測試確認失敗**

Run: `flutter test test/settings_screen_test.dart`
Expected: FAIL —— `Target of URI doesn't exist: 'package:jack_calculator/views/settings_screen.dart'`

- [ ] **Step 3: 建立 `lib/views/settings_screen.dart`**

```dart
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/settings_cubit.dart';
import '../engine/calc_settings.dart';

/// 稅率輸入驗證：只接受 0–100、最多一位小數；非法回 null。
Decimal? parseTaxRate(String raw) {
  var text = raw.trim();
  if (text.endsWith('.')) text = text.substring(0, text.length - 1);
  if (text.isEmpty) return null;
  final parsed = Decimal.tryParse(text);
  if (parsed == null) return null;
  if (parsed < Decimal.zero || parsed > Decimal.fromInt(100)) return null;
  if (parsed.scale > 1) return null;
  return parsed;
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _taxController;
  String? _taxError;

  @override
  void initState() {
    super.initState();
    _taxController = TextEditingController(
      text: context.read<SettingsCubit>().state.taxRate.toString(),
    );
  }

  @override
  void dispose() {
    _taxController.dispose();
    super.dispose();
  }

  void _onTaxChanged(SettingsCubit cubit, String value) {
    final parsed = parseTaxRate(value);
    if (parsed == null) {
      setState(() => _taxError = '請輸入 0–100、最多一位小數');
      return;
    }
    setState(() => _taxError = null);
    cubit.setTaxRate(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: BlocBuilder<SettingsCubit, CalcSettings>(
        builder: (context, settings) {
          final isFloat = settings.rounding == RoundingMode.float;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('稅率 (%)'),
              TextField(
                key: const Key('taxRateField'),
                controller: _taxController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) => _onTaxChanged(cubit, value),
                decoration: InputDecoration(
                  errorText: _taxError,
                  helperText: '範圍 0–100，最多一位小數',
                ),
              ),
              const SizedBox(height: 24),
              const Text('捨入模式'),
              const SizedBox(height: 8),
              SegmentedButton<RoundingMode>(
                segments: const [
                  ButtonSegment(value: RoundingMode.float, label: Text('F')),
                  ButtonSegment(value: RoundingMode.cut, label: Text('CUT')),
                  ButtonSegment(value: RoundingMode.up, label: Text('UP')),
                  ButtonSegment(value: RoundingMode.halfUp, label: Text('5/4')),
                ],
                selected: {settings.rounding},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    cubit.setRounding(selection.first),
              ),
              const SizedBox(height: 24),
              Text(isFloat ? '小數位（F 模式下無效）' : '小數位'),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('0')),
                  ButtonSegment(value: 2, label: Text('2')),
                  ButtonSegment(value: 3, label: Text('3')),
                  ButtonSegment(value: 4, label: Text('4')),
                ],
                selected: {settings.decimalPlaces},
                showSelectedIcon: false,
                onSelectionChanged: isFloat
                    ? null
                    : (selection) => cubit.setDecimalPlaces(selection.first),
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                key: const Key('groupingSwitch'),
                title: const Text('千分位'),
                value: settings.grouping,
                onChanged: cubit.setGrouping,
              ),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: 取代 `lib/main.dart` 全檔**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/calculator_cubit.dart';
import 'bloc/settings_cubit.dart';
import 'core/theme.dart';
import 'data/settings_repository.dart';
import 'views/calculator_screen.dart';

void main() => runApp(const JackCalculator());

class JackCalculator extends StatelessWidget {
  const JackCalculator({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SettingsCubit(const SettingsRepository())),
        BlocProvider(create: (_) => CalculatorCubit()),
      ],
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

- [ ] **Step 5: 讓既有 widget 測試在「有 SettingsCubit 的 App」下可跑**

`test/widget_test.dart` 改為（**斷言仍是 Phase 1 的 `'5'`，Task 14 才改成 `'5.00'`**）：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('computes 2 + 3 = 5', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

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

- [ ] **Step 6: 執行全部測試確認通過**

Run: `flutter test`
Expected: `All tests passed!`（18 + 6 + 6 + 4 + 3 = 37 條）

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/views/settings_screen.dart lib/main.dart test/settings_screen_test.dart test/widget_test.dart
git commit -m "feat(ui): add SettingsScreen and wire SettingsCubit via MultiBlocProvider"
```

---

## B 段｜引擎語意（TDD，全 Phase 風險集中處）

### Task 6: 注入設定 + 非除法路徑的四模式捨入

**Files:**
- Modify: `lib/engine/calculator_engine.dart`
- Create: `test/engine_tools.dart`
- Test: `test/rounding_test.dart`

**Interfaces:**
- Consumes: `CalcSettings`／`RoundingMode`（Task 2）
- Produces:
  - `CalculatorEngine()` 預設 `CalcSettings.raw`
  - `void applySettings(CalcSettings settings)`
  - private `Decimal _applyRounding(Decimal d)`（`F` 原樣；`CUT`=`truncate(scale:)`；`5/4`=`round(scale:)`；`UP`=`d.sign < 0 ? -(-d).ceil(scale: n) : d.ceil(scale: n)`）
  - `+`／`−`／`×` 的結果在 `_compute()` 內經 `_applyRounding`；**除法不走這裡**（Task 7）
  - 測試工具 `test/engine_tools.dart`：`engineWith(...)`／`enter(...)`／`compute(...)`

- [ ] **Step 1: 建立共用測試工具 `test/engine_tools.dart`**

```dart
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
```

- [ ] **Step 2: 寫失敗測試 `test/rounding_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/engine/calc_settings.dart';
import 'package:jack_calculator/engine/calculator_engine.dart';

import 'engine_tools.dart';

void main() {
  group('非除法路徑的捨入', () {
    test('F 不捨入：1.234 × 1 保持 1.234', () {
      expect(compute('1.234', CalcOp.multiply, '1', rounding: RoundingMode.float),
          '1.234');
    });

    test('CUT 向零截斷：1.234 × 1 @2 → 1.23', () {
      expect(compute('1.234', CalcOp.multiply, '1', rounding: RoundingMode.cut),
          '1.23');
    });

    test('UP 向遠離零進位：1.234 × 1 @2 → 1.24', () {
      expect(compute('1.234', CalcOp.multiply, '1', rounding: RoundingMode.up),
          '1.24');
    });

    test('5/4：1.234 → 1.23、1.235 → 1.24（half away from zero）', () {
      expect(compute('1.234', CalcOp.multiply, '1', rounding: RoundingMode.halfUp),
          '1.23');
      expect(compute('1.235', CalcOp.multiply, '1', rounding: RoundingMode.halfUp),
          '1.24');
    });

    test('負值方向：-1.239 @2 → CUT -1.23、UP -1.24、5/4 -1.24', () {
      for (final (mode, expected) in [
        (RoundingMode.cut, '-1.23'),
        (RoundingMode.up, '-1.24'),
        (RoundingMode.halfUp, '-1.24'),
      ]) {
        final engine = engineWith(mode, 2);
        enter(engine, '1.239');
        engine.toggleSign();
        engine.applyOperator(CalcOp.multiply);
        enter(engine, '1');
        engine.equals();
        expect(engine.display, expected, reason: '$mode');
      }
    });

    test('加減也走同一條捨入：0.005 + 0 @2 → CUT 0、UP 0.01、5/4 0.01', () {
      expect(compute('0.005', CalcOp.add, '0', rounding: RoundingMode.cut), '0');
      expect(compute('0.005', CalcOp.add, '0', rounding: RoundingMode.up), '0.01');
      expect(
        compute('0.005', CalcOp.add, '0', rounding: RoundingMode.halfUp),
        '0.01',
      );
    });

    test('小數位 0／3／4 各一（CUT）', () {
      expect(
        compute('1.239', CalcOp.multiply, '1',
            rounding: RoundingMode.cut, decimalPlaces: 0),
        '1',
      );
      expect(
        compute('1.2395', CalcOp.multiply, '1',
            rounding: RoundingMode.cut, decimalPlaces: 3),
        '1.239',
      );
      expect(
        compute('1.2395', CalcOp.multiply, '1',
            rounding: RoundingMode.cut, decimalPlaces: 4),
        '1.2395',
      );
    });

    test('鏈捨入：每一步的出口就是捨入後的值', () {
      final engine = engineWith(RoundingMode.cut, 2);
      enter(engine, '1.234');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '1');
      engine.equals(); // 1.234 → 1.23
      expect(engine.display, '1.23');
      engine.applyOperator(CalcOp.add);
      enter(engine, '0.005');
      engine.equals(); // 1.23 + 0.005 = 1.235 → 1.23（上一筆已是 1.23，不是 1.234）
      expect(engine.display, '1.23');
    });

    test('engine 預設是 raw：Phase 1 語意不受影響', () {
      final engine = CalculatorEngine();
      enter(engine, '1.234');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '1');
      engine.equals();
      expect(engine.display, '1.234');
    });
  });
}
```

- [ ] **Step 3: 執行測試確認失敗**

Run: `flutter test test/rounding_test.dart`
Expected: FAIL —— `The method 'applySettings' isn't defined for the type 'CalculatorEngine'`

- [ ] **Step 4: 修改 `lib/engine/calculator_engine.dart`**

4a. 檔頭加 import：

```dart
import 'package:decimal/decimal.dart';

import 'calc_settings.dart';
```

4b. 自 `class CalculatorEngine {` 起、到 `bool _hasError = false;`（含）為止整段取代為（`_divisionScale` 改名 `_floatDivisionScale`；新增 `_settings`；其餘既有欄位與建構子不動）：

```dart
class CalculatorEngine {
  static const int _maxDigits = 16;

  /// 只在 [RoundingMode.float] 模式使用的除法截斷位（Phase 1 行為）。
  static const int _floatDivisionScale = 10;

  CalcSettings _settings = CalcSettings.raw;

  Decimal _accumulator = Decimal.zero;
  CalcOp? _pendingOp;
  String _entry = '0';
  bool _startNewEntry = true;
  bool _hasError = false;

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
```

> `_divisionScale` 改名為 `_floatDivisionScale`；Task 7 會把 `_divide` 內對它的引用一併更新。

4c. `_compute()`（原 line 77-95）整塊取代為：

```dart
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
```

4d. 為了讓 Task 6 能編譯，`_divide` 暫時改成使用新常數名（Task 7 會整塊重寫）：

```dart
  static Decimal _divide(Decimal a, Decimal b) {
    final shifted = a.shift(_floatDivisionScale);
    final quotient = shifted ~/ b; // BigInt，截斷除法
    return Decimal.fromBigInt(quotient).shift(-_floatDivisionScale);
  }
```

- [ ] **Step 5: 執行測試確認通過**

Run: `flutter test test/rounding_test.dart`
Expected: `All tests passed!`（9 條）

Run: `flutter test`
Expected: `All tests passed!`（Phase 1 的 18 條＋A 段 19 條＋本段 9 條＝46 條）

- [ ] **Step 6: Commit**

```bash
git add lib/engine/calculator_engine.dart test/engine_tools.dart test/rounding_test.dart
git commit -m "feat(engine): inject CalcSettings and add four-mode rounding for +-x"
```

---

### Task 7: 餘數法除法（單次捨入）

**Files:**
- Modify: `lib/engine/calculator_engine.dart`（只改 `_divide`）
- Test: `test/division_test.dart`

**Interfaces:**
- Consumes: Task 6 的 `_settings`、`_floatDivisionScale`、`_two`
- Produces:
  - `Decimal _divide(Decimal a, Decimal b)`（**改為 instance method**）：`F` 走截斷 10 位；其餘模式「除到 `effectiveDecimalPlaces` 位並用真實餘數決定進位」
  - 進位方向由 `a.sign * b.sign < 0` 決定（**不可**看商，`q = 0` 時會失去符號）

- [ ] **Step 1: 寫失敗測試 `test/division_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/engine/calc_settings.dart';
import 'package:jack_calculator/engine/calculator_engine.dart';

import 'engine_tools.dart';

void main() {
  group('餘數法除法：單次捨入', () {
    test('UP 不被截斷抹掉餘數（本專案的回歸照妖鏡）', () {
      // 真實商 5.000000000001；先截到 10 位會變成恰好 5，UP 会誤判成整數。
      expect(
        compute('5000000000001', CalcOp.divide, '1000000000000',
            rounding: RoundingMode.up, decimalPlaces: 2),
        '5.01',
      );
      expect(
        compute('5000000000001', CalcOp.divide, '1000000000000',
            rounding: RoundingMode.cut, decimalPlaces: 2),
        '5',
      );
      expect(
        compute('5000000000001', CalcOp.divide, '1000000000000',
            rounding: RoundingMode.halfUp, decimalPlaces: 2),
        '5',
      );
    });

    test('1 ÷ 3 @2：CUT 0.33、UP 0.34、5/4 0.33', () {
      expect(compute('1', CalcOp.divide, '3', rounding: RoundingMode.cut), '0.33');
      expect(compute('1', CalcOp.divide, '3', rounding: RoundingMode.up), '0.34');
      expect(
        compute('1', CalcOp.divide, '3', rounding: RoundingMode.halfUp),
        '0.33',
      );
    });

    test('2 ÷ 3 @2 × 四模式：CUT 0.66、UP 0.67、5/4 0.67、F 截斷 10 位', () {
      expect(compute('2', CalcOp.divide, '3', rounding: RoundingMode.cut), '0.66');
      expect(compute('2', CalcOp.divide, '3', rounding: RoundingMode.up), '0.67');
      expect(
        compute('2', CalcOp.divide, '3', rounding: RoundingMode.halfUp),
        '0.67',
      );
      expect(
        compute('2', CalcOp.divide, '3', rounding: RoundingMode.float),
        '0.6666666666',
      );
    });

    test('負方向由運算元符號決定：-1 ÷ 3 @0 UP → -1', () {
      final engine = engineWith(RoundingMode.up, 0);
      enter(engine, '1');
      engine.toggleSign();
      engine.applyOperator(CalcOp.divide);
      enter(engine, '3');
      engine.equals();
      expect(engine.display, '-1');
    });

    test('-1 ÷ 3 @2：CUT -0.33、UP -0.34', () {
      for (final (mode, expected) in [
        (RoundingMode.cut, '-0.33'),
        (RoundingMode.up, '-0.34'),
      ]) {
        final engine = engineWith(mode, 2);
        enter(engine, '1');
        engine.toggleSign();
        engine.applyOperator(CalcOp.divide);
        enter(engine, '3');
        engine.equals();
        expect(engine.display, expected, reason: '$mode');
      }
    });

    test('從含稅價反推也是同一條路：2100 ÷ 1.05 @2 5/4 → 2000', () {
      expect(
        compute('2100', CalcOp.divide, '1.05', rounding: RoundingMode.halfUp),
        '2000',
      );
    });

    test('F 模式維持 Phase 1 的截斷 10 位', () {
      expect(compute('1', CalcOp.divide, '3', rounding: RoundingMode.float),
          '0.3333333333');
    });

    test('除零仍走 hasError', () {
      final engine = engineWith(RoundingMode.halfUp, 2);
      enter(engine, '5');
      engine.applyOperator(CalcOp.divide);
      enter(engine, '0');
      engine.equals();
      expect(engine.hasError, true);
      expect(engine.display, 'Error');
    });
  });
}
```

- [ ] **Step 2: 執行測試確認失敗**

Run: `flutter test test/division_test.dart`
Expected: FAIL —— 捨入相關條目全掛（照妖鏡的 UP 得到 `5` 而非 `5.01`；`1 ÷ 3` 得到 `0.3333333333` 而非 `0.33`）。**會過的只有三條**：F 模式、`2100 ÷ 1.05`（本身整除）、除零。**這是預期中的紅燈**：它證明現行 `_divide` 只截斷、完全沒套用捨入。

- [ ] **Step 3: 整塊取代 `_divide`**

先在欄位區（`_floatDivisionScale` 之下）加一行（Task 6 刻意不放，避免尚未使用先觸發 `unused_field`）：

```dart
  static final Decimal _two = Decimal.fromInt(2);
```

再整塊取代 `_divide`：

```dart
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
```

- [ ] **Step 4: 執行測試確認通過**

Run: `flutter test test/division_test.dart`
Expected: `All tests passed!`（8 條）

Run: `flutter test`
Expected: `All tests passed!`（54 條）

- [ ] **Step 5: Commit**

```bash
git add lib/engine/calculator_engine.dart test/division_test.dart
git commit -m "feat(engine): remainder-based division for single-pass rounding"
```

---

### Task 8: GT 總計

**Files:**
- Modify: `lib/engine/calculator_engine.dart`
- Test: `test/grand_total_test.dart`

**Interfaces:**
- Consumes: Task 6／7 的 engine
- Produces:
  - `Decimal _grandTotal`、`Decimal get grandTotal`、`bool get hasGT`（= `_grandTotal != Decimal.zero`）
  - `void showGrandTotal()`：把總和帶進 `_entry`、`_startNewEntry = true`、**不清空**、`_pendingOp` 不動、錯誤態 no-op
  - `equals()` 成功完成一筆時 `_grandTotal += _accumulator`
  - `allClear()` 清 GT；`clearEntry()` 不清

- [ ] **Step 1: 寫失敗測試 `test/grand_total_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/engine/calc_settings.dart';
import 'package:jack_calculator/engine/calculator_engine.dart';

import 'engine_tools.dart';

void main() {
  group('GT 真值表', () {
    test('每按一次 = 累加一筆', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '1');
      engine.applyOperator(CalcOp.add);
      enter(engine, '2');
      engine.equals(); // 顯示 3，GT = 3
      engine.applyOperator(CalcOp.add);
      enter(engine, '4');
      engine.applyOperator(CalcOp.add); // 立即執行：3 + 4 = 7（不進 GT）
      enter(engine, '5');
      engine.equals(); // 顯示 12，GT = 3 + 12 = 15
      expect(engine.grandTotal.toString(), '15');
      expect(engine.hasGT, true);
    });

    test('立即執行的中間值不進 GT', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '2');
      engine.applyOperator(CalcOp.add);
      enter(engine, '3');
      engine.applyOperator(CalcOp.multiply); // 中間值 5 不進 GT
      enter(engine, '4');
      engine.equals(); // 20
      expect(engine.grandTotal.toString(), '20');
    });

    test('GT 鍵把總和帶入顯示，且不清空（可重複引用）', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '7');
      engine.applyOperator(CalcOp.add);
      enter(engine, '8');
      engine.equals(); // 15
      engine.showGrandTotal();
      expect(engine.display, '15');
      engine.showGrandTotal();
      expect(engine.display, '15'); // 再按一次仍是同一總和
      expect(engine.grandTotal.toString(), '15');
    });

    test('AC 清 GT', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '7');
      engine.applyOperator(CalcOp.add);
      enter(engine, '8');
      engine.equals();
      engine.allClear();
      expect(engine.hasGT, false);
      expect(engine.grandTotal.toString(), '0');
    });

    test('C（clearEntry）不清 GT', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '7');
      engine.applyOperator(CalcOp.add);
      enter(engine, '8');
      engine.equals(); // GT = 15
      engine.clearEntry();
      expect(engine.hasGT, true);
      expect(engine.grandTotal.toString(), '15');
    });

    test('重複按 = 不重複累加', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '5');
      engine.applyOperator(CalcOp.add);
      enter(engine, '5');
      engine.equals(); // 10
      engine.equals();
      engine.equals();
      expect(engine.grandTotal.toString(), '10');
    });

    test('錯誤態不進 GT', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '5');
      engine.applyOperator(CalcOp.divide);
      enter(engine, '0');
      engine.equals(); // Error
      expect(engine.hasGT, false);
    });

    test('總和為 0 時 hasGT 為 false（刻意的定義，不是 bug）', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '5');
      engine.applyOperator(CalcOp.subtract);
      enter(engine, '5');
      engine.equals(); // 0
      expect(engine.hasGT, false);
      expect(engine.grandTotal.toString(), '0');
    });
  });
}
```

- [ ] **Step 2: 執行測試確認失敗**

Run: `flutter test test/grand_total_test.dart`
Expected: FAIL —— `The getter 'grandTotal' isn't defined for the type 'CalculatorEngine'`

- [ ] **Step 3: 修改 `lib/engine/calculator_engine.dart`**

3a. 欄位區在 `bool _hasError = false;` 之後加：

```dart
  Decimal _grandTotal = Decimal.zero;
```

3b. 在 `bool get hasError => _hasError;` 之後加：

```dart
  /// GT 總計（`=` 完成一筆時累加）。
  Decimal get grandTotal => _grandTotal;

  /// 定義是「總和不為 0」，不是「本 session 用過 GT」。
  /// 副作用：一筆 `X = 0` 進 GT 後總和仍是 0，indicator 不會亮 —— 刻意如此。
  bool get hasGT => _grandTotal != Decimal.zero;
```

3c. `equals()` 內在 `_compute()` 成功之後累加：

```dart
  void equals() {
    if (_hasError || _pendingOp == null) return;
    if (!_compute()) return;
    _grandTotal += _accumulator;
    _pendingOp = null;
    _startNewEntry = true;
    _entry = _clean(_accumulator);
  }
```

3d. 新增 `showGrandTotal()`（放在 `equals()` 之後）：

```dart
  void showGrandTotal() {
    if (_hasError) return;
    _entry = _clean(_grandTotal);
    _startNewEntry = true;
  }
```

3e. `allClear()` 加一行 `_grandTotal = Decimal.zero;`（放在 `_hasError = false;` 之前）。

- [ ] **Step 4: 執行測試確認通過**

Run: `flutter test test/grand_total_test.dart`
Expected: `All tests passed!`（8 條）

Run: `flutter test`
Expected: `All tests passed!`（62 條）

- [ ] **Step 5: Commit**

```bash
git add lib/engine/calculator_engine.dart test/grand_total_test.dart
git commit -m "feat(engine): add GT accumulation on equals with AC/C semantics"
```

---

### Task 9: Tax+ / Tax−

**Files:**
- Modify: `lib/engine/calculator_engine.dart`
- Test: `test/tax_test.dart`

**Interfaces:**
- Consumes: `_settings.taxRate`、`_applyRounding`、`_divide`、`_entryValue`
- Produces:
  - `void taxPlus()`：`entry × (1 + t/100)`，經 `_applyRounding` 一次落地
  - `void taxMinus()`：`entry ÷ (1 + t/100)`，走 `_divide`（餘數法一次到位）
  - 兩者**只改 `_entry`**（＋`_startNewEntry = true`），**不動 `_accumulator`／`_pendingOp`**，也不寫 GT
  - 分母為 0（`t = −100`）→ `hasError`；錯誤態 no-op

- [ ] **Step 1: 寫失敗測試 `test/tax_test.dart`**

```dart
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/engine/calc_settings.dart';
import 'package:jack_calculator/engine/calculator_engine.dart';

import 'engine_tools.dart';

void main() {
  group('Tax', () {
    test('Tax+：1000 → 1050（t=5%）', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '1000');
      engine.taxPlus();
      expect(engine.display, '1050');
    });

    test('Tax−：2100 → 2000（反推未稅，不是 1995）', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '2100');
      engine.taxMinus();
      expect(engine.display, '2000');
    });

    test('Tax+ 與 Tax− 互為反函數：1000 → 1050 → 1000', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '1000');
      engine.taxPlus();
      expect(engine.display, '1050');
      engine.taxMinus();
      expect(engine.display, '1000');
    });

    test('小數稅率：t=8.5、100 → 108.5', () {
      final engine = engineWith(RoundingMode.float, 2, taxRate: Decimal.parse('8.5'));
      enter(engine, '100');
      engine.taxPlus();
      expect(engine.display, '108.5');
    });

    test('t=0 時 Tax+ 不改變值', () {
      final engine = engineWith(RoundingMode.float, 2, taxRate: Decimal.zero);
      enter(engine, '100');
      engine.taxPlus();
      expect(engine.display, '100');
    });

    test('作用對象是 entry，不是 accumulator：5 + 3 Tax+ = → 8.15', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '5');
      engine.applyOperator(CalcOp.add);
      enter(engine, '3');
      engine.taxPlus(); // 只有 3 被含稅
      engine.equals();
      expect(engine.display, '8.15');
    });

    test('5/4·2 位時 Tax+ 的出口套用一次捨入', () {
      final engine = engineWith(RoundingMode.halfUp, 2);
      enter(engine, '1000');
      engine.taxPlus(); // 1050.00 → 1050
      expect(engine.display, '1050');
    });

    test('錯誤態下 Tax 為 no-op', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '5');
      engine.applyOperator(CalcOp.divide);
      enter(engine, '0');
      engine.equals(); // Error
      engine.taxPlus();
      expect(engine.display, 'Error');
      expect(engine.hasError, true);
    });

    test('t 超出設定範圍（-100）時 Tax− 報錯，防呆', () {
      final engine = engineWith(RoundingMode.float, 2, taxRate: Decimal.fromInt(-100));
      enter(engine, '100');
      engine.taxMinus();
      expect(engine.hasError, true);
    });
  });
}
```

- [ ] **Step 2: 執行測試確認失敗**

Run: `flutter test test/tax_test.dart`
Expected: FAIL —— `The method 'taxPlus' isn't defined for the type 'CalculatorEngine'`

- [ ] **Step 3: 修改 `lib/engine/calculator_engine.dart`**

在 `showGrandTotal()` 之後新增：

```dart
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
```

- [ ] **Step 4: 執行測試確認通過**

Run: `flutter test test/tax_test.dart`
Expected: `All tests passed!`（9 條）

Run: `flutter test`
Expected: `All tests passed!`（71 條）

- [ ] **Step 5: Commit**

```bash
git add lib/engine/calculator_engine.dart test/tax_test.dart
git commit -m "feat(engine): add Tax+ and reverse-derived Tax- keys"
```

---

### Task 10: MU（Casio 二元按鍵）

**Files:**
- Modify: `lib/engine/calculator_engine.dart`
- Test: `test/mu_test.dart`

**Interfaces:**
- Consumes: `_divide`、`_applyRounding`、`_accumulator`、`_pendingOp`
- Produces:
  - `Decimal? _muCost` 欄位（成本暫存；`allClear()` 清為 `null`）
  - `void mu()`：第一次（`_pendingOp == multiply` 且 `_muCost == null`）算售價 `成本 ÷ (1 − 利潤率/100)`，並把 `_accumulator = 售價`、`_pendingOp = null`、`_muCost = 成本`；第二次（`_muCost != null`）顯示利潤額 `售價 − 成本` 並清 `_muCost`
  - `_pendingOp != multiply` 且 `_muCost == null` → no-op；分母 0 → `hasError`；錯誤態 no-op

- [ ] **Step 1: 寫失敗測試 `test/mu_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/engine/calc_settings.dart';
import 'package:jack_calculator/engine/calculator_engine.dart';

import 'engine_tools.dart';

void main() {
  group('MU', () {
    test('100 × 20 MU → 售價 125', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '100');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '20');
      engine.mu();
      expect(engine.display, '125');
    });

    test('再按一次 MU → 利潤額 25', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '100');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '20');
      engine.mu();
      engine.mu();
      expect(engine.display, '25');
    });

    test('第三次 MU（成本已清、pendingOp 已清）→ no-op', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '100');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '20');
      engine.mu(); // 125
      engine.mu(); // 25
      engine.mu(); // no-op
      expect(engine.display, '25');
    });

    test('MU 吃掉 pendingOp：售價不會被後續 = 再乘一次', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '100');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '20');
      engine.mu();
      engine.equals(); // pendingOp 已清 → no-op
      expect(engine.display, '125');
    });

    test('MU 不進 GT', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '100');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '20');
      engine.mu();
      engine.equals();
      expect(engine.hasGT, false);
    });

    test('100 + 20 MU（pendingOp 非 multiply）→ no-op', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '100');
      engine.applyOperator(CalcOp.add);
      enter(engine, '20');
      engine.mu();
      expect(engine.display, '20');
      expect(engine.hasError, false);
    });

    test('利潤率 100% → 除零 Error', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '100');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '100');
      engine.mu();
      expect(engine.hasError, true);
    });

    test('利潤率 > 100% → 負售價（不攔截）', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '100');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '120');
      engine.mu();
      expect(engine.display, '-500');
    });

    test('5/4·2 位時售價套用一次捨入：100 × 33 MU → 149.25', () {
      final engine = engineWith(RoundingMode.halfUp, 2);
      enter(engine, '100');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '33');
      engine.mu();
      expect(engine.display, '149.25');
    });

    test('AC 清掉 _muCost：下一筆不會沿用上一筆成本', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '100');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '20');
      engine.mu(); // 125
      engine.allClear();
      enter(engine, '3');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '4');
      engine.mu(); // 3 ÷ 0.96 = 3.125
      expect(engine.display, '3.125');
    });
  });
}
```

- [ ] **Step 2: 執行測試確認失敗**

Run: `flutter test test/mu_test.dart`
Expected: FAIL —— `The method 'mu' isn't defined for the type 'CalculatorEngine'`

- [ ] **Step 3: 修改 `lib/engine/calculator_engine.dart`**

3a. 欄位區加（在 `Decimal _grandTotal = Decimal.zero;` 之後）：

```dart
  Decimal? _muCost;
```

3b. 在 `_setEntryResult` 之後新增：

```dart
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
```

3c. `allClear()` 內加 `_muCost = null;`。

- [ ] **Step 4: 執行測試確認通過**

Run: `flutter test test/mu_test.dart`
Expected: `All tests passed!`（10 條）

Run: `flutter test`
Expected: `All tests passed!`（81 條）

- [ ] **Step 5: Commit**

```bash
git add lib/engine/calculator_engine.dart test/mu_test.dart
git commit -m "feat(engine): add Casio-style MU key with cost memo and pendingOp consumption"
```

---

### Task 11: `±` 修正 + 引擎邊界測試

**Files:**
- Modify: `lib/engine/calculator_engine.dart`
- Test: `test/sign_and_bounds_test.dart`、`test/calculator_engine_test.dart`（追加一組邊界測試）

**Interfaces:**
- Consumes: 既有 entry 狀態機
- Produces:
  - `bool _pendingSign`：`_startNewEntry == true` 時按 `±` 只翻這個旗標，讓「下一個輸入的數字」帶負號
  - `toggleSign()` **永不回溯 `_accumulator`**
  - `inputDigit`／`inputDecimalPoint` 在 `_startNewEntry` 分支消費 `_pendingSign`；`applyOperator`／`equals`／`allClear`／`clearEntry` 將它歸零
  - 不變項：`_entry = _clean(_accumulator)` 的 echo 保持不動，`5 + =` → `10`

- [ ] **Step 1: 寫失敗測試 `test/sign_and_bounds_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/engine/calc_settings.dart';
import 'package:jack_calculator/engine/calculator_engine.dart';

import 'engine_tools.dart';

void main() {
  group('± 真值表', () {
    test('5 + ± 3 = → 2（只作用於 entry，不回溯 accumulator）', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '5');
      engine.applyOperator(CalcOp.add);
      engine.toggleSign();
      enter(engine, '3');
      expect(engine.display, '-3');
      engine.equals();
      expect(engine.display, '2');
    });

    test('5 + = → 10（echo 不變項，改 ± 不得弄壞）', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '5');
      engine.applyOperator(CalcOp.add);
      engine.equals();
      expect(engine.display, '10');
    });

    test('5 ± = → -5', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '5');
      engine.toggleSign();
      expect(engine.display, '-5');
      engine.equals(); // pendingOp 為 null → no-op
      expect(engine.display, '-5');
    });

    test('± 兩次回到正號', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '5');
      engine.toggleSign();
      engine.toggleSign();
      expect(engine.display, '5');
    });

    test('空 entry 上按 ±：顯示不變，下一個輸入的數字帶負號', () {
      final engine = engineWith(RoundingMode.float, 2);
      // spec D9：_startNewEntry 時 ± 只翻 _pendingSign，不改顯示。
      engine.toggleSign();
      expect(engine.display, '0');
      enter(engine, '7');
      expect(engine.display, '-7');
    });

    test('pendingSign 不跨運算子洩漏：± + 3 = → 0 + 3 = 3', () {
      final engine = engineWith(RoundingMode.float, 2);
      engine.toggleSign(); // 空 entry 上按，_pendingSign 翻 true
      engine.applyOperator(CalcOp.add);
      enter(engine, '3');
      engine.equals();
      expect(engine.display, '3');
    });

    test('± 之後打小數點：-0.5', () {
      final engine = engineWith(RoundingMode.float, 2);
      engine.applyOperator(CalcOp.add); // 讓 _startNewEntry = true
      engine.toggleSign();
      engine.inputDecimalPoint();
      engine.inputDigit('5');
      expect(engine.display, '-0.5');
    });
  });

  group('引擎邊界（Phase 1 延後項 #3）', () {
    test('輸入上限 16 位，第 17 位被忽略', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '1234567890123456'); // 16 位
      expect(engine.display, '1234567890123456');
      engine.inputDigit('7');
      expect(engine.display, '1234567890123456');
    });

    test('負值退格：-5 退成 0', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '5');
      engine.toggleSign();
      engine.backspace();
      expect(engine.display, '0');
    });

    test('尾點退格：1. 退成 1', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '1');
      engine.inputDecimalPoint();
      expect(engine.display, '1.');
      engine.backspace();
      expect(engine.display, '1');
    });

    test('運算子重按：2 + + 3 = → 5', () {
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '2');
      engine.applyOperator(CalcOp.add);
      engine.applyOperator(CalcOp.add); // 重按，2 被重新當成左運算元
      enter(engine, '3');
      engine.equals();
      expect(engine.display, '5');
    });

    test('5 + 3 × 4 = → 20（立即執行不變項）', () {
      expect(
        compute('5', CalcOp.add, '3', rounding: RoundingMode.float),
        '8',
      );
      final engine = engineWith(RoundingMode.float, 2);
      enter(engine, '2');
      engine.applyOperator(CalcOp.add);
      enter(engine, '3');
      engine.applyOperator(CalcOp.multiply);
      enter(engine, '4');
      engine.equals();
      expect(engine.display, '20');
    });

    test('trunc-vs-round：CUT 不進位、UP 一定進位', () {
      expect(compute('0.001', CalcOp.multiply, '1', rounding: RoundingMode.cut), '0');
      expect(compute('0.001', CalcOp.multiply, '1', rounding: RoundingMode.up), '0.01');
    });
  });
}
```

- [ ] **Step 2: 執行測試確認失敗**

Run: `flutter test test/sign_and_bounds_test.dart`
Expected: FAIL —— `5 + ± 3 =` 得到 `-2`（舊行為回溯了 accumulator）；`空 entry 上按 ±` 的 `-7` 得到 `7`；`± 之後打小數點` 得到 `0.5`。其餘邊界測試應已通過。

- [ ] **Step 3: 修改 `lib/engine/calculator_engine.dart`**

3a. 欄位區加 `bool _pendingSign = false;`（放在 `bool _startNewEntry = true;` 之後）。

3b. `inputDigit` 的 `_startNewEntry` 分支：

```dart
    if (_startNewEntry) {
      _entry = _pendingSign ? '-$digit' : digit;
      _pendingSign = false;
      _startNewEntry = false;
    } else {
```

3c. `inputDecimalPoint` 的 `_startNewEntry` 分支：

```dart
    if (_startNewEntry) {
      _entry = _pendingSign ? '-0.' : '0.';
      _pendingSign = false;
      _startNewEntry = false;
    } else if (!_entry.contains('.')) {
```

3d. `toggleSign()` 整塊取代：

```dart
  /// ± 只作用於 entry，永不回溯 accumulator。
  void toggleSign() {
    if (_hasError) return;
    if (_startNewEntry) {
      _pendingSign = !_pendingSign; // 套用給下一個被輸入的數字
      return;
    }
    if (_entry == '0' || _entry == '0.') return;
    _entry = _entry.startsWith('-') ? _entry.substring(1) : '-$_entry';
  }
```

3e. 下列三處各加 `_pendingSign = false;`（符號只存活到「下一個被輸入的數字」）：`_setEntryResult()`（Task 9 已把 `applyOperator`／`equals`／`showGrandTotal` 的結果寫入收斂進這裡；`taxPlus`／`taxMinus` 也經由它，放這裡即涵蓋所有這些入口）、`allClear()`、`clearEntry()`。

3f. `backspace()` 不變（`-5` 已由既有 `s.length == 2 && s.startsWith('-')` 處理）。

- [ ] **Step 4: 把邊界測試也追加一組到 `test/calculator_engine_test.dart`**

在檔案末尾的 `group('clear & error', ...)` 之後追加（**不要動 Phase 1 既有的 15 條**）：

```dart
  group('phase 2 regression invariants', () {
    test('1 / 3 still truncates to 10 places under default settings', () {
      final e = CalculatorEngine()
        ..inputDigit('1')
        ..applyOperator(CalcOp.divide)
        ..inputDigit('3')
        ..equals();
      expect(e.display, '0.3333333333');
    });

    test('default engine ignores rounding until settings are applied', () {
      final e = CalculatorEngine()
        ..inputDigit('1')
        ..applyOperator(CalcOp.divide)
        ..inputDigit('8')
        ..equals();
      expect(e.display, '0.125');
    });
  });
```

- [ ] **Step 5: 執行測試確認通過**

Run: `flutter test test/sign_and_bounds_test.dart`
Expected: `All tests passed!`（13 條）

Run: `flutter test`
Expected: `All tests passed!`（96 條）

- [ ] **Step 6: Commit**

```bash
git add lib/engine/calculator_engine.dart test/sign_and_bounds_test.dart test/calculator_engine_test.dart
git commit -m "fix(engine): scope +/- to the entry and add engine boundary tests"
```

---

### Task 12: `CalculatorState` 與 `CalculatorCubit` 橋接

**Files:**
- Modify: `lib/bloc/calculator_state.dart`（整檔取代）
- Modify: `lib/bloc/calculator_cubit.dart`（整檔取代）
- Test: `test/calculator_cubit_test.dart`（追加）

**Interfaces:**
- Consumes: 全部 engine 新 API（Task 6-11）
- Produces:
  - `CalculatorState({required String display, required bool hasError, bool hasGT = false})`＋手寫 `==`／`hashCode`
  - `CalculatorCubit()` 建構時即以 `CalcSettings.defaults` 設定 engine
  - `applySettings(CalcSettings)`／`onGrandTotal()`／`onTaxPlus()`／`onTaxMinus()`／`onMu()`
  - `_sync()` 帶上 `hasGT`

- [ ] **Step 1: 寫失敗測試（追加到 `test/calculator_cubit_test.dart`）**

在 `void main()` 內追加：

```dart
  test('applySettings 後引擎依設定捨入', () {
    final c = CalculatorCubit();
    c.applySettings(CalcSettings(
      taxRate: Decimal.fromInt(5),
      rounding: RoundingMode.halfUp,
      decimalPlaces: 2,
      grouping: false,
    ));
    c.onDigit('1');
    c.applyOperator(CalcOp.divide);
    c.onDigit('3');
    c.equals();
    expect(c.state.display, '0.33');
  });

  test('預設設定（App 用）是 5/4·2 位', () {
    final c = CalculatorCubit();
    c.onDigit('1');
    c.applyOperator(CalcOp.divide);
    c.onDigit('3');
    c.equals();
    expect(c.state.display, '0.33'); // 不是 0.3333333333
  });

  test('onGrandTotal 帶回總和並標記 hasGT', () {
    final c = CalculatorCubit();
    c.onDigit('7');
    c.applyOperator(CalcOp.add);
    c.onDigit('8');
    c.equals();
    expect(c.state.hasGT, true);
    c.onGrandTotal();
    expect(c.state.display, '15');
  });

  test('onTaxPlus 對 entry 含稅', () {
    final c = CalculatorCubit();
    c.onDigit('1');
    c.onDigit('0');
    c.onDigit('0');
    c.onDigit('0');
    c.onTaxPlus();
    expect(c.state.display, '1050');
  });

  test('onMu 產出售價', () {
    final c = CalculatorCubit();
    c.onDigit('1');
    c.onDigit('0');
    c.onDigit('0');
    c.applyOperator(CalcOp.multiply);
    c.onDigit('2');
    c.onDigit('0');
    c.onMu();
    expect(c.state.display, '125');
  });

  test('等價 state 不重複發送（== 生效）', () async {
    final c = CalculatorCubit();
    final seen = <CalculatorState>[];
    final sub = c.stream.listen(seen.add);
    c.onDigit('0'); // state 與初始值等價；但「首次 emit」不受 == 去重（bloc 規則）
    await pumpEventQueue();
    expect(seen.length, 1);
    c.allClear(); // 仍等價 → 這次應被 == 擋下
    await pumpEventQueue();
    expect(seen.length, 1);
    c.onDigit('5'); // 不等價 → 應再送一次
    await pumpEventQueue();
    expect(seen.length, 2);
    await sub.cancel();
  });
```

檔案頂端補 import：

```dart
import 'package:decimal/decimal.dart';
import 'package:jack_calculator/bloc/calculator_state.dart';
import 'package:jack_calculator/engine/calc_settings.dart';
```

- [ ] **Step 2: 執行測試確認失敗**

Run: `flutter test test/calculator_cubit_test.dart`
Expected: FAIL —— `The method 'applySettings' isn't defined for the type 'CalculatorCubit'`；`hasGT` 也不存在。

- [ ] **Step 3: 取代 `lib/bloc/calculator_state.dart` 全檔**

```dart
import 'package:flutter/foundation.dart';

@immutable
class CalculatorState {
  const CalculatorState({
    required this.display,
    required this.hasError,
    this.hasGT = false,
  });

  /// raw 字串：不含逗號、不補零。格式化只發生在 DisplayScreen。
  final String display;
  final bool hasError;
  final bool hasGT;

  @override
  bool operator ==(Object other) =>
      other is CalculatorState &&
      other.display == display &&
      other.hasError == hasError &&
      other.hasGT == hasGT;

  @override
  int get hashCode => Object.hash(display, hasError, hasGT);
}
```

- [ ] **Step 4: 取代 `lib/bloc/calculator_cubit.dart` 全檔**

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../engine/calc_settings.dart';
import '../engine/calculator_engine.dart';
import 'calculator_state.dart';

// 讓 UI 只經由此橋接層取得 CalcOp／CalcSettings，維持「Cubit 是 UI↔engine 唯一橋」的邊界。
export '../engine/calculator_engine.dart' show CalcOp;
export '../engine/calc_settings.dart' show CalcSettings, RoundingMode;

class CalculatorCubit extends Cubit<CalculatorState> {
  CalculatorCubit()
      : super(const CalculatorState(display: '0', hasError: false)) {
    _engine.applySettings(CalcSettings.defaults);
  }

  final CalculatorEngine _engine = CalculatorEngine();

  void _sync() => emit(CalculatorState(
        display: _engine.display,
        hasError: _engine.hasError,
        hasGT: _engine.hasGT,
      ));

  void applySettings(CalcSettings settings) {
    _engine.applySettings(settings);
    _sync();
  }

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

  void onGrandTotal() {
    _engine.showGrandTotal();
    _sync();
  }

  void onTaxPlus() {
    _engine.taxPlus();
    _sync();
  }

  void onTaxMinus() {
    _engine.taxMinus();
    _sync();
  }

  void onMu() {
    _engine.mu();
    _sync();
  }
}
```

- [ ] **Step 5: 執行測試確認通過**

Run: `flutter test test/calculator_cubit_test.dart`
Expected: `All tests passed!`（8 條：原 2 條＋新 6 條）

Run: `flutter test`
Expected: `All tests passed!`（102 條）

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/bloc/calculator_state.dart lib/bloc/calculator_cubit.dart test/calculator_cubit_test.dart
git commit -m "feat(bloc): expose settings, GT, Tax and MU through CalculatorCubit"
```

---

## C 段｜UI

### Task 13: `number_format` 千分位與補零

**Files:**
- Modify: `lib/core/number_format.dart`（整檔取代）
- Test: `test/number_format_test.dart`

**Interfaces:**
- Consumes: `CalcSettings`（Task 2）
- Produces:
  - `String formatForDisplay(String raw, CalcSettings settings)`
  - 契約：`raw == 'Error'` 或空字串原樣返回；`F`（`effectiveDecimalPlaces == null`）不補零；輸入中的尾點（`'12.'`）保留尾點且不補零；負號永遠在最前面；整數段才分組；**永不回傳含逗號的 raw**

- [ ] **Step 1: 寫失敗測試 `test/number_format_test.dart`**

```dart
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
```

- [ ] **Step 2: 執行測試確認失敗**

Run: `flutter test test/number_format_test.dart`
Expected: FAIL —— 參數數量不符（現行簽名是 `formatForDisplay(String raw)`）

- [ ] **Step 3: 取代 `lib/core/number_format.dart` 全檔**

```dart
import '../engine/calc_settings.dart';

/// 顯示層格式化：千分位（國際分位）與固定小數位補零。
///
/// 契約：輸入永遠是 engine 產出的 raw 字串（無逗號、無補零）。
/// `F` 模式不補零；輸入中的尾點（`12.`）保留且不補零。
String formatForDisplay(String raw, CalcSettings settings) {
  if (raw.isEmpty || raw == 'Error') return raw;

  var sign = '';
  var body = raw;
  if (body.startsWith('-')) {
    sign = '-';
    body = body.substring(1);
  }

  final editing = body.endsWith('.');
  if (editing) body = body.substring(0, body.length - 1);

  final parts = body.split('.');
  var intPart = parts[0];
  var fracPart = parts.length > 1 ? parts[1] : '';

  final places = settings.effectiveDecimalPlaces;
  if (places != null) {
    if (fracPart.length > places) {
      fracPart = fracPart.substring(0, places);
    } else if (!editing) {
      fracPart = fracPart.padRight(places, '0');
    }
  }

  if (settings.grouping) intPart = _group(intPart);

  final buffer = StringBuffer(sign)..write(intPart);
  if (fracPart.isNotEmpty) {
    buffer
      ..write('.')
      ..write(fracPart);
  }
  if (editing) buffer.write('.');
  return buffer.toString();
}

/// 每三位插一個逗號（國際分位）。
String _group(String digits) {
  if (digits.length <= 3) return digits;
  final chunks = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    final start = end - 3 < 0 ? 0 : end - 3;
    chunks.insert(0, digits.substring(start, end));
  }
  return chunks.join(',');
}
```

- [ ] **Step 4: 執行測試確認通過**

Run: `flutter test test/number_format_test.dart`
Expected: `All tests passed!`（11 條）

- [ ] **Step 5: 過渡 patch `DisplayScreen`（維持全量綠燈）**

簽名改了 1 參數 → 2 參數，`lib/views/components/display_screen.dart` 的舊呼叫會編譯失敗。先做最小過渡（Task 14 會整檔取代）：

`display_screen.dart` 檔頭加 import：

```dart
import '../../engine/calc_settings.dart';
```

line 27 的 `formatForDisplay(display),` 改為：

```dart
          formatForDisplay(display, CalcSettings.raw),
```

（`CalcSettings.raw` 是 F 模式 → 不補零、不分位，`widget_test.dart` 此刻的斷言 `'5'` 不受影響。）

- [ ] **Step 6: 全量測試與 analyze 確認全綠**

Run: `flutter test`
Expected: `All tests passed!`（113 條）

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/core/number_format.dart lib/views/components/display_screen.dart test/number_format_test.dart
git commit -m "feat(core): implement thousands grouping and decimal padding in number_format"
```

---

### Task 14: `DisplayScreen` 接設定 + `StatusIndicator` + 煙霧測試改斷言

**Files:**
- Modify: `lib/views/components/display_screen.dart`（整檔取代）
- Create: `lib/views/components/status_indicator.dart`
- Modify: `lib/views/calculator_screen.dart`（只改顯示區，鍵盤 Task 15 才動）
- Test: `test/widget_test.dart`（改斷言 + 加測試）

**Interfaces:**
- Consumes: `formatForDisplay(raw, settings)`（Task 13）、`SettingsCubit`（Task 4）、`CalculatorState.hasGT`（Task 12）
- Produces:
  - `DisplayScreen({required String display, required CalcSettings settings, bool hasError = false, bool hasGT = false})`
  - `StatusIndicator({required CalcSettings settings})`，內部 key：`Key('indTax')`／`Key('indRounding')`／`Key('indPlaces')`／`Key('indGrouping')`
  - `DisplayScreen` 的 `Key('gtBadge')`（僅 `hasGT == true` 時存在）

- [ ] **Step 1: 寫失敗測試（`test/widget_test.dart` 追加）**

```dart
  testWidgets('鎖 2 位時顯示補零：2 + 3 = → 5.00', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    await tester.tap(find.text('2'));
    await tester.tap(find.text('+'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('='));
    await tester.pump();

    final display = find.byKey(const Key('displayValue'));
    expect(tester.widget<Text>(display).data, '5.00');
  });

  testWidgets('indicator 顯示目前設定', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(find.byKey(const Key('indTax'))).data, '5%');
    expect(tester.widget<Text>(find.byKey(const Key('indRounding'))).data, '5/4');
    expect(tester.widget<Text>(find.byKey(const Key('indPlaces'))).data, '2位');
    expect(find.byKey(const Key('indGrouping')), findsOneWidget);
  });

  testWidgets('F 模式不顯示位數格', (tester) async {
    SharedPreferences.setMockInitialValues({'rounding_mode': 0}); // float
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(find.byKey(const Key('indRounding'))).data, 'F');
    expect(find.byKey(const Key('indPlaces')), findsNothing);
  });
```

同時把第一條測試的斷言 `'5'` 改成 `'5.00'`（**這是預期的行為變更**，見 spec「測試計畫」）。

- [ ] **Step 2: 執行測試確認失敗**

Run: `flutter test test/widget_test.dart`
Expected: FAIL —— `indicator 顯示目前設定` 找不到 key；`5.00` 那條拿到 `'5'`

- [ ] **Step 3: 取代 `lib/views/components/display_screen.dart` 全檔**

```dart
import 'package:flutter/material.dart';

import '../../core/number_format.dart';
import '../../engine/calc_settings.dart';

class DisplayScreen extends StatelessWidget {
  const DisplayScreen({
    super.key,
    required this.display,
    required this.settings,
    this.hasError = false,
    this.hasGT = false,
  });

  /// raw 字串（無逗號、不補零），格式化在此元件內發生。
  final String display;
  final CalcSettings settings;
  final bool hasError;
  final bool hasGT;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      alignment: Alignment.centerRight,
      color: hasError ? scheme.errorContainer : scheme.surfaceContainerHighest,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (hasGT)
            Text(
              'GT',
              key: const Key('gtBadge'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              formatForDisplay(display, settings),
              key: const Key('displayValue'),
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w300,
                color: hasError ? scheme.onErrorContainer : scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: 建立 `lib/views/components/status_indicator.dart`**

```dart
import 'package:flutter/material.dart';

import '../../engine/calc_settings.dart';

/// 顯示屏與鍵盤之間的細列：稅率 ｜ 捨入模式 ｜ 小數位 ｜ 千分位。
class StatusIndicator extends StatelessWidget {
  const StatusIndicator({super.key, required this.settings});

  final CalcSettings settings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = TextStyle(fontSize: 13, color: scheme.onSurfaceVariant);
    final isFloat = settings.rounding == RoundingMode.float;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerRight,
      child: Row(
        children: [
          const Spacer(),
          Text('${settings.taxRate}%',
              key: const Key('indTax'), style: style),
          Text('  ｜  ', style: style),
          Text(
            switch (settings.rounding) {
              RoundingMode.float => 'F',
              RoundingMode.cut => 'CUT',
              RoundingMode.up => 'UP',
              RoundingMode.halfUp => '5/4',
            },
            key: const Key('indRounding'),
            style: style,
          ),
          if (!isFloat) ...[
            Text('  ｜  ', style: style),
            Text('${settings.decimalPlaces}位',
                key: const Key('indPlaces'), style: style),
          ],
          if (settings.grouping) ...[
            Text('  ｜  ', style: style),
            Text(',', key: const Key('indGrouping'), style: style),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: 修改 `lib/views/calculator_screen.dart` 的顯示區**

把原本的：

```dart
            BlocBuilder<CalculatorCubit, CalculatorState>(
              builder: (_, s) =>
                  DisplayScreen(display: s.display, hasError: s.hasError),
            ),
```

整塊換成：

```dart
            BlocBuilder<SettingsCubit, CalcSettings>(
              builder: (_, settings) =>
                  BlocBuilder<CalculatorCubit, CalculatorState>(
                builder: (_, state) => Column(
                  children: [
                    DisplayScreen(
                      display: state.display,
                      settings: settings,
                      hasError: state.hasError,
                      hasGT: state.hasGT,
                    ),
                    StatusIndicator(settings: settings),
                  ],
                ),
              ),
            ),
```

檔頭補 import：

```dart
import '../bloc/settings_cubit.dart';
import '../engine/calc_settings.dart';
import 'components/status_indicator.dart';
```

- [ ] **Step 6: 執行測試確認通過**

Run: `flutter test test/widget_test.dart`
Expected: `All tests passed!`（4 條）

Run: `flutter test`
Expected: `All tests passed!`（116 條）

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/views/components/display_screen.dart lib/views/components/status_indicator.dart lib/views/calculator_screen.dart test/widget_test.dart
git commit -m "feat(ui): wire settings-aware display and add StatusIndicator"
```

---

### Task 15: 5×5 鍵盤 + `CalcButton` 自適應 + `⚙` 導航

**Files:**
- Modify: `lib/views/components/calc_button.dart`（整檔取代）
- Modify: `lib/views/calculator_screen.dart`（整檔取代）
- Test: `test/widget_test.dart`（追加）

**Interfaces:**
- Consumes: `CalculatorCubit` 新方法（Task 12）、`SettingsScreen`（Task 5）
- Produces:
  - `CalcButton` 高度自適應（`LayoutBuilder` 取可用高度、字級 `clamp(12, 24)`、`FittedBox` 收長標籤）
  - `CalculatorScreen`：`BlocListener<SettingsCubit, CalcSettings>` → `applySettings()`；5 欄 × 5 列鍵盤；`Key('openSettings')` 為 `⚙`

- [ ] **Step 1: 寫失敗測試（`test/widget_test.dart` 追加）**

```dart
  testWidgets('5×5 鍵盤：新鍵存在', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    for (final label in ['GT', 'MU', 'Tax+', 'Tax−', 'AC', 'C', '⌫', '±', '=']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('Tax+ 點擊後顯示含稅值', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    for (final d in ['1', '0', '0', '0']) {
      await tester.tap(find.text(d));
    }
    await tester.tap(find.text('Tax+'));
    await tester.pump();

    final display = find.byKey(const Key('displayValue'));
    expect(tester.widget<Text>(display).data, '1,050.00');
  });

  testWidgets('⚙ 導航到設定頁', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('openSettings')));
    await tester.pumpAndSettle();

    expect(find.text('設定'), findsOneWidget);
    expect(find.text('捨入模式'), findsOneWidget);
  });

  testWidgets('改變設定會即時反映到顯示（切到 F 後不補零）', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('openSettings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('F'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    for (final d in ['2', '+', '3', '=']) {
      await tester.tap(find.text(d));
    }
    await tester.pump();
    final display = find.byKey(const Key('displayValue'));
    expect(tester.widget<Text>(display).data, '5');
  });

  testWidgets('窄高度不 overflow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 260);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
```

> 「改變設定會即時反映」那條的 `find.text('+')` 要小心：`Tax+` 也含 `+` 字元但 `find.text` 是**完全匹配**，所以 `find.text('+')` 只會命中 `+` 鍵 ✓。

- [ ] **Step 2: 執行測試確認失敗**

Run: `flutter test test/widget_test.dart`
Expected: FAIL —— 找不到 `GT`／`MU`／`Tax+` 等鍵

- [ ] **Step 3: 取代 `lib/views/components/calc_button.dart` 全檔**

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 64dp 的硬下限是 Phase 1 的 overflow 來源；改成跟著可用高度走。
          // 44dp 只是設計參考：真的不夠高時以「不 overflow」優先。
          final available =
              constraints.maxHeight.isFinite ? constraints.maxHeight : 64.0;
          final fontSize = (available * 0.38).clamp(12.0, 24.0).toDouble();
          return TextButton(
            style: TextButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              padding: EdgeInsets.zero,
              minimumSize: Size(0, available),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            onPressed: onPressed,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: TextStyle(fontSize: fontSize)),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: 取代 `lib/views/calculator_screen.dart` 全檔**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/calculator_cubit.dart';
import '../bloc/calculator_state.dart';
import '../bloc/settings_cubit.dart';
import '../engine/calc_settings.dart';
import 'components/calc_button.dart';
import 'components/display_screen.dart';
import 'components/status_indicator.dart';
import 'settings_screen.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CalculatorCubit>();
    return BlocListener<SettingsCubit, CalcSettings>(
      listenWhen: (previous, current) => previous != current,
      listener: (_, settings) => cubit.applySettings(settings),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              BlocBuilder<SettingsCubit, CalcSettings>(
                builder: (_, settings) =>
                    BlocBuilder<CalculatorCubit, CalculatorState>(
                  builder: (_, state) => Column(
                    children: [
                      DisplayScreen(
                        display: state.display,
                        settings: settings,
                        hasError: state.hasError,
                        hasGT: state.hasGT,
                      ),
                      StatusIndicator(settings: settings),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      _row([
                        _btn('GT', cubit.onGrandTotal, CalcButtonVariant.function),
                        _btn('AC', cubit.allClear, CalcButtonVariant.function),
                        _btn('C', cubit.clearEntry, CalcButtonVariant.function),
                        _btn('⌫', cubit.backspace, CalcButtonVariant.function),
                        _btn('÷', () => cubit.applyOperator(CalcOp.divide),
                            CalcButtonVariant.operator),
                      ]),
                      _row([
                        _btn('MU', cubit.onMu, CalcButtonVariant.function),
                        _num('7', cubit),
                        _num('8', cubit),
                        _num('9', cubit),
                        _btn('×', () => cubit.applyOperator(CalcOp.multiply),
                            CalcButtonVariant.operator),
                      ]),
                      _row([
                        _btn('Tax+', cubit.onTaxPlus,
                            CalcButtonVariant.function),
                        _num('4', cubit),
                        _num('5', cubit),
                        _num('6', cubit),
                        _btn('−', () => cubit.applyOperator(CalcOp.subtract),
                            CalcButtonVariant.operator),
                      ]),
                      _row([
                        _btn('Tax−', cubit.onTaxMinus,
                            CalcButtonVariant.function),
                        _num('1', cubit),
                        _num('2', cubit),
                        _num('3', cubit),
                        _btn('+', () => cubit.applyOperator(CalcOp.add),
                            CalcButtonVariant.operator),
                      ]),
                      _row([
                        _btn('⚙', () => _openSettings(context),
                            CalcButtonVariant.function, key: 'openSettings'),
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
      ),
    );
  }

  void _openSettings(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
      );

  Widget _row(List<Widget> buttons) =>
      Expanded(child: Row(children: buttons));

  Widget _btn(
    String label,
    VoidCallback onTap,
    CalcButtonVariant variant, {
    String? key,
  }) =>
      Expanded(
        child: CalcButton(
          key: key == null ? null : Key(key),
          label: label,
          onPressed: onTap,
          variant: variant,
        ),
      );

  Widget _num(String digit, CalculatorCubit cubit) =>
      _btn(digit, () => cubit.onDigit(digit), CalcButtonVariant.number);
}
```

- [ ] **Step 5: 執行測試確認通過**

Run: `flutter test test/widget_test.dart`
Expected: `All tests passed!`（9 條）

Run: `flutter test`
Expected: `All tests passed!`（121 條）

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/views/components/calc_button.dart lib/views/calculator_screen.dart test/widget_test.dart
git commit -m "feat(ui): 5x5 keyboard with GT/Tax/MU keys and adaptive button height"
```

---

### Task 16: 全量驗證（analyze / test / 真機操作 / 兩個平台建置）

**Files:**
- 不改程式碼（只驗證）

**Interfaces:**
- Consumes: Task 1-15 全部產出
- Produces: 一份可貼進 PR 的驗證結果

- [ ] **Step 1: 靜態分析與測試**

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: `All tests passed!`（121 條）

- [ ] **Step 2: 插桩追蹤測試覆蓋的關鍵路徑（可選但建議）**

Run: `flutter test --plain-name "GT 真值表"`
Expected: `All tests passed!`（8 條）

Run: `flutter test --plain-name "餘數法除法"`
Expected: `All tests passed!`（8 條）

- [ ] **Step 3: Windows 手動走查**

Run: `flutter run -d windows`

手動依序確認（截圖或記下結果）：
1. 啟動時 indicator 顯示 `5% ｜ 5/4 ｜ 2位 ｜ ,`
2. `1 ÷ 3 =` → 顯示 `0.33`
3. `2 + 3 =` → `5.00`；再 `+ 4 =` → `9.00`；畫面左上出現 `GT` 標記
4. 按 `GT` → 顯示 `14.00`（再按一次仍是 `14.00`；GT = 5 + 9）
5. `AC` → 顯示 `0.00`、`GT` 標記消失
6. `1000` `Tax+` → `1,050.00`；接著 `Tax−` → `1,000.00`
7. `100` `×` `20` `MU` → `125.00`；再按 `MU` → `25.00`
8. `⚙` → 設定頁：把捨入改成 `CUT`、小數位 `0`、關閉千分位 → 返回
9. indicator 變成 `5% ｜ CUT ｜ 0位`；`1 ÷ 3 =` → 顯示 `0`
10. **關閉 App 再 `flutter run -d windows` 一次** → indicator 必須仍是 `CUT ｜ 0位`（持久化生效）
11. `⚙` → 把稅率改成 `8.5` → 返回 → `100` `Tax+` → 顯示 `108`（CUT·0 位把 108.5 截斷）

- [ ] **Step 4: Windows 建置**

Run: `flutter build windows`
Expected: `√ Built build\windows\x64\runner\Release\jack_calculator.exe`

- [ ] **Step 5: Android 建置（本專案第一次有 plugin，必測）**

Run: `flutter build apk`
Expected: `√ Built build\app\outputs\flutter-apk\app-debug.apk`

> 若卡在 `Running Gradle task 'assembleDebug'...` 超過 5 分鐘沒有輸出，先讀 AGENTS.md 的「Gradle distribution 下載會卡死」一節（看 `E:\gradle-home\wrapper\dists\gradle-9.3.1-all\*\` 的 `.part` 有沒有長大），那是本機已知的網路坑，不是這次改動造成的。

- [ ] **Step 6: Commit（若前面步驟有微調）**

```bash
git add -A
git commit -m "chore: phase 2 verification pass"
```

（若完全沒有檔案變更，跳過此步驟。）

---

### Task 17: 同步 `AGENTS.md` 並收尾

**Files:**
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: Task 16 的驗證結果
- Produces: 文件與程式碼一致的 repo 狀態

- [ ] **Step 1: 更新四處**

1. 「已脫離範本階段」段的 `lib/` 檔案數與 Phase 2 狀態：改為 **14 個 Dart 檔**（Phase 1 的 9 個 ＋ `engine/calc_settings.dart`、`data/settings_repository.dart`、`bloc/settings_cubit.dart`、`views/settings_screen.dart`、`views/components/status_indicator.dart` ＝ 5 個新檔，加上 `test/` 的 11 個新測試檔與 1 個測試工具）；把「Phase 2 設計規格已定案但尚未開工」改成「Phase 2 已完成（branch `feat/phase2-commercial-core`）」。
2. 「環境」段的依賴那行：`shared_preferences` 已引入（**不再是零第三方 plugin**），並標「Phase 3 記錄儲存用 `hive_ce`」。
3. 「指令」段的測試數：`flutter test` 註解從「目前 18 個」改成實測數字（Task 16 的結果）。
4. 「Phase 路線圖」：Phase 2 那條改成「**Phase 2（已完成，branch `feat/phase2-commercial-core`）**」，並把「已知延後項」整節改成「Phase 1 延後項（已於 Phase 2 收掉）」並逐條寫上落地位置（`CalculatorState.==` 在 `calculator_state.dart`、`±` 在 `toggleSign`、邊界測試在 `test/sign_and_bounds_test.dart`、overflow 在 `calc_button.dart` 的 `LayoutBuilder`）。

**不要**改「依賴政策」的三條規則本文 —— 它們已經涵蓋 `shared_preferences` 的引入；只需在該節末尾補一句「`shared_preferences` 2.5.6 已於 Phase 2 引入，為本專案第一個 plugin」。

- [ ] **Step 2: 驗證文件沒有說謊**

逐項對照 Task 16 的實測輸出，特別確認：
- 檔案數：`find lib -name '*.dart' | wc -l`
- 測試數：`flutter test` 的 `+NN` 數字

- [ ] **Step 3: Commit**

```bash
git add AGENTS.md
git commit -m "docs: sync AGENTS.md with Phase 2 completion"
```

---

## 完成後

- 執行 `superpowers:finishing-a-development-branch` 決定 `feat/phase2-commercial-core` 的整合方式。
- 合併前**不要** push（專案沒有任何 CI，push 與否由使用者決定）。
- Phase 3 的銜接點（`hive_ce`、M1–M3、紙帶記錄捨入後的值）見 spec 的「Phase 3 銜接點」一節。
