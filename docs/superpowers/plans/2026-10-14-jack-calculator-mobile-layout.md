# 行動裝置版面（4 欄基本盤＋chevron 進階面板）實作計畫

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把主畫面重排為行動優先：標準 4×5 數字盤 ＋ 可展開的 chevron 進階面板（GT／MU／Tax±，預設收起），⚙ 移至顯示區頂列，桌機整欄置中限寬 420dp —— 純視圖層、引擎與 bloc 零改動。

**Architecture:** `calculator_screen.dart` 改為 `StatefulWidget`（面板狀態是區域 `bool`，不進 Cubit）；`DisplayScreen` 加頂列（⚙／GT 徽章）與 `onSettingsTap` callback；chevron 是 `calculator_screen.dart` 內的私有 `_AdvancedToggle`；鍵盤列全部 `Expanded` → 展開時自動壓縮（`CalcButton` 既有自適應機制免改）；`Center ＋ ConstrainedBox(maxWidth: 420)` 處理桌機置中。

**Tech Stack:** Flutter 3.47.7 / Dart 3.13.5、flutter_bloc（既有）、Material 3；**無新增依賴**、無 codegen。

**Spec:** `docs/superpowers/specs/2026-10-13-jack-calculator-mobile-layout-design.md`（決議 L1–L7；本計畫是它的逐字實作）

## Global Constraints

- 純視圖層：`engine/`、`bloc/`、`data/`、`core/`、`views/settings_screen.dart`、`views/components/calc_button.dart`、`views/components/status_indicator.dart` **零改動**。
- 既有測試掛點全保留：`Key('displayValue')`、`Key('gtBadge')`、`Key('openSettings')`、`Key('indTax')`、`Key('indRounding')`、`Key('indPlaces')`、`Key('indGrouping')`；新增 `Key('advancedToggle')`。
- L2 面板狀態不持久化（每次啟動收起，視窗縮放間保留）；L3 無過渡動畫；L4 `maxWidth: 420`（單一常數）。
- 不變項「絕不 overflow」：320×260 收起與展開皆不溢出（優先於觸控下限）。
- 紀律「格式化只在一層」「raw 字串」不觸及、不得破壞。
- 命令成功判讀看字串：`No issues found!`、`All tests passed!`、`√ Built` —— 不看 shell exit code（PowerShell 下 Flutter 寫 stderr 會假報 NativeCommandError）。
- 使用者親自跑 walkthrough；controller 不操作計算機視窗，只交付腳本。
- 刻意未提交檔案（Phase 2 spec 修訂、Phase 2 plan、本輪 spec、本輪 plan、`docs/superpowers/references/`）**不得 commit 或整理**；每個 task 的 commit 只 `git add` 該 task 點名的檔案。
- 分支：`feat/mobile-layout`（自 `main` @ `ae4cc37` 開出）。`main` 領先 origin 19 個 commit、**不 push**。

---

### Task 1: 版面重排（4 欄基本盤 ＋ chevron 面板 ＋ ⚙/GT 頂列 ＋ 桌機限寬）

**Files:**
- Modify: `lib/views/components/display_screen.dart`（全文替換）
- Modify: `lib/views/calculator_screen.dart`（全文替換）
- Modify: `test/widget_test.dart`（3 處編輯）

**Interfaces:**
- Consumes（全部既有、簽名不變）：`CalculatorCubit` 的 `onGrandTotal`／`onMu`／`onTaxPlus`／`onTaxMinus`／`allClear`／`clearEntry`／`backspace`／`applyOperator(CalcOp)`／`onDigit(String)`／`onDecimalPoint`／`toggleSign`／`equals`；`CalcSettings`；`CalculatorState.display`／`hasError`／`hasGT`；`CalcButton(label, onPressed, variant)`。
- Produces（Task 2 與完成後 walkthrough 依賴）：
  - `DisplayScreen({required String display, required CalcSettings settings, bool hasError = false, bool hasGT = false, VoidCallback? onSettingsTap})` —— `onSettingsTap` 非 null 時在頂列左側渲染 `IconButton`（`Key('openSettings')`）。
  - `Key('advancedToggle')`：chevron 細條的 `InkWell`；收起文案「進階」、展開「收起」。
  - `Center ＋ ConstrainedBox(maxWidth: 420)` 包住整欄。

- [ ] **Step 1: 開分支**

```bash
git checkout -b feat/mobile-layout
```

預期：`Switched to a new branch 'feat/mobile-layout'`。工作區本來就有刻意未提交的檔案，會跟著帶過去，**不要動它們**。

- [ ] **Step 2: 寫測試（先紅）——3 處編輯 `test/widget_test.dart`**

**2a. 檔頭 import**（加兩行；`main.dart` 之後、`shared_preferences` 之前）：

old:
```dart
import 'package:jack_calculator/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
```
new:
```dart
import 'package:jack_calculator/main.dart';
import 'package:jack_calculator/views/components/calc_button.dart';
import 'package:jack_calculator/views/components/display_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
```

**2b. 替換「5×5 鍵盤：新鍵存在」整條測試**為兩條：

old:
```dart
  testWidgets('5×5 鍵盤：新鍵存在', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    for (final label in ['GT', 'MU', 'Tax+', 'Tax−', 'AC', 'C', '⌫', '±', '=']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });
```
new:
```dart
  testWidgets('預設收起：標準四欄盤存在、商用鍵不存在', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    for (final label in ['AC', 'C', '⌫', '÷', '×', '−', '+', '±', '.', '=']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    for (final label in ['GT', 'MU', 'Tax+', 'Tax−']) {
      expect(find.text(label), findsNothing, reason: label);
    }
    expect(find.text('進階'), findsOneWidget);
  });

  testWidgets('chevron 切換：展開出現商用鍵、再收起消失', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('advancedToggle')));
    await tester.pump();
    for (final label in ['GT', 'MU', 'Tax+', 'Tax−']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('收起'), findsOneWidget);

    await tester.tap(find.byKey(const Key('advancedToggle')));
    await tester.pump();
    for (final label in ['GT', 'MU', 'Tax+', 'Tax−']) {
      expect(find.text(label), findsNothing, reason: label);
    }
    expect(find.text('進階'), findsOneWidget);
  });
```

**2c. 改「Tax+ 點擊後顯示含稅值」**（加展開步驟、改名）：

old:
```dart
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
```
new:
```dart
  testWidgets('展開後 Tax+ 點擊後顯示含稅值', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    for (final d in ['1', '0', '0', '0']) {
      await tester.tap(find.text(d));
    }
    await tester.tap(find.byKey(const Key('advancedToggle')));
    await tester.pump();
    await tester.tap(find.text('Tax+'));
    await tester.pump();

    final display = find.byKey(const Key('displayValue'));
    expect(tester.widget<Text>(display).data, '1,050.00');
  });
```

**2d. 檔尾（最後一條「超位輸入」測試之後、`main()` 的 `}` 之前）加入三條新測試**：

old:
```dart
    for (final d in ['+', '0', '=']) {
      await tester.tap(find.text(d));
    }
    await tester.pump();
    expect(tester.widget<Text>(display).data, '1.24');
  });
}
```
new:
```dart
    for (final d in ['+', '0', '=']) {
      await tester.tap(find.text(d));
    }
    await tester.pump();
    expect(tester.widget<Text>(display).data, '1.24');
  });

  testWidgets('展開後 GT 鍵把總計帶入顯示', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    for (final d in ['2', '+', '3', '=']) {
      await tester.tap(find.text(d));
    }
    await tester.pump();

    await tester.tap(find.byKey(const Key('advancedToggle')));
    await tester.pump();

    expect(find.text('GT'), findsNWidgets(2)); // 徽章 ＋ 按鍵
    await tester.tap(find.widgetWithText(CalcButton, 'GT'));
    await tester.pump();

    final display = find.byKey(const Key('displayValue'));
    expect(tester.widget<Text>(display).data, '5.00');
  });

  testWidgets('窄窗展開態不 overflow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 260);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('advancedToggle')));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('寬窗：內容置中且寬度上限 420', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    final size = tester.getSize(find.byType(DisplayScreen));
    expect(size.width, 420);
    expect(tester.getCenter(find.byType(DisplayScreen)).dx, closeTo(640, 1));
  });
}
```

- [ ] **Step 3: 跑測試確認紅**

Run: `flutter test test/widget_test.dart`
預期：**6 條失敗**（預設收起／chevron 切換／展開後 Tax+／展開後 GT／窄窗展開態／寬窗），其餘通過——失敗原因都是找不到 `advancedToggle`、商用鍵仍在、或寬度不是 420。

- [ ] **Step 4: 實作 `lib/views/components/display_screen.dart`（全文替換）**

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
    this.onSettingsTap,
  });

  /// raw 字串（無逗號、不補零），格式化在此元件內發生。
  final String display;
  final CalcSettings settings;
  final bool hasError;
  final bool hasGT;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 24),
      alignment: Alignment.centerRight,
      color: hasError ? scheme.errorContainer : scheme.surfaceContainerHighest,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            height: 32,
            child: Row(
              children: [
                if (onSettingsTap != null)
                  IconButton(
                    key: const Key('openSettings'),
                    onPressed: onSettingsTap,
                    icon: const Icon(Icons.settings),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints.tightFor(width: 32, height: 32),
                    visualDensity: VisualDensity.compact,
                    color: hasError
                        ? scheme.onErrorContainer
                        : scheme.onSurfaceVariant,
                  ),
                const Spacer(),
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
              ],
            ),
          ),
          const SizedBox(height: 4),
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

- [ ] **Step 5: 實作 `lib/views/calculator_screen.dart`（全文替換）**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/calculator_cubit.dart';
import '../bloc/calculator_state.dart';
import '../bloc/settings_cubit.dart';
import 'components/calc_button.dart';
import 'components/display_screen.dart';
import 'components/status_indicator.dart';
import 'settings_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  bool _advancedExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CalculatorCubit>();
    return BlocListener<SettingsCubit, CalcSettings>(
      listenWhen: (previous, current) => previous != current,
      listener: (_, settings) => cubit.applySettings(settings),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
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
                            onSettingsTap: () => _openSettings(context),
                          ),
                          // Task 15 偏離（已於報告揭露，非 brief 內容）：
                          // 狀態列本體 Row（status_indicator.dart:20）在大字型的
                          // 320dp 窄視窗需要約 305dp，會橫向 overflow 25px。
                          // 依 spec「絕不 overflow」原則：IntrinsicWidth 先給該 Row
                          // 有界的內在寬度（Row 內有 Spacer，不能吃無界約束），
                          // 再由 FittedBox 在空間不足時整條等比縮小；寬度足夠時
                          // （含 Windows 與實機常見 360dp）渲染與原設計完全相同。
                          Align(
                            alignment: Alignment.centerRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: IntrinsicWidth(
                                child: StatusIndicator(settings: settings),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _AdvancedToggle(
                    expanded: _advancedExpanded,
                    onTap: () =>
                        setState(() => _advancedExpanded = !_advancedExpanded),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          if (_advancedExpanded)
                            _row([
                              _btn('GT', cubit.onGrandTotal,
                                  CalcButtonVariant.function),
                              _btn('MU', cubit.onMu,
                                  CalcButtonVariant.function),
                              _btn('Tax+', cubit.onTaxPlus,
                                  CalcButtonVariant.function),
                              _btn('Tax−', cubit.onTaxMinus,
                                  CalcButtonVariant.function),
                            ]),
                          _row([
                            _btn('AC', cubit.allClear,
                                CalcButtonVariant.function),
                            _btn('C', cubit.clearEntry,
                                CalcButtonVariant.function),
                            _btn('⌫', cubit.backspace,
                                CalcButtonVariant.function),
                            _btn('÷', () => cubit.applyOperator(CalcOp.divide),
                                CalcButtonVariant.operator),
                          ]),
                          _row([
                            _num('7', cubit),
                            _num('8', cubit),
                            _num('9', cubit),
                            _btn('×', () => cubit.applyOperator(CalcOp.multiply),
                                CalcButtonVariant.operator),
                          ]),
                          _row([
                            _num('4', cubit),
                            _num('5', cubit),
                            _num('6', cubit),
                            _btn('−', () => cubit.applyOperator(CalcOp.subtract),
                                CalcButtonVariant.operator),
                          ]),
                          _row([
                            _num('1', cubit),
                            _num('2', cubit),
                            _num('3', cubit),
                            _btn('+', () => cubit.applyOperator(CalcOp.add),
                                CalcButtonVariant.operator),
                          ]),
                          _row([
                            _btn('±', cubit.toggleSign,
                                CalcButtonVariant.function),
                            _num('0', cubit),
                            _btn('.', cubit.onDecimalPoint,
                                CalcButtonVariant.number),
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
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
      );

  Widget _row(List<Widget> buttons) =>
      Expanded(child: Row(children: buttons));

  Widget _btn(String label, VoidCallback onTap, CalcButtonVariant variant) =>
      Expanded(
        child: CalcButton(label: label, onPressed: onTap, variant: variant),
      );

  Widget _num(String digit, CalculatorCubit cubit) =>
      _btn(digit, () => cubit.onDigit(digit), CalcButtonVariant.number);
}

class _AdvancedToggle extends StatelessWidget {
  const _AdvancedToggle({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      key: const Key('advancedToggle'),
      onTap: onTap,
      child: SizedBox(
        height: 28,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              expanded ? '收起' : '進階',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
```

注意：**import 區塊與上方完全一致**（`CalcSettings`／`CalcOp` 由既有 re-export 提供，不要新增 import）。原本 `_btn` 的 `key:` 具名參數已無使用者（⚙ 搬走），一併移除。

- [ ] **Step 6: 跑測試確認全綠**

Run: `flutter test`
預期：`All tests passed!`，共 **126** 條（122 ＋ 拆一條變兩條的 +1 ＋ 新 3 條）。

- [ ] **Step 7: analyze**

Run: `flutter analyze`
預期：`No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/views/components/display_screen.dart lib/views/calculator_screen.dart test/widget_test.dart
git commit -m "feat: mobile-first 4-column pad with chevron advanced panel"
```

---

### Task 2: 全量驗證 ＋ exe／APK 建置 ＋ AGENTS.md 對帳 ＋ walkthrough 交付

**Files:**
- Modify: `AGENTS.md`（4 處小編輯）

**Interfaces:**
- Consumes: Task 1 全部產物（`Key('advancedToggle')`、420dp 常數、新版面）。
- Produces: `build\windows\x64\runner\Release\jack_calculator.exe`（walkthrough 用）、`build\app\outputs\flutter-apk\app-release.apk`（手機終驗用）、更新後的 AGENTS.md。

- [ ] **Step 1: 全量驗證**

Run: `flutter analyze && flutter test`
預期：`No issues found!` ＋ `All tests passed!`（126 條）。有任何失敗就停下修復，不進下一步。

- [ ] **Step 2: 建 Windows exe**

Run: `flutter build windows`
預期：`√ Built build\windows\x64\runner\Release\jack_calculator.exe`（PowerShell 的 stderr 警告可忽略，認 `√ Built` 字串）。

- [ ] **Step 3: AGENTS.md 對帳（4 處）**

3a. 標題段（改括號年份與補一句）：

old:
```
**已脫離範本階段（2026-10-13 Phase 1 完成、Phase 2 完成）**：
```
new:
```
**已脫離範本階段（2026-10-13 Phase 1 完成、Phase 2 完成；2026-10-14 行動裝置版面完成）**：
```

3b. 同段 Phase 2 句尾（補版面輪）：

old:
```
計算機已完成 Phase 1（四則運算 + Decimal 精度）；**Phase 2 已完成（branch `feat/phase2-commercial-core`）**，見下方「Phase 路線圖」與 `docs/superpowers/specs/2026-10-13-jack-calculator-phase2-design.md`。
```
new:
```
計算機已完成 Phase 1（四則運算 + Decimal 精度）；**Phase 2 已完成（branch `feat/phase2-commercial-core`）**；**行動裝置版面已完成（branch `feat/mobile-layout`）**：4 欄基本盤＋chevron 進階面板（預設收起、展開時數字盤壓縮）、⚙ 移至顯示區頂列、桌機置中限寬 420dp（純視圖層）。見下方「Phase 路線圖」與 `docs/superpowers/specs/2026-10-13-jack-calculator-phase2-design.md`、`docs/superpowers/specs/2026-10-13-jack-calculator-mobile-layout-design.md`。
```

3c. 指令段測試數（以 Step 1 實測數為準，預期 126）：

old:
```
# 全部測試（目前 122 個）
```
new:
```
# 全部測試（目前 126 個）
```

3d. Phase 路線圖：在 `- **Phase 3（未開工）**` 那行**前面**插入新 bullet；並在 Phase 4 行尾補字：

在 `- **Phase 3（未開工）**` 前插入：
```
- **行動裝置版面（已完成，branch `feat/mobile-layout`，2026-10-14）**：手機優先版面重排 —— 標準 4 欄盤＋chevron 面板收 GT／MU／Tax±、⚙ 進顯示區頂列、桌機整欄置中限寬 420dp。設計 `docs/superpowers/specs/2026-10-13-jack-calculator-mobile-layout-design.md`、計畫 `docs/superpowers/plans/2026-10-14-jack-calculator-mobile-layout.md`。
```

Phase 4 行：
old:
```
- **Phase 4（未開工）**：音效/震動回饋、擬真桌上型主題（第二套 `ThemeData`）、橫式展開進階按鍵。
```
new:
```
- **Phase 4（未開工）**：音效/震動回饋、擬真桌上型主題（第二套 `ThemeData`）、橫式展開進階按鍵、行動版面的展開動畫與視覺皮膚。
```

**不要**改動 AGENTS.md 其他任何段落；**不要**把本輪 spec／plan commit 進去。

- [ ] **Step 4: Commit AGENTS.md**

```bash
git add AGENTS.md
git commit -m "docs: sync AGENTS.md for mobile-layout round"
```

- [ ] **Step 5: 交付 walkthrough 腳本給使用者（controller 停在這裡等回報）**

使用者跑 `build\windows\x64\runner\Release\jack_calculator.exe`，逐項回報「符合／不符合」（含數字）：

1. 啟動即收起：只有 4 欄基本盤（AC C ⌫ ÷ ／ 7 8 9 × ／ 4 5 6 − ／ 1 2 3 ＋ ／ ± 0 . =）＋「▼ 進階」細條；GT／MU／Tax± 不在盤上。
2. 點「▼ 進階」→ 面板列（GT｜MU｜Tax+｜Tax−）出現在最上排、下方數字盤壓縮；再點「▲ 收起」→ 回復。
3. 展開狀態下：`1000 Tax+` → `1,050.00`；`100 × 20 MU` → `125.00`；`2 + 3 =` → GT 徽章亮 → 點 GT 鍵 → `5.00`。
4. 視窗拉窄到接近手機寬（約 360dp）：收起與展開都不出現 overflow 條。
5. 視窗拉寬（1280×720）：整欄置中、寬度停在 420 左右（兩側留白對稱）。
6. 展開狀態下縮放視窗：展開狀態保留（不持久化只指「重啟後收起」）。
7. ⚙（顯示區左上）→ 設定頁往返正常；改個設定（如切 CUT）回主頁，狀態列有反映。

不符的項目：回報現象與重現步驟 → 走 fix round 修復後重新交付本步驟。

- [ ] **Step 6: 使用者 PASS 後 — 建 release APK**

Run: `flutter build apk`
預期：`√ Built build\app\outputs\flutter-apk\app-release.apk`（release、仍為 debug 簽章——AGENTS 已知項，屬正常）。交付 APK 路徑給使用者，請其安裝到手機後重跑第 1–7 項（並注意狀態列／手勢列 SafeArea 是否正常）。

---

## 完成後（計畫之外，交接給 finishing 技能）

使用者整體驗收 PASS → 整支分支 final review → `superpowers:finishing-a-development-branch`（合併選項由使用者定；**不 push**）。本輪 spec 與本計畫依既有慣例**維持未提交**，除非使用者明確指示。
