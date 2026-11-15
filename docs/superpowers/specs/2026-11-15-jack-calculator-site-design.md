# JackCalculator 開發者網站與隱私宣告 — 設計 spec

日期：2026-11-15｜狀態：設計已於對話核可（approach A）｜實作前須經使用者審查本檔
參考來源：JackCompass 上線站 `https://jackcompass-site.web.app/`（index／privacy）與其 repo `E:\projects\JackCompass\ads-txt\`（firebase.json／.firebaserc／public/）。

## 1. 背景與範圍

Play Console 上架需要隱私政策 URL；本輪建立 JackCalculator 的開發者網站（產品介紹＋隱私權政策）並以 **Firebase Hosting** 部署到既有專案 `jackcalculator-site`（編號 803093500271，與 App 的 Firebase／GA 同一專案）。

**本輪零 app 程式碼變更**（使用者裁定 2026-11-15）：隱私政策照現況如实寫，不先補 UMP／Analytics 同意閘門。UMP 同意表單仍留在 AGENTS.md「上架前待辦」；屆時依政策更新條款改頁。

非目標（OUT）：Qoder Sites（使用者已指定 Firebase Hosting）、Flutter web（專案刻意不含 web/）、app-ads.txt（現仍測試廣告 ID，正式 ID 落地時依 JackCompass 格式補）、任何 app 端同意機制、commit（須另獲使用者指示）。

## 2. Repo 佈局

```
site/
  firebase.json        # hosting: public=public, ignore=[firebase.json, **/.*, **/node_modules/**]（與 JackCompass 同）
  .firebaserc          # { "projects": { "default": "jackcalculator-site" } }
  .gitignore           # .firebase/
  public/
    index.html         # 產品頁，繁中＋英文同頁
    privacy.html       # 隱私權政策，繁中＋英文同頁
```

## 3. 頁面與風格

鏡像參考站：`<html lang="zh-Hant">`、繁中區塊後接英文區塊（各元素 `lang="en"`）、系統字體堆疊（-apple-system／Segoe UI／Noto Sans TC／Microsoft JhengHei）、`max-width: 44rem` 置中、`color-scheme: light dark` ＋ `prefers-color-scheme` 深色覆寫。accent 改 App 主色：淺色 `#0066CC`（`lib/core/theme.dart` seed）、深色 `#4D94FF`；深色覆寫：底 `#101418`、文字 `#e6e9ee`、muted `#a8b0ba`、邊框 `#333a44`、表頭底 `rgba(0, 102, 204, .14)`（結構同參考站）。

### 3.1 index.html

- 標題「Jack計算機」；lede：四則運算＋GT＋Tax±＋MU＋捨入與千分位，不需要註冊的 Android 計算機。
- 「這個 App 做什麼」：四則運算（Decimal 零誤差）、GT 總計、Tax+/Tax-、MU markup、F/CUT/UP/5-4 捨入＋小數位鎖定、千分位開關、三語（繁中／簡中／英文）；無帳號、無註冊、無內購；免費、以廣告支持。
- 「連結」：privacy.html（中英同頁）。
- 「聯絡」：wenhsiaoyi@gmail.com（與參考站同，開發者本人信箱）。
- footer：package `com.wenhsiaoyi.jackcalculator`、Last updated 2026-11-15。
- 英文區塊鏡像以上。

### 3.2 privacy.html（十一節，雙語；生效日 2026 年 11 月 15 日）

主張必須與現況一致（查證來源：AndroidManifest 僅 `INTERNET`；`lib/data/settings_repository.dart` 五個 key；AdMob 一輪與調整一輪 AGENTS.md 紀錄；Firebase 接入一輪 logcat 實測）：

1. **涵蓋範圍**：App（Play 套件 `com.wenhsiaoyi.jackcalculator`）與本網站。
2. **開發者直接收集**：無帳號系統、無自有伺服器、不索取姓名／email／電話；不持有可指認個人之資料。
3. **裝置上取得什麼**：**無位置、無感測器、無震動權限**（僅 INTERNET，供廣告與統計 SDK 網路行為）；計算輸入與 GT 記憶體只在本機，不出裝置。
4. **廣告（Google AdMob／GMA SDK）**：底部橫幅（顯示 15 秒後自動隱藏）＋設定頁「支持我們」按鈕觸發之插屏（使用者主動）。資料類別表同參考站四列（裝置或其他識別碼：Advertising ID／App Set ID／帳戶識別碼；大致位置：IP 推測；App 活動；App 資訊與效能：診斷），用途投放／衡量／防詐欺與診斷；由 Google 直接收集、開發者無法存取；連結 Google 隱私政策與廣告政策（zh-TW）。
   - **同意現況如实寫**：目前版本**無 UMP 同意表單**、無 App 內廣告同意設定；需同意之地區（EEA／英國等）依 Google SDK 預設機制（非個人化廣告）；**正式發佈前會補 Google 同意表單（UMP）並更新本頁**。
   - 退出管道：裝置「設定 → Google → 廣告」重置廣告識別碼／停用個人化；解除安裝。
5. **使用情形統計（Firebase Analytics）**：**預設收集**（無同意閘門，現況）：App 開啟／工作階段／畫面瀏覽等事件、App 版本／裝置型號／OS／語言／螢幕大小、App 執行個體 ID 與**裝置提供且未重置／退出之廣告識別碼**、IP 推之大略國家／地區。開發者僅見彙總統計；不將計算輸入送進 Analytics。由 Google Firebase 依其隱私說明與 Google 隱私政策處理。退出：裝置 Google 廣告設定、解除安裝；正式發佈前補同意機制並更新本頁（與第四節同一段承諾）。
6. **裝置上儲存**：僅五項設定（語系 `app_locale`、捨入 `rounding_mode`、小數位 `decimal_places`、千分位 `grouping`、稅率 `tax_rate`，shared_preferences）；無資料庫、無使用者內容；解除安裝一併清除；Android 自動備份但書（取決於裝置備份設定、非開發者發起）。
7. **資料分享**：不持有可指認資料故無分享；Google 為廣告與統計之資料處理者，開發者僅收彙總報表。
8. **兒童**：通用工具，不針對 13 歲以下兒童設計、不有意收集其個人資料。
9. **權利行使**：裝置 Google 廣告設定、解除安裝、來信；無 App 內同意設定（現況，不宣稱有）。
10. **政策更新**：資料處理方式改變（含補同意機制）時更新本頁與日期。
11. **聯絡**：wenhsiaoyi@gmail.com。

footer：回 index.html 連結＋Last updated 2026-11-15。英文區塊鏡像十一節。

## 4. Hosting 部署與驗證

- 本機 firebase CLI 15.34.1、已登入 wenhsiaoyi@gmail.com；`firebase projects:list` 實測含 `jackcalculator-site`（2026-11-15）。
- 部署：於 `site/` 目錄執行 `firebase deploy --only hosting`（首部署自動佈建預設 site）。
- 上線 URL：`https://jackcalculator-site.web.app/` 與 `https://jackcalculator-site.web.app/privacy.html`（firebaseapp.com 鏡像同內容）。
- 驗證：curl 兩頁 HTTP 200；內容抽查雙語標題、套件名、生效日；index↔privacy 連結互指；privacy 無「同意後才收集」等不實主張（grep 抽查）。
- 隱私 URL 供 Play Console listing 使用（記入 AGENTS.md Play 待辦）。

## 5. 文件更新

AGENTS.md 新增「開發者網站與 Firebase Hosting」一節：site/ 佈局、兩 URL、部署指令、隱私立場裁定（照現況、2026-11-15）、app-ads.txt 延後理由、UMP 落地時須同步改頁；Play 待辦補「listing 隱私 URL 已就緒」。

## 6. 驗收清單

- [ ] site/ 五檔齊備、firebase.json／.firebaserc 與參考同構
- [ ] 兩頁雙語齊全、無不實同意主張、accent 為 App 主色
- [ ] deploy 成功、兩 URL curl 200 且內容抽查通過
- [ ] AGENTS.md 網站節與 Play 待辦更新
- [ ] git status 僅 site/＋docs／AGENTS.md 變動（零 app 變更）
- [ ] 未 commit（待使用者指示）