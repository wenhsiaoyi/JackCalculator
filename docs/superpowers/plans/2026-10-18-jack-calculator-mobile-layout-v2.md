# Jack計算機 行動版面 v2（圓形鍵＋膠囊面板）實作計畫

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 將行動版面從圓角矩形鍵＋文字 chevron 改版為參考圖款式：圓形鍵基本盤（頂列 `AC C ± ÷`、底列 `0 . ⌫ =`）＋膠囊進階面板，展開時全盤轉膠囊，字級按參考圖比例放大。

**Architecture:** 純視圖層。`CalcButton` 增加形狀（circle/capsule）與字級比例參數；`calculator_screen.dart` 重排鍵位、依 `_advancedExpanded` 傳形狀、面板四鍵傳較小字級；chevron 改無文字雙箭頭。引擎、bloc、設定、顯示區零改動。

**Tech Stack:** Flutter 3.47.7 / Dart 3.13.5、flutter_test。無新依賴。

**Spec:** `docs/superpowers/specs/2026-10-18-jack-calculator-mobile-layout-v2-design.md`（綁定權威；衝突時以 spec 為準）

## Global Constraints

- 只動 `lib/views/components/calc_button.dart`、`lib/views/calculator_screen.dart`、`test/widget_test.dart`、完工時的 `AGENTS.md`；引擎/bloc/設定/顯示區零改動。
- 不加 `%`、`( )` 鍵；不加工具列（歷史圖示／⋮）；不換深色主題；不加過渡動畫；不動橫式。
- 所有既有 `Key()` 保留：`advancedToggle`、`openSettings`、`displayValue`、`indTax`、`indRounding`、`indPlaces`、`indGrouping`。
- 淺色 Material 3 主題與按鈕角色色（number/operator/function/equals）不變；改變的只有形狀、字級、鍵位編排、chevron 樣式。
- 絕不 overflow：320×260 窄窗收起態與展開態皆無例外；寬窗（1280×720）內容置中限寬 420。
- 面板狀態不持久化（每次啟動收起）。
- 分支 `feat/mobile-layout-v2`（自 main @ 515cfe6）；commit 只加各 task 點名檔案；**不 push**。
- 成功判讀一律看輸出字串：`No issues found!`／`All tests passed!`／`√ Built`，不看 exit code（Flutter 寫 stderr 會造成 PowerShell/Git Bash 誤報失敗）。
- 測試總數以實測為準（預估 128＝126＋2），AGENTS.md 依實測填。

## Setup（controller 執行，dispatch Task 1 前）

1. 工作區有已驗證但刻意未提交的鎖直式編輯（`AGENTS.md` intro 段）。為避免被本輪 commit 掃入，先隔離：
   ```bash
   git stash push -m "rotation-lock-agents-md" -- AGENTS.md
   ```
   （`AndroidManifest.xml`／`Info.plist` 兩檔本輪不碰，留在工作區無妨。）
2. 建分支：`git checkout -b feat/mobile-layout-v2`（自 main @ 515cfe6）。
3. 本輪 SDD workspace：`.superpowers/sdd/2026-10-18-jack-calculator-mobile-layout-v2/`。

## Finishing（controller 於整合後執行）

- `git stash pop` 還原鎖直式 `AGENTS.md` 編輯；若與本輪 AGENTS.md 同步衝突（都在 intro 段），兩句並保留（rotation 句＋v2 版面句）。

---

### Task 1: 版面重排＋圓形/膠囊形狀＋字級比例

**Files:**
- Modify: `lib/views/components/calc_button.dart`（全部重寫，61 行 → 約 75 行）
- Modify: `lib/views/calculator_screen.dart`（鍵位重排、傳形狀/字級、chevron 改雙箭頭）
- Test: `test/widget_test.dart`（更新 2 個既有測試、新增 2 個測試）

**Interfaces:**
- Consumes: 現行 `CalcButtonVariant { number, operator, function, equals }` 與所有 `Key()`（不變）。
- Produces:
  - `enum CalcButtonShape { circle, capsule }`（新，export 於 calc_button.dart）。
  - `CalcButton` 新欄位：`final CalcButtonShape shape`（預設 `CalcButtonShape.circle`）、`final double fontScale`（預設 `0.60`）。
  - 字級公式：`fontSize = available × fontScale`（**移除** `.clamp(12.0, 24.0)`），`FittedBox(scaleDown)` 保險保留。
  - 形狀映射：`circle → const CircleBorder()`、`capsule → const StadiumBorder()`（取代 `RoundedRectangleBorder(radius: 12)`）。
  - `calculator_screen.dart` 助手 `_btn` 增 `double fontScale = 0.60` 選参；基本盤鍵傳 `shape: _advancedExpanded ? capsule : circle`；面板四鍵傳 `fontScale: 0.34`。

- [ ] **Step 1: 更新既有 2 個測試（無文字 chevron）**

`test/widget_test.dart` 第 70 行，把

```dart
    expect(find.text('進階'), findsOneWidget);
```

改為

```dart
    expect(find.text('進階'), findsNothing);
    expect(find.text('收起'), findsNothing);
```

第 83 行 `expect(find.text('收起'), findsOneWidget);` 改為 `expect(find.text('收起'), findsNothing);`；第 90 行 `expect(find.text('進階'), findsOneWidget);` 改為 `expect(find.text('進階'), findsNothing);`。兩處皆保留前後的 GT/MU/Tax+/Tax− 存在與消失斷言不變。

- [ ] **Step 2: 新增結構測試（RED）**

在 `test/widget_test.dart` 的 `main()` 內、`'窄窗展開態不 overflow'` 測試之前，插入：

```dart
  testWidgets('收起態鍵位結構：頂列 AC C ± ÷、底列 0 . ⌫ =', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    double dyOf(String label) =>
        tester.getCenter(find.widgetWithText(CalcButton, label)).dy;

    final topDy = dyOf('AC');
    for (final label in ['C', '±', '÷']) {
      expect((dyOf(label) - topDy).abs(), lessThan(1), reason: label);
    }
    expect(dyOf('7'), greaterThan(topDy));

    final bottomDy = dyOf('0');
    for (final label in ['.', '⌫', '=']) {
      expect((dyOf(label) - bottomDy).abs(), lessThan(1), reason: label);
    }
    expect((dyOf('±') - bottomDy).abs(), greaterThan(1));
  });
```

- [ ] **Step 3: 新增形狀測試（RED）**

緊接著插入：

```dart
  testWidgets('形狀：收起態全圓形、展開全膠囊', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    for (final btn in tester.widgetList<CalcButton>(find.byType(CalcButton))) {
      expect(btn.shape, CalcButtonShape.circle);
    }

    await tester.tap(find.byKey(const Key('advancedToggle')));
    await tester.pump();

    final expanded =
        tester.widgetList<CalcButton>(find.byType(CalcButton)).toList();
    expect(expanded.length, greaterThan(20));
    for (final btn in expanded) {
      expect(btn.shape, CalcButtonShape.capsule);
    }
  });
```

- [ ] **Step 4: 跑測試確認 RED**

Run: `flutter test test/widget_test.dart`
Expected: FAIL — 編譯錯誤 `Undefined name 'CalcButtonShape'`（測試無法編譯即 RED，符合預期）。

- [ ] **Step 5: 重寫 calc_button.dart**

完整新內容：

```dart
import 'package:flutter/material.dart';

enum CalcButtonVariant { number, operator, function, equals }

enum CalcButtonShape { circle, capsule }

class CalcButton extends StatelessWidget {
  const CalcButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CalcButtonVariant.number,
    this.shape = CalcButtonShape.circle,
    this.fontScale = 0.60,
  });

  final String label;
  final VoidCallback onPressed;
  final CalcButtonVariant variant;
  final CalcButtonShape shape;

  /// 字級 = 可用高度 × fontScale（行動版面 v2：主鍵 0.60、面板鍵 0.34）。
  /// 外層 FittedBox(scaleDown) 保證窄窗不 overflow。
  final double fontScale;

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
          final available =
              constraints.maxHeight.isFinite ? constraints.maxHeight : 64.0;
          final fontSize = available * fontScale;
          return TextButton(
            style: TextButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              padding: EdgeInsets.zero,
              minimumSize: Size(0, available),
              shape: switch (shape) {
                CalcButtonShape.circle => const CircleBorder(),
                CalcButtonShape.capsule => const StadiumBorder(),
              },
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

- [ ] **Step 6: 重排 calculator_screen.dart**

6a. 助手改為攜帶形狀與字級（第 144–153 行區塊整段替換）：

```dart
  Widget _row(List<Widget> buttons) =>
      Expanded(child: Row(children: buttons));

  Widget _btn(String label, VoidCallback onTap, CalcButtonVariant variant,
          {double fontScale = 0.60}) =>
      Expanded(
        child: CalcButton(
          label: label,
          onPressed: onTap,
          variant: variant,
          shape:
              _advancedExpanded ? CalcButtonShape.capsule : CalcButtonShape.circle,
          fontScale: fontScale,
        ),
      );

  Widget _num(String digit, CalculatorCubit cubit) =>
      _btn(digit, () => cubit.onDigit(digit), CalcButtonVariant.number);
```

6b. 面板列四鍵加 `fontScale: 0.34`（第 77–87 行）：

```dart
                          if (_advancedExpanded)
                            _row([
                              _btn('GT', cubit.onGrandTotal,
                                  CalcButtonVariant.function,
                                  fontScale: 0.34),
                              _btn('MU', cubit.onMu,
                                  CalcButtonVariant.function,
                                  fontScale: 0.34),
                              _btn('Tax+', cubit.onTaxPlus,
                                  CalcButtonVariant.function,
                                  fontScale: 0.34),
                              _btn('Tax−', cubit.onTaxMinus,
                                  CalcButtonVariant.function,
                                  fontScale: 0.34),
                            ]),
```

6c. 基本盤重排。頂列（第 88–97 行）改為：

```dart
                          _row([
                            _btn('AC', cubit.allClear,
                                CalcButtonVariant.function),
                            _btn('C', cubit.clearEntry,
                                CalcButtonVariant.function),
                            _btn('±', cubit.toggleSign,
                                CalcButtonVariant.function),
                            _btn('÷', () => cubit.applyOperator(CalcOp.divide),
                                CalcButtonVariant.operator),
                          ]),
```

底列（第 119–126 行）改為：

```dart
                          _row([
                            _num('0', cubit),
                            _btn('.', cubit.onDecimalPoint,
                                CalcButtonVariant.number),
                            _btn('⌫', cubit.backspace,
                                CalcButtonVariant.function),
                            _btn('=', cubit.equals, CalcButtonVariant.equals),
                          ]),
```

（中間三列 7 8 9 ×／4 5 6 −／1 2 3 + 不變。）

6d. `_AdvancedToggle.build`（第 163–186 行）改無文字雙箭頭：

```dart
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      key: const Key('advancedToggle'),
      onTap: onTap,
      child: SizedBox(
        height: 28,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.expand_less,
                size: 12, color: scheme.onSurfaceVariant),
            Icon(Icons.expand_more,
                size: 12, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
```

- [ ] **Step 7: 跑測試確認 GREEN**

Run: `flutter test`
Expected: `All tests passed!`（預估 128 個；以實測數為準）

- [ ] **Step 8: flutter analyze**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 9: Commit**

```bash
git add lib/views/components/calc_button.dart lib/views/calculator_screen.dart test/widget_test.dart
git commit -m "feat: circular keys with capsule advanced panel (mobile layout v2)"
```

- [ ] **Step 10: 自我審查 diff**

`git show --stat HEAD` 確認只有 3 個檔案；`git show HEAD` 逐行檢查：無 clamp 殘留、無 Key 更動、引擎零改動、無 emoji。

---

### Task 2: 全量驗證＋建置＋模擬器校準＋AGENTS.md 對帳＋walkthrough 交付

**Files:**
- Modify: `AGENTS.md`（intro 行動版面描述、測試數、路線圖行）
- Verify: `flutter build windows`／`flutter build apk`

**Interfaces:**
- Consumes: Task 1 的版面與測試（128 GREEN）。
- Produces: walkthrough 腳本（交付使用者親跑）、release APK（手機終驗用）、AGENTS.md 對帳。

- [ ] **Step 1: flutter analyze ＋全量測試**

Run: `flutter analyze` → `No issues found!`；`flutter test` → `All tests passed!`。記下實測測試數。

- [ ] **Step 2: flutter build windows**

Run: `flutter build windows`
Expected: `√ Built build\windows\x64\runner\Release\jack_calculator.exe`（或新版 Flutter 對應路徑，認 `√ Built` 字串）。

- [ ] **Step 3: flutter build apk**

Run: `flutter build apk`
Expected: `√ Built build\app\outputs\flutter-apk\app-release.apk`（release、debug 簽章為已知項）。

- [ ] **Step 4: 模擬器視覺校準（controller 執行；背景 `flutter run` 為 controller 行程）**

重啟 `flutter run -d emulator-5554` 載入新版面，adb 截圖收起與展開兩態，與 `docs/superpowers/references/mobile-layout-v2/basic-collapsed.jpeg`、`advanced-expanded.jpeg` 比對：圓形鍵貼欄寬、字級比例（主鍵 ≈ 鍵高 0.60、面板 ≈ 0.34）、雙箭頭 chevron、底列 `0 . ⌫ =`。若比例需要微調，改 `calculator_screen.dart`/`calc_button.dart` 的 0.60/0.34 常數後重跑 Step 1（測試不鎖比例常數，無需改測試）。校準結果寫進 ledger。

- [ ] **Step 5: AGENTS.md 對帳**

5a. intro 的行動版面句改為 v2 描述（約第 5 行，原句「4 欄基本盤＋chevron 進階面板（預設收起、展開時數字盤壓縮）、⚙ 移至顯示區頂列、桌機置中限寬 420dp（純視圖層）」→「4 欄圓形鍵基本盤（頂列 AC C ± ÷、底列 0 . ⌫ =）＋chevron 無文字雙箭頭展開膠囊面板 GT/MU/Tax±（預設收起、展開時全盤轉膠囊並壓縮）、⚙ 顯示區頂列、桌機置中限寬 420dp（純視圖層）」）。
5b. 「指令」節「目前 126 個」改為實測數。
5c. Phase 路線圖「行動裝置版面」條目補 v2（branch `feat/mobile-layout-v2`：圓形鍵＋膠囊面板重排，2026-10-18）。

- [ ] **Step 6: Commit AGENTS.md**

```bash
git add AGENTS.md
git commit -m "docs: sync AGENTS.md for mobile-layout-v2 round"
```

（若 `git stash pop` 已先還原鎖直式句導致本 commit 掃入，於報告揭露；正常流程下鎖直式句仍在 stash。）

- [ ] **Step 7: 交付 walkthrough 腳本（使用者親跑 exe）**

交付以下清單給使用者，等回報：
1. 啟動 exe：收起態為圓形鍵；頂列 `AC C ± ÷`；底列 `0 . ⌫ =`；chevron 為無文字雙箭頭。
2. 按 chevron 展開：面板 `GT MU Tax+ Tax−` 膠囊列出現；全盤變膠囊；版面無 overflow。
3. `2 + 3 =` → `5.00`（行為不變）。
4. 新位置操作：`5` `±` → `-5.00`；`C` 清 entry；`⌫` 退格正常。
5. 展開態 `Tax+`（如 `1000` → `1,050.00`）與 `GT` 正常。
6. 視窗壓到最窄：收起與展開皆不 overflow。
7. 寬窗：整欄置中、寬度上限 420。

- [ ] **Step 8: 報告**

回報 controller：analyze/test/build 字串、實測測試數、校準截圖結論、walkthrough 已交付。APK 路徑 `build\app\outputs\flutter-apk\app-release.apk`。

---

## Self-Review 紀錄（寫 plan 時已執行）

- **Spec 覆蓋**：L1 鍵位→Task 1 Step 6b/6c；L2 形狀→Step 5/6a；L3 字級→Step 5（0.60/0.34）＋Step 4 校準；L4 chevron→Step 6d＋Step 1 測試更新；L5 面板→Step 6b（不持久化為既有行為，無改動）；L6 寬窗/窄窗→既有測試＋新結構測試；L7 驗證→Task 2 全部。
- **Placeholder 掃描**：無 TBD/TODO；所有程式碼步驟含完整程式碼。
- **型別一致性**：`CalcButtonShape`／`fontScale`（double，預設 0.60，面板 0.34）跨 Task 1 各步一致；Task 2 只消費不新增介面。
- **已知風險**：320×260 展開態 6 列高度緊繃——既有測試守住；真溢出時依 spec 縮減固定飾件高度（chevron 28dp／顯示區 padding），不動列結構。
