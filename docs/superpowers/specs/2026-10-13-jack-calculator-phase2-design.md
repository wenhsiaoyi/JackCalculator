# Jack計算機 — Phase 2 設計規格（商用核心）

日期：2026-10-13
狀態：待使用者 review
前置：Phase 1 設計規格 `2026-10-13-jack-calculator-phase1-design.md`（已完成，branch `feat/phase1-calculator`）

## 總覽

在 Phase 1 的四則運算骨架上加入**商用計算核心**：GT 總計、Tax+／Tax−、MU 利潤定價、四種捨入模式（F／CUT／UP／5/4）＋小數位鎖定（0／2／3／4）、千分位格式化，以及承載這些設定的**持久化層與設定頁**。同時收掉 Phase 1 四項延後（`±` 語意歧義、`CalculatorState` 缺 `==`／`hashCode`、引擎邊界未測、按鍵 overflow 隱患）。

**不含**：歷史紙帶、多組記憶體 M1–M3、匯出、擬真主題、音效震動 —— 紙帶與 M1–M3 屬 Phase 3，主題與回饋屬 Phase 4。

對應 `specs/功能需求滿足這樣需求.md` 的 GT／Tax／MU／捨入／格式化的需求，與 `specs/Flutter細部功能.md` 的 Phase 2 段。

## 範圍

### 在範圍內
- `RoundingMode`（F／CUT／UP／5/4）＋小數位鎖定（0／2／3／4），以**混合語意**套用（見「捨入語意」）。
- GT 累積與 GT 鍵，含 `AC`／`C`／錯誤對 GT 的影響（見「GT 真值表」）。
- `Tax+`／`Tax−`（稅率存設定，預設 5%）。
- `MU`（Casio 式二元按鍵語意）。
- 千分位格式化（國際分位）與固定小數位補零，**只存在於顯示層**。
- `SettingsScreen`＋`shared_preferences` 持久化。
- 5 欄 × 5 列鍵盤與狀態 indicator 細列；`CalcButton` 自適應最小高度。
- `CalculatorState` 手寫 `==`／`hashCode`；`±` 真值表＋修正；引擎邊界測試。

### 明確不在範圍（YAGNI）
- **印度計數系統分位**：PRD:33 有列，但對台灣商用場景價值趨近於零，且會把 formatter 從字串插入升格成「分組策略」抽象並拖進負號／不足位邊界。日後要補時新增 `GroupingStrategy` 即可，**不需要動 engine**。
- **MU「反之亦然」（已知售價求成本）**：PRD:11 有這句，但 `售價 × (100 − 利潤率)% =` 用既有四則即可算出；做成實體鍵會和 `MU` 的二元按鍵模型（要吃 `pendingOp`）打架，並再擠掉一個按鍵空間。
- **Tax− 的減法扣稅模式（`A − A×t`）與 European 開關**：见「Tax 語意」。
- **橫式展開進階按鍵**（`Flutter細部功能.md`:25-27 建議）：需同時維護兩套按鍵矩陣與兩套佈局測試，留給 Phase 4（擬真主題本來就要動佈局）。
- **Tax／MU 結果寫入 GT**：见「GT 真值表」。
- **雲端同步、匯出、历史记录**。

## 技術選型

| 項目 | 決定 | 說明 |
| --- | --- | --- |
| 高精度數學 | `decimal` 3.2.6（既有） | 捨入直接用 `round(scale:)`／`truncate(scale:)`／`ceil(scale:)`。 |
| 設定持久化 | **`shared_preferences: ^2.5.6`** | 專案**第一個 plugin**。要 `flutter >=3.41.0`（本機 3.47.7 ✅）、宣告支援 android／ios／linux／windows —— 正好是本專案的四個目標。 |
| ~~`hive`~~ | **不可用** | 最新版 2.2.3 的 pubspec 限制 `sdk: >=2.12.0 <3.0.0`，本專案 Dart 3.13.5 會被 pub 拒絕解析。（結論出自 pub 官方 API 的 metadata，未做 live resolve 查證。） |
| `hive_ce` 2.20.2 | **退路，非主計畫** | 純 Dart、無 plugin。若 `shared_preferences` 在 Android 建置上出問題（見「風險」），改用它在 Phase 2 存設定、Phase 3 存記錄。 |
| 狀態管理 | `flutter_bloc`（既有，兩個 Cubit） | 不引入 Riverpod／equatable。 |
| 不引入 | `intl` `NumberFormat`、`build_runner`、`Isar`、`path_provider` 自寫 JSON | `intl` 的 locale grouping ≠ 商用機千分位開關（會引入空格分隔等無關注釋）；自寫 JSON 要把 shared_preferences 已代管的寫入可靠性重做一遍。 |

**新增依賴**：只有 `shared_preferences`。

## 依賴政策（同步寫入 AGENTS.md，取代「只 flutter_bloc＋decimal」的默規）

一階依賴僅限同時滿足以下三者的套件：

1. Flutter 官方／flutter.dev 維護，或活躍維護的社群 fork（需檢查最新版的 Dart SDK 限制能否與本專案 `^3.13.5` 共同解析）。
2. 在本專案四個目標中**至少 Windows** 可建置（Windows 是唯一能本機驗證的目標）。
3. 不需要 `build_runner`／codegen。

每個 Phase 只為**該 Phase 的明確需求**引入儲存相關套件，不提前引入。據此，Phase 3 的記錄儲存（可能 `hive_ce`）與 Phase 2 的設定儲存（`shared_preferences`）**共存不視為重複** —— 層級不同：key-value 設定 vs 可查詢記錄。設定不遷移。

## 架構

### 目錄（粗體為新增）

```
lib/
├── core/
│   ├── theme.dart
│   └── number_format.dart        # 改：千分位＋固定小數補零；只被 DisplayScreen 呼叫
├── data/
│   └── settings_repository.dart  # 新：shared_preferences 的唯一接觸點
├── engine/
│   ├── calc_settings.dart        # 新：不可變值物件 ＋ RoundingMode 列舉（純 Dart）
│   └── calculator_engine.dart    # 改：持 CalcSettings；applyRounding 為唯一捨入出口；新增 GT／Tax／MU／±修正
├── bloc/
│   ├── calculator_cubit.dart     # 改：＋applySettings／onGT／onTaxPlus／onTaxMinus／onMu
│   ├── settings_cubit.dart       # 新：載入／儲存／變更設定
│   └── calculator_state.dart     # 改：＋hasGT，手寫 ==／hashCode
└── views/
    ├── calculator_screen.dart    # 改：5×5 鍵盤、indicator 細列、BlocListener
    ├── settings_screen.dart      # 新：稅率／捨入模式／小數位／千分位
    └── components/
        ├── calc_button.dart      # 改：自適應最小高度（LayoutBuilder，44dp 下限＋字級縮放）
        ├── display_screen.dart   # 改：套用 formatForDisplay、GT 標記
        └── status_indicator.dart # 新：5% | 5/4 | 2位 | ,
main.dart                          # 改：MultiBlocProvider（SettingsCubit ＋ CalculatorCubit）
```

### `CalcSettings` 的擺位裁決

`CalcSettings` 放 **`engine/`**，不是 `Flutter細部功能.md`:47 建議的 `data/models/`。理由：engine 需要 import 它（鏈捨入要在 engine 內發生），而 `data/` 本來就要 import `engine/` 的型別 —— 若 model 住在 `data/`，依賴方向會變成 `engine/ → data/ → engine/` 的迴圈。`settings_repository.dart`（在 `data/`）負責把 `CalcSettings` serialize／deserialize，型別所有權留給 `engine/`。

### 元件職責與邊界

- **`CalcSettings`**（`engine/`）：不可變值物件，欄位 `taxRate`（`Decimal`，0–100，一位小數）、`rounding`（`RoundingMode`）、`decimalPlaces`（`int`，0／2／3／4）、`grouping`（`bool`）。`enum RoundingMode { float, cut, up, halfUp }` —— 對應 UI 標籤 `F`／`CUT`／`UP`／`5/4`（UI 顯示 5/4，code 用 `halfUp` 避免 `5-4`/`halfEven` 誤讀）。帶 `const CalcSettings.defaults()` = `5%, 5/4, 2, true`。手寫 `==`／`hashCode`。
- **`CalculatorEngine`**：新增 private `Decimal applyRounding(Decimal)` —— **全引擎唯一的捨入出口**，所有產出結果的路徑（`_compute()`、Tax、MU）都必須經過它，讓「有沒有雙重捨入」成為一條可守住的測試。`_divisionScale` 從硬編碼 10 改為由設定推導的 guard 位。新增 `Decimal _grandTotal`、`onTaxPlus()`／`onTaxMinus()`／`onMu()`／`showGrandTotal()`。保持**零 Flutter import**（Phase 1 invariant），所以 Phase 2 全部新邏輯都能脫離 widget 單元測試。
  - **MU 需要一個新狀態欄位**：第二次按 `MU` 要顯示利潤額 `= 售價 − 成本`，而此時 `_accumulator` 已經被售價覆蓋，所以成本必須另存 —— 新增 `Decimal? _muCost`，第一次 `onMu()` 時存下當時的成本，第二次讀它算利潤額。`allClear()` 與 `_pendingOp` 被重置時一併清為 `null`（否則 `AC` 後再按 `MU` 會拿到上一筆的成本）。
  - **`hasGT` 的定義是 `_grandTotal != Decimal.zero`**，不是「本-session 用過 GT」。副作用要老實記錄：一筆 `X = 0` 的計算進 GT 後總和仍是 0，indicator 不會亮起 —— 這是刻意選擇（避免多一個布爾欄位追蹤「是否曾用過」），測試要鎖住這個行為而不是當 bug 修。
- **`SettingsRepository`**：`Future<CalcSettings> load()`（讀不到／半壞 → 回傳 `defaults()`，不拋）、`Future<void> save(CalcSettings)`。內部只存 4 個純量：`taxRate` String、`roundingModeIndex` int、`decimalPlaces` int、`grouping` bool。是 repo 內**唯一 import `shared_preferences` 的檔案**。
- **`SettingsCubit`**：`SettingsCubit(this._repo)` 啟動即 `load()`；每個 `on*` setter 更新 state 後 fire-and-forget `save()`。
- **`CalculatorCubit`**：新增 `applySettings(CalcSettings)` 把設定推進 engine 並 `_sync()`。仍是 UI ↔ engine 的唯一橋。
- **`DisplayScreen`**：依設定格式化顯示；承載 GT 標記。
- **`StatusIndicator`**：`BlocBuilder<SettingsCubit, CalcSettings>` 渲染目前稅率／捨入／小數位／分位，讓使用者知道 Tax 鍵用的是哪個值。
- **`SettingsScreen`**：表單式（不是計算機鍵盤），改即存，無「確定」按鈕。

### 邊界紀律：格式化只在一層

`CalculatorEngine._entry` 與 `CalculatorState.display` **一律是 raw 字串（無逗號）**。`formatForDisplay()` 由 `DisplayScreen` 呼叫，**不得**在 Cubit `_sync()` 前呼叫。否則會被這些既有邏輯污染：
- `inputDigit` 以 `replaceAll(RegExp(r'[^0-9]'), '')` 計算位數（`calculator_engine.dart:27`）—— 逗號會被當成非數字而少算位數。
- `_entryValue` 的 `Decimal.tryParse(_entry)`（line 19）—— 含逗號會 parse 失敗並**靜默退回 `Decimal.zero`**。
- `backspace()` 的 `substring` 與 `toggleSign()` 的 `startsWith('-')` —— 字串操作會錯位。

**鎖 2 位時 `5` 顯示為 `5.00`**：補零屬格式化，只在顯示層做，**不回寫 `_entry`**（`_entry` 仍為 `5`），避免退格把 `5.00` 退成 `5.0` 這類顯示／內部不一致。

## 運算語意

### 捨入語意（混合，D1＝C）

| 路徑 | 捨入套用點 |
| --- | --- |
| `+ − × ÷` 與 `=` | **鏈捨入**：每次 `_compute()` 出口即捨入，`_accumulator` 存的當下就是捨入後的值。所以「畫面顯示什麼、下一筆就用什麼」，與 Casio 桌上型商用機一致。 |
| `Tax+`／`Tax−`／`MU` | **一鍵功能**：中繼結果**不中途捨入**，只在最終輸出套用一次捨入。 |

> 「不中途捨入」不等於「無窮精度」：`Tax−` 與 `MU` 都含除法，仍受下方「除法 guard 位」的截斷約束。措辭上 spec 不宣稱全精度，實作與測試都以 guard 位為準。

### `F` 模式與小數位鎖定的關係（**F 使小數位設定失效**）

Casio 的 `F`（Float）本身就是「不鎖定小數位」，所以它和 0/2/3/4 鎖定是**互斥**的，不是兩個正交開關。定案：

- `rounding == F` 時，`decimalPlaces` **一併忽略**：不捨入、**不補零**，顯示 raw 值（`5` 顯示 `5`，不是 `5.00`）。
- `rounding ∈ {CUT, UP, 5/4}` 時，`decimalPlaces` 同時控制**捨入位數**與**顯示補零**。
- `StatusIndicator` 在 `F` 模式顯示 `F` 而**不顯示** `n位`，避免「那個控制項是死的」的困惑。
- 設定頁不隱藏小數位選單（維持 `F` 切回 5/4 時使用者先前選的位數還在），只在 `F` 時把該列顯示為 disabled 樣式。

`CalcSettings` 要有對應的單一查詢點：`int? get effectiveDecimalPlaces => rounding == RoundingMode.float ? null : decimalPlaces;` —— engine 與 formatter 都讀它，**不要各處自己判斷** `F`。

連帶的 spec 措辭修正：PRD 非功能性需求的「絕對精確」要在文件中重新表述為「**不用 `double`、無浮點誤差**」，而不是「不捨入」—— 鏈捨入會累積捨入誤差，這是刻意選取的機台行為。

### 四種模式

| 模式 | 實作 | 負值 `-1.239` @ 2 位 | 說明 |
| --- | --- | --- | --- |
| `F`（浮動） | 不捨入，僅 `_clean` | `-1.239` | 除法 guard 位改用 `_maxDigits` = 16。 |
| `CUT` | `truncate(scale: n)` | `-1.23` | 向零捨去（已核對 `decimal.dart:250` 「q is already truncated toward zero」）。 |
| `UP` | 符號導向 wrapper | `-1.24` | **不能直接用 `ceil(scale: n)`** —— 它是向 +∞，對負值是 `-1.23`。寫 `d.isNegative ? -(-d).ceil(scale: n) : d.ceil(scale: n)`。 |
| `5/4` | `round(scale: n)` | `-1.24` | 已核對 `decimal.dart:216-231`：half **away from zero**（`-3.5 → -4`），正是商用機的 5/4，不是 banker's rounding。 |

### 除法 guard 位（D2＝A）：消除雙重捨入

既有 `_divisionScale = 10` 是硬編碼截斷；若在其上再套一層捨入就會**捨入兩次，而兩次不等於一次**：

> `1.444449` 鎖 4 位、5/4 → 直接捨入 `1.4444`；先截 5 位得 `1.44445` 再捨入 → `1.4445`。**不同。**

改法：除法內部先算到 **`decimalPlaces + 6`** 位 guard（`F` 模式則 16 位），再由 `applyRounding()` 一次性落地。`_divisionScale` 不再是對外語意，只是「算夠位」的實作細節。此條由上面那組數字的回歸測試守住。

### GT 真值表（D3：採 `Flutter細部功能.md` 的「= 累加」定義）

兩份來源衝突 —— PRD:10 說「自動累積所有**乘除**計算的總和」，`Flutter細部功能.md`:20 說「每次按下 **=** 時累加」。**採後者。** PRD 那句是對實機機制的誤述（源自「+ 鍵同時是加總鍵」）；「只累積乘除」會讓 `100 + 50 =` 這種最常見的加總筆進不了 GT，違反 PRD 自己列出的使用場景（盤點、清點多筆總金額）。

| 事件 | GT 行為 |
| --- | --- |
| `=` 完成一筆 | `GT += 結果` |
| 立即執行的**中間值**（`2+3×4=` 裡的 `5`） | **不進 GT**，只有 `=` 的最終值進 |
| `Tax+`／`Tax−`／`MU` 鍵 | **不直接進 GT**（只改 accumulator，之後按 `=` 才入總） |
| `AC` | 清 GT |
| `C`（clearEntry） | **不**清 GT |
| `GT` 鍵 | 把總和帶入 `_entry` 且 `_startNewEntry = true`；**不清空**（可重複引用，再按 GT 仍是同一總和） |
| 除以零／MU 100% 等錯誤態 | 該筆**不進 GT** |
| `=` 之後重複按 `=` | 不重複累加 —— 既有 `equals()` 在 `_pendingOp == null` 時直接 return（`calculator_engine.dart:70`）已保護此不變項，寫成測試鎖住 |

### Tax 語意（D4＝反推未稅）

- `Tax+`：`A × (1 + t/100)` → 含稅價。
- `Tax−`：`A ÷ (1 + t/100)` → 從含稅價**反推**未稅價。採此而非歐洲 cash register 的 `A − A×t`，因為台灣／日本加值型營業稅的實務用法是「客戶給含稅價，算出未稅額」：`2100` 按 Tax−（t=5%）= **2000**（減法版會錯給 1995）。PRD:12「含稅／未稅一鍵切換」描述的正是這一對互為反函數的按鍵。
- 稅率**存在設定**（預設 5%），主鍵盤**不放**改稅率的鍵；由 `StatusIndicator` 顯示目前稅率。
- 依 D1，Tax 鍵中繼值不在中途捨入、出口一次捨入（仍受 guard 位約束）；依 D3，不直接寫 GT。
- `÷ (1 + t/100)` 在 `t = −100` 時為除零 → `hasError`。設定頁把稅率限制在 **0–100%、一位小數**，從源頭排除；engine 仍保留檢查作防呆。

### MU 語意（D5＝Casio 二元按鍵）

`MU` 不是「對目前顯示值做一件事」，而是**讀取待執行運算子與兩個運算元**（Phase 1 的立即執行模型剛好支持：`applyOperator` 已把手邊值存進 `_accumulator`、新值留給 `_entry`，見 `calculator_engine.dart:57-67`）。

| 按鍵序列 | 結果 |
| --- | --- |
| `100 × 20 MU` | 售價 `= 100 ÷ (1 − 20/100)` = **125** |
| 再按一次 `MU` | 利潤額 `= 售價 − 成本` = **25** |
| `100 + 20 MU`（`pendingOp != multiply`） | **no-op**：不改顯示、不進 GT、不報錯 |
| `100 × 100 MU` | 分母 `1 − 1 = 0` → `hasError` |
| 利潤率 > 100% | 照算出**負值**（Casio 亦如此），不攔截 —— 數學正確但商業無意義，記錄於此 |

### `±` 修正（D9）

既有死路：`toggleSign()` 在 `_startNewEntry == true`（剛按完運算子）時**同時**翻轉 `_accumulator` 和 `_entry`（`calculator_engine.dart:50-55`），但不把 `_startNewEntry` 設為 false，於是隨後輸入的數字會**整個取代** `_entry`（line 23-25）。結果 `5 + ± 3 =` 算的是 `(-5) + 3 = -2` —— 而使用者按 `±` 的意圖永遠是「我手邊這個數」，絕不是回頭改第一個運算元。

新規則：**`±` 只作用於 entry，永不回溯 accumulator。**
- `_startNewEntry == true` 時，`±` 翻轉一個 `_pendingSign` 旗標，讓「下一個被輸入的數字」帶符號（`inputDigit` 套用它）。
- 否則照現行翻轉 `_entry` 的字串符號。
- **保留** `_entry = _clean(_accumulator)` 的 echo 行為（`applyOperator` 內）—— 它剛好讓 `5 + =` → **10**，與 Casio 重複第一運算元的行為一致。此條列為不變項測試，改 `±` 時不得弄壞。

### 運算子優先順序與連算

維持 Phase 1 的**立即執行**（左到右，`2 + 3 × 4 =` → **20**），不引入運算子優先順序。

## 資料流

```
啟動 → SettingsRepository.load() → SettingsCubit(CalcSettings)
                                          │ BlocListener（CalculatorScreen）
                                          ▼
                                CalculatorCubit.applySettings() → engine._settings
使用者點按 → Cubit.on* / onTaxPlus / onMu / onGT …
                → CalculatorEngine（_compute → applyRounding → GT 判定）
                  → emit(CalculatorState{display, hasError, hasGT})
                    → DisplayScreen.formatForDisplay(raw, settings)   ← 逗號／補零只在這層
                    → CalcButton 矩阵

設定頁變更 → SettingsCubit 更新 state → fire-and-forget save()
                                    └→ BlocListener → applySettings() → engine
```

`CalculatorState` 欄位 = `display`、`hasError`、`hasGT`（GT 已累積時顯示標記）。**設定不複製進 `CalculatorState`** —— `StatusIndicator` 直接 `BlocBuilder` 訂閱 `SettingsCubit`，避免兩處 state 需要同步。

**啟動時序**（`SettingsCubit.load()` 是 async，一定要有定論）：App 建立時 `CalculatorCubit` 帶著 `CalcSettings.defaults()`（`5%／5/4／2位／分位 on`）立即可用，**不等待載入**；`load()` 完成後 `SettingsCubit` emit 實際設定，`BlocListener` 隨之呼叫 `applySettings()`。也就是**允許極短的「預設值閃一下」**，不做 loading 畫面。代價是第一幀可能用 5/4·2位 渲染，載入後若設定是 `F` 就立刻改顯示 —— 這在可接受範圍，且避免把 engine 初始化做成非同步而破壞 Phase 1 的同步事件流。

## 錯誤處理

- 沿用 Phase 1 的單一 `hasError` 旗標與「`AC`／`C`／任何數字輸入清除錯誤」路徑。
- 新增的錯誤觸發點：÷ 0（既有）、`Tax−` 且 t = −100%（設定頁已排除，engine 防呆）、`MU` 且利潤率 = 100%。
- 錯誤態下按 `Tax`／`MU`／`GT` 一律 no-op（同既有「錯誤態下按運算子不產生新結果」）。
- `SettingsRepository.load()` 任何異常 → `defaults()`，不拋、不白畫面。設定頁的輸入驗證：稅率欄限 0–100、一位小數，非法輸入不寫入 state。

## UI 與按鍵佈局（D8＝5 欄 × 5 列）

方向判據：Phase 1 的 overflow 隱患是**垂直**的（`minimumSize: Size(0, 64)` × 5 列 ≈ 516dp，`calc_button.dart:36`），所以要**加寬、不加高**。

```
GT    AC   C   ⌫   ÷
MU    7    8   9   ×
Tax+  4    5   6   −
Tax−  1    2   3   +
⚙     ±    0   .   =
```

- **列數維持 5** → 垂直需求完全不變，Phase 1 那條延後項不被放大。
- 寬度下限變成 5 × 64 ≈ 320dp：Android 最窄常見直式螢幕（360dp）放得下，Windows 1280×720 有餘裕。
- `StatusIndicator` 是顯示屏與鍵盤之間的**細列**（20–24dp，不是 64dp 的按鍵列），內容為 `5% ｜ 5/4 ｜ 2位 ｜ ,`；`F` 模式下第二格顯示 `F` 且**不顯示**位數格（見「`F` 模式與小數位鎖定的關係」）。
- `⚙` 推入 `SettingsScreen` route。
- **自適應下限**：`CalcButton` 改用 `LayoutBuilder`，最小高度 64 → **44dp**（Material 可觸碰下限）依可用高度縮放，並同步縮字級。極矮視窗只是字變小，不再出現 yellow-black overflow 條。**以此永久關掉 Phase 1 延後項 #4。**

## 測試計畫

目前 18 條 → 預估 **~70 條**。主體在 engine 層（因 engine 保持零 Flutter import）。

**引擎單元測試**
- 捨入矩陣：4 模式 × `+ − × ÷`；負值方向差異（`-1.239`：CUT→`-1.23`、UP→`-1.24`、5/4→`-1.24`、F→`-1.239`）；小數位 0／2／3／4 各一。
- **雙重捨入照妖鏡**：`1.444449` 鎖 4 位 5/4 → `1.4444`（不是 `1.4445`）；`1/3` 鎖 2 位 × 四模式。
- GT 真值表 8 條逐項（含「`=` 重複按不重複累加」與「中間值不進 GT」兩條不變項）。
- Tax：`Tax+`／`Tax−` 互為反函數（1000 → 1050 → 1000）；t=5% 下 `2100 Tax−` → `2000`（**不是** 1995）；並驗證中繼值未在途中被捨掉（1000 Tax+ Tax− 應回到 1000，而非因中途捨入漂走）。
- MU：`100 × 20 MU` → 125；再按 → 25；`+` 下 no-op；利潤率 100% → Error；>100% → 負值。
- `±` 真值表：含 `5 + ± 3 =` → `2`、`5 + =` → `10`（不變項）、`5 ± =` → `-5`。
- 邊界（Phase 1 延後項 #3）：`_maxDigits` 上限、負值退格、尾點退格、運算子重按、trunc-vs-round。
- **自我審查補入的三條**：`F` 模式忽略 `decimalPlaces`（`F` + 鎖 2 位時 `5` 不捨入也不補零）；`AC` 清掉 `_muCost`（`AC` 後按 `MU` 不得沿用上一筆成本）；GT 總和為 0 時 `hasGT` 為 false（把上文的副作用鎖成測試，別當 bug 改）。

**格式化單元測試**（`number_format`）：分位開關、補零（`5` @ 2 位 → `5.00`）、負號、`Error` 字串不加逗號、超過 3 位邊界、小數段不分組、raw 不含逗號的邊界紀律。

**資料層測試**：`SettingsRepository` round-trip（`SharedPreferences.setMockInitialValues`）；預設值；壞值退回 `defaults()`。

**Widget 測試**：Phase 1 煙霧測試（`2 + 3 =` → `5`）**必須照過**；新增 indicator 渲染、`⚙` 導航到 `SettingsScreen`、`Tax+` 點擊後顯示含稅值、鎖 2 位時顯示 `5.00`、5×5 矩陣在窄高度下不 overflow（`LayoutBuilder` 驗證）。

**不做**：golden／視覺回歸測試（本 repo 無 CI、無 pre-commit hook）。

## 實作分段（給 writing-plans）

本 Phase 比 Phase 1 大（Phase 1 計畫 1053 行只做骨架）。仍是**一 Phase 一計畫**，但計畫內部按此順序分段，每段結束都能 `analyze`＋`test` 乾淨通過：

1. **A 段｜設定基礎**：`CalcSettings`/`RoundingMode`、`SettingsRepository`＋`shared_preferences`、`SettingsCubit`、`SettingsScreen`、`main.dart` 改 `MultiBlocProvider`。此段結束時設定可存可取，但還沒影響計算。
2. **B 段｜引擎語意**：`applyRounding`（四模式＋guard 位）、GT、Tax、MU、`±` 修正、`CalculatorState.==`。**全部先寫測試再實作**（TDD），因為這段是全 Phase 風險集中處。
3. **C 段｜UI**：5×5 鍵盤、`StatusIndicator`、`CalcButton` 自適應高度、`number_format` 千分位與補零接上 `DisplayScreen`。

A→B→C 的依賴是單向的：B 只依賴 `engine/calc_settings.dart`（A 段產出的型別），C 只讀 state 與 settings。段與段之間不平行動工，避免 engine 和 UI 同時改導致測試難歸因。

## 驗證步驟

```powershell
flutter pub get          # shared_preferences 首次解析
flutter analyze
flutter test
flutter run -d windows   # 手動走：改稅率 → 重開 App 看是否留值
flutter build windows    # plugin 的 Windows 端要能編
flutter build apk        # plugin 的 Android 端要能編（第一次有 plugin）
```

`ios`／`linux` 本機無法建置，spec 老實標「未實測」。注意 AGENTS.md 的既有教訓：`flutter` 寫 stderr 會讓 PowerShell 回報 exit code 1 但其實成功 —— 判成功看有無 `√ Built ...`／`All tests passed!`。

## 風險與退路

| 風險 | 影響 | 退路 |
| --- | --- | --- |
| `shared_preferences` 是本專案**第一個 plugin**，Android 端多出 Gradle plugin 專案（AGP 9.1.0／Kotlin 2.4.0／Gradle 9.3.1），而本機 Gradle 那條路徑有已知下載坑 | `flutter build apk` 可能失敗或需重新拉 distribution | 改用 `hive_ce`（純 Dart、零 plugin），Phase 2 存設定、Phase 3 存記錄共用一套 |
| 鏈捨入累積誤差與「零誤差」需求文字衝突 | 使用者質疑「不是說零誤差嗎」 | spec 內把需求重新表述為「不用 `double`、無浮點誤差」；App 說明與 PRD 同步措辭 |
| 一鍵功能（Tax／MU）出口捨入、鏈路徑每步捨入，兩者混用時的心智模型複雜 | 測試邊界多、易出「看起來算錯」的 case | 混合語意寫成上表的兩行紀律；每個功能各有專屬測試，實作採 TDD |
| 5 欄在 360dp 寬的 Android 上是 72dp／鍵，比 Phase 1 的 90dp 小 | 手感變差；Phase 4 擬真主題還要再改佈局 | Phase 2 接受（Windows 是本機驗證目標）；橫式展開留 Phase 4 一併處理 |
| `hive` 的不可用結論出自 pub metadata 而非 live resolve | 誤判機率極低（SDK 上限是 pub 硬性規則），但非實測 | 如需實測，在 workspace 內開暫時專案跑 `dart pub get`（外部的已被權限擋掉） |

## Phase 1 延後項對帳

| Phase 1 延後項 | Phase 2 處置 |
| --- | --- |
| `CalculatorState` 無 `==`／`hashCode` | **收掉**：手寫（欄位增加到 3 個，no-op 重繪代價变大，此刻做價值更高）。**不加 `equatable`**。 |
| `±` 在 `A <op> ± =` 退化路徑的符號歧義 | **收掉**：先寫 ± 真值表＋測試，再依「只作用於 entry、回溯不到 accumulator」的新規則實作。 |
| 引擎邊界未測（`maxDigits`、負值／尾點退格、運算子重按、trunc-vs-round） | **收掉**：與捨入測試同輪寫。 |
| `CalcButton` 64×5 列 ≈ 516dp overflow 隱患 | **收掉**：5×5 佈局不增加列數 ＋ `LayoutBuilder` 44dp 自適應下限。 |

## Phase 3 銜接點

- **M1–M3 多組獨立記憶體從「未排入任何 Phase」移入 Phase 3**（原本它出現在 PRD:23 卻不在四期路線圖任何一處，屬孤兒需求）。Phase 3 已有歷史紙帶＋本地儲存的工作量，記憶體與之共享同一持久化決策最省。需同步改 AGENTS.md 路線圖。
- `SettingsRepository` 是 `shared_preferences` 唯一接觸點；Phase 3 引入記錄儲存（`hive_ce`／Isar）時**不要把設定遷過去**（層級不同，見「依賴政策」）。
- Phase 3 紙帶要記錄「捨入後的值」—— 因 D1 鏈捨入，`_entry`／`_accumulator` 已是機台語意的最終值，直接記錄即可，不需回溯未捨入的中間值；但 Tax／MU 的中間值若要進紙帶，需要一組新的 debug 級資料，屆時再評估。
- 擬真主題（Phase 4）會需要第二套 `ThemeData` 與橫式展開按鍵；Phase 2 的 5×5 矩陣是它的基础，不要預先抽兩套佈局。
