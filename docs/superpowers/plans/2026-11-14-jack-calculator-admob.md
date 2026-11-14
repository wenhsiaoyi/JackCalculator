# Jack計算機 AdMob 整合 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 Android／iOS 整合 AdMob 測試廣告（主畫面底部 Banner＋設定頁「支持我們」插屏），桌面平台無廣告且建置不受影響。

**Architecture:** 集中式 `AdService`（平台 gating、初始化、測試裝置、廣告單元 ID、插屏載入）＋薄 `BannerAdView` widget；設定頁按鈕 on-demand 載入插屏，關閉後感謝 SnackBar。全用官方範例 App ID 與測試廣告單元 ID。

**Tech Stack:** Flutter 3.47.7／Dart 3.13.5、`google_mobile_ads` 9.2.0、flutter_bloc（Cubit）、`shared_preferences`（既有）、Android emulator `jack_android36`。

**Spec:** `docs/superpowers/specs/2026-11-14-jack-calculator-admob-design.md`（D1–D13 決議；plan 與 spec 一起讀）

## Global Constraints

- 分支：`feat/admob`（自 main @ `509bec9` 開出）；**不 push**，push 需使用者另行指示。
- 標準檢查順序：`flutter analyze` → `flutter test`。成功判斷看 `No issues found!`／`All tests passed!`／`√ Built …`，**不看 shell exit code**（Flutter/Gradle 寫 stderr 會讓 PowerShell 誤報失敗）。
- 測試基線：182 條全綠（本輪新增後以實際數字更新 AGENTS.md）。
- 依賴政策例外（spec D11，使用者已核准）：`google_mobile_ads` 僅 Android／iOS 生效，桌面建置不受影響即可。**不得 `flutter pub upgrade`**（`pubspec.lock` 有進版控）。
- 平台：android／ios／windows／linux。**不加 web／macos**。
- 廣告 ID（spec 廣告 ID 一覽，逐字使用）：
  - Android App ID：`ca-app-pub-3940256099942544~3347511713`
  - iOS App ID：`ca-app-pub-3940256099942544~1458002511`
  - Banner：Android `ca-app-pub-3940256099942544/9214589741`／iOS `ca-app-pub-3940256099942544/2435281174`
  - Interstitial：Android `ca-app-pub-3940256099942544/1033173712`／iOS `ca-app-pub-3940256099942544/4411468910`
- 中文輸出一律台灣正體（全形標點、中英半形空格）；`AppStrings` 的 zh-Hans 欄用道地大陸用語（豁免）。
- adb 一律走 `scripts/`：需裝置的子命令用 `.\scripts\adb_run.ps1`（自帶裝置檢查），其他用 `.\scripts\adb_monitor.ps1`。**沒有狀態 `device` 的機子就停下來問使用者**。
- Android 16 模擬器 `input tap` 會被靜默忽略：點擊用同點 timed swipe（`input swipe X Y X Y 150`）；座標在全解析度 PNG 上量；截圖用 `screencap`。
- 測試裝置設定 `kDebugMode` 限定（spec D3）；**release APK 不會套用**，模擬器驗證用 debug APK。
- Commit 訊息風格：`type(scope): 英文小寫祈使句`（repo 慣例）。
- 本輪不動 `lib/engine/`、`lib/core/theme.dart`、`lib/core/number_format.dart`、`scripts/*.ps1`。

---

### Task 1: 引入 google_mobile_ads＋原生設定＋桌面建置驗證

**Files:**
- Modify: `pubspec.yaml`（dependencies 節）
- Modify: `pubspec.lock`（pub get 產生）
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`

**Interfaces:**
- Consumes: 無（第一個任務）
- Produces: `google_mobile_ads` 可供 Dart import；Android／iOS 原生 App ID 就緒；`flutter build windows` 通過證明（spec D1）

- [ ] **Step 1: 開分支**

```bash
git checkout -b feat/admob
```

- [ ] **Step 2: 加依賴**

```bash
flutter pub add google_mobile_ads
```

預期：`pubspec.yaml` 出現 `google_mobile_ads: ^9.2.0`，`pub get` 成功解析（SDK `>=3.10.0 <4.0.0` 與 `^3.13.5` 相容，spec D11 已實測 metadata）。`pubspec.lock` 會新增 `google_mobile_ads` 與 `webview_flutter` 家族 transitive。

- [ ] **Step 3: Android manifest 加 App ID 與 INTERNET 權限**

`android/app/src/main/AndroidManifest.xml`：在 `<manifest …>` 之下、`<application>` 之前加：

```xml
    <uses-permission android:name="android.permission.INTERNET"/>
```

在 `<application>` 內（`android:roundIcon` 行之後、`<activity>` 之前）加：

```xml
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-3940256099942544~3347511713"/>
```

- [ ] **Step 4: iOS Info.plist 加 GADApplicationIdentifier**

`ios/Runner/Info.plist`：在 `<key>CFBundleVersion</key><string>$(FLUTTER_BUILD_NUMBER)</string>` 之後加：

```xml
	<key>GADApplicationIdentifier</key>
	<string>ca-app-pub-3940256099942544~1458002511</string>
```

（iOS 本機建不了，僅語法層修改；spec D8。）

- [ ] **Step 5: 驗證 analyze 與既有測試**

```bash
flutter analyze
flutter test
```

預期：`No issues found!`；`All tests passed!`（182 條，尚未新增）。

- [ ] **Step 6: 驗證 Windows 建置不被 plugin 破壞（spec D1 必要實測）**

```bash
flutter build windows
```

預期：`√ Built build\windows\x64\runner\Release\jack_calculator.exe`。Flutter 對無 Windows 實作的 plugin 會跳過（可能印警告），**只要出現 `√ Built` 就算通過**。若失敗，停下來回報錯誤訊息，不要自行猜修。

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist
git commit -m "feat(admob): add google_mobile_ads and native app ID setup"
```

---

### Task 2: AppStrings 新增 3 個廣告字串（TDD）

**Files:**
- Modify: `test/app_strings_test.dart`（`_fields` 表＋zh-Hans 測試）
- Modify: `lib/core/app_strings.dart`

**Interfaces:**
- Consumes: 無
- Produces: `AppStrings.supportUs`、`AppStrings.thanksForSupport`、`AppStrings.adLoadFailed`（三個 `final String` 欄位，三語目錄皆填）；Task 5 的按鈕與 SnackBar 取用

- [ ] **Step 1: 擴充失敗測試**

`test/app_strings_test.dart`：在 `_fields` map 的 `'languageSystem'` 行之後加 3 個存取器：

```dart
  'supportUs': (s) => s.supportUs,
  'thanksForSupport': (s) => s.thanksForSupport,
  'adLoadFailed': (s) => s.adLoadFailed,
```

在 `test('zh-Hans 用道地大陸用語，不是繁簡字形轉換', …)` 內追加：

```dart
    expect(AppStrings.simplified.supportUs, '支持我们');
    expect(AppStrings.simplified.adLoadFailed, contains('广告加载失败'));
```

（既有的「三語皆填」「繁簡不得相同」「英文不撞字」三個遍歷測試會自動覆蓋新欄位，不必另寫。）

- [ ] **Step 2: 跑測試確認失敗**

```bash
flutter test test/app_strings_test.dart
```

預期：編譯失敗，`The getter 'supportUs' isn't defined for the type 'AppStrings'`。

- [ ] **Step 3: 實作字串欄位**

`lib/core/app_strings.dart`：

建構子（`required this.languageSystem,` 之後）加：

```dart
    required this.supportUs,
    required this.thanksForSupport,
    required this.adLoadFailed,
```

欄位宣告（`final String languageSystem;` 之後）加：

```dart
  final String supportUs;
  final String thanksForSupport;
  final String adLoadFailed;
```

`english` 目錄（`languageSystem: 'System',` 之後）加：

```dart
    supportUs: 'Support us',
    thanksForSupport: 'Thanks for your support!',
    adLoadFailed: 'Ad failed to load. Please try again later.',
```

`simplified` 目錄（`languageSystem: '跟随系统',` 之後）加：

```dart
    supportUs: '支持我们',
    thanksForSupport: '感谢您的赞助！',
    adLoadFailed: '广告加载失败，请稍后再试',
```

`traditional` 目錄（`languageSystem: '跟隨系統',` 之後）加：

```dart
    supportUs: '支持我們',
    thanksForSupport: '感謝您的贊助！',
    adLoadFailed: '廣告載入失敗，請稍後再試',
```

- [ ] **Step 4: 跑測試確認通過**

```bash
flutter test test/app_strings_test.dart
flutter analyze
flutter test
```

預期：全綠（182 條，測試數不變——新斷言加在既有 test 內）。

- [ ] **Step 5: Commit**

```bash
git add lib/core/app_strings.dart test/app_strings_test.dart
git commit -m "feat(admob): add support-button and ad strings to AppStrings"
```

---

### Task 3: AdService＋main() 初始化接線（TDD）

**Files:**
- Create: `lib/core/ad_service.dart`
- Create: `test/ad_service_test.dart`
- Modify: `lib/main.dart:14`（`void main() => runApp(...)` 一行）

**Interfaces:**
- Consumes: `google_mobile_ads`（Task 1）
- Produces:
  - `AdService.supported`（`static bool get`）
  - `AdService.initialize()`（`static Future<void>`，桌面 no-op）
  - `AdService.testDeviceIds`（`static const List<String>`，Task 6 填入模擬器 ID）
  - `AdService.bannerAdUnitIdFor({required bool isAndroid})`／`interstitialAdUnitIdFor({required bool isAndroid})`（純函式）
  - `AdService.bannerAdUnitId`／`interstitialAdUnitId`（`static String get`）
  - `AdService.loadInterstitial()`（`static Future<InterstitialAd?>`，失敗回 null）
  - Task 4 用 `supported`／`bannerAdUnitId`；Task 5 用 `supported`／`loadInterstitial()`

- [ ] **Step 1: 寫失敗測試**

建立 `test/ad_service_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/core/ad_service.dart';

void main() {
  test('Windows／Linux host 上 supported 為 false', () {
    expect(AdService.supported, isFalse);
  });

  test('initialize() 在不支援平台是 no-op（不觸碰 MobileAds）', () async {
    // 若誤呼叫 MobileAds，test binding 無 platform channel 會拋
    // MissingPluginException；能完成即證明 guard 生效。
    await AdService.initialize();
  });

  test('bannerAdUnitIdFor 按平台選官方測試 ID', () {
    expect(AdService.bannerAdUnitIdFor(isAndroid: true),
        'ca-app-pub-3940256099942544/9214589741');
    expect(AdService.bannerAdUnitIdFor(isAndroid: false),
        'ca-app-pub-3940256099942544/2435281174');
  });

  test('interstitialAdUnitIdFor 按平台選官方測試 ID', () {
    expect(AdService.interstitialAdUnitIdFor(isAndroid: true),
        'ca-app-pub-3940256099942544/1033173712');
    expect(AdService.interstitialAdUnitIdFor(isAndroid: false),
        'ca-app-pub-3940256099942544/4411468910');
  });
}
```

- [ ] **Step 2: 跑測試確認失敗**

```bash
flutter test test/ad_service_test.dart
```

預期：編譯失敗，`Target of URI doesn't exist: 'package:jack_calculator/core/ad_service.dart'`。

- [ ] **Step 3: 實作 AdService**

建立 `lib/core/ad_service.dart`：

```dart
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 廣告設定唯一入口（spec D2）；僅 Android／iOS 生效（spec D1）。
class AdService {
  const AdService._();

  static bool get supported => Platform.isAndroid || Platform.isIOS;

  /// 模擬器測試裝置 ID（spec D3）：Task 6 從 logcat 取得後填入。
  /// 模擬器本就會自動成為測試裝置，此清單是需求 2 的明確註冊。
  /// 上架前必須清空並移除相關呼叫。
  static const List<String> testDeviceIds = <String>[];

  static Future<void> initialize() async {
    if (!supported) return;
    await MobileAds.instance.initialize();
    if (kDebugMode && testDeviceIds.isNotEmpty) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: testDeviceIds),
      );
    }
  }

  static String bannerAdUnitIdFor({required bool isAndroid}) => isAndroid
      ? 'ca-app-pub-3940256099942544/9214589741'
      : 'ca-app-pub-3940256099942544/2435281174';

  static String interstitialAdUnitIdFor({required bool isAndroid}) => isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  static String get bannerAdUnitId =>
      bannerAdUnitIdFor(isAndroid: Platform.isAndroid);

  static String get interstitialAdUnitId =>
      interstitialAdUnitIdFor(isAndroid: Platform.isAndroid);

  /// 失敗回 null（spec D13：不拋、不擋操作）。僅行動平台會走到。
  static Future<InterstitialAd?> loadInterstitial() {
    final completer = Completer<InterstitialAd?>();
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: completer.complete,
        onAdFailedToLoad: (_) => completer.complete(null),
      ),
    );
    return completer.future;
  }
}
```

- [ ] **Step 4: 跑測試確認通過**

```bash
flutter test test/ad_service_test.dart
```

預期：4 條全過。

- [ ] **Step 5: main() 接線（spec D9）**

`lib/main.dart`：import 節加 `import 'core/ad_service.dart';`（排在 `core/app_strings.dart` 之後，依字母序）。把第 14 行：

```dart
void main() => runApp(const JackCalculator());
```

改成：

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService.initialize();
  runApp(const JackCalculator());
}
```

（測試直接 pump `JackCalculator`、不經 `main()`，既有 `pumpApp` harness 不受影響；桌面 `initialize()` 為 no-op。）

- [ ] **Step 6: 全量驗證**

```bash
flutter analyze
flutter test
```

預期：`No issues found!`；`All tests passed!`（186 條＝182＋4）。

- [ ] **Step 7: Commit**

```bash
git add lib/core/ad_service.dart test/ad_service_test.dart lib/main.dart
git commit -m "feat(admob): add AdService with platform gating and init wiring"
```

---

### Task 4: BannerAdView＋主畫面底部接線（TDD）

**Files:**
- Create: `lib/views/components/banner_ad_view.dart`
- Create: `test/banner_ad_view_test.dart`
- Modify: `lib/views/calculator_screen.dart`（import 節；Column children 末尾，約 135 行 `Expanded(…)` 之後）

**Interfaces:**
- Consumes: `AdService.supported`、`AdService.bannerAdUnitId`（Task 3）
- Produces: `const BannerAdView()` widget（無參數）；桌面與載入失敗時 zero-size

- [ ] **Step 1: 寫失敗測試**

建立 `test/banner_ad_view_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:jack_calculator/bloc/calculator_cubit.dart';
import 'package:jack_calculator/bloc/language_cubit.dart';
import 'package:jack_calculator/bloc/settings_cubit.dart';
import 'package:jack_calculator/data/settings_repository.dart';
import 'package:jack_calculator/views/calculator_screen.dart';
import 'package:jack_calculator/views/components/banner_ad_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('桌面 host 上 BannerAdView 是 zero-size shrink、無 AdWidget',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BannerAdView())),
    );
    expect(find.byType(AdWidget), findsNothing);
    expect(tester.getSize(find.byType(BannerAdView)), Size.zero);
  });

  testWidgets('桌面 host 上 CalculatorScreen 不出現 AdWidget', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsCubit(const SettingsRepository());
    final language = LanguageCubit(const SettingsRepository());
    final calculator = CalculatorCubit();
    addTearDown(settings.close);
    addTearDown(language.close);
    addTearDown(calculator.close);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: settings),
          BlocProvider.value(value: language),
          BlocProvider.value(value: calculator),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: CalculatorScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AdWidget), findsNothing);
  });
}
```

- [ ] **Step 2: 跑測試確認失敗**

```bash
flutter test test/banner_ad_view_test.dart
```

預期：編譯失敗，`Target of URI doesn't exist: '…/banner_ad_view.dart'`。

- [ ] **Step 3: 實作 BannerAdView**

建立 `lib/views/components/banner_ad_view.dart`：

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/ad_service.dart';

/// 主畫面底部錨定自適應 Banner（spec D4／D5）。
/// 載入前、失敗、桌面一律 zero-size，不佔版面。
class BannerAdView extends StatefulWidget {
  const BannerAdView({super.key});

  @override
  State<BannerAdView> createState() => _BannerAdViewState();
}

class _BannerAdViewState extends State<BannerAdView> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    if (!AdService.supported) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadAd());
    });
  }

  Future<void> _loadAd() async {
    final width = MediaQuery.sizeOf(context).width.truncate();
    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;
    final ad = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _bannerAd = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          // 自動重新整理失敗時 ad 可能正是顯示中的那顆，不能 dispose。
          if (_bannerAd != ad) ad.dispose();
        },
      ),
    );
    // load() 必須在進 widget tree 之前呼叫（規格）；這裡只在 onAdLoaded 後才掛樹。
    unawaited(ad.load());
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
```

- [ ] **Step 4: 主畫面接線**

`lib/views/calculator_screen.dart`：import 節加 `import 'components/banner_ad_view.dart';`（排在 `components/calc_button.dart` 之前，依字母序）。

在 Column children 裡、`Expanded(child: Padding(…鍵盤…))` 的閉合 `),` 之後（約第 135 行，children 串列結尾 `],` 之前）加：

```dart
                  const BannerAdView(),
```

（位置在 ConstrainedBox 420dp 之內：手機寬度小於 420 時即全寬；桌面渲染 shrink，不影響置中版面。）

- [ ] **Step 5: 跑測試確認通過＋全量回歸**

```bash
flutter test test/banner_ad_view_test.dart
flutter analyze
flutter test
```

預期：2 條新測試過；全量 `All tests passed!`（188 條＝186＋2）。既有窄窗／overflow 測試守住鍵盤壓縮後不 overflow（spec D5）。

- [ ] **Step 6: Commit**

```bash
git add lib/views/components/banner_ad_view.dart test/banner_ad_view_test.dart lib/views/calculator_screen.dart
git commit -m "feat(admob): show anchored adaptive banner on the calculator screen"
```

---

### Task 5: 設定頁「支持我們」按鈕＋插屏流程

**Files:**
- Modify: `lib/views/settings_screen.dart`（import 節；state 欄位；ListView children 末尾；新 method）
- Modify: `test/settings_screen_test.dart`（新增 1 條回歸守護）

**Interfaces:**
- Consumes: `AdService.supported`、`AdService.loadInterstitial()`（Task 3）；`AppStrings.supportUs`／`thanksForSupport`／`adLoadFailed`（Task 2）
- Produces: `Key('supportUsButton')` ListTile（僅行動平台建）；Task 6 模擬器驗證此流程

- [ ] **Step 1: 加回歸守護測試**

`test/settings_screen_test.dart`：在 `main()` 內（任一個 testWidgets 之後）加：

```dart
  testWidgets('桌面 host 上不支持按鈕整個隱藏（spec D7）', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final cubit = SettingsCubit(const SettingsRepository());
    addTearDown(cubit.close);
    await tester.pumpWidget(_settingsApp(cubit, const Locale('en')));
    expect(find.byKey(const Key('supportUsButton')), findsNothing);
    expect(find.text('Support us'), findsNothing);
  });
```

**注意**：這是回歸守護，不是 TDD 驅動測試——按鈕在實作前後都不存在於桌面，此測試兩階段都會通過。行動平台的按鈕與插屏流程由 Task 6 模擬器實測驗證（dart:io `Platform` 在 widget test 無法覆寫，spec 測試策略已定案）。

- [ ] **Step 2: 跑測試確認現狀通過**

```bash
flutter test test/settings_screen_test.dart
```

預期：全綠（含新守護）。

- [ ] **Step 3: 實作按鈕與插屏流程**

`lib/views/settings_screen.dart`：

import 節加（依字母序插入）：

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';
```

與（在 `../core/app_strings.dart` 之後）：

```dart
import '../core/ad_service.dart';
```

`_SettingsScreenState` 欄位（`bool _taxInvalid = false;` 之後）加：

```dart
  bool _loadingAd = false;
```

ListView children 裡、語言選單 `BlocBuilder<LanguageCubit, AppLocale?>(…)` 的閉合 `),` 之後（children 串列結尾 `],` 之前）加：

```dart
              if (AdService.supported) ...[
                const SizedBox(height: 24),
                ListTile(
                  key: const Key('supportUsButton'),
                  leading: const Icon(Icons.volunteer_activism),
                  title: Text(strings.supportUs),
                  enabled: !_loadingAd,
                  trailing: _loadingAd
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: () => _onSupportTap(strings),
                ),
              ],
```

在 `_onTaxChanged` method 之後加兩個 method：

```dart
  Future<void> _onSupportTap(AppStrings strings) async {
    setState(() => _loadingAd = true);
    final ad = await AdService.loadInterstitial();
    if (!mounted) return;
    setState(() => _loadingAd = false);
    if (ad == null) {
      _showSnack(strings.adLoadFailed);
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (mounted) _showSnack(strings.thanksForSupport);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (mounted) _showSnack(strings.adLoadFailed);
      },
    );
    await ad.show();
  }

  void _showSnack(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
```

- [ ] **Step 4: 全量驗證**

```bash
flutter analyze
flutter test
```

預期：`No issues found!`；`All tests passed!`（189 條＝188＋1）。

- [ ] **Step 5: Commit**

```bash
git add lib/views/settings_screen.dart test/settings_screen_test.dart
git commit -m "feat(admob): add support-us interstitial flow to settings"
```

---

### Task 6: 模擬器實測＋測試裝置 ID 註冊（需求 2）

**Files:**
- Modify: `lib/core/ad_service.dart`（`testDeviceIds` 填入實測 ID）
- Create: `docs/admob/`（截圖證據）

**Interfaces:**
- Consumes: Task 1–5 全部；`jack_android36` 模擬器（`ANDROID_AVD_HOME=E:\Android\avd`）
- Produces: 填好 ID 的 `AdService.testDeviceIds`；Banner／插屏／SnackBar 截圖；Task 7 寫入 AGENTS.md 的實測值（ID、APK 大小）

- [ ] **Step 1: 建 debug APK（kDebugMode=true 才會套用測試裝置設定）**

```bash
flutter build apk --debug
```

預期：`√ Built build\app\outputs\flutter-apk\app-debug.apk`。

**若失敗且錯誤是 minSdk 衝突**（GMA SDK 要求高於 `flutter.minSdkVersion`）：把 `android/app/build.gradle.kts` 的 `minSdk = flutter.minSdkVersion` 改為錯誤訊息要求的數字（預期 21 或 23），重跑；把這個變更記入 Task 7 的 AGENTS.md 對帳。其他錯誤停下來回報。

- [ ] **Step 2: 確認裝置**

```powershell
.\scripts\adb_run.ps1 devices
```

預期：有一台狀態 `device` 的模擬器。**沒有就停下來問使用者**（可建議啟動指令：`E:\Android\Sdk\emulator\emulator.exe -avd jack_android36`，背景執行）。

- [ ] **Step 3: 安裝並啟動**

```powershell
.\scripts\adb_monitor.ps1 install build\app\outputs\flutter-apk\app-debug.apk
.\scripts\adb_run.ps1 shell am start -n wenhsiaoyi.jack_calculator/.MainActivity
```

- [ ] **Step 4: 從 logcat 取測試裝置 ID**

```powershell
.\scripts\adb_run.ps1 logcat -d -s Ads
```

找 `Use RequestConfiguration.Builder.setTestDeviceIds(Arrays.asList("…"))` 訊息，複製 32 位 hex ID。

**若訊息沒出現**（模擬器已被自動判為測試裝置時可能不印）：改取 ANDROID_ID 的 MD5（GMA Android 測試裝置 ID 的定義）：

```powershell
.\scripts\adb_run.ps1 shell settings get secure android_id
```

```bash
python -c "import hashlib,sys;print(hashlib.md5(sys.argv[1].strip().encode()).hexdigest().upper())" <android_id值>
```

兩種方式都拿不到就停下來回報，不要猜 ID。

- [ ] **Step 5: 填入 AdService 並重裝驗證**

`lib/core/ad_service.dart`：把 `static const List<String> testDeviceIds = <String>[];` 改為（ID 換成實測值）：

```dart
  static const List<String> testDeviceIds = <String>['<實測32位hexID>'];
```

```bash
flutter build apk --debug
```

```powershell
.\scripts\adb_monitor.ps1 install -r build\app\outputs\flutter-apk\app-debug.apk
.\scripts\adb_run.ps1 shell am start -n wenhsiaoyi.jack_calculator/.MainActivity
```

- [ ] **Step 6: 截圖驗證 Banner**

```powershell
.\scripts\adb_run.ps1 shell screencap -p /sdcard/admob_banner.png
.\scripts\adb_monitor.ps1 pull /sdcard/admob_banner.png docs/admob/banner.png
```

用 Read 看全解析度 PNG：主畫面底部應有 Banner 且頂部中央有「Test Ad」標籤；鍵盤無 overflow。若 Banner 沒出現，查 `logcat -d -s Ads` 的錯誤碼回報，不要盲目重試。

- [ ] **Step 7: 截圖驗證插屏流程**

1. 從 `docs/admob/banner.png` 量 ⚙ 圖示座標（顯示區頂列），同點 swipe 進設定頁：

```powershell
.\scripts\adb_run.ps1 shell input swipe <X> <Y> <X> <Y> 150
.\scripts\adb_run.ps1 shell screencap -p /sdcard/admob_settings.png
.\scripts\adb_monitor.ps1 pull /sdcard/admob_settings.png docs/admob/settings.png
```

2. 確認設定頁末尾有「支持我們」按鈕，量座標，swipe 點選；等 2–3 秒讓插屏載入：

```powershell
.\scripts\adb_run.ps1 shell input swipe <X> <Y> <X> <Y> 150
.\scripts\adb_run.ps1 shell screencap -p /sdcard/admob_interstitial.png
.\scripts\adb_monitor.ps1 pull /sdcard/admob_interstitial.png docs/admob/interstitial.png
```

3. 確認全螢幕廣告有「Test Ad」標籤；量關閉鈕（×）座標，swipe 關閉；截 SnackBar：

```powershell
.\scripts\adb_run.ps1 shell input swipe <X> <Y> <X> <Y> 150
.\scripts\adb_run.ps1 shell screencap -p /sdcard/admob_thanks.png
.\scripts\adb_monitor.ps1 pull /sdcard/admob_thanks.png docs/admob/thanks.png
```

4. 確認畫面有「感謝您的贊助！」SnackBar（繁中語系時）。

任何一步不如預期：截圖＋logcat 回報，停下來等指示。**UI 最終 acceptance 由使用者親驗**，agent 備齊截圖與指令。

- [ ] **Step 8: Commit**

```bash
git add lib/core/ad_service.dart docs/admob/
git commit -m "feat(admob): register the emulator test device and verify ads on device"
```

---

### Task 7: AGENTS.md 對帳（需求 3）＋終驗

**Files:**
- Modify: `AGENTS.md`（依賴清單、依賴政策、測試基線、新 AdMob 節、APK 對帳）

**Interfaces:**
- Consumes: Task 6 實測值（測試裝置 ID、debug 驗證結果）；本任務量到的 release APK 大小與測試總數
- Produces: 更新後的 AGENTS.md；完整終驗紀錄

- [ ] **Step 1: 終驗指令與量測**

```bash
flutter analyze
flutter test
flutter build windows
flutter build apk
python -c "import os;print(os.path.getsize('build/app/outputs/flutter-apk/app-release.apk'))"
```

記錄：測試總數（預期 189）、release APK bytes、對基線 50,212,142 bytes（47.89 MiB）的增量（spec D12）。`√ Built` 與 `All tests passed!` 缺一不可。

- [ ] **Step 2: 更新 AGENTS.md**

以下各處以**實測值**填入（括號內為預期，實際以 Step 1 與 Task 6 為準）：

(a) 環境節「一階依賴」清單：加入 `google_mobile_ads`，並把「目前唯一第三方 plugin 為 `shared_preferences`」的敘述改為「第三方 plugin：`shared_preferences`、`google_mobile_ads`（僅 Android／iOS 生效）」。

(b)「測試基線：182 條全綠」改為實際數字（預期 189），日期改 2026-11-14。

(c) 依賴政策節尾追加例外裁定：

```markdown
- **`google_mobile_ads` 例外（2026-11-14 使用者核准）**：官方只支援 Android／iOS，牴觸第 2 條「至少 Windows 可建置」。裁定：廣告類 plugin 僅 Android／iOS 生效，**桌面建置不受影響即可**（無 Windows 原生碼，Flutter 跳過未實作平台；`flutter build windows` 已實測通過）。9.2.0，`sdk: >=3.10.0 <4.0.0`、`flutter: >=3.38.1`，transitive 帶入 `webview_flutter` 家族（同樣無 Windows 原生碼）。
```

(d) 新增「AdMob（2026-11-14 一輪）」節，內容含：

```markdown
## AdMob（2026-11-14 一輪，branch `feat/admob`）

設計 `docs/superpowers/specs/2026-11-14-jack-calculator-admob-design.md`、計畫 `docs/superpowers/plans/2026-11-14-jack-calculator-admob.md`。主畫面底部錨定自適應 Banner＋設定頁「支持我們」插屏（關閉後感謝 SnackBar）；僅 Android／iOS，桌面無廣告。

- **本輪全用官方測試值，上架前必換**：App ID Android `ca-app-pub-3940256099942544~3347511713`／iOS `ca-app-pub-3940256099942544~1458002511`；Banner 單元 Android `…/9214589741`／iOS `…/2435281174`；Interstitial 單元 Android `…/1033173712`／iOS `…/4411468910`（完整 ID 見 spec）。
- **測試裝置**：`jack_android36` 的 ID `<Task 6 實測值>` 已註冊在 `AdService.testDeviceIds`，`kDebugMode` 限定（release 不套用）。模擬器 wipe／重建後 ID 會變：重取看 `logcat -s Ads` 的 `setTestDeviceIds` 訊息，或 `settings get secure android_id` 取 MD5 大寫。
- **模擬器驗證要用 debug APK**（`flutter build apk --debug`）：release 的 `kDebugMode=false`，測試裝置設定不生效。
- **上架前待辦**：換正式 App ID／廣告單元 ID、清空 `testDeviceIds`、GDPR／UMP 同意、iOS `SKAdNetworkItems`。
- APK 體積：release `<實測 bytes>` bytes（`<實測 MiB>` MiB），對 47.89 MiB 基線增量 `<實測增量>`（GMA SDK＋webview transitive）。
```

(e) 若 Task 6 動過 minSdk：在 Android 工具鏈一節記一筆實際數字與原因。

- [ ] **Step 3: 驗證 AGENTS.md 更新後整體仍綠**

```bash
flutter analyze
flutter test
```

預期：與 Step 1 相同結果（文件變更不影響程式）。

- [ ] **Step 4: Commit**

```bash
git add AGENTS.md
git commit -m "docs(agents): reconcile AGENTS.md for the AdMob round"
```

- [ ] **Step 5: 回報**

向使用者回報：各 commit hash、測試總數、APK 增量、截圖路徑、剩餘待辦（上架前項目）。**不 push**——等使用者指示。