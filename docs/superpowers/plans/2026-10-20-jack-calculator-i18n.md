# Jack計算機 多國語系（i18n）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 讓 App 支援 English／簡體中文／繁體中文 三語，預設跟隨系統語系，並可在設定頁切換且持久化。

**Architecture:** 新增 `AppLocale` 語系模型與純函式 `resolveFrom()`（自己解析系統語系，不交給 Flutter 的 matcher）、手寫三語字串目錄 `AppStrings`（視圖用 `AppStrings.of(Localizations.localeOf(context))` 取用）、`LanguageCubit`（state 為 `AppLocale?`，null＝跟隨系統，沿用 `SettingsRepository` 做持久化）。`MaterialApp` 外面包一層 `BlocBuilder` 決定 `locale`／`supportedLocales`／`localizationsDelegates`，並引入 `flutter_localizations` 讓 Material 內建文字同步。按鍵標籤與引擎的 `Error` 是符號詞，不動。

**Tech Stack:** Flutter 3.47.7 / Dart 3.13.5、flutter_bloc（Cubit）、shared_preferences、flutter_localizations（本輪唯一新增依賴）。

**Spec:** `docs/superpowers/specs/2026-10-20-jack-calculator-i18n-design.md`（本計畫是該 spec 的論證；兩份檔要一起讀，D1–D12 是逐條對應的定案）

## Global Constraints

- 分支 `feat/i18n`，自 main @ `37507b0` 開。**只在本機 commit，不 push**——push 需要使用者另行指示。
- Dart SDK `^3.13.5`、Flutter 3.47.7。平台只有 android／ios／windows／linux，**Windows 是唯一能本機跑起來的目標**；不新增 web 或 macos。
- 依賴政策（AGENTS.md）：不引入 build_runner／codegen；本輪只加 `flutter_localizations`（`sdk: flutter`）。**不在 `pubspec.yaml` 宣告 `intl`**（`pubspec.lock` 裡 `intl 0.20.3` 已是 transitive，與 `flutter_localizations` 的 pin 完全一致，Task 1 會驗）。
- 所有中文輸出採**台灣正體用語與全形標點**（檔案／程式／資料／本機／預設／使用者……），中英文之間加半形空格。**唯一豁免**：`app_strings.dart` 的 zh-Hans 欄與測試裡的簡體期望值是**道地大陸用語**，刻意的（spec D8 與「中文用語規範」對帳項）。
- 驗證只看輸出字串，不看 shell exit code：`No issues found!`、`All tests passed!`、`√ Built ...`。Flutter／Gradle 寫 stderr 會讓 PowerShell 報 `NativeCommandError`，那不是失敗。
- 對 overflow **零容忍**：任何新 UI 都要在 361×794dp（手機）與 320×260（極矮視窗）兩種尺寸下不爆紅條。
- **`Locale` 的 import 規則（已查證，彙整檔會絆人）**：`Locale` 定義在 `dart:ui`。`package:flutter/widgets.dart` 有把它轉出（SDK `lib/src/widgets/app.dart:50` 與 `binding.dart:51` 各寫了一次 `export 'dart:ui' show Locale;`），而 `material.dart:200` 又 `export 'widgets.dart'`——**所以凡是 import 了 `package:flutter/material.dart` 的檔案，直接寫 `Locale(...)` 就對了，不要多加 import**。反過來說，**沒 import material 的檔案一定要自己 import `dart:ui`**：本計畫的 `lib/core/app_locale.dart`、`lib/core/app_strings.dart`、`test/app_locale_test.dart`、`test/app_strings_test.dart`、`test/helpers/pump_app.dart` 都是這一類。特別注意 **`package:flutter/painting.dart` 沒有轉出 `Locale`**（SDK `lib/painting.dart:24` 的 show 清單只有 `PlaceholderAlignment, Shadow, TextHeightBehavior, TextLeadingDistribution, kTextHeightNone`），`flutter_test.dart` 也沒有——想用 `painting.dart` 拿 `Locale` 會直接編譯不過。
- **`Locale` 的構造規則（已查證 SDK 原始碼：`c:/tools/flutter/bin/cache/pkg/sky_engine/lib/ui/platform_dispatcher.dart:2893`）**：`const Locale(this._languageCode, [this._countryCode]) : scriptCode = null;`——位置參數**只有兩個**，第三個會編譯不過（`Locale('zh', '', 'TW')` 是錯的，要寫 `Locale('zh', 'TW')`）；第二參數一律落進 `countryCode`，**永遠拿不到 `scriptCode`**。要帶 script 只能用 `Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')`。據此：`AppLocale.locale`、`supportedLocales`、Task 7 的 `MaterialApp(locale:)` 一律用 `fromSubtags`；模擬系統回報的台灣／中國語系用區碼形式 `Locale('zh', 'TW')`／`Locale('zh', 'CN')`，由 `resolveFrom` 的 `countryCode` 分支接手。踩坑後果（已實測確認）：`Locale('zh', 'Hant')` 的 `scriptCode` 是 `null`、`countryCode` 是 `'Hant'`，`resolveFrom` 會把它解析成**簡體**，使用者的繁中設定會被彈回簡體。
- Commit 訊息沿用 repo 既有風格：英文 conventional commits（例：`feat(core): resolve app locale from system language list`）。
- 每個 Task 結束時 `flutter analyze` 與 `flutter test` 都必須是乾淨的；**不得留紅燈進下一個 Task**。基線：146 條測試全綠。

---

### Task 1: 開分支並引入 flutter_localizations

**Files:**
- Modify: `pubspec.yaml`（`dependencies:` 節）
- Modify: `pubspec.lock`（`flutter pub get` 自動寫入，勿手改）

**Interfaces:**
- Consumes: 無
- Produces: 可解析 `package:flutter_localizations/flutter_localizations.dart`（Task 6 起會 import）。後續 Task 用的 `AppLocale`／`AppStrings` 尚未存在。

- [ ] **Step 1: 開分支並確認基線綠**

```bash
cd /e/projects/JackCalculator
git checkout -b feat/i18n
flutter analyze
flutter test
```

Expected: `No issues found!` 與 `All tests passed!`，測試總數 146。若基線不是 146，先停下來回報實際數字，後續 Task 的「+N 條」要以基線為準。

- [ ] **Step 2: 加依賴**

在 `pubspec.yaml` 的 `dependencies:` 裡，把 `flutter_localizations` 加在 `flutter:` 之後（順序照 SDK 套件先列的慣例）：

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # The following adds the Cupertino Icons font to your application.
  # Use with the CupertinoIcons class for iOS style icons.
  cupertino_icons: ^1.0.8
  flutter_bloc: ^9.0.0
  decimal: ^3.2.0
  shared_preferences: ^2.5.6
```

- [ ] **Step 3: 解析依賴並確認不需要宣告 intl**

```bash
flutter pub get
grep -n -A6 "^  intl:" pubspec.lock
grep -n -A5 "^  flutter_localizations:" pubspec.lock
```

Expected: `pub get` 成功；`flutter_localizations` 出現且 `dependency: "direct main"`、來源為 `sdk: flutter`；`intl` 仍是 `dependency: transitive`、version `0.20.3`。
**若 pub 要求宣告 `intl`**（解析失敗或 analyzer 抱怨）：在 `pubspec.yaml` 加 `intl: ^0.20.3`，並在 commit 訊息與 Task 10 的 AGENTS.md 對帳裡老實記錄這個結果——這是 spec D11 保留的應變分支，不要硬改別的版本號。

- [ ] **Step 4: 確認依賴不破壞現有測試**

```bash
flutter analyze
flutter test
```

Expected: 皆綠（還沒有任何程式碼引用它，純驗證解析與建置可行性）。

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "build: add flutter_localizations for multi-language support"
```

---

### Task 2: AppLocale 與系統語系解析

**Files:**
- Create: `lib/core/app_locale.dart`
- Create: `test/app_locale_test.dart`

**Interfaces:**
- Consumes: 無
- Produces:
  - `enum AppLocale { english, simplified, traditional }`，實例成員 `String languageCode`、`String scriptCode`、`String prefsCode`；getter `Locale get locale`；`static AppLocale? fromPrefsCode(String? code)`（未知／null 回 `null`）
  - 頂層函式 `AppLocale resolveFrom(Iterable<Locale?> systemLocales)`（Task 3、6 都呼叫這個，不是呼叫 `AppLocale.resolve`）

- [ ] **Step 1: 寫失敗測試**

`test/app_locale_test.dart`：

```dart
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/core/app_locale.dart';

void main() {
  group('resolveFrom 依偏好清單順序', () {
    test('繁體線索：Hant 腳本或 TW/HK/MO 地區', () {
      expect(resolveFrom([const Locale('zh', 'TW')]), AppLocale.traditional);
      expect(resolveFrom([const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')]), AppLocale.traditional);
      expect(resolveFrom([const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'HK')]), AppLocale.traditional);
      expect(resolveFrom([const Locale('zh', 'MO')]), AppLocale.traditional);
    });

    test('簡體線索：裸 zh、Hans 腳本、CN/SG 地區', () {
      expect(resolveFrom([const Locale('zh')]), AppLocale.simplified);
      expect(resolveFrom([const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans')]), AppLocale.simplified);
      expect(resolveFrom([const Locale('zh', 'CN')]), AppLocale.simplified);
      expect(resolveFrom([const Locale('zh', 'SG')]), AppLocale.simplified);
    });

    test('清單順序優先，未識別的語系繼續往後找', () {
      expect(resolveFrom([const Locale('en'), const Locale('zh', 'TW')]),
          AppLocale.english);
      expect(resolveFrom([const Locale('ja'), const Locale('zh', 'TW')]),
          AppLocale.traditional);
    });

    test('其他語系與空清單退回 english', () {
      expect(resolveFrom([const Locale('ja')]), AppLocale.english);
      expect(resolveFrom([const Locale('fr', 'FR')]), AppLocale.english);
      expect(resolveFrom(<Locale?>[]), AppLocale.english);
      expect(resolveFrom([null]), AppLocale.english);
    });
  });

  group('持久化碼', () {
    test('prefsCode 往返一致，壞值與 null 回 null（跟隨系統）', () {
      for (final l in AppLocale.values) {
        expect(AppLocale.fromPrefsCode(l.prefsCode), l);
      }
      expect(AppLocale.fromPrefsCode('zh'), isNull);
      expect(AppLocale.fromPrefsCode('de'), isNull);
      expect(AppLocale.fromPrefsCode(null), isNull);
    });

    test('locale 帶正確 scriptCode，裸 zh 不帶 script', () {
      expect(AppLocale.traditional.locale, const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'));
      expect(AppLocale.simplified.locale, const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));
      expect(AppLocale.english.locale, const Locale('en'));
    });
  });
}
```

- [ ] **Step 2: 跑測試確認失敗原因正確**

```bash
flutter test test/app_locale_test.dart
```

Expected: 編譯失敗，訊息含 `Target of URI doesn't exist: 'package:jack_calculator/core/app_locale.dart'`。（若是其他錯誤，先修錯誤，不要直接跳到 Step 3。）

- [ ] **Step 3: 實作**

`lib/core/app_locale.dart`：

```dart
import 'dart:ui' show Locale;

/// App 語系。UI 層概念，不進引擎吃的 `CalcSettings`（spec D1）。
enum AppLocale {
  english('en', '', 'en'),
  simplified('zh', 'Hans', 'zh_Hans'),
  traditional('zh', 'Hant', 'zh_Hant');

  const AppLocale(this.languageCode, this.scriptCode, this.prefsCode);

  final String languageCode;

  /// 空字串代表不帶 script（例如裸 `zh`）。
  final String scriptCode;

  /// 持久化用的穩定字串碼；enum 改名不會毀掉使用者舊設定。
  final String prefsCode;

  Locale get locale => scriptCode.isEmpty
      ? Locale(languageCode)
      : Locale.fromSubtags(languageCode: languageCode, scriptCode: scriptCode);

  /// 壞值與缺 key 一律回 `null`，語意是「跟隨系統」（spec D2／D3）。
  static AppLocale? fromPrefsCode(String? code) {
    for (final locale in AppLocale.values) {
      if (locale.prefsCode == code) return locale;
    }
    return null;
  }
}

/// 從系統偏好清單解析語系（spec D5）。不交給 Flutter 的 matcher：
/// 系統回報 `zh_TW`（無 scriptCode）時 `zh_Hans` 與 `zh_Hant` 同分，
/// 會按 supportedLocales 的字母序誤解析成簡體。
AppLocale resolveFrom(Iterable<Locale?> systemLocales) {
  for (final locale in systemLocales.whereType<Locale>()) {
    if (locale.languageCode == 'en') return AppLocale.english;
    if (locale.languageCode != 'zh') continue;
    final region = locale.countryCode;
    final isHant = locale.scriptCode == 'Hant' ||
        region == 'TW' ||
        region == 'HK' ||
        region == 'MO';
    return isHant ? AppLocale.traditional : AppLocale.simplified;
  }
  return AppLocale.english;
}
```

- [ ] **Step 4: 跑測試確認通過**

```bash
flutter test test/app_locale_test.dart
```

Expected: `All tests passed!`（6 條）。

- [ ] **Step 5: 標準檢查後 commit**

```bash
flutter analyze
flutter test
git add lib/core/app_locale.dart test/app_locale_test.dart
git commit -m "feat(core): add AppLocale with explicit system locale resolution"
```

Expected: `No issues found!`、`All tests passed!`（152 條＝基線 146＋新 6）。

---

### Task 3: AppStrings 三語字串目錄

**Files:**
- Create: `lib/core/app_strings.dart`
- Create: `test/app_strings_test.dart`

**Interfaces:**
- Consumes: `AppLocale`、`resolveFrom(Iterable<Locale?>)`（Task 2）
- Produces: `class AppStrings`，13 個 `String` 欄位：`appTitle`、`settingsTitle`、`taxRateLabel`、`taxRateHelper`、`taxRateError`、`roundingMode`、`decimalPlaces`、`decimalPlacesInactive`、`grouping`、`placesSuffix`、`indicatorSeparator`、`languageLabel`、`languageSystem`；`static const AppStrings english／simplified／traditional`；`static AppStrings of(Locale)`；`static const String languageEnglish／languageTraditional／languageSimplified`（Task 7、8、9 全部讀這些）

**與 spec 字串目錄表的一處命名差異（不是漏實作）**：spec 第 10 條寫的是 `indicatorPlaces(n)`——一個帶參數的渲染函式。本計畫拆成 `placesSuffix`（只有後綴「位」／「 dp」），因為 `StatusIndicator` 手邊已經有 `settings.decimalPlaces` 可拼，多一層函式只是把拼接從視圖搬到目錄、拿不到額外好處。語意完全相同（`'$n${placesSuffix}'` ≡ `indicatorPlaces(n)`），spec 第 11 條的 `indicatorSeparator` 則照原名實作。 reviewer 對帳時這條算「實作層微調」，不要當偏離 spec。

- [ ] **Step 1: 寫失敗測試**

`test/app_strings_test.dart`：

```dart
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/core/app_strings.dart';

/// 13 個欄位的存取器，讓下面兩個測試不用逐條複製。
final Map<String, String Function(AppStrings)> _fields = {
  'appTitle': (s) => s.appTitle,
  'settingsTitle': (s) => s.settingsTitle,
  'taxRateLabel': (s) => s.taxRateLabel,
  'taxRateHelper': (s) => s.taxRateHelper,
  'taxRateError': (s) => s.taxRateError,
  'roundingMode': (s) => s.roundingMode,
  'decimalPlaces': (s) => s.decimalPlaces,
  'decimalPlacesInactive': (s) => s.decimalPlacesInactive,
  'grouping': (s) => s.grouping,
  'placesSuffix': (s) => s.placesSuffix,
  'indicatorSeparator': (s) => s.indicatorSeparator,
  'languageLabel': (s) => s.languageLabel,
  'languageSystem': (s) => s.languageSystem,
};

void main() {
  test('of() 對映三個語系，未知 locale 退回 english', () {
    expect(AppStrings.of(const Locale('en')), AppStrings.english);
    expect(AppStrings.of(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans')), AppStrings.simplified);
    expect(AppStrings.of(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')), AppStrings.traditional);
    // 解析規則本身在 app_locale_test 測；這裡只確認 fallback 不拋、不回 null。
    expect(AppStrings.of(const Locale('und')), AppStrings.english);
    expect(AppStrings.of(const Locale('zh', 'TW')), AppStrings.traditional);
  });

  test('每個欄位在三語下都已填（不允許空字串）', () {
    for (final catalog in [
      AppStrings.english,
      AppStrings.simplified,
      AppStrings.traditional,
    ]) {
      for (final entry in _fields.entries) {
        expect(entry.value(catalog).trim(), isNotEmpty, reason: entry.key);
      }
    }
  });

  test('繁簡只差在字形：刻意相同的三欄以外不得相同', () {
    const sharedByDesign = {'grouping', 'placesSuffix', 'indicatorSeparator'};
    for (final entry in _fields.entries) {
      final hant = entry.value(AppStrings.traditional);
      final hans = entry.value(AppStrings.simplified);
      if (sharedByDesign.contains(entry.key)) {
        expect(hans, hant, reason: '${entry.key} 繁簡本就同字');
      } else {
        expect(hans, isNot(hant), reason: '${entry.key} 繁簡應有差異');
      }
    }
  });

  test('英文目錄不與任一中文目錄撞字', () {
    for (final entry in _fields.entries) {
      final en = entry.value(AppStrings.english);
      expect(en, isNot(entry.value(AppStrings.traditional)), reason: entry.key);
      expect(en, isNot(entry.value(AppStrings.simplified)), reason: entry.key);
    }
  });

  test('語言選項標籤三語都不翻（spec D8）', () {
    expect(AppStrings.languageEnglish, 'English');
    expect(AppStrings.languageTraditional, '繁體中文');
    expect(AppStrings.languageSimplified, '简体中文');
  });

  test('zh-Hans 用道地大陸用語，不是繁簡字形轉換', () {
    expect(AppStrings.simplified.settingsTitle, '设置');
    expect(AppStrings.simplified.taxRateError, contains('请输入'));
    expect(AppStrings.simplified.decimalPlaces, '小数位数');
    expect(AppStrings.simplified.languageSystem, '跟随系统');
  });
}
```

- [ ] **Step 2: 跑測試確認失敗**

```bash
flutter test test/app_strings_test.dart
```

Expected: 編譯失敗 `Target of URI doesn't exist: '.../core/app_strings.dart'`。

- [ ] **Step 3: 實作**

`lib/core/app_strings.dart`。13 條內容逐條照抄 spec 的字串目錄表，不要自己重新翻譯：

```dart
import 'dart:ui' show Locale;

import 'app_locale.dart';

/// 三語字串目錄（spec D4：不建 Localizations delegate，視覺層直接查表）。
/// 新增字串時三份都要補，`test/app_strings_test.dart` 會抓到漏填。
class AppStrings {
  const AppStrings({
    required this.appTitle,
    required this.settingsTitle,
    required this.taxRateLabel,
    required this.taxRateHelper,
    required this.taxRateError,
    required this.roundingMode,
    required this.decimalPlaces,
    required this.decimalPlacesInactive,
    required this.grouping,
    required this.placesSuffix,
    required this.indicatorSeparator,
    required this.languageLabel,
    required this.languageSystem,
  });

  /// `MaterialApp.title`；原生啟動器名稱不受它影響（spec OUT 項）。
  final String appTitle;
  final String settingsTitle;
  final String taxRateLabel;
  final String taxRateHelper;
  final String taxRateError;
  final String roundingMode;
  final String decimalPlaces;
  final String decimalPlacesInactive;
  final String grouping;

  /// 小數位數後綴：中文「2位」、英文「2 dp」，由 StatusIndicator 拼接。
  final String placesSuffix;

  /// 狀態列分隔符：中文用全形｜，英文用半形直線加空格。
  final String indicatorSeparator;

  final String languageLabel;

  /// 唯一會被翻譯的語言選項；其餘三個是自稱，見下方常數。
  final String languageSystem;

  static const String languageEnglish = 'English';
  static const String languageTraditional = '繁體中文';

  /// 刻意寫簡體：語言選項以該語言自己的書寫系統呈現（spec D8），不是錯字。
  static const String languageSimplified = '简体中文';

  static const AppStrings english = AppStrings(
    appTitle: 'Jack Calculator',
    settingsTitle: 'Settings',
    taxRateLabel: 'Tax rate (%)',
    taxRateHelper: 'Range 0–100, up to 1 decimal',
    taxRateError: 'Enter 0–100 with at most 1 decimal',
    roundingMode: 'Rounding mode',
    decimalPlaces: 'Decimal places',
    decimalPlacesInactive: 'Decimal places (off in F mode)',
    grouping: 'Thousands separator',
    placesSuffix: ' dp',
    indicatorSeparator: '   |   ',
    languageLabel: 'Language',
    languageSystem: 'System',
  );

  static const AppStrings simplified = AppStrings(
    appTitle: 'Jack计算器',
    settingsTitle: '设置',
    taxRateLabel: '税率 (%)',
    taxRateHelper: '范围 0–100，最多一位小数',
    taxRateError: '请输入 0–100，最多一位小数',
    roundingMode: '舍入模式',
    decimalPlaces: '小数位数',
    decimalPlacesInactive: '小数位数（F 模式下无效）',
    grouping: '千分位',
    placesSuffix: '位',
    indicatorSeparator: '  ｜  ',
    languageLabel: '语言',
    languageSystem: '跟随系统',
  );

  static const AppStrings traditional = AppStrings(
    appTitle: 'Jack計算機',
    settingsTitle: '設定',
    taxRateLabel: '稅率 (%)',
    taxRateHelper: '範圍 0–100，最多一位小數',
    taxRateError: '請輸入 0–100、最多一位小數',
    roundingMode: '捨入模式',
    decimalPlaces: '小數位',
    decimalPlacesInactive: '小數位（F 模式下無效）',
    grouping: '千分位',
    placesSuffix: '位',
    indicatorSeparator: '  ｜  ',
    languageLabel: '語言',
    languageSystem: '跟隨系統',
  );

  /// 沒有對照表的 locale 一律退回 English，所以呼叫端不必先檢查支援與否。
  static AppStrings of(Locale locale) => switch (resolveFrom([locale])) {
        AppLocale.english => english,
        AppLocale.simplified => simplified,
        AppLocale.traditional => traditional,
      };
}
```

- [ ] **Step 4: 跑測試確認通過**

```bash
flutter test test/app_strings_test.dart
```

Expected: `All tests passed!`（6 條）。若「繁簡只差在字形」那條報 `languageSystem` 相同之類，代表某欄兩份目錄被打成同一份，照 spec 表改正，**不要放寬斷言**。

- [ ] **Step 5: 標準檢查後 commit**

```bash
flutter analyze
flutter test
git add lib/core/app_strings.dart test/app_strings_test.dart
git commit -m "feat(core): add three-locale AppStrings catalog"
```

Expected: analyze 綠；測試 158 條＝基線 146＋6＋6。

---

### Task 4: SettingsRepository 的語系持久化

**Files:**
- Modify: `lib/data/settings_repository.dart`（檔頭註解、常量區、`save()` 之後新增兩個方法）
- Modify: `test/settings_repository_test.dart`（檔尾新增一個 group）

**Interfaces:**
- Consumes: `AppLocale.prefsCode`、`AppLocale.fromPrefsCode(String?)`（Task 2）
- Produces: `static const String SettingsRepository.languageKey`（值 `'app_locale'`）、`Future<AppLocale?> loadLanguage()`、`Future<void> saveLanguage(AppLocale?)`（Task 5 的 `LanguageCubit` 只依賴這三個）

- [ ] **Step 1: 寫失敗測試**

在 `test/settings_repository_test.dart` 的 `main()` 內、最後一個 `group` 之後新增：

```dart
  group('語系持久化', () {
    test('沒寫過就回 null（跟隨系統）', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await const SettingsRepository().loadLanguage(), isNull);
    });

    test('save 後可讀回同一個 AppLocale', () async {
      SharedPreferences.setMockInitialValues({});
      const repo = SettingsRepository();
      for (final locale in AppLocale.values) {
        await repo.saveLanguage(locale);
        expect(await repo.loadLanguage(), locale);
      }
    });

    test('存 null 會移除 key，不是寫空字串', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'zh_Hant'});
      const repo = SettingsRepository();
      await repo.saveLanguage(null);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(SettingsRepository.languageKey), isFalse);
      expect(await repo.loadLanguage(), isNull);
    });

    test('壞值退回 null，不拋', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'klingon'});
      expect(await const SettingsRepository().loadLanguage(), isNull);
    });
  });
```

並在該檔 import 區補上（若還沒有）：

```dart
import 'package:jack_calculator/core/app_locale.dart';
```

- [ ] **Step 2: 跑測試確認失敗**

```bash
flutter test test/settings_repository_test.dart
```

Expected: 編譯失敗，`Method not found: 'SettingsRepository.loadLanguage'`（或 `languageKey` 不存在）。

- [ ] **Step 3: 實作**

`lib/data/settings_repository.dart`：先把檔頭那句「唯一的接觸點」改準，再補 key 與兩個方法。

```dart
/// `shared_preferences` 在整個 repo 內唯一的接觸點，
/// 管計算機設定與語系兩個聚合（語系是 App 層設定，不進 `CalcSettings`）。
///
/// 只存純量；稅率以字串存放以保留 Decimal 精度。
class SettingsRepository {
  const SettingsRepository();

  static const String taxRateKey = 'tax_rate';
  static const String roundingKey = 'rounding_mode';
  static const String decimalPlacesKey = 'decimal_places';
  static const String groupingKey = 'grouping';

  /// 存 `AppLocale.prefsCode`；key 不存在＝跟隨系統。
  static const String languageKey = 'app_locale';
```

在 `save()` 之後、`_normalizePlaces` 之前插入：

```dart
  /// 讀語系；缺 key、壞值、平台異常一律回 `null`（＝跟隨系統），不拋。
  Future<AppLocale?> loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return AppLocale.fromPrefsCode(prefs.getString(languageKey));
    } catch (_) {
      return null;
    }
  }

  /// `null` 代表跟隨系統，此時移除該 key，避免留一個讀不出來的空字串。
  Future<void> saveLanguage(AppLocale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(languageKey);
      return;
    }
    await prefs.setString(languageKey, locale.prefsCode);
  }
```

import 區補：

```dart
import '../core/app_locale.dart';
```

- [ ] **Step 4: 跑測試確認通過**

```bash
flutter test test/settings_repository_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: 標準檢查後 commit**

```bash
flutter analyze
flutter test
git add lib/data/settings_repository.dart test/settings_repository_test.dart
git commit -m "feat(data): persist app language through SettingsRepository"
```

---

### Task 5: LanguageCubit

**Files:**
- Create: `lib/bloc/language_cubit.dart`
- Create: `test/language_cubit_test.dart`

**Interfaces:**
- Consumes: `SettingsRepository.loadLanguage()`／`saveLanguage()`／`languageKey`（Task 4）、`AppLocale`（Task 2）
- Produces: `class LanguageCubit extends Cubit<AppLocale?>`，方法 `void setLanguage(AppLocale? locale)`，初始 state `null`（Task 6、8 讀它）

- [ ] **Step 1: 寫失敗測試**

`test/language_cubit_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/bloc/language_cubit.dart';
import 'package:jack_calculator/core/app_locale.dart';
import 'package:jack_calculator/data/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('初始是 null（跟隨系統），載入完成後讀回持久化值', () async {
    SharedPreferences.setMockInitialValues({SettingsRepository.languageKey: 'zh_Hans'});
    final cubit = LanguageCubit(const SettingsRepository());
    expect(cubit.state, isNull); // emit 是非同步的，建構後還沒讀到
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, AppLocale.simplified);
    await cubit.close();
  });

  test('setLanguage 會 emit 並寫入 prefs', () async {
    SharedPreferences.setMockInitialValues({});
    final cubit = LanguageCubit(const SettingsRepository());
    await Future<void>.delayed(Duration.zero);

    cubit.setLanguage(AppLocale.traditional);
    expect(cubit.state, AppLocale.traditional);

    await Future<void>.delayed(Duration.zero);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SettingsRepository.languageKey), 'zh_Hant');
    await cubit.close();
  });

  test('setLanguage(null) 寫回跟隨系統：key 被移除', () async {
    SharedPreferences.setMockInitialValues({SettingsRepository.languageKey: 'en'});
    final cubit = LanguageCubit(const SettingsRepository());
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, AppLocale.english);

    cubit.setLanguage(null);
    await Future<void>.delayed(Duration.zero);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(SettingsRepository.languageKey), isFalse);
    await cubit.close();
  });

  test('prefs 裡是壞值時 state 退回 null 而不是崩潰', () async {
    SharedPreferences.setMockInitialValues({SettingsRepository.languageKey: 'klingon'});
    final cubit = LanguageCubit(const SettingsRepository());
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isNull);
    await cubit.close();
  });
}
```

- [ ] **Step 2: 跑測試確認失敗**

```bash
flutter test test/language_cubit_test.dart
```

Expected: 編譯失敗 `Target of URI doesn't exist: '.../bloc/language_cubit.dart'`。

- [ ] **Step 3: 實作**

`lib/bloc/language_cubit.dart`（結構與 `SettingsCubit` 一致：非阻塞載入、emit 後 fire-and-forget 儲存）：

```dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/app_locale.dart';
import '../data/settings_repository.dart';

/// 語系的載入與儲存。state 是 `AppLocale?`，`null` 代表跟隨系統（spec D2）。
class LanguageCubit extends Cubit<AppLocale?> {
  LanguageCubit(this._repo) : super(null) {
    _load();
  }

  final SettingsRepository _repo;

  Future<void> _load() async {
    final loaded = await _repo.loadLanguage();
    if (isClosed) return;
    emit(loaded);
  }

  void setLanguage(AppLocale? locale) {
    emit(locale);
    unawaited(_repo.saveLanguage(locale)); // 不等寫入：UI 立刻反映，跟 SettingsCubit 一樣
  }
}
```

- [ ] **Step 4: 跑測試確認通過**

```bash
flutter test test/language_cubit_test.dart
```

Expected: `All tests passed!`（4 條）。若第一條紅在 `expect(cubit.state, isNull)`，代表 `SharedPreferences` 的 mock 在同一 isolate 裡已被前一條測試建立過——`setMockInitialValues` 之後要重新拿 `getInstance()`；本檔每條測試開頭都呼叫 `setMockInitialValues`，照 Step 1 寫就沒事。若紅在 `delayed(Duration.zero)` 之後 state 還是 null，是 `_load()` 的 await 鏈多了一拍，把 `_load()` 裡的等待縮成一次 await（不要改用 `pumpEventQueue` 之類的探測來繞）。

- [ ] **Step 5: 標準檢查後 commit**

```bash
flutter analyze
flutter test
git add lib/bloc/language_cubit.dart test/language_cubit_test.dart
git commit -m "feat(bloc): add LanguageCubit with follow-system null state"
```

---

### Task 6: MaterialApp 接線與測試 pumpApp helper

**Files:**
- Modify: `lib/main.dart`（整檔重寫，見 Step 3）
- Create: `test/helpers/pump_app.dart`
- Modify: `test/widget_test.dart`（`indPlaces` 那條與「⚙ 導航到設定頁」那條改走 helper）

**Interfaces:**
- Consumes: `LanguageCubit`（Task 5）、`resolveFrom`／`AppLocale`（Task 2）、`AppStrings.of`（Task 3）、`flutter_localizations`（Task 1）
- Produces: `Future<void> pumpApp(WidgetTester tester, {List<Locale> locales})`（Task 7、8、9 都用它）；`JackCalculator` 的 `supportedLocales` 為 `[en, zh_Hans, zh_Hant]`

- [ ] **Step 1: 建立 helper**

`test/helpers/pump_app.dart`：

```dart
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 以指定「系統語系」起 App。走真實解析路徑（spec 測試策略 1）：
/// 塞 `TestPlatformDispatcher.localesTestValue`，而不是在 App 裡留 test-only 參數。
/// 不傳 `locales` 時保持 flutter_test 預設（en）。
Future<void> pumpApp(
  WidgetTester tester, {
  List<Locale> locales = const <Locale>[],
}) async {
  SharedPreferences.setMockInitialValues({});
  if (locales.isNotEmpty) {
    tester.platformDispatcher.localesTestValue = locales;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  }
  // 同一條測試內重複呼叫也要重新冷開機：根元件是同一個 const 實例，
  // 不先拆樹的話框架跳過重建，上一輪推起的路由還留在頂端（R11）。
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(const JackCalculator());
  await tester.pumpAndSettle();
}
```

- [ ] **Step 2: 先讓兩條會紅的測試走 helper**

`test/widget_test.dart` import 區補：

```dart
import 'helpers/pump_app.dart';
```

把「indicator 顯示目前設定」測試的開頭三行（`setMockInitialValues`／`pumpWidget`／`pumpAndSettle`）換成：

```dart
    await pumpApp(tester, locales: const [Locale('zh', 'TW')]);
```

把「⚙ 導航到設定頁」同樣的三行換成同一句。其餘測試先不動（符號標籤不受語系影響，`find.text('進階')` 那四條是 `findsNothing` 的殭屍斷言）。

跑一次確認還是綠：

```bash
flutter test test/widget_test.dart
```

Expected: 全綠——因為字串還是 hardcode 中文。這一步只是把語系錨點先放好，讓接下來的在地化改動無處可藏。

- [ ] **Step 3: 重寫 `lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'bloc/calculator_cubit.dart';
import 'bloc/language_cubit.dart';
import 'bloc/settings_cubit.dart';
import 'core/app_locale.dart';
import 'core/app_strings.dart';
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
        BlocProvider(create: (_) => LanguageCubit(const SettingsRepository())),
        BlocProvider(create: (_) => CalculatorCubit()),
      ],
      // 切語系要讓 MaterialApp 換 locale，所以整棵包在 BlocBuilder 裡。
      child: BlocBuilder<LanguageCubit, AppLocale?>(
        builder: (context, selected) {
          final effective = selected ??
              resolveFrom(WidgetsBinding.instance.platformDispatcher.locales);
          return MaterialApp(
            title: AppStrings.of(effective.locale).appTitle,
            locale: selected?.locale,
            supportedLocales: const [
              Locale('en'),
              Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
              Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
            ],
            localeListResolutionCallback: (locales, supportedLocales) =>
                resolveFrom(locales ?? const <Locale?>[]).locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: const CalculatorScreen(),
          );
        },
      ),
    );
  }
}
```

四個注意點（踩過就記在 commit 訊息裡）：
- 一定用 `WidgetsBinding.instance.platformDispatcher.locales`，不是 `ui.PlatformDispatcher.instance.locales`——後者在 widget 測試裡不會被 `TestPlatformDispatcher` 換掉。
- 「跟隨系統」的實作本體是 `locale: selected?.locale` 帶 null。機制（Task 6 reviewer 查證 SDK `localizations.dart:819-825`／`:890-910`）：callback 在 `locale` **非 null 時也會跑**，只是餵進去的是 `[selected.locale]` 而不是系統清單——最後生效的是 callback 的回傳值，不是 `widget.locale` 本身。因為 `resolveFrom` 對自己那三個輸出是冪等，手動選語言不會跑錯目錄，所以行為正確；原本的「null 時才會走」是機制描述不精，非缺陷。
- `LanguageCubit` 與 `SettingsCubit` 各持一個 `const SettingsRepository()`：該類是 const 且無狀態，寫的是不同 key，不需要共用實例。
- **與 spec D6 的一處寫法差異（控制器裁定，不是漏實作）**：spec 第 48 行把 `supportedLocales` 寫成 `Locale('zh', 'Hans')`／`Locale('zh', 'Hant')`，但 `dart:ui` 的 `Locale` 位置參數只有兩個、第二個一律進 `countryCode`（見 Global Constraints 的構造規則），那種寫法拿不到 `scriptCode`，`resolveFrom` 會把繁中解析成簡體。這裡改用 `Locale.fromSubtags(languageCode: 'zh', scriptCode: '…')`，spec 意圖（en／zh-Hans／zh-Hant 三份）完全不變。reviewer 對帳時算實作層修正。

- [ ] **Step 4: 新增 App 層語系測試**

`test/widget_test.dart` 檔尾 `main()` 內新增：

```dart
  testWidgets('預設跟隨系統：zh-TW 裝置顯示繁中 indicator', (tester) async {
    await pumpApp(tester, locales: const [Locale('zh', 'TW')]);
    expect(tester.widget<Text>(find.byKey(const Key('indPlaces'))).data, '2位');
  });

  testWidgets('預設跟隨系統：en 裝置也是同一套符號按鍵', (tester) async {
    await pumpApp(tester, locales: const [Locale('en')]);
    for (final label in ['AC', 'C', '⌫', '÷', '=']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(tester.widget<Text>(find.byKey(const Key('indPlaces'))).data, '2位');
  });

  testWidgets('未識別語系退回 english 渲染', (tester) async {
    await pumpApp(tester, locales: const [Locale('ja', 'JP')]);
    // AppStrings 目錄還沒接進視圖（Task 7），此處只驗解析不炸、按鍵仍在。
    expect(find.text('AC'), findsOneWidget);
  });
```

- [ ] **Step 5: 跑測試並確認綠**

```bash
flutter test
```

Expected: 全綠。`indPlaces` 此刻仍是 hardcode `'2位'`，所以 en 那條也會過——這是預期的，Task 9 會把它改成真的跟語系走。

- [ ] **Step 6: Commit**

```bash
flutter analyze
git add lib/main.dart test/helpers/pump_app.dart test/widget_test.dart
git commit -m "feat(app): wire locale resolution and flutter_localizations into MaterialApp"
```

---

### Task 7: 設定頁改用 AppStrings（含 D9 錯誤原因重構）

**Files:**
- Modify: `lib/views/settings_screen.dart`（`_taxError`→`_taxInvalid`、`build()` 內 8 條字串）
- Modify: `test/settings_screen_test.dart`（稅率錯誤那條要錨定語系，並補一條英文）

**Interfaces:**
- Consumes: `AppStrings`（Task 3）
- Produces: 設定頁所有文字來自 `AppStrings.of(Localizations.localeOf(context))`；`SettingsScreen` 仍是 `const SettingsScreen({super.key})`，Task 8 往同一個 `ListView` 加語言選單

- [ ] **Step 1: 寫失敗測試**

`test/settings_screen_test.dart`：把「合法稅率即時生效、非法稅率顯示錯誤且不寫入 state」那條的 `MaterialApp` 改成明確指定語系（裸 `MaterialApp` 的 `supportedLocales` 只有 en，不寫 `locale` 就永遠是英文），並在檔尾新增一條英文對照：

```dart
  testWidgets('非法稅率提示跟隨 locale：繁中', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final cubit = SettingsCubit(const SettingsRepository());
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
          supportedLocales: const <Locale>[
            Locale('en'),
            Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
          ],
          home: const SettingsScreen(),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('taxRateField')), '150');
    await tester.pump();
    expect(find.text('請輸入 0–100、最多一位小數'), findsOneWidget);
  });

  testWidgets('非法稅率提示跟隨 locale：英文', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final cubit = SettingsCubit(const SettingsRepository());
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          locale: const Locale('en'),
          home: const SettingsScreen(),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('taxRateField')), '150');
    await tester.pump();
    expect(find.text('Enter 0–100 with at most 1 decimal'), findsOneWidget);
  });
```

原本那條「合法稅率即時生效、非法稅率顯示錯誤且不寫入 state」的 `locale:` 也要補 `Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')`（它 assert 的是繁中訊息），**並且同一個 `MaterialApp` 要補上面那組 `supportedLocales`**（見下方 R8）。import 不用動：該檔已經 import `package:flutter/material.dart`，而 `Locale` 正是透過 `material.dart` → `widgets.dart` → `src/widgets/app.dart:50` 的轉出鏈拿到（見 Global Constraints 的 import 規則）。`lib/views/settings_screen.dart` 同樣已 import `material.dart`，也不需要新增 import。

**R8（控制者修正，實測查證）：`MaterialApp` 的測試 harness 只給 `locale:` 不夠，一定要同時給 `supportedLocales:`。** SDK 的 `LocalizationsResolver.locale`（`c:/tools/flutter/packages/flutter/lib/src/widgets/localizations.dart:819-825`）會把 `widget.locale` 再丟進 `_resolveLocales([locale], supportedLocales)`，沒有 callback 時落到 `basicLocaleListResolution`，而它在「清單內無人配對」時一律回 `supportedLocales.first`。裸 `MaterialApp` 的 `supportedLocales` 預設只有 `[Locale('en')]`，本機探針實測 `locale: Locale.fromSubtags(zh, Hant)` 靜默解析成 **`en_US`**（同探針補上 `supportedLocales` 後才是 `zh_Hant`；多出來的 `en_US` 地區是 `TestPlatformDispatcher` 預設 `en-US` 的_country_ 保留）。照舊寫法，繁中那條測試會紅在「看到英文訊息」這個錯原因上。Task 7 三處 harness 都要 `locale` 與 `supportedLocales` 並齊；只 tap `CUT`／`groupingSwitch`、只斷言 Cubit 狀態的那條不受語系影響，維持原樣。
**R8 addendum (實測修正，controller ruling)**: `locale` + `supportedLocales` alone is STILL not enough. A bare `MaterialApp` with no `localizationsDelegates` installs `DefaultMaterialLocalizations`, whose `isSupported()` accepts only `languageCode == 'en'` (verified: `packages/flutter/lib/src/material/app.dart:938` + `material_localizations.dart`), so a `zh-Hant` harness throws `No MaterialLocalizations found`. Every test harness that pins a non-English locale must pass THREE things: `locale`, `supportedLocales` (containing that locale), and the `Global{Material,Widgets,Cupertino}Localizations.delegate` trio from `package:flutter_localizations/flutter_localizations.dart`. Implementers adding the delegates are following this ruling, not exceeding the brief.

- [ ] **Step 2: 跑測試確認失敗**

```bash
flutter test test/settings_screen_test.dart
```

Expected: FAIL —英文那條找到的是 `請輸入 0–100、最多一位小數`（因為還沒接目錄），且報文中能看到 `findsOneWidget` 未命中。若繁中那條也紅，先檢查是不是 `locale` 沒生效。

- [ ] **Step 3: 實作**

`lib/views/settings_screen.dart` 的兩個改動。先是 D9：錯誤狀態改存布林。

```dart
class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _taxController;
  bool _taxInvalid = false;

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
    // 存「原因」不存字串：切語系後舊語言的錯誤訊息不會留著（spec D9）。
    setState(() => _taxInvalid = parsed == null);
    if (parsed == null) return;
    cubit.setTaxRate(parsed);
  }
```

然後 `build()` 頂端取目錄，把 8 條字串換掉（`AppStrings` 之外的佈局、key、`SegmentedButton` 的 `F／CUT／UP／5/4` 與 `0／2／3／4` 都不動——那是符號標籤，spec D10）：

```dart
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final strings = AppStrings.of(Localizations.localeOf(context));
    return Scaffold(
      appBar: AppBar(title: Text(strings.settingsTitle)),
      body: BlocBuilder<SettingsCubit, CalcSettings>(
        builder: (context, settings) {
          final isFloat = settings.rounding == RoundingMode.float;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(strings.taxRateLabel),
              TextField(
                key: const Key('taxRateField'),
                controller: _taxController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) => _onTaxChanged(cubit, value),
                decoration: InputDecoration(
                  errorText: _taxInvalid ? strings.taxRateError : null,
                  helperText: strings.taxRateHelper,
                ),
              ),
              const SizedBox(height: 24),
              Text(strings.roundingMode),
              const SizedBox(height: 8),
              SegmentedButton<RoundingMode>(
                segments: const [
                  ButtonSegment(value: RoundingMode.float, label: Text('F')),
                  ButtonSegment(value: RoundingMode.cut, label: Text('CUT')),
                  ButtonSegment(value: RoundingMode.up, label: Text('UP')),
                  ButtonSegment(
                      value: RoundingMode.halfUp, label: Text('5/4')),
                ],
                selected: {settings.rounding},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    cubit.setRounding(selection.first),
              ),
              const SizedBox(height: 24),
              Text(isFloat
                  ? strings.decimalPlacesInactive
                  : strings.decimalPlaces),
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
                title: Text(strings.grouping),
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

import 區補：

```dart
import '../core/app_strings.dart';
```

- [ ] **Step 4: 跑測試確認通過**

```bash
flutter test test/settings_screen_test.dart
flutter test test/widget_test.dart
```

Expected: 兩檔都綠（widget_test 的「⚙ 導航到設定頁」靠 Task 6 的 helper 錨在繁中）。

- [ ] **Step 5: Commit**

```bash
flutter analyze
flutter test
git add lib/views/settings_screen.dart test/settings_screen_test.dart
git commit -m "feat(views): source settings screen labels from AppStrings"
```

---

### Task 8: 語言選單

**Files:**
- Modify: `lib/views/settings_screen.dart`（`ListView.children` 末尾加一段）
- Modify: `test/widget_test.dart`（新增八條）
- Modify: `test/settings_screen_test.dart`（Task 7 的四個隔離 harness 要補 `LanguageCubit` provider，否則 `ProviderNotFoundException`，R13）

**Interfaces:**
- Consumes: `LanguageCubit.setLanguage(AppLocale?)`（Task 5）、`AppLocale`（Task 2）、`AppStrings.languageLabel／languageSystem／languageEnglish／languageTraditional／languageSimplified`（Task 3）、Task 6 的 `pumpApp`
- Produces: `Key('languagePicker')` 的 `SegmentedButton<AppLocale?>`（測試用這個 key 定位）

- [ ] **Step 1: 寫失敗測試**

`test/widget_test.dart` 檔尾新增：

```dart
  testWidgets('語言選單四選項存在，預設選到跟隨系統', (tester) async {
    await pumpApp(tester, locales: const [Locale('zh', 'TW')]);
    await tester.tap(find.byKey(const Key('openSettings')));
    await tester.pumpAndSettle();

    for (final label in ['跟隨系統', 'English', '繁體中文', '简体中文']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(tester.widget<SegmentedButton<AppLocale?>>(
      find.byKey(const Key('languagePicker'))).selected, {null});
  });

  testWidgets('選『简体中文』後停在設定頁並即時換字', (tester) async {
    await pumpApp(tester, locales: const [Locale('zh', 'TW')]);
    await tester.tap(find.byKey(const Key('openSettings')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('简体中文'));
    await tester.pumpAndSettle();

    // 停住 = MaterialApp 原地更新、Navigator state 保留（spec D6 的硬檢查）。
    expect(find.text('设置'), findsOneWidget);
    expect(find.byKey(const Key('languagePicker')), findsOneWidget);
    // 按鍵是符號詞，三語一致（spec D10）。
    expect(find.text('AC', skipOffstage: false), findsOneWidget);  // 鍵盤路由在設定路由之下，屬 offstage（R12）
  });

  testWidgets('語言選擇會持久化，重進 App 仍是簡體', (tester) async {
    await pumpApp(tester, locales: const [Locale('zh', 'TW')]);
    await tester.tap(find.byKey(const Key('openSettings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('简体中文'));
    await tester.pumpAndSettle();
    await tester.runAsync(pumpEventQueue); // 等 fire-and-forget 的寫入落地

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SettingsRepository.languageKey), 'zh_Hans');
  });

  testWidgets('手機寬 361dp：語言選單不 overflow', (tester) async {
    tester.view.physicalSize = const Size(361, 794);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester, locales: const [Locale('zh', 'TW')]);
    await tester.tap(find.byKey(const Key('openSettings')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // 光是「不拋異常」抓不到 D7 回歸：沒包 SingleChildScrollView 時按鈕會被夾成 361dp
    // 並換行長高、不拋 overflow，測試照樣綠。這一條才是真的鎖住可捲動（R14）。
    expect(tester.getRect(find.byKey(const Key('languagePicker'))).width,
        greaterThan(361));
    expect(find.text('跟隨系統'), findsOneWidget);
  });

  // spec 測試策略 6＋驗收第 1 條：三語各自渲染、且互不殘留。
  testWidgets('三語設定頁：標題與標籤全從目錄來，別語的字不出現', (tester) async {
    final cases = [
      (const <Locale>[Locale('en')], AppStrings.english),
      (const <Locale>[Locale('zh', 'CN')], AppStrings.simplified),
      (const <Locale>[Locale('zh', 'TW')], AppStrings.traditional),
    ];
    final titles = [
      AppStrings.english.settingsTitle,
      AppStrings.simplified.settingsTitle,
      AppStrings.traditional.settingsTitle,
    ];
    for (final (systemLocales, strings) in cases) {
      await pumpApp(tester, locales: systemLocales);
      await tester.tap(find.byKey(const Key('openSettings')));
      await tester.pumpAndSettle();

      for (final label in [
        strings.taxRateLabel,
        strings.taxRateHelper,
        strings.roundingMode,
        strings.decimalPlaces, // 預設 5/4 不是 F，所以這裡不該是 Inactive 變體
        strings.grouping,
        strings.languageLabel,
      ]) {
        expect(find.text(label), findsOneWidget,
            reason: '${strings.appTitle} 少了「$label」');
      }
      for (final title in titles) {
        expect(find.text(title),
            title == strings.settingsTitle ? findsOneWidget : findsNothing,
            reason: 'AppBar 標題不該同時出現兩種語系');
      }
    }
  });

  // spec D6 那句「換語系不會被彈出設定頁」在這裡被證明；紅了請停在原地回報。
  testWidgets('選「跟隨系統」會移除偏好並回到系統語系', (tester) async {
    await pumpApp(tester, locales: const [Locale('zh', 'TW')]);
    await tester.tap(find.byKey(const Key('openSettings')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('简体中文'));
    await tester.pumpAndSettle();
    expect(find.text('设置'), findsOneWidget);

    // 切到簡體後，「跟隨系統」這個選項自己也被翻譯成「跟随系统」，
    // 所以要點的是簡體字形——它是四個選項裡唯一會被翻的那個（spec D8）。
    await tester.tap(find.text('跟随系统'));
    await tester.pumpAndSettle();
    expect(find.text('設定'), findsOneWidget); // 回到 zh-TW 系統的繁中

    await tester.runAsync(pumpEventQueue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(SettingsRepository.languageKey), isFalse);
  });

  // spec 測試策略 8：flutter_localizations 對 zh_Hans／zh_Hant 真的有感應。
  testWidgets('delegates 冒煙測試：三語下長按稅率欄都不拋 Localizations assert',
      (tester) async {
    for (final systemLocales in [
      const <Locale>[Locale('en')],
      const <Locale>[Locale('zh', 'CN')],
      const <Locale>[Locale('zh', 'TW')],
    ]) {
      await pumpApp(tester, locales: systemLocales);
      await tester.tap(find.byKey(const Key('openSettings')));
      await tester.pumpAndSettle();
      await tester.longPress(find.byKey(const Key('taxRateField')));
      await tester.pumpAndSettle();
      // 缺 delegate 時 debug mode 會在這裡拋 assert；有異常 takeException 才會吞得到。
      expect(tester.takeException(), isNull);
    }
  });
```

**這條冒煙測試的誠實邊界**：test binding 不一定真的把文字選取工具列渲染出來（桌面 target 要先有 focus），所以它可能「無事發生就過」。真正的證據是 Task 10 在 exe 裡人工長按一次，看那列 Cut／Copy／Paste 有沒有跟著換成繁中的「剪下／複製／貼上」與簡中的「剪切／复制／粘贴」。這條測試只保證不會因為缺 delegate 而炸，不證明翻譯內容有沒有換過去。

import 區補：

```dart
import 'package:jack_calculator/core/app_locale.dart';
import 'package:jack_calculator/core/app_strings.dart';
import 'package:jack_calculator/data/settings_repository.dart';
```

- [ ] **Step 2: 跑測試確認失敗**

```bash
flutter test test/widget_test.dart
```

Expected: FAIL —`find.text('跟隨系統')` 找不到（語言選單還不存在）。

- [ ] **Step 3: 實作**

`lib/views/settings_screen.dart`：在 `SwitchListTile(...)` 之後（同一個 `children` 清單尾端）加一段；`const SizedBox(height: 24)` 沿用該頁既有節奏。

```dart
              const SizedBox(height: 24),
              Text(strings.languageLabel),
              const SizedBox(height: 8),
              BlocBuilder<LanguageCubit, AppLocale?>(
                // Flutter 3.47.7 的 `SegmentedButton` 沒有 `scrollable` 參數（R10），
                // 外層改用橫向 `SingleChildScrollView` 滿足 spec D7 的捲動需求。
                builder: (context, selected) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<AppLocale?>(
                    key: const Key('languagePicker'),
                    segments: [
                      ButtonSegment(
                          value: null, label: Text(strings.languageSystem)),
                      const ButtonSegment(
                          value: AppLocale.english,
                          label: Text(AppStrings.languageEnglish)),
                      const ButtonSegment(
                          value: AppLocale.traditional,
                          label: Text(AppStrings.languageTraditional)),
                      const ButtonSegment(
                          value: AppLocale.simplified,
                          label: Text(AppStrings.languageSimplified)),
                    ],
                    selected: {selected},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) => context
                        .read<LanguageCubit>()
                        .setLanguage(selection.first),
                  ),
                ),
              ),
```

import 區補：

```dart
import '../bloc/language_cubit.dart';
import '../core/app_locale.dart';
```

- [ ] **Step 4: 跑測試確認通過**

```bash
flutter test test/widget_test.dart
```

Expected: 新增 8 條全綠。若「選『简体中文』後停在設定頁並即時換字」那條紅在 `find.text('设置')` 找不到（route 被彈出），**停在原地回報**，不要改測試去遷就——spec 風險表留了退路（語言選單搬到主屏或加提示），那是需要重新裁定的設計改動。

- [ ] **Step 5: Commit**

```bash
flutter analyze
flutter test
git add lib/views/settings_screen.dart test/widget_test.dart
git commit -m "feat(views): add language switcher to settings screen"
```

---

### Task 9: StatusIndicator 接字串目錄

**Files:**
- Modify: `lib/views/components/status_indicator.dart`
- Modify: `test/widget_test.dart`（Task 6 那條 en indicator 測試的期望值要跟著改）

**Interfaces:**
- Consumes: `AppStrings.of`、`placesSuffix`、`indicatorSeparator`（Task 3）
- Produces: indicator 的位數與分隔符跟 locale 走

- [ ] **Step 1: 改測試（先紅）**

`test/widget_test.dart`：把 Task 6 加的「預設跟隨系統：en 裝置也是同一套符號按鍵」裡這一行

```dart
    expect(tester.widget<Text>(find.byKey(const Key('indPlaces'))).data, '2位');
```

換成

```dart
    expect(tester.widget<Text>(find.byKey(const Key('indPlaces'))).data, '2 dp');
```

同一條再補一個分隔符斷言（鎖住 en 的半形分隔符；預設設定是 5-4 / 2 位 / 千分位 on，所以有三處）：

```dart
    expect(find.text('   |   '), findsNWidgets(3));
```

並在檔尾補一條：

```dart
  testWidgets('簡體 indicator 同繁中後綴、分隔符不變', (tester) async {
    await pumpApp(tester, locales: const [Locale('zh', 'CN')]);
    expect(tester.widget<Text>(find.byKey(const Key('indPlaces'))).data, '2位');
    expect(find.text('  ｜  '), findsNWidgets(3));
  });
```

```bash
flutter test test/widget_test.dart
```

Expected: FAIL —`expected: '2 dp'`、`actual: '2位'`。

- [ ] **Step 2: 實作**

`lib/views/components/status_indicator.dart` 的 `build` 頂端取目錄，把 `'${settings.decimalPlaces}位'` 與三處 `'  ｜  '` 換掉：

```dart
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strings = AppStrings.of(Localizations.localeOf(context));
    final style = TextStyle(fontSize: 13, color: scheme.onSurfaceVariant);
    final isFloat = settings.rounding == RoundingMode.float;
    final separator = Text(strings.indicatorSeparator, style: style);
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerRight,
      child: Row(
        children: [
          const Spacer(),
          Text('${settings.taxRate}%', key: const Key('indTax'), style: style),
          separator,
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
            separator,
            Text('${settings.decimalPlaces}${strings.placesSuffix}',
                key: const Key('indPlaces'), style: style),
          ],
          if (settings.grouping) ...[
            separator,
            Text(',', key: const Key('indGrouping'), style: style),
          ],
        ],
      ),
    );
  }
```

**注意**：`separator` 是同一個 `Text` widget 實例被放進 `Row` 三次。`Row` 的子元件是同一 `Key`-less element 的重複引用，Flutter 容許（widget 是不可變描述），但若跑出 `duplicate key` 或渲染異常，就改回每處各 new 一個 `Text(strings.indicatorSeparator, style: style)`。先按上面寫、跑測試驗證，別憑空怕。

import 區補：

```dart
import '../../core/app_strings.dart';
```

- [ ] **Step 3: 跑測試確認通過**

```bash
flutter test test/widget_test.dart
flutter test
```

Expected: 全綠。

- [ ] **Step 4: Commit**

```bash
flutter analyze
git add lib/views/components/status_indicator.dart test/widget_test.dart
git commit -m "feat(views): localize status indicator suffix and separator"
```

---

### Task 10: 全量驗證、建置、AGENTS.md 對帳與交付

**Files:**
- Modify: `AGENTS.md`（四節，見 Step 4）

**Interfaces:**
- Consumes: 前 9 個 Task 的全部產出
- Produces: 可交付的 `feat/i18n` 分支（本機 commit，未 push）

- [ ] **Step 1: 全量靜態與測試驗證**

```bash
flutter analyze
flutter test
```

Expected: `No issues found!`、`All tests passed!`。記錄總數。新增條數：Task 2 有 6、Task 3 有 6、Task 4 有 4、Task 5 有 4、Task 6 有 3、Task 7 有 2、Task 8 有 8、Task 9 有 1，合計 **34 條**，預設總數 146＋34＝**180**。Task 6／7 另外改寫了 4 條既有測試（加語系錨點，不增條數），若實測不是 180，以實測為準並在交付報告裡說明差在哪。

- [ ] **Step 2: 雙平台建置**

```bash
flutter build windows
flutter build apk
```

Expected: 兩個 `√ Built ...`。APK 基線是 **47.1MB**，把本輪實際大小記下來（spec D12 要的增量），例如「`app-release.apk 47.xMB（+0.yMB）`」。PowerShell 報 `NativeCommandError`／exit 1 不算失敗，看有沒有 `√ Built`。

- [ ] **Step 3a: Windows exe 三語自查（agent 自己跑，不算使用者驗收）**

```bash
flutter build windows && ./build/windows/x64/runner/Release/jack_calculator.exe
```

用既有的 PrintWindow 截圖法抓三張（把 `app_locale` 寫進 prefs 或在選單裡切）：繁中主屏＋設定頁、簡中主屏＋設定頁、英文主屏＋設定頁，存到 `docs/superpowers/references/i18n/`。自己先看一眼：簡體切換後設定頁有無殘留繁體、indicator 的 `2 dp` 有無被擠壓、語言選單有沒有捲動條。真正的驗收由使用者親跑（預設慣例），交付時把三張圖跟檢查清單一起給。

- [ ] **Step 3b: 手機端截圖存證（spec 測試策略 10）**

裝到那台序列號 `ce27901d` 的實機，用 adb 各截一張繁中／簡中／英文的主屏＋設定頁，存進同一個 `docs/superpowers/references/i18n/`（檔名帶平台前綴，例 `phone-en-settings.png`）：

```bash
adb devices                                   # 確認 ce27901d 有在清單上
flutter install -d ce27901d                   # 或 adb install -r build/app/outputs/flutter-apk/app-release.apk
adb -s ce27901d shell am start -n wenhsiaoyi.jack_calculator/.MainActivity
adb -s ce27901d exec-out screencap -p > docs/superpowers/references/i18n/phone-<locale>-<page>.png
```

語系用 `adb -s ce27901d shell settings put system system_locales zh-CN` 換（換完要重啟 App 才讀得到），或在設定頁的語言選單裡直接點。這一步也順手驗了 spec 風險表的「手機上 `flutter_localizations` 的 Material 字串有沒有跟着換」。
**裝置不在手上就跳過，並在交付報告裡老實寫「手機端未驗，僅 Windows exe 自查」**——不要用模擬器截圖冒充實機。

- [ ] **Step 4: AGENTS.md 對帳（五處）**

1. 「中文用語規範（台灣正體）」段尾加豁免條：該規範管開發產出（文件、註解、commit）與繁體 UI；`lib/core/app_strings.dart` 的 zh-Hans 欄與對應測試期望值是道地大陸用語（2026-10-20 裁定），掃詞彙表 `cn` 欄時跳過該檔簡體欄。
2. 「環境」節：一階依賴清單加入 `flutter_localizations`（SDK 套件）；說明 `intl 0.20.3` 仍是 transitive、未宣告、不用於千分位；測試數基線更新成 Step 1 的實測值。
3. 「App 顯示名稱」節補一句：只有 Dart 側 `MaterialApp.title` 會隨語系變動，Android label／iOS `CFBundleDisplayName`／Windows 視窗標題恆為「Jack計算機」。
4. 「Phase 路線圖」加一行：多國語系一輪已完成（分支 `feat/i18n`，spec＋plan 路徑），並註明 Phase 3 新增字串一律走 `AppStrings`，超過 40 條時重新評估 `gen-l10n`。
5. 記 APK 體積增量（Step 2 的數字）。

- [ ] **Step 5: Commit**

```bash
git add AGENTS.md
git commit -m "docs(agents): record i18n round, zh-Hans copy exemption and APK delta"
```

- [ ] **Step 6: 交付回報**

報告內容：三語截圖路徑、analyze/test/build 三項輸出原文、APK 大小增量、`intl` 是否免宣告的實測結論、以及 Task 8 Step 4 若曾觸發的 route 彈出狀況。

spec 驗收標準裡有兩項是**圖面比對、不是測試**，報告時要逐項交代：（a）顯示屏數字、`Error`、`GT` 徽章與按鍵標籤在三語下完全一致（靠 Task 8 那條符號按鍵測試＋三張截圖對照證明視圖層沒被誤動）；（b）Material 內建的選字工具列（長按稅率欄那列 Cut／Copy／Paste）確實跟著換成繁中／簡中——Task 8 那條冒煙測試只保證不炸，這條要靠截圖或人工看到才算數。分支保持在本機、未 push，等使用者裁定 integration（`finishing-a-development-branch`）。

---

## 附註：spec 對應表

| spec 定案 | Task |
|---|---|
| D1 `AppLocale` 不進 `CalcSettings` | 2 |
| D2 `LanguageCubit`（null＝跟隨系統） | 5 |
| D3 沿用 `SettingsRepository` | 4 |
| D4 不建 delegate，視圖查表 | 3、7、9 |
| D5 自寫解析規則 | 2 |
| D6 `MaterialApp` 接線＋route 保留 | 6、8（測試證明） |
| D7 `SegmentedButton` ＋橫向捲動（R10：改由 `SingleChildScrollView` 承辦） | 8 |
| D8 語言選項不翻 | 3、8 |
| D9 錯誤存原因不存字串 | 7 |
| D10 `Error`／按鍵不譯 | 6（符號按鍵測試）、7（segment 標籤保持 F／CUT／UP／5-4） |
| D11 只加 `flutter_localizations` | 1 |
| D12 APK 增量 | 10 |
| OUT：原生啟動器名稱、gen-l10n、在地數字格式 | 無對應 Task（刻意不做） |

## 附註二：spec「測試策略」10 條對應

| spec 測試策略 | Task |
|---|---|
| 1 `pumpApp` helper（走真實解析路徑） | 6 Step 1 |
| 2 改既有中文斷言（spec 說 7 條，其中 4 條真的會紅） | 6 Step 2（widget_test 那兩條）＋ 7 Step 1（設定頁那條加 `locale:`）；另 4 條是 `findsNothing` 殭屍斷言，spec 自己標明不必動 |
| 3 `app_locale_test.dart` 解析表 | 2 Step 1 |
| 4 `language_cubit_test.dart` | 5 Step 1 |
| 5 `settings_repository_test.dart` 語系 group | 4 Step 1 |
| 6 三語渲染（設定頁標題與標籤） | 7（稅率錯誤兩語）＋ 8（三語設定頁全表） |
| 7 語言選單：四選項／361dp／切後不重啟／持久化／還原跟系統 | 8 Step 1 |
| 8 delegates 冒煙測試 | 8 Step 1（自動化那條，誠實邊界已標註）＋ 10 Step 3a（exe 人工長按看工具列） |
| 9 標準檢查（analyze／test／build windows／build apk） | 每個 Task 收尾＋ 10 Step 1–2 |
| 10 Walkthrough 交付（Windows 三語截圖＋手機 adb 存證） | 10 Step 3a（exe）＋ 3b（`ce27901d` 實機） |
