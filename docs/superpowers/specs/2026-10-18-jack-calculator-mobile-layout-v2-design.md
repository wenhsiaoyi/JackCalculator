# Jack計算機 行動裝置版面 v2 設計 — 圓形鍵＋膠囊進階面板

> 狀態：已定案（2026-10-18，brainstorming 逐節核准）
> 前輪：`2026-10-13-jack-calculator-mobile-layout-design.md`（chevron 面板，已併回 main @ 515cfe6）
> 參考截圖：`docs/superpowers/references/mobile-layout-v2/{basic-collapsed, advanced-expanded, overflow-menu}.jpeg`

## 背景與動機

前一輪行動版面（4 欄基本盤＋chevron 面板收 GT/MU/Tax±）已完工併回 main。使用者提供另一款 Android 計算機 app 截圖 3 張，指定採用其「版面的編排及進階版面的處理」作為行動裝置版面的新基線：圓形鍵、頂列 `AC ( ) % ÷`、底列 `0 . ⌫ =`、進階面板以膠囊列展開於基本盤上方並壓縮基本盤、展開時全盤轉膠囊。

本輪是前一輪的迭代而非取代關係：鍵位集合與功能不變，重排編排、引入形狀語言與字級比例，並對齊參考圖的進階面板處理。

## 範圍（IN）

1. 鍵位編排重排：頂列 `AC C ± ÷`、底列 `0 . ⌫ =`。
2. 形狀語言：收起態全盤圓形鍵；展開態全盤膠囊（含進階面板四鍵）。
3. 字級比例：按參考圖量測比例調整（主鍵與面板鍵兩級）。
4. chevron 切換器改無文字小雙箭頭圖示。
5. 純視圖層：只動 `lib/views/`（含 `CalcButton`），引擎、bloc、設定、狀態結構零改動。

## 非目標（OUT — 維持既有延期決議）

- 不加 `%` 鍵、`( )` 鍵：引擎無此功能（括號需運算式求值，屬獨立大工程，將來若要走得另開一輪）。
- 工具列（歷史圖示、⋮ 溢出席單）：歷史圖示屬 Phase 3（歷史紙帶）；溢出席單屬 Phase 3/4。⚙ 維持顯示區頂列左側現狀。
- 深色系配色／視覺皮膚：Phase 4（含第二套 ThemeData）。本輪維持 Material 3 淺色主題與現行按鈕角色色。
- 展開／收合過渡動畫：Phase 4。本輪直切。
- 橫式／寬螢幕展開模式：Phase 4。手機維持直式鎖定（已於 2026-10-14 落地，未併入 main 的 3 個平台檔案維持原狀）。

## 設計定案（L 決議）

- **L1 鍵位對映**：基本盤 4×5 維持；頂列 `AC C ± ÷`（C 占參考圖 `( )` 位、± 占 `%` 位）；底列 `0 . ⌫ =`（⌫ 移至第 3 位，± 離開底列）。面板四鍵 `GT MU Tax+ Tax−` 與順序不變。
- **L2 形狀**：收起態 `CircleBorder`、展開態 `StadiumBorder`，全盤一致（含面板）；由 `expanded` bool 直切，無動畫。圓直徑貼欄寬，列間留參考圖同款間隙；觸控範圍維持整格不縮水（a11y 觸控目標不變，視覺縮小為已知項）。
- **L3 字級**：主鍵（數字、運算子、AC/C/±/⌫/=）fontSize ≈ 鍵高 × 0.60；面板鍵（GT/MU/Tax±）≈ 膠囊高 × 0.34。鍵高沿用 `LayoutBuilder` 自適應，字級跟鍵高走比例；外層 `FittedBox(scaleDown)` 保險，絕不 overflow。比例量自參考圖（鍵 ≈200px、字形 ≈85px → 字形高 ≈ 鍵高 42–45%，換算 em ≈ 0.60）。實作時於模擬器上視覺校準一次。
- **L4 chevron**：28dp 細條置中不變；「進階／收起」文字與單箭頭改為無文字小雙箭頭圖示（參考圖 ⌃⌄ 款式）；`Key('advancedToggle')` 保留。
- **L5 面板**：`GT MU Tax+ Tax−` 1 列膠囊列於 chevron 之下、基本盤之上；列高與基本盤列均分（沿用 Expanded 自適應）；展開插入、收合移除，壓縮機制沿用前一輪。面板狀態不持久化（每次啟動收起）。
- **L6 寬窗**：整欄置中限寬 420dp 不變；320dp 窄窗 overflow 防護（FittedBox/自適應）沿用並重驗展開態 6 列（面板 1＋基本盤 5）。
- **L7 驗證**：126 測試基線對帳＋新增 widget 測試；`flutter analyze`／`flutter test`／`flutter build windows`／`flutter build apk` 皆以輸出字串判定；Windows exe walkthrough 使用者親跑；開發期模擬器 hot reload 即時監看（jack_android36）；完工交付手機 APK 終驗。分支 `feat/mobile-layout-v2`（自 main @ 515cfe6）；不 push。

## 版面規格

收起態（預設，啟動時）：

```
[顯示區：⚙ 頂列左 + GT 徽章頂列右]
[chevron 小雙箭頭（28dp 細條，置中）]
AC   C   ±   ÷
7    8   9   ×
4    5   6   −
1    2   3   +
0    .   ⌫   =
```

展開態：

```
[顯示區同收起態]
[chevron（展開指示）]
GT   MU   Tax+   Tax−      ← 膠囊列
AC   C    ±      ÷        ← 膠囊
7    8    9      ×        ← 膠囊
4    5    6      −        ← 膠囊
1    2    3      +        ← 膠囊
0    .    ⌫      =        ← 膠囊
```

- 按鈕角色色（function/operator/equals/number）與淺色主題維持現行，不隨形狀改變。
- 顯示區、StatusIndicator、設定頁：本輪零改動。

## 測試計畫

**對帳既有 126 個測試**：僅鍵位位置／標籤相關的 widget 斷言受編排影響（±、⌫ 移位），逐個更新；引擎行為測試零改動。

**新增 widget 測試**：

1. 收起態鍵位結構：頂列 `AC C ± ÷`、底列 `0 . ⌫ =` 的位置斷言。
2. 形狀斷言：收起態 `CircleBorder`、展開態全盤 `StadiumBorder`（含面板四鍵）。
3. chevron 無文字：「進階／收起」字樣不存在，`Key('advancedToggle')` 保留。
4. 展開後面板四鍵存在且功能可用（沿用現行 GT/MU/Tax 測試路徑於新位置重打）。
5. 320dp 窄窗展開態不 overflow；寬窗置中限寬 420dp。

測試總數以實測為準，AGENTS.md 於完工時對帳。

## 實作介面提示（給計畫階段）

- `CalcButton` 需新增形狀能力（如 `shape` 參數或 variant 擴充），由 `calculator_screen.dart` 依 `_advancedExpanded` 傳入；字級同步改為依鍵高比例（保留 FittedBox 保險層）。
- 檔案範圍預期：`lib/views/components/calc_button.dart`、`lib/views/calculator_screen.dart`、`test/widget_test.dart`（對帳＋新增）、AGENTS.md（完工對帳）。計畫階段確認，不排除微調。

## 風險與已知項

- 展開態 6 列在 320dp 窄窗高度緊繃：自適應高度＋FittedBox 為既有機制，仍需實測；若真溢出，縮減固定飾件高度（chevron/顯示區 padding），不動列結構。
- 圓形視覺縮小觸控目標感知：觸控仍全格；列入 Phase 4 a11y 清單。
- `overflow-menu.jpeg` 僅作編排參考存檔，其選單內容（清除記錄／選擇主題／隱私權政策／提供意見／說明）本輪不實作。
