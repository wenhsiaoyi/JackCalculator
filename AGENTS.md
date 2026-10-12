# AGENTS.md — JackCalculator

Jack計算機。Flutter app，private repo：https://github.com/wenhsiaoyi/JackCalculator

**目前仍是 Flutter 範本階段**：`lib/main.dart` 是預設 counter 範例，`test/widget_test.dart` 也只測 counter。改動 app 邏輯時這兩個檔案會一起壞掉，要同步更新或刪除測試。

## 環境（本機實測 2026-10-13）

- Flutter **3.47.7** stable，SDK 在 `c:\tools\flutter`（非預設路徑）；Dart 3.13.5
- org / 套件名：`wenhsiaoyi` / `jack_calculator`；`pubspec.yaml` SDK 限制 `^3.13.5`
- 平台：**android / ios / windows / linux**。沒有 web、沒有 macos，`web/` 與 `macos/` 目錄不存在
- Visual Studio Community 2022 (17.14.39) + Windows 10 SDK 已安裝，Windows 桌面可建置
- Android SDK 在 `E:\Android\Sdk`
- 無 codegen（未引入 build_runner）、無 state management 套件、無第三方 plugin；依賴只有 `cupertino_icons`

## 指令

```powershell
flutter pub get
flutter analyze          # lint；設定於 analysis_options.yaml（flutter_lints）
flutter test             # 全部測試
flutter test test/widget_test.dart
flutter test --plain-name "Counter increments smoke test"   # 單一測試
flutter run -d windows   # 目前唯一能直接在本機跑起來的目标
```

建置：`flutter build apk`、`flutter build windows`

**改完 code 的標準檢查順序：`flutter analyze` → `flutter test`。**

## 會絆住 agent 的地方

### Android 目前建不了
Android SDK 版本是 **33.0.2**，但 Flutter 3.47.7 要求 **SDK 36 + BuildTools 28.0.3**。`flutter doctor` 因此報 Android toolchain 錯誤，`flutter build apk` 會失敗。要動 Android 前得先升 SDK。也沒有接任何 Android 裝置或模擬器（`flutter devices` 只有 Windows / Chrome / Edge）。

### 有 Chrome，但這個專案不能跑 web
`flutter doctor` 會列出 Chrome/Edge 可用，但專案沒有 `web/` 目錄，`flutter run -d chrome` 會直接失敗。要補 web 必須 `flutter create . --platforms web` — 但目前刻意不含 web，不要順手加。

### iOS 與 Linux 在本機建不了
Windows 主機上 `flutter build ios` / `flutter build linux` 必定失敗（分別需 macOS / Linux）。`linux/` 目錄存在只是原始碼產出，不代表可建置。

### App 顯示名稱還是範本預設值
「Jack計算機」目前只出現在 `pubspec.yaml` 的 `description`、`README.md`、GitHub repo 說明。使用者在裝置上看到的仍是：
- Android：`android/app/src/main/AndroidManifest.xml` → `android:label="jack_calculator"`
- iOS：`ios/Runner/Info.plist` → `CFBundleDisplayName` = `Jack Calculator`
- Windows / Linux：視窗標題在 `windows/runner/Runner.rc` 與 `linux/runner/my_application.cc`，預設為 `jack_calculator`

### Android release 簽章還是 debug key
`android/app/build.gradle.kts` 的 release `signingConfig` 指向 debug（模板 TODO 未處理）。不能直接產出可發佈的 APK。

### 換行符號雜訊
全域 git `core.autocrlf = true`，repo 內**沒有** `.gitattributes` → `git add` 時會出現 `LF will be replaced by CRLF` 警告。屬正常現象，不要因此去「修正」那些檔案。若要讓跨平台貢獻乾淨，加 `.gitattributes`（`* text=auto eol=lf`）勝過個別調整。

### 其他
- `flutter config --enable-windows-desktop --enable-linux-desktop` 已開啟。之後若用 `flutter create` 補平台，先確認這兩個旗標仍在。
- `.metadata` 已把 `lib/main.dart` 列為 `unmanaged_files` → `flutter create .` 不會覆蓋它，可安全用來補平台目錄。
- Android `applicationId` = `wenhsiaoyi.jack_calculator`（含底線）。上架前請確認商店是否接受。
- Android 工具鏈版本（`android/settings.gradle.kts`、`android/app/build.gradle.kts`）：AGP 9.1.0、Kotlin 2.4.0、Gradle 9.3.1、Java 17。
- 沒有 `analysis_options.yaml` 之外的 lint 設定；`android/`、`ios/`、`windows/`、`linux/` 已被 analyzer 排除。

## 尚未決定

計算機本身的規格還沒討論過（基本運算範圍、科學運算、歷史紀錄、主題…）。動 UI 或加功能前先跟使用者確認，不要自行發揮。