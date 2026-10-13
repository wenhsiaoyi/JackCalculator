# Jack計算機 — Phase 1 設計規格（MVP 骨架）

日期：2026-10-13
狀態：待使用者 review

## 總覽

商用計算機 App 的第一個可交付里程碑：以 **Cubit** 作狀態管理、**`decimal`** 保證零浮點誤差，完成**現代簡約風格**的鍵盤與顯示屏，並實作加減乘除與清理/退格/正負號。**不含**歷史紙帶、稅率、多組記憶體、GT/MU、擬真主題、匯出——那些留待後續 Phase，各自再走一輪「設計→計畫→實作」。

本里程碑對應 `specs/Flutter細部功能.md` 的 Phase 1，並滿足 `specs/功能需求滿足這樣需求.md` 非功能性需求中的「絕對精確（避免浮點數誤差）」與「離線優先」。

## 範圍

### 在範圍內
- 純計算引擎 `CalculatorEngine`，全程使用 `Decimal`。
- 運算：數字輸入、小數點、`+ − × ÷`、`=`、`AC`（全清）、`C`（清當前輸入）、`⌫`（退格）、`±`（正負號）。
- Cubit 單向事件流，驅動 UI 顯示態。
- 現代簡約 Material 3 UI，深/淺色自適應，直式 4 欄按鍵。
- 引擎單元測試 + 最小煙霧測試。
- 將 App 顯示名稱改為「Jack計算機」。

### 明確不在範圍（YAGNI）
- 狀態以外的持久化（不引入 Hive/Isar）。
- 千分位/多國數位格式（`number_format.dart` 僅預留介面，不實作分位邏輯）。
- 捨入模式（F/CUT/UP/5-4）、小數位鎖定 → Phase 2。
- Tax±、MU、GT、M1–M3 → Phase 2。
- 紙帶歷史、匯出（pdf/csv/share_plus）→ Phase 3。
- 擬真桌上型主題、音效/震動 → Phase 4。

## 技術選型

| 項目 | 決定 | 說明 |
| --- | --- | --- |
| 狀態管理 | **Cubit**（`flutter_bloc`） | 取代 spec 建議的 Provider/Riverpod。 |
| 高精度數學 | **`decimal`** | 禁止用 Dart `double` 做商業計算。 |
| 持久化 | 不引入 | Phase 1 無設定/歷史需儲存。 |
| UI 框架 | Material 3 | 深/淺色自適應。 |
| 建置目標 | Windows（唯一可本機跑） | `flutter run -d windows`；mobile-first 佈局但本機用 Windows 驗證。 |

**新增依賴**：`flutter_bloc`、`decimal`。這兩個會打破目前「零第三方依賴」狀態（AGENTS.md 已記錄），需在 `pubspec.yaml` 加入並 `flutter pub get`。

## 架構

### 資料夾結構
```
lib/
├── core/
│   ├── theme.dart            # Material 3 主題、深/淺色
│   └── number_format.dart    # 顯示格式化介面（Phase 1 僅轉字串，不做千分位）
├── engine/
│   └── calculator_engine.dart  # 純 Dart，不 import Flutter，全程 Decimal
├── bloc/
│   ├── calculator_cubit.dart
│   └── calculator_state.dart
└── views/
    ├── calculator_screen.dart
    └── components/
        ├── calc_button.dart
        └── display_screen.dart
main.dart
```

### 元件職責與邊界
- **`CalculatorEngine`**：封裝所有運算狀態（暫存運算元、待執行運算子、目前輸入）。對外方法對應每個事件，回傳更新後的顯示字串與錯誤旗標。可脫離 Flutter 獨立單元測試。
- **`CalculatorState`**：不可變，欄位 `display`（String）、`hasError`（bool）。engine 內部態不暴露給 UI。
- **`CalculatorCubit`**：持有單一 `CalculatorEngine` 實例；每個 `on*` 事件呼叫 engine 後 `emit` 新 state。是 UI 與 engine 之間唯一的橋。
- **`DisplayScreen`**：讀 state 渲染右對齊大字。
- **`CalcButton`**：可重複使用按鍵元件，承載標籤、樣式變體（數字/運算子/功能/等號）與回呼。
- **`CalculatorScreen`**：組裝顯示屏 + 4 欄按鍵矩陣；用 `BlocBuilder` 訂閱 Cubit。

### 運算語意（連算 = 立即執行）
`2 + 3 × 4 =` → **20**（左到右立即執行，非運算子優先順序）。這符合商用桌上型計算機盲打習慣。

### 錯誤處理
- 除以零：進入錯誤態（`hasError = true`，顯示如 `Error`）；下一次 `AC`/`C` 或任何數字輸入清除錯誤。錯誤態下按運算子不產生新結果。
- 溢位/超長數值：Phase 1 依賴 Decimal 任意精度，不做截斷；僅在顯示寬度上做字體縮放（fit）。

## 資料流

```
使用者點按
  → CalculatorCubit.onDigit/onOperator/onEquals/...
    → CalculatorEngine 更新內部 Decimal 狀態
      → emit(CalculatorState)
        → BlocBuilder 重繪 DisplayScreen
```

## App 顯示名稱改為「Jack計算機」

依 AGENTS.md，需同步更新各平台原生設定（Linux/iOS 本機建置不了，但改原始碼安全）：

| 平台 | 檔案 | 欄位 |
| --- | --- | --- |
| Windows | `windows/runner/main.cpp` | `window.Create(L"Jack計算機", ...)` |
| Windows | `windows/runner/Runner.rc` | ProductName / FileDescription / OriginalFilename 中繼資料 |
| Android | `android/app/src/main/AndroidManifest.xml` | `android:label` |
| iOS | `ios/Runner/Info.plist` | `CFBundleDisplayName` |
| Linux | `linux/runner/my_application.cc` | `gtk_header_bar_set_title` 與 `gtk_window_set_title` 兩處 |

## 測試計畫

- **引擎單元測試**（`test/calculator_engine_test.dart`，重點）：
  - 精度：`0.1 + 0.2 == 0.3`（非 `0.30000000000000004`）。
  - 連續運算立即執行：`2+3×4=` → 20。
  - 除以零進入錯誤態且可被 AC/C/數字清除。
  - `AC` 全清、`C` 只清當前輸入、`±` 正負號、`⌫` 退格。
  - 小數點不可重複、前導零處理。
- ** widget 煙霧測試**：改寫 `test/widget_test.dart`（目前測 counter，會因改動失效，AGENTS.md 已警示）→ 啟動 App、點 `2 + 3 =`、斷言顯示 `5`。
- **標準檢查順序**：`flutter analyze` → `flutter test`（兩者需乾淨通過）。

## 踩坑與約束（來自 AGENTS.md）

- 改 `lib/main.dart` 與 `test/widget_test.dart` 會使舊 counter 測試失效，本里程碑一併改寫。
- 引入 `flutter_bloc`/`decimal` 後 **不要** 順手 `flutter pub upgrade`（`pubspec.lock` 進版控，會產生無關 diff）。
- Windows 是唯一可本機執行的目標；iOS/Linux 建置指令在本機必定失敗。
- PowerShell 下 `flutter` 寫 stderr 可能造成 shell 回報 exit code 1 但實際成功——判成功看有無 `√ Built ...` / `All tests passed!`。

## 未決 / 後續 Phase 銜接點

- `number_format.dart` 僅佔位，Phase 2 再實作千分位與國際/印度分位。
- engine 的捨入/精度控制點預留但不啟用，Phase 2 加 F/CUT/UP/5-4 時擴充。
- 雙主題（擬真 vs 現代）於 Phase 4 以第二套 `ThemeData` 疊加。
