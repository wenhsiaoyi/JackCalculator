# Jack計算機 多國語系（i18n）設計

> 狀態：待使用者 review（2026-10-20 brainstorming；§1 架構已口頭核准，全文於本文件送審）
> 需求來源：使用者要求「增加多國語系的功能，在設定提供 English／簡體中文／繁體中文 切換」
> 分支：`feat/i18n`（自 main @ `37507b0`）

## 背景與動機

目前所有使用者可見的文字是 hardcode 的台灣正體字串，只散在三個檔共 11 條：`lib/main.dart`（`MaterialApp.title`）、`lib/views/settings_screen.dart`（8 條，其中 `小數位` 有兩個變體）、`lib/views/components/status_indicator.dart`（`{n}位` 與分隔符）。鍵盤按鍵標籤（`AC C ± ÷ 7…0 . ⌫ =`、`GT MU Tax+ Tax−`）與顯示屏的 `Error` 是符號／機器詞，與語系無關。

本輪要建立的是一個**後面每個 Phase 都得依賴的機制**（Phase 3 的歷史紙帶與匯出會帶來大批字串），所以走完整子系統設計，而不是把三行字串改成三元運算子。

## 範圍（IN）

1. `AppLocale` 語系模型（English／簡體／繁體）與**純函式**的系統語系解析。
2. 語系選擇的持久化（含「跟隨系統」＝不存值）。
3. 手寫字串目錄 `AppStrings`，三語對照，替換現有 11 條 hardcode 字串（＋2 條新的語言選單字串，共 13 條）。
4. 設定頁新增「語言」選單（4 個選項）。
5. 引入 `flutter_localizations`，讓 Material 內建文字跟著走（稅率輸入框長按時那列 Cut／Copy／Paste 現在是英文，頁面卻是中文）。
6. 既有測試的語系固定，以及新增解析表／持久化／三語渲染的測試。
7. AGENTS.md 對帳：為 `flutter_localizations` 與 zh-Hans 文案補政策說明。

## 非目標（OUT）

- **各平台原生啟動器名稱**：Android `android:label`、iOS `CFBundleDisplayName`、Windows `windows/runner/main.cpp` 的視窗標題。那是原生資源，Dart 管不到，要做得寫各平台自己的多語資源檔。本輪一律維持「Jack計算機」。
- **不做在地數字格式**：千分位維持 Phase 2 裁定的「僅國際分位」（三個一組、`,`），不因語系改用其他分組習慣；小數點一律 `.`。
- **不做 RTL、不做時區／日期**：本輪三語都是 LTR，且 App 內沒有日期顯示。
- **不引入 `gen-l10n`／`.arb`，不在 `pubspec.yaml` 宣告 `intl`**：字串表面只有 13 條，工具化的收益（缺譯檢查、ICU 複數）換不成「多一個 codegen 步驟＋多一條宣告依賴」的成本。本輪以手寫目錄＋測試守住完整性。
- **不動 `AppTheme`、版面、引擎語意**：`lib/engine/` 與 `lib/core/number_format.dart` 零改動。
- **不做語言切換動畫或重啟提示**。

## 設計定案（D 決議）

- **D1 語系不進 `CalcSettings`。** 新增 `lib/core/app_locale.dart`：`enum AppLocale { english, simplified, traditional }`，自帶 `Locale get locale`、`String get prefsCode`、`static AppLocale? fromPrefsCode(String? code)`。理由：`CalcSettings` 是引擎吃的值物件，讓 `lib/engine/` 認識 UI 語系是反向依賴。放 `lib/core/` 是因為它同時被 `data/`、`bloc/`、`views/` 需要。
- **D2 獨立的 `LanguageCubit`，state 是 `AppLocale?`，`null` 代表「跟隨系統」。** 新增 `lib/bloc/language_cubit.dart`，結構沿用 `SettingsCubit`：建構時非阻塞載入、`_update` 先 `emit` 再 `unawaited(save)`。選「跟隨系統」時 `remove` 持久化 key。
- **D3 持久化沿用 `SettingsRepository`，不另開 repo。** 該類別的檔頭註解自稱「`shared_preferences` 在整個 repo 內唯一的接觸點」，本輪把這句話改成「設定與語系兩個聚合的共同接觸點」，並加 `languageKey = 'app_locale'`、`loadLanguage() → AppLocale?`、`saveLanguage(AppLocale?)`。讀到壞值／未知 code／平台異常一律回 `null`（＝跟隨系統），不拋——和現行 `load()` 退回 defaults 的作風一致。`SettingsRepository` 是 `const` 且無狀態，`LanguageCubit` 與 `SettingsCubit` 各持一個實例不產生競態（寫的是不同的 key）。
- **D4 取用方式：不建自訂 delegate，視圖直接查表。** 一律寫 `AppStrings.of(Localizations.localeOf(context))`。理由：`Localizations.localeOf` 回報的是 Flutter **最終實際採用**的 locale，比讓每個視圖去 `watch<LanguageCubit>` 更權威，也讓視圖層不認識 cubit。`AppStrings.of(locale)` 對任何沒有對照表的 locale 一律退回 English，所以不依賴 `supportedLocales` 的解析結果也不會拿到 null。
  **已知前提**：需要祖先有 `Localizations` widget。`MaterialApp` 一定裝一個；測試裡裸 `MaterialApp(home: …)` 的 harness（現有 `CalcButton` 那幾條）照樣可用，不需改。
- **D5 語系解析自己寫，不交給 Flutter 的 matcher。** 純函式 `AppLocale resolveFrom(Iterable<Locale?> systemLocales)`（放 `app_locale.dart`，忽略清單中的 `null`），規則依序：
  1. 照系統偏好清單的順序走，第一個命中的算。
  2. `languageCode == 'zh'` 且（`scriptCode == 'Hant'` 或 `countryCode ∈ {TW, HK, MO}`）→ traditional。
  3. `languageCode == 'zh'` 且（`scriptCode == 'Hans'` 或 `countryCode ∈ {CN, SG}` 或**沒有 script 也沒有 country**）→ simplified。
  4. 其他任何語系 → english；清單空 → english。

  之所以不用 Flutter 內建的 `BasicMessageLocaleMatcher`：系統回報 `zh_TW`（無 scriptCode）時，`zh_Hant` 與 `zh_Hans` 兩個候選同分，取捨落到 `supportedLocales` 的順序，而預設順序是字母序（`zh_Hans` 在前）→ 台灣裝置會被解析成簡體。自己解析才能把 `TW/HK/MO` 與裸 `zh` 分開，也才能寫成不需要 context 的單元測試。
- **D6 `MaterialApp` 接線。** `MultiBlocProvider`（已在 `MaterialApp` 之上）加 `LanguageCubit`，外面包一層 `BlocBuilder<LanguageCubit, AppLocale?>` 回傳 `MaterialApp`：
  - `locale: selected?.locale`（null 就讓 resolution callback 決定）
  - `supportedLocales: const [Locale('en'), Locale('zh', 'Hans'), Locale('zh', 'Hant')]`
  - `localizationsDelegates:` `GlobalMaterialLocalizations.delegate`、`GlobalWidgetsLocalizations.delegate`、`GlobalCupertinoLocalizations.delegate`（Cupertino 也要：iOS 上 `AdaptiveTextSelectionToolbar` 走 Cupertino 的文字選取工具列）
  - `localeListResolutionCallback: (locales, supported) => resolveFrom(locales ?? const <Locale?>[]).locale`
  - `title:` 用 `AppStrings.of((selected ?? resolveFrom(WidgetsBinding.instance.platformDispatcher.locales)).locale).appTitle`；`MaterialApp` 上面沒有 `Localizations` 可讀，所以要自己讀系統語系清單。**必須走 `WidgetsBinding.instance.platformDispatcher`，不能用 `ui.PlatformDispatcher.instance`** —— 後者在 widget 測試裡不會被 `TestPlatformDispatcher` 換掉，等於測試測不到這條路徑。

  **切語系不會被弹出設定頁。** `BlocBuilder` 換的是同一個位置的同一個 `MaterialApp` 型別，element 原地更新 → 它內部的 `Navigator` state 保留，`_openSettings()` 那條 `Navigator.push` 的 route 不受影響，改變的只有 `Localizations` 底下的 locale。這是 Flutter 的標準切語系路徑，**但必須由測試 7 實際證明**（選完語言仍停在設定頁），不能只靠這段推理。
- **D7 語言選單用 `SegmentedButton<AppLocale?>`，並 `scrollable: true`。** segments 依序為「跟隨系統／English／繁體中文／简体中文」，`showSelectedIcon: false`，`onSelectionChanged` 取 `.first` 丟給 `LanguageCubit`；值型別是可空 enum，`null` 就是第一個 segment。**必須 `scrollable: true`**：361dp 手機寬下四個長標籤塞不進一整列，會 overflow（本專案對 overflow 零容忍，見既有窄窗測試）。
- **D8 語言選項的 self-denomination 規則**：`English`／`繁體中文`／`简体中文` 三個標籤在**三種語系下都不翻**，一律以該語言自己的書寫系統呈現（讓使用者挑自己看得懂的那個）；只有「跟隨系統」會被翻譯（繁→「跟隨系統」、简→「跟随系统」、英→「System」）。繁體／簡體標籤的**字形差異是刻意的**（「繁體中文」vs「简体中文」），不是錯字。
- **D9 錯誤訊息存「原因」不存「字串」。** `SettingsScreen` 現行的 `_taxError` 存的是已渲染好的中文，切語系後會留一條舊語言的錯誤文字。本輪改成 `bool _taxInvalid`，`errorText: _taxInvalid ? strings.taxRateError : null`，讓它跟 locale 一起重渲染。這是 i18n 的標準錯誤類別，順手在地改掉。
- **D10 `Error` 保持不譯。** `CalculatorEngine.display` 在錯誤時回 `'Error'`。要在地化它就得把字串目錄塞進引擎（純 Dart、無 context），違反 D1 的隔離原則；商用機顯示屏上的 `E/Error` 本來就是機器詞。維持原樣，並在 spec 與程式註解記一筆。同理鍵盤符號標籤（`AC`／`⌫`／`Tax−`）與 `GT` 徽章全部不動 → `lib/views/calculator_screen.dart`、`calc_button.dart`、`display_screen.dart` **零改動**。
- **D11 依賴：只加 `flutter_localizations`（`sdk: flutter`）。** 它是 Flutter 官方 SDK 套件、純 Dart、非 plugin、四平台（含 Windows）皆可建置、不需 codegen → 通過 AGENTS.md 依賴政策的三關。它 pin `intl: ^0.20.3`，本專案會把 `intl` 帶成 transitive，但**不在 `pubspec.yaml` 宣告**（我們的程式不 import 它）。AGENTS.md 既有「不要用 `intl` 的 `NumberFormat` 做千分位」維持有效——那條禁的是用途，不是套件存在。
  **實作時要先驗證**：加完 `flutter_localizations` 後 `flutter pub get` 能否乾淨解析。若 pub 或 analyzer 要求宣告 `intl`，就加 `intl: ^0.20.3` 並把這條記進 AGENTS.md；不能假設一定能免。
- **D12 APK 體積增量。** `flutter_localizations` 帶入所有 locale 的 Material 翻譯碼。本輪不設門檻，但終驗時要記錄 `flutter build apk` 的實際大小增量（基線 47.1MB），寫進 AGENTS.md 對帳，讓後續 Phase 知道代價。

## 字串目錄（`lib/core/app_strings.dart`）

`AppStrings` 是 immutable 類別，三個具名 factory（`AppStrings.english／.simplified／.traditional`）＋ `static AppStrings of(Locale l)`。下面 13 條是**完整**清單，實作時逐條照抄；zh-Hans 依 2026-10-20 裁定採**道地大陸用語**（「输入／范围／设置／语言／跟随系统」），不是繁簡字形轉換。

| # | key | zh-Hant（現行） | zh-Hans | English |
|---|---|---|---|---|
| 1 | appTitle | Jack計算機 | Jack计算器 | Jack Calculator |
| 2 | settingsTitle | 設定 | 设置 | Settings |
| 3 | taxRateLabel | 稅率 (%) | 税率 (%) | Tax rate (%) |
| 4 | taxRateHelper | 範圍 0–100，最多一位小數 | 范围 0–100，最多一位小数 | Range 0–100, up to 1 decimal |
| 5 | taxRateError | 請輸入 0–100、最多一位小數 | 请输入 0–100，最多一位小数 | Enter 0–100 with at most 1 decimal |
| 6 | roundingMode | 捨入模式 | 舍入模式 | Rounding mode |
| 7 | decimalPlaces | 小數位 | 小数位数 | Decimal places |
| 8 | decimalPlacesInactive | 小數位（F 模式下無效） | 小数位数（F 模式下无效） | Decimal places (off in F mode) |
| 9 | grouping | 千分位 | 千分位 | Thousands separator |
| 10 | indicatorPlaces(n) | `{n}位` | `{n}位` | `{n} dp` |
| 11 | indicatorSeparator | `  ｜  ` | `  ｜  ` | `   \|   ` |
| 12 | languageLabel | 語言 | 语言 | Language |
| 13 | languageSystem | 跟隨系統 | 跟随系统 | System |

三條 self-denomination 標籤（`繁體中文`／`简体中文`／`English`）依 D8 不入對照表，直接當常數，避免被誤「翻譯」。

**標點**：全形標點只用於中文；zh-Hans 跟大陸的標點習慣——第 5 條繁體「0–100、最多」的頓號在簡體改成「，」是刻意的。中英文之間加半形空格（`稅率 (%)`、`F 模式`）。

## 測試策略

**既有 146 條測試的影響面（已逐條核對）**：含中文的 assert 有 2 檔 7 條，但**真的會紅的只有 4 條**——`test/widget_test.dart` 的 `indPlaces`『2位』與「⚙ 導航到設定頁」的『設定』『捨入模式』，加上 `test/settings_screen_test.dart` 的稅率錯誤訊息。另外 4 條（`find.text('進階')`／`find.text('收起')`）是 `findsNothing` 的殭屍断言，任何語系下都永遠成立，不必動。`find.text('AC')`／`find.text('2')`／`find.text('GT')` 是符號標籤，不受影響；`find.byKey` 系全部不受影響。

1. **新增 `test/` 小工具**：`pumpApp(tester, {List<Locale> locales})`，內部先 `SharedPreferences.setMockInitialValues({})`、設 `tester.platformDispatcher.locales`、再 `pumpWidget(const JackCalculator())` ＋ `pumpAndSettle()`。走**真實解析路徑**，而不是塞一個 test-only locale 參數進 `JackCalculator`——這樣測到的是 D5 的規則本身。
2. **改 7 條中文斷言**：一律改用 `pumpApp(…, locales: [const Locale('zh', 'TW')])`，斷言內容不變。不新增「中文模式」以外的分支。
3. **新增 `test/app_locale_test.dart`**（純單元，無 widget）：D5 的解析表逐條——`zh_TW`／`zh_HK`／`zh_MO`／`zh_Hant` → traditional；`zh`（裸）／`zh_CN`／`zh_SG`／`zh_Hans` → simplified；`ja`／`fr`／空清單／含 `null` → english；偏好清單順序優先（`[en, zh_TW]` → english）。
4. **新增 `test/language_cubit_test.dart`**：預設 `null`；`setLanguage(AppLocale.simplified)` 後重建 cubit 會讀回；`setLanguage(null)` 會移除 key（用 `SharedPreferences.getInstance()` 查 `containsKey('app_locale')`）；寫入壞值退回 `null`。
5. **`test/settings_repository_test.dart` 新增語系 group**：`loadLanguage`／`saveLanguage` 的往返與壞值。
6. **三語渲染測試**（加進 `test/widget_test.dart`，或檔太長就開 `test/i18n_render_test.dart`）：同一條「開啟設定頁」流程分別用 en／zh-Hans／zh-Hant 跑，斷言 `find.text('Settings')`／`find.text('设置')`／`find.text('設定')` 各命中。另加一條：鎖 2 位時 indicator 在英文下顯示 `2 dp`。
7. **語言選單測試**：四個選項存在；361dp 手機尺寸下不 overflow（沿用既有窄窗測試的寫法 `tester.view.physicalSize = const Size(361, 794)`）；選「简体中文」後**仍停在設定頁**且標題變成「设置」（這條同時證明 D6 的 route 保留推論）；重進 App 仍是簡體（持久化）；選「跟隨系統」後回到系統語系。
8. **delegates 冒煙測試**：三語下各開一次設定頁並檢查 debug console 沒有 `Localizations` 相關的 assert（`flutter_localizations` 認不出某個 locale 時會在 debug 拋）。這條主要在 Windows exe／手機人工驗，自動化只在拿得到 console 輸出時記一筆。
9. **標準檢查**：`flutter analyze` → `flutter test` → `flutter build windows` → `flutter build apk`，一律看輸出字串（`No issues found!`／`All tests passed!`／`√ Built …`）判定，不看 shell exit code。
10. **Walkthrough 交付**：使用者親跑 Windows exe（預設慣例），三語各截一張設定頁＋主屏 indicator；手機端重建 APK 裝到 `ce27901d`，用 adb 截圖存證到 `docs/superpowers/references/i18n/`。

## AGENTS.md 對帳

1. 「中文用語規範（台灣正體）」加豁免：**該規範管的是開發產出（文件、註解、commit）與繁體 UI**；zh-Hans 的 UI 文案依 2026-10-20 裁定採道地大陸用語，不算違規。掃描詞彙表 `cn` 欄時要跳過 `app_strings.dart` 的簡體欄。
2. 「依賴政策」記下 `flutter_localizations`（官方 SDK 套件、非 plugin、免 codegen）與其 transitive `intl`（不宣告、不用於千分位）。若 D11 驗證結果需要宣告 `intl`，一併老實寫進去。
3. 「環境」節的一階依賴清單加上 `flutter_localizations`；測試基線數字從 146 更新成實測值。
4. 「App 顯示名稱」節補一句：原生啟動器名稱**不**隨語系變動，只有 Dart 側的 `MaterialApp.title` 會。
5. Phase 路線圖補記本輪：i18n 不屬於任何既有 Phase，是獨立一輪；之後 Phase 3 加字串時一律走 `AppStrings`。

## 驗收標準

- 三語各自渲染：設定頁 13 條（8 條既有＋「語言」標題＋4 個選項，其中 3 個選項依 D8 不翻）、indicator 2 條（`{n}位`／`{n} dp` 與分隔符）、`MaterialApp.title`。
- 預設跟隨系統：zh-TW 裝置→繁中、zh-CN→簡中、英文／日文裝置→English；選過之後重啟保持；選「跟隨系統」能還原。
- 按鍵、顯示屏數字、`Error`、`GT` 徽章在三語下完全一致（證明視圖層未被誤動）。
- `flutter analyze` 乾淨、`flutter test` 全綠（146 條不被破壞＋新增）、Windows build 成功、APK build 成功並記錄大小增量。
- 361dp 手機寬下語言選單無 overflow；切語系後仍停在設定頁。

## 風險

| 風險 | 處置 |
|---|---|
| `flutter_localizations` 讓 pub 解析要求宣告 `intl` | D11 先驗證；真要求就加 `intl: ^0.20.3` 並對帳，不硬猜 |
| Flutter 的 Material 翻譯檔與我們傳的 `Locale('zh', 'Hant')` 對不上 → debug assert | 驗收標準第 8 條專門測它；必要時 `supportedLocales` 改傳 `Locale('zh', 'TW')`（D5 解析表不動） |
| D6「Navigator state 保留」的推論若與實測不符，切語系會掉回主屏 | 測試 7 是硬檢查；真的被弹出才改方案（語言選單搬到主屏，或切完顯示一條提示），本輪不預先建防護 |
| `Localizations` 載入新 locale 是 async，切語系瞬間可能有一幀仍是舊文字 | 屬可接受；walkthrough 顯式看一次不卡死。若明顯閃爍再考慮語言選單的載入態 |
| 未來 Phase 3 字串變多，手寫目錄缺譯無人抓 | 新增 `AppStrings` 完整性測試（三語取同一 key 不得為 null、不得與英文佔位相同）；Phase 3 若超過 40 條字串，重新評估 `gen-l10n`（本輪已在 OUT 記一筆） |
