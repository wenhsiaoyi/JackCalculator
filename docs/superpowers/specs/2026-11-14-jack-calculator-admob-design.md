# Jack計算機 AdMob 整合設計

> 狀態：待使用者 review（2026-11-14 brainstorming；第 1 節架構與資料流、第 2 節原生設定與測試已口頭核准，全文於本文件送審）
> 需求來源：`docs/requirement.txt`（3 條）＋`docs/admob-flutter-quickstart.html`（依 Google 官方快速入門整理的規格）
> 分支：`feat/admob`（自 main @ `a0686ae`）

## 背景與動機

需求 1 寫「替換原先 admob 的元件」，但**本 repo 沒有任何既有 AdMob**：`pubspec.yaml` 無 `google_mobile_ads`、`lib/` 無廣告程式碼、全分支無相關 commit。規格檔頁尾標示「JackCompass」，應是從其他專案帶來的文件。因此本輪實際上是**全新整合**，不是替換。

App 為免費工具，本輪建立變現機制：計算機主畫面底部 Banner＋設定頁「支持我們」按鈕觸發的全版（插屏）廣告，廣告關閉後以 SnackBar 感謝贊助。

關鍵限制：`google_mobile_ads` **僅支援 Android／iOS**（規格檔明載），而本專案四平台中 Windows 是唯一能本機驗證的目標。廣告必須以平台判斷跳過桌面，且不能破壞桌面建置。

## 範圍（IN）

1. 引入 `google_mobile_ads` 9.2.0，AGENTS.md 依賴政策記例外裁定。
2. `AdService`：平台 gating、SDK 初始化、測試裝置設定（`kDebugMode` 限定）、廣告單元 ID 管理、插屏載入。
3. 主畫面底部錨定自適應 Banner（`BannerAdView`）。
4. 設定頁「支持我們」按鈕：點選→載入插屏→顯示→關閉→感謝 SnackBar；失敗→錯誤 SnackBar。
5. 原生設定：Android `APPLICATION_ID` meta-data＋`INTERNET` 權限；iOS `GADApplicationIdentifier`。皆用官方範例 App ID。
6. 測試廣告：官方 Banner／Interstitial 測試廣告單元 ID；`jack_android36` 模擬器 device ID 明確註冊進測試裝置清單（需求 2）。
7. `AppStrings` 新增 3 個 key×3 語言（支持按鈕、感謝贊助、載入失敗）。
8. 新增測試＋AGENTS.md 對帳（需求 3：必要測試資訊）。

## 非目標（OUT）

- **其他廣告格式**：Native、Rewarded、Rewarded interstitial、App open 本輪不做。
- **Mediation、Ad Inspector、WebView API for Ads、SSV、GMA Next-Gen SDK**：規格檔有這些章節，但本輪只需基本 Banner＋Interstitial，不引入 `USE_NEXT_GEN_SDK`、不加 mediation adapters。
- **正式 App ID／廣告單元 ID**：本輪全用官方範例／測試 ID，上架前再換（記入 AGENTS.md 待辦）。
- **GDPR／UMP 同意流程**：發布到歐盟等地區前才需要，本輪不做，記入待辦。
- **iOS `SKAdNetworkItems`**：iOS 原生快速入門建議加入以利歸因，但本輪遵循的 Flutter 規格只要求 `GADApplicationIdentifier`；且 iOS 本機建不了、無從驗證。記入上架前待辦。
- **桌面廣告**：Windows／Linux 無廣告是刻意設計，不是缺漏。
- **不動引擎、主題、既有版面語意**：`lib/engine/`、`lib/core/theme.dart`、`lib/core/number_format.dart` 零改動；Banner 只在主畫面 Column 底部新增一個位置。
- **不做廣告預載池、頻率控制、遠端開關**：YAGNI。

## 設計定案（D 決議）

- **D1 平台 gating 用 `dart:io` 的 `Platform` 判斷，不用 conditional import／stub 套件。** `AdService.supported = Platform.isAndroid || Platform.isIOS`。`google_mobile_ads` 的 Dart 程式是純 Dart＋method channel，在四平台都能編譯，只在 runtime 呼叫時才因無原生實作而失敗 → 桌面只要不呼叫即可。`initialize()` 在 `!supported` 時直接 return。**實作時必須實測 `flutter build windows` 確認 plugin 不破壞桌面建置**（Flutter 對無該平台實作的 plugin 會跳過並警告，預期可過，但不能假設）。
- **D2 集中式 `AdService`（`lib/core/ad_service.dart`）。** 唯一管理廣告設定的地方：`supported`、`initialize()`、`bannerAdUnitId`／`interstitialAdUnitId`（按平台回傳測試 ID）、`loadInterstitial()`。`BannerAdView` 因 `AdWidget`／`BannerAd` 型別必然 import `google_mobile_ads`，但設定與 ID 一律取自 `AdService`，不得散落。廣告是純視圖層關注點，**不建 Cubit**（方案 C 已否決）。
- **D3 測試裝置設定 `kDebugMode` 限定。** `initialize()` 完成後呼叫 `MobileAds.instance.updateRequestConfiguration(RequestConfiguration(testDeviceIds: [<模擬器 ID>]))`。ID 於實作階段第一次在 `jack_android36` 跑起來後，從 logcat 的 `I/Ads: Use RequestConfiguration.Builder.setTestDeviceIds(Arrays.asList("…"))` 訊息取得，填入 `AdService` 與 AGENTS.md。規格明載模擬器會自動成為測試裝置，但需求 2 要求明確註冊，兩者並行。**發布前必須移除此設定**（官方要求，記入 AGENTS.md 警告）。
- **D4 Banner 用標準錨定自適應，不用規格範例的 large。** `AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width)`（約 50–60dp），而非 `getLargeAnchoredAdaptiveBannerAdSize`（最高可達螢幕 20%、150dp，會明顯壓縮鍵盤）。同屬規格定義的錨定自適應家族，固定長寬比、重新整理時周圍內容不位移。寬度取自版面實際可用寬（`MediaQuery`／`LayoutBuilder`）。手機已鎖直式，不需處理方向變更。
- **D5 Banner 位置與生命週期。** 主畫面 Column 底部（Expanded 鍵盤之後、SafeArea 之內），全寬。`BannerAdView` 為 StatefulWidget：載入前、載入失敗、桌面一律 `SizedBox.shrink()`（不佔空間）；`onAdLoaded` 後以符合廣告寬高的 `SizedBox` 包 `AdWidget` 顯示；`onAdFailedToLoad` 中 `ad.dispose()`；widget dispose 時釋放 Banner。`load()` 必須在進 widget tree 之前呼叫（規格要求）。鍵盤按鈕已有 `LayoutBuilder` 自適應高度，會被壓縮但不會 overflow —— 由既有窄窗測試守住。
- **D6 插屏 on-demand 載入，不預載。** 點「支持我們」→ 按鈕停用＋顯示 loading → `loadInterstitial()` → 成功設 `fullScreenContentCallback` 後 `show()`：
  - `onAdDismissedFullScreenContent`：`ad.dispose()`＋感謝贊助 SnackBar。
  - `onAdFailedToShowFullScreenContent`：`ad.dispose()`＋錯誤 SnackBar。
  - 載入失敗（`onAdFailedToLoad`）：錯誤 SnackBar，不顯示廣告。
  一次一顆，不重複請求。
- **D7 支持按鈕桌面整個隱藏。** `!AdService.supported` 時不建該 widget（不是顯示但停用）。位置在設定頁 ListView 末尾（語言選單之後），icon＋標籤。
- **D8 原生設定用官方範例 App ID。**
  - Android `AndroidManifest.xml`：`<application>` 內加 `com.google.android.gms.ads.APPLICATION_ID` meta-data = `ca-app-pub-3940256099942544~3347511713`；另加 `android.permission.INTERNET`（目前 main manifest 沒有，只存在 debug／profile 變體，release 會缺）。
  - iOS `Info.plist`：`GADApplicationIdentifier` = `ca-app-pub-3940256099942544~1458002511`（2026-11-14 對官方文件核實；**注意與舊常見值 `~1458004511` 不同**）。iOS 本機建不了，僅語法層修改。
- **D9 `main()` 改 async。** `WidgetsFlutterBinding.ensureInitialized()` → `await AdService.initialize()` → `runApp()`。規格：SDK 初始化 Future 於完成或 30 秒後結束；行動裝置啟動會多一點等待，可接受；桌面為 no-op 零延遲。初始化必須在請求任何廣告之前完成，故 await 而非 fire-and-forget。
- **D10 字串走 `AppStrings`，三語同 key。** 新增 `supportUs`（支持我們／支持我们／Support us）、`thanksForSupport`（感謝您的贊助！／感谢您的赞助！／Thanks for your support!）、`adLoadFailed`（廣告載入失敗，請稍後再試／广告加载失败，请稍后再试／Ad failed to load. Please try again later.）。既有完整性測試（三語同 key 不得為 null、不得與英文佔位相同）自動納管。zh-Hans 欄用道地大陸用語（豁免規範）。
- **D11 依賴政策例外裁定（2026-11-14 使用者核准）。** `google_mobile_ads` 官方只支援 Android／iOS，牴觸政策第 2 條「至少 Windows 可建置」。裁定：**廣告類 plugin 僅 Android／iOS 生效，桌面建置不受影響即可**（無 Windows 原生碼，Flutter 跳過未實作平台）。AGENTS.md 依賴政策節記此例外。Metadata 實測（pub.dev API，2026-11-14）：9.2.0，`sdk: >=3.10.0 <4.0.0`（與本專案 `^3.13.5` 可共同解析）、`flutter: >=3.38.1`（本機 3.47.7 ✅）、平台 android／ios；transitive 帶入 `webview_flutter ^4.14.1`、`webview_flutter_android ^4.12.0`、`webview_flutter_wkwebview ^3.25.1`（同樣無 Windows 原生碼）。無 codegen。
- **D12 APK 體積增量。** GMA SDK 預期增加數 MB。本輪不設門檻，終驗記錄 `flutter build apk` 實際增量（基線 47.89 MiB／50,212,142 bytes），寫進 AGENTS.md 對帳。
- **D13 錯誤處理原則：廣告失敗永遠不干擾計算機本業。** Banner 失敗→隱形；插屏失敗→SnackBar 告知；不拋異常、不擋任何操作。無網路時 App 照常可用。

## 廣告 ID 一覽（本輪全用官方測試值）

| 用途 | Android | iOS |
|---|---|---|
| App ID（原生設定） | `ca-app-pub-3940256099942544~3347511713` | `ca-app-pub-3940256099942544~1458002511` |
| Banner 廣告單元 | `ca-app-pub-3940256099942544/9214589741` | `ca-app-pub-3940256099942544/2435281174` |
| Interstitial 廣告單元 | `ca-app-pub-3940256099942544/1033173712` | `ca-app-pub-3940256099942544/4411468910` |

測試裝置 ID：實作階段從 `jack_android36` 的 logcat 取得後填入 `AdService`（`kDebugMode` 限定）與 AGENTS.md。模擬器 wipe／重建後 ID 可能改變，重取方法記入 AGENTS.md。

## 測試策略

- **單元測試**：`AdService.supported` 在 Windows host 為 false；`initialize()` 在桌面為 no-op（若誤觸 `MobileAds` 會拋 `MissingPluginException`，測試通過即證明未呼叫）；廣告單元 ID 的平台選擇邏輯抽成可測純函式。
- **Widget 測試**：桌面 host 上 `CalculatorScreen` 的 Banner 位置渲染為 shrink、`SettingsScreen` 無支持按鈕；既有 182 條測試零回歸。
- **字串測試**：既有三語完整性測試自動覆蓋 3 個新 key。
- **模擬器實測**（UI acceptance 由使用者親驗，agent 備截圖與指令）：
  1. `flutter build apk` → `scripts/adb_monitor.ps1 install …` 裝上 `jack_android36`。
  2. 主畫面底部 Banner 出現「Test Ad」標籤。
  3. 設定頁「支持我們」→ 插屏「Test Ad」→ 關閉 → 感謝 SnackBar。
  4. Android 16 的 `input tap` 會被靜默忽略，點擊用 timed same-point swipe；截圖用 `screencap`（實測可靠）。
- **標準檢查順序**：`flutter analyze` → `flutter test` → `flutter build windows`（驗證 D1）→ `flutter build apk`（記錄 D12 增量）。

## AGENTS.md 對帳（需求 3）

1. 一階依賴清單新增 `google_mobile_ads`（版本、平台限制、transitive、政策例外裁定）。
2. 新增 AdMob 節：範例 App ID、四組測試廣告單元 ID、模擬器測試裝置 ID 與重取方法（logcat 訊息長相）、`kDebugMode` gate、**上架前必換正式 ID＋移除測試裝置設定**警告、GDPR／UMP／SKAdNetworkItems 待辦。
3. 測試基線數字更新（182＋新增）。
4. APK 體積增量記錄（D12）。
5. 環境／指令節視需要補模擬器廣告測試流程。

## 驗收標準

1. `flutter analyze` 零 issue、`flutter test` 全綠（182＋新增）。
2. `flutter build windows` 成功 —— 證明 plugin 不破壞桌面。
3. `flutter build apk` 成功，體積增量已記錄。
4. 模擬器：Banner 於底部顯示「Test Ad」；支持按鈕流程完整（插屏 Test Ad → 關閉 → 感謝 SnackBar）。
5. Windows exe：無 Banner、無支持按鈕，既有功能不變。
6. AGENTS.md 已更新（需求 3）。

## 風險

- **plugin 的 minSdk 要求**：若 GMA SDK 要求的 minSdk 高於現行 `flutter.minSdkVersion`，需調 `android/app/build.gradle.kts` 並記錄；實作時以建置結果為準，不預先假設數字。
- **transitive webview 家族**：可能增加 Android 建置時間與 APK 體積，終驗觀察。
- **`await initialize()` 延遲行動啟動**：最壞 30 秒 timeout（規格），一般很快；可接受，若實測過慢再議。
- **測試裝置 ID 隨模擬器重建改變**：重取方法文件化。
- **iOS 值未經本機驗證**：範例 App ID 已對官方文件核實，但 iOS 建置本機不可行，僅語法層保證。
- **廣告載入失敗（無網路等）**：D13 保證不影響本業，SnackBar／隱形處理。

## 上架前待辦（本輪不做，僅記錄）

1. 換正式 AdMob App ID（Android＋iOS）與廣告單元 ID。
2. 移除 `kDebugMode` 測試裝置設定。
3. GDPR／UMP 同意流程（若發布歐盟等地區）。
4. iOS `SKAdNetworkItems`（歸因最佳化）。
5. Android release 簽章（現仍 debug key，既有待辦）。