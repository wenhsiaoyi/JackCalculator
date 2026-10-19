# Jack計算機 — 行動裝置版面設計規格（A 案：4 欄基本盤＋chevron 進階面板）

日期：2026-10-13
狀態：設計已口頭核准（2026-10-13），spec 待使用者 review
前置：Phase 2 設計規格 `2026-10-13-jack-calculator-phase2-design.md`（已完成，合併於 main `ae4cc37`，未 push）

參考素材：`docs/superpowers/references/mobile-layout/` 三張 Android 商用計算機截圖（**基本版面**／**進階面板展開**／**溢出選單**）。本輪採用其**版面編排**與**進階面板展開／壓縮處理**；溢出選單（⋮）屬 Phase 3 工具列，不在本輪。

## 總覽

把主畫面從「5 欄 × 5 列（左側常駐商用鍵欄）」重排為**參考圖的兩段式編排**：平日是標準 **4 欄 × 5 列**大數字盤；GT／MU／Tax± 收進一條 **chevron 細條**可展開的進階面板（**預設收起**），展開時面板列插入盤頂、數字盤自動壓縮。⚙ 移到顯示區頂列。手機直立優先；Windows 寬視窗**整欄置中、上限寬 420dp**。

**純視圖層重排**：engine、CalculatorCubit、SettingsCubit、持久化、設定頁、按鈕樣式**零改動**。

## 範圍

### 在範圍內
- 鍵盤重排：收起＝標準 4×5；展開＝面板列（GT｜MU｜Tax+｜Tax−）＋壓縮後 4×5。
- chevron 細條：預設收起、點擊切換；`Key('advancedToggle')`。
- 顯示區頂列：⚙（沿用 `Key('openSettings')`）＋ GT 徽章同列。
- Windows 置中限寬 420dp；極窄視窗（320×260）收起與展開皆不 overflow。
- 對應的 widget 測試更新與新增。

### 明確不在範圍（YAGNI）
- **視覺皮膚**（配色、深色主題、擬真桌面機外觀）：Phase 4。本輪沿用現有 Material 3 theme 色。
- **過渡動畫**（展開／收起的尺寸動畫）：Phase 4 polish。本輪**直接切換**（見 L3）。
- **工具列**（歷史圖示、⋮ 溢出選單）：Phase 3。
- **橫式展開進階版面**（桌機橫向的第二套佈局）：Phase 4（Phase 2 spec 已排定）。
- **面板狀態持久化**：見 L2，不持久化。
- **引擎語意任何調整**：GT／Tax／MU／± 行為完全不動。

## 設計決議（L1–L7）

| # | 決議 | 說明 |
| --- | --- | --- |
| L1 | **方案 A：4 欄基本盤＋chevron 面板、預設收起** | 使用者以瀏覽器 mockup 比較 A／B／C 三案後選定（終端與瀏覽器點選一致）。B（同機制預設展開）與 C（常駐緊湊列、無 chevron）不採用。 |
| L2 | **面板狀態不持久化** | 每次啟動都收起；展開狀態只存活於本次 session（含視窗縮放）。與參考 app 一致，也不動設定層（`SettingsRepository` 零改動）。 |
| L3 | **無過渡動畫** | 切換為直接替換。`CalcButton` 的 FittedBox 會讓按鈕內文字瞬切；捲動/縮放動畫列 Phase 4。 |
| L4 | **桌機置中限寬 420dp** | 約當現代手機直立寬（Pixel／iPhone ≈ 393–430）。高度仍填滿視窗。值集中為單一常數，walkthrough 可微調。 |
| L5 | **⚙ 移到顯示區頂列（左）；GT 徽章同列（右）** | 頂列 `Row [⚙ ｜ Spacer ｜ GT 徽章?]`，數字仍右下。`Key('openSettings')` **保留**（既有導航測試不動）。⚙ 為緊湊 `IconButton`（縮小 constraints，約 32–36dp）。 |
| L6 | **面板列內容與順序：GT｜MU｜Tax+｜Tax−** | 單列四格均分，`CalcButtonVariant.function`（與現行左欄同變體）。handler 沿用 `onGrandTotal`／`onMu`／`onTaxPlus`／`onTaxMinus`。無新增鍵、無刪鍵。 |
| L7 | **chevron 細條** | 全寬、約 28dp 高，位於狀態列與鍵盤之間；收起文案「▼ 進階」、展開「▲ 收起」（含對應 `Icons.expand_more`／`expand_less`）。`Key('advancedToggle')`。 |

## 版面規格

### 收起狀態（預設，等同今日的標準區塊）

```
┌─ 顯示區 ────────────────────┐
│ ⚙                    GT     │   ← 頂列（L5）
│               1,050.00      │   ← 數字（右對齊）
└─────────────────────────────┘
 稅率 8.5% ｜ CUT 2 ｜ 千分位開      ← StatusIndicator（不動）
 ▼ 進階                            ← chevron 細條（L7）
 ┌────┬────┬────┬────┐
 │ AC │ C  │ ⌫  │ ÷  │
 │ 7  │ 8  │ 9  │ ×  │
 │ 4  │ 5  │ 6  │ −  │
 │ 1  │ 2  │ 3  │ +  │
 │ ±  │ 0  │ .  │ =  │
 └────┴────┴────┴────┘
```

### 展開狀態（面板列插盤頂）

```
 ── 同上到 chevron ──
 ▲ 收起                            ← chevron 已展開
 ┌────┬────┬────┬────┐
 │ GT │ MU │Tax+│Tax−│            ← 面板列（L6）
 │ AC │ C  │ ⌫  │ ÷  │
 │ 7  │ 8  │ 9  │ ×  │
 │ 4  │ 5  │ 6  │ −  │
 │ 1  │ 2  │ 3  │ +  │
 │ ±  │ 0  │ .  │ =  │
 └────┴────┴────┴────┘
```

### 壓縮機制（不變項：絕不 overflow）

- 鍵盤區是 `Expanded`；每列是 `Expanded`（flex 1）。收起 5 列、展開 6 列，列高自動均分。
- `CalcButton` 既有的 `LayoutBuilder` 自適應高度（Phase 2 已落地的機制）**不做任何修改**即涵蓋壓縮：按鈕吃掉父層可用高度、字級隨之縮放、`FittedBox` 收長標籤。
- 面板列的加入／移除是**條件插入**（不是 `Visibility(maintainState)`）—— 收起時面板鍵不存在於 widget tree（測試據此斷言）。
- 極端下限（320×260）以「不 overflow」優先，字變小可接受（與 Phase 2 既有紀律一致）。

### 顯示區頂列（L5 細節）

- `DisplayScreen` 新增選用參數 `VoidCallback? onSettingsTap`；非 null 時渲染 ⚙（`Icons.settings`，`Key('openSettings')`）。元件維持 presentational —— 導航仍由 `calculator_screen.dart` 的 `_openSettings` 提供（callback 傳入）。
- GT 徽章（`Key('gtBadge')`、現行樣式不動）移入頂列右側；僅 `hasGT` 時渲染。
- 垂直留白調整：顯示區 padding 由「上下 24」改為「上 12／下 24」，讓頂列取代原本的頂部留白，顯示區總高變化約 ±20dp 內。

### 響應式（L4 細節）

- `Scaffold.body`：`SafeArea → Center → ConstrainedBox(maxWidth: 420) → Column(...)`。
- Windows 寬視窗：整欄置中（含顯示區底色塊，寬 420），兩側為 Scaffold 背景。
- Windows 窄視窗／手機：Constrain 不生效，行為與純手機相同。
- 高度一律填滿（`Center` 給的是 bounded maxHeight，`Expanded` 照常運作）。

## 元件與檔案

```
lib/views/calculator_screen.dart         # 改（主）：StatefulWidget；4×5 重排；chevron 細條（私有 _AdvancedToggle）；面板列條件插入；
                                         #   Center＋ConstrainedBox(maxWidth: 420)；_openSettings 以 callback 傳入 DisplayScreen
lib/views/components/display_screen.dart # 改：＋頂列 [⚙(Key openSettings) ｜ Spacer ｜ GT 徽章?]＋onSettingsTap 參數；padding 微調
test/widget_test.dart                    # 改 2 條、新增數條（見「測試計畫」）
```

**新檔案：0 個**（chevron 細條是 `calculator_screen.dart` 內的私有 widget，僅此一處使用，YAGNI 不抽 component 檔）。實作完成後 `lib/` 檔數維持 14。

## 不動的東西（不變項）

- `engine/`（含 `calculator_engine.dart`、`calc_settings.dart`）、`bloc/`（兩個 Cubit、`CalculatorState`）、`data/settings_repository.dart`、`core/`、`views/settings_screen.dart`、`views/components/calc_button.dart`、`views/components/status_indicator.dart`：**零改動**。
- `StatusIndicator` 的窄幅防護（`FittedBox`＋`IntrinsicWidth`，`calculator_screen.dart:43-51` 的延續）：保留。
- `Key('displayValue')`、`Key('gtBadge')`、`Key('openSettings')`、`Key('indTax')` 等既有測試掛點：一律保留原名。
- 「格式化只在一層」「raw 字串」等 Phase 2 紀律：本輪不觸及。

## 測試計畫

目前 122 條。本輪預估：**改 2 條、新增約 5–6 條**，engine 層測試零變動。

**改寫（預期行為變更，不是回歸）**
1. `test/widget_test.dart`「5×5 鍵盤：新鍵存在」→ 更名為收起／展開兩段：預設（收起）時標準鍵（`AC`／`C`／`⌫`／`±`／`=`…）存在、`MU`／`Tax+`／`Tax−`／`GT` **不存在**；點 `Key('advancedToggle')` 後四鍵出現。
2. `test/widget_test.dart`「Tax+ 點擊後顯示含稅值」→ 輸入後先點 `Key('advancedToggle')` 再點 `Tax+`（斷言不變：`1,050.00`）。

**新增**
1. 預設收起：一開始 `find.text('MU')` 等 findsNothing（含 `GT`——此時 GT 徽章未亮、面板未展開）。
2. 切換顯隱：點兩次 `advancedToggle` 回到收起（面板鍵消失、`▼ 進階` 文案回來）。
3. 展開後功能鍵可用：展開 → `2 + 3 =` → 點面板的 GT 鍵 → 顯示 `5.00`。（`hasGT` 亮起後 `find.text('GT')` 會同時命中徽章與按鍵 —— 一律改用 `find.widgetWithText(CalcButton, 'GT')` 消歧義，不為此新增 Key。）
4. 窄窗兩狀態都不 overflow：320×260 收起（既有測試保留）＋**展開**（新）。
5. 寬窗置中限寬：1280×720 下量測內容寬度 == 420 且水平置中。
6. ⚙ 在收起狀態即可用（既有「⚙ 導航到設定頁」不變即覆蓋；若 widget tree 變動導致找不到則修）。

**不變的**：所有 engine／cubit／repository／settings screen 測試。

## 驗證步驟

```powershell
flutter analyze
flutter test
flutter build windows        # 產 exe 供使用者 walkthrough
```

**使用者 walkthrough 清單（exe，使用者親自操作）**
1. 啟動即收起：只有 4 欄基本盤＋「▼ 進階」細條；GT／MU／Tax± 不存在。
2. 點「▼ 進階」→ 面板列出現、數字盤壓縮；再點「▲ 收起」→ 回復。
3. 展開狀態下跑既有商用流程：`1000 Tax+` → `1,050.00`；`100 × 20 MU` → `125.00`；`2 + 3 =` → GT 徽章亮 → 點 GT 鍵 → `5.00`。
4. 視窗拉窄至手機寬（~360dp）：收起／展開皆不 overflow。
5. 視窗拉寬（1280）：內容置中、寬度停在上限 420。
6. 展開狀態下縮放視窗：狀態保留（L2 只指「重啟後收起」）。
7. ⚙ 往返設定頁正常。

**手機終驗**：`flutter build apk`（**release**）→ 使用者安裝到手機 → 同 1–7 觀察（含 SafeArea 與實機手感）。`ios`／`linux` 本機不可建置，照舊標「未實測」。

## 風險與退路

| 風險 | 影響 | 退路 |
| --- | --- | --- |
| 顯示區多一列（⚙／GT 頂列）＋ chevron 細條，垂直吃掉鍵盤高度 | 小手機按鍵變矮 | padding 與細條高度是常數，walkthrough 後微調；「不 overflow」優先於觸控下限（Phase 2 既有紀律） |
| 420dp 上限值未必順眼 | 桌機觀感 | 單一常數調整，不動結構 |
| `find.text('GT')` 徽章／按鍵同名 | 測試誤命中 | 一律用 `find.widgetWithText(CalcButton, 'GT')` 消歧義（無生產碼改動） |
| 320×260 展開態是新的最壞情境 | 極端視窗 | 已列測試；壓縮機制沿用 Phase 2 已驗證的自適應路徑 |

## 銜接點

- **Phase 3（歷史紙帶／工具列）**：屆時若要放 ⋮ 或歷史圖示，顯示區頂列已有位置概念（L5）；實際落點到 Phase 3 再定。紙帶入口若做成懸浮鍵，需重新評估與面板列的位置關係。
- **Phase 4（橫式展開、動畫、皮膚）**：本輪的 6 列壓縮機制與 chevron 是動畫升級的直接載體（對 `_AdvancedToggle` 與面板列做尺寸過渡即可）；橫式版布局在此之上展開。
- **AGENTS.md**：實作完成後對帳 —— 路線圖補「行動裝置版面」完成項、`lib/` 檔數不變（14）、測試數更新（122 → 約 128）。

## 修訂紀錄

- **2026-10-13（建立）**：初版。依據使用者 mockup 選案（A）與三項決議（不持久化／不動畫／420dp）撰寫。
