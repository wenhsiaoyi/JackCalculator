# JackCalculator 開發者網站與隱私宣告 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立 JackCalculator 雙語開發者網站（index＋privacy）並以 Firebase Hosting 部署到 jackcalculator-site，供 Play Console listing 使用。

**Architecture:** 純靜態 HTML（無 JS、無建置步驟），鏡像 JackCompass 上線站結構；`site/` 目錄自帶 firebase.json／.firebaserc，firebase CLI 部署；隱私主張照 App 現況如实寫（無 UMP、Analytics 預設收集）。

**Tech Stack:** HTML/CSS（prefers-color-scheme 深淺雙色）、Firebase Hosting（firebase CLI 15.34.1，已登入 wenhsiaoyi@gmail.com）。

**Spec:** `docs/superpowers/specs/2026-11-15-jack-calculator-site-design.md`

## Global Constraints

- 中文一律台灣正體用語與全形標點；中英文之間半形空格；專有名詞保留英文。
- **任何 task 都不得 commit**（repo 政策：commit 須使用者明確指示）；結尾維持未提交狀態。
- **零 app 程式碼變更**：不動 lib/、android/、ios/、windows/、linux/、pubspec.*。
- 套件名 `com.wenhsiaoyi.jackcalculator`；聯絡信箱 wenhsiaoyi@gmail.com；生效／更新日期 2026-11-15。
- accent：淺色 `#0066CC`、深色 `#4D94FF`；深色底 `#101418`、文字 `#e6e9ee`、muted `#a8b0ba`、邊框 `#333a44`、表頭底 `rgba(0, 102, 204, .14)`。
- Firebase 專案 `jackcalculator-site`；部署指令於 `site/` 目錄執行 `firebase deploy --only hosting`。
- 隱私政策不得宣稱「同意後才收集」「預設關閉」「UMP 同意表單已有」「App 內廣告同意設定」等現況不存在之機制。
- 雙語同頁：繁中區塊後接英文區塊，英文元素帶 `lang="en"`。

---

### Task 1: site/ 骨架與 index.html

**Files:**
- Create: `site/firebase.json`
- Create: `site/.firebaserc`
- Create: `site/.gitignore`
- Create: `site/public/index.html`

**Interfaces:**
- Consumes: 無（首 task）。
- Produces: `site/public/index.html` 之 `./privacy.html` 連結（Task 2 產出該頁）；共用 CSS 區塊（Task 2 复用同一份 style）。

- [ ] **Step 1: 寫失敗檢查**

Run:
```bash
test -f site/public/index.html && echo EXISTS || echo MISSING
python -c "import json;json.load(open('site/firebase.json',encoding='utf-8'));json.load(open('site/.firebaserc',encoding='utf-8'));print('JSON_OK')"
```
Expected: `MISSING`；python 報 FileNotFoundError（檔案尚不存在）。

- [ ] **Step 2: 建立三個設定檔**

`site/firebase.json`:
```json
{
  "hosting": {
    "public": "public",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ]
  }
}
```
`site/.firebaserc`:
```json
{
  "projects": {
    "default": "jackcalculator-site"
  }
}
```
`site/.gitignore`:
```
.firebase/
```

- [ ] **Step 3: 建立 index.html（完整內容）**

```html
<!DOCTYPE html>
<html lang="zh-Hant">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Jack計算機 — 商用計算機</title>
<meta name="description" content="Jack計算機的開發者網站：隱私權政策、聯絡方式。四則運算、GT、Tax±、MU、捨入與千分位的 Android 計算機。">
<style>
:root { color-scheme: light dark; --accent: #0066CC; }
body {
  margin: 0 auto; padding: 2.5rem 1.25rem 4rem; max-width: 44rem;
  font: 16px/1.75 -apple-system, "Segoe UI", "Noto Sans TC", "Microsoft JhengHei", system-ui, sans-serif;
}
h1 { font-size: 1.75rem; margin: 0 0 .25rem; letter-spacing: .01em; }
h2 { font-size: 1.125rem; margin: 2.5rem 0 .75rem; }
p, li { margin: .6rem 0; }
.lede { color: #666; margin: 0 0 2rem; }
a { color: var(--accent); text-decoration-thickness: 1px; text-underline-offset: 2px; }
ul { padding-left: 1.25rem; }
hr { border: 0; border-top: 1px solid #ddd; margin: 3rem 0 0; }
footer { font-size: .875rem; color: #666; }
@media (prefers-color-scheme: dark) {
  body { background: #101418; color: #e6e9ee; }
  .lede, footer { color: #a8b0ba; }
  hr { border-color: #333a44; }
  a { color: #4D94FF; }
}
</style>
</head>
<body>

<h1>Jack計算機</h1>
<p class="lede">四則運算＋GT＋Tax±＋MU＋捨入與千分位，一個不需要註冊的 Android 計算機。</p>

<h2>這個 App 做什麼</h2>
<ul>
  <li><strong>四則運算</strong>：Decimal 高精度、零浮點誤差。</li>
  <li><strong>商用鍵</strong>：GT 總計、Tax+/Tax-、MU markup。</li>
  <li><strong>捨入與顯示</strong>：F/CUT/UP/5-4 捨入、小數位鎖定、千分位開關。</li>
  <li><strong>三語</strong>：繁中／簡中／英文，可跟隨系統。</li>
  <li>沒有帳號、沒有註冊、沒有內購；免費、以廣告支持。</li>
</ul>

<h2>連結</h2>
<ul>
  <li><a href="./privacy.html">隱私權政策（Privacy Policy）</a>｜中英同頁</li>
</ul>

<h2>聯絡</h2>
<p>任何問題、資料相關請求，或希望我把某個功能拿掉：<a href="mailto:wenhsiaoyi@gmail.com">wenhsiaoyi@gmail.com</a></p>

<hr>

<h1 lang="en">Jack Calculator</h1>
<p class="lede" lang="en">Arithmetic, GT, Tax±, MU, rounding and thousands separators — an Android calculator that needs no sign-up.</p>

<h2 lang="en">What the app does</h2>
<ul lang="en">
  <li><strong>Arithmetic</strong>: decimal-based, no floating-point drift.</li>
  <li><strong>Commercial keys</strong>: GT total, Tax+/Tax-, MU markup.</li>
  <li><strong>Rounding &amp; display</strong>: F/CUT/UP/5-4 rounding, fixed decimal places, thousands-separator toggle.</li>
  <li><strong>Three languages</strong>: Traditional Chinese, Simplified Chinese, English; can follow the system.</li>
  <li>No account, no sign-up, no in-app purchases. Free, supported by ads.</li>
</ul>

<h2 lang="en">Links</h2>
<ul lang="en">
  <li><a href="./privacy.html">Privacy Policy</a> — Chinese and English on the same page</li>
</ul>

<h2 lang="en">Contact</h2>
<p lang="en">Questions, data requests, or a feature you would like removed: <a href="mailto:wenhsiaoyi@gmail.com">wenhsiaoyi@gmail.com</a></p>

<footer>
  <p>Developer website for Jack計算機 (package <code>com.wenhsiaoyi.jackcalculator</code>). Last updated 2026-11-15.</p>
</footer>

</body>
</html>
```

- [ ] **Step 4: 跑檢查確認通過**

Run:
```bash
python -c "import json;json.load(open('site/firebase.json',encoding='utf-8'));json.load(open('site/.firebaserc',encoding='utf-8'));print('JSON_OK')"
grep -c 'lang="en"' site/public/index.html
grep -c 'com.wenhsiaoyi.jackcalculator' site/public/index.html
grep -c './privacy.html' site/public/index.html
```
Expected: `JSON_OK`；lang="en" ≥ 8；套件名 ≥ 1；privacy 連結 ≥ 2。

---

### Task 2: privacy.html（雙語十一節、現況主張）

**Files:**
- Create: `site/public/privacy.html`

**Interfaces:**
- Consumes: Task 1 的 CSS 區塊（同一份 style，另加 table 與 .updated 規則）。
- Produces: 上線後之隱私 URL `https://jackcalculator-site.web.app/privacy.html`（Task 3 驗證、Task 4 記入文件）。

- [ ] **Step 1: 寫失敗檢查**

Run:
```bash
test -f site/public/privacy.html && echo EXISTS || echo MISSING
```
Expected: `MISSING`。

- [ ] **Step 2: 建立 privacy.html（完整內容）**

head 與 Task 1 同構，僅換：
```html
<title>隱私權政策 — Jack計算機</title>
<meta name="description" content="Jack計算機的隱私權政策：計算輸入只在本機；廣告由 Google Mobile Ads SDK 投放；使用情形統計由 Firebase Analytics 預設收集；現況無同意表單、正式發佈前補上。">
```
style 完整內容（含 table 與 .updated 規則）：
```css
:root { color-scheme: light dark; --accent: #0066CC; }
body {
  margin: 0 auto; padding: 2.5rem 1.25rem 4rem; max-width: 44rem;
  font: 16px/1.75 -apple-system, "Segoe UI", "Noto Sans TC", "Microsoft JhengHei", system-ui, sans-serif;
}
h1 { font-size: 1.75rem; margin: 0 0 .25rem; letter-spacing: .01em; }
h2 { font-size: 1.125rem; margin: 2.25rem 0 .75rem; }
p, li { margin: .6rem 0; }
.updated { color: #666; margin: 0 0 2rem; }
a { color: var(--accent); text-decoration-thickness: 1px; text-underline-offset: 2px; }
ul { padding-left: 1.25rem; }
table { border-collapse: collapse; width: 100%; margin: 1rem 0; font-size: .9375rem; }
th, td { border: 1px solid #ddd; padding: .5rem .625rem; text-align: left; vertical-align: top; }
th { background: rgba(0, 102, 204, .08); font-weight: 600; }
hr { border: 0; border-top: 1px solid #ddd; margin: 3rem 0 0; }
footer { font-size: .875rem; color: #666; }
@media (prefers-color-scheme: dark) {
  body { background: #101418; color: #e6e9ee; }
  .updated, footer { color: #a8b0ba; }
  hr { border-color: #333a44; }
  th, td { border-color: #333a44; }
  th { background: rgba(0, 102, 204, .14); }
  a { color: #4D94FF; }
}
```

body 完整內容（繁中十一節＋英文十一節）：

```html
<h1>隱私權政策</h1>
<p class="updated">Jack計算機｜生效日期：2026 年 11 月 15 日</p>

<h2>一、這份政策涵蓋什麼</h2>
<p>本政策適用於 Jack計算機 這個 Android 應用程式（Google Play 上的套件名稱 <code>com.wenhsiaoyi.jackcalculator</code>）與這個開發者網站。它說明這個 App 取得哪些資料、那些資料去哪裡，以及你可以怎麼控制它。</p>

<h2>二、我們（開發者）直接收集什麼</h2>
<ul>
  <li>這個 App <strong>沒有帳號系統</strong>：不需要註冊，也不會向你索取姓名、電子郵件、電話或任何足以識別你個人的資料。</li>
  <li>這個 App <strong>沒有一個屬於我們的伺服器</strong>：除了廣告 SDK 與使用情形統計（第四、五節）的網路行為之外，App 本身不會把資料送出裝置。</li>
  <li>我們手上沒有一份可以指認「你是誰」的資料，所以也沒有個人資料可以賣出或分享。</li>
</ul>

<h2>三、App 在你裝置上取得什麼</h2>
<ul>
  <li><strong>沒有位置、感測器或震動權限</strong>：計算機不需要這些；App 只宣告 <code>INTERNET</code> 權限，供廣告與使用情形統計 SDK 的網路行為。</li>
  <li><strong>計算輸入只在本機</strong>：你輸入的數字、運算子與 GT 記憶體只在裝置上運算與顯示，不會上傳、不會傳給我們或任何第三方。</li>
</ul>

<h2>四、廣告：由 Google Mobile Ads SDK 收集什麼</h2>
<p>這個 App 使用 <strong>Google AdMob（Google Mobile Ads SDK）</strong>投放兩種廣告：底部橫幅（顯示 15 秒後自動隱藏），以及你在設定頁主動點「支持我們」時顯示的全螢幕插屏。那個 SDK 會<strong>自行</strong>收集並使用下列類別的資料，用途是投放廣告、衡量成效，以及防詐欺與診斷：</p>
<table>
  <thead>
    <tr><th>資料類別</th><th>內容</th><th>用途</th></tr>
  </thead>
  <tbody>
    <tr><td>裝置或其他識別碼</td><td>廣告識別碼（Advertising ID）、App Set ID、帳戶識別碼</td><td>投放廣告、分析、防詐欺／安全／診斷</td></tr>
    <tr><td>大致位置</td><td>由 IP 位址推測的大略位置</td><td>投放廣告、防詐欺／安全／診斷</td></tr>
    <tr><td>App 活動</td><td>你在 App 內與產品／廣告的互動</td><td>投放廣告、分析、防詐欺／安全／診斷</td></tr>
    <tr><td>App 資訊與效能</td><td>診斷資料</td><td>分析、防詐欺／安全／診斷</td></tr>
  </tbody>
</table>
<p>這些資料是由 Google 的 SDK 直接收集並依 <a href="https://policies.google.com/privacy?hl=zh-TW">Google 隱私政策</a>處理；<strong>開發者無法存取這批資料</strong>，也不經手它。相關說明請看 <a href="https://policies.google.com/technologies/ads?hl=zh-TW">Google 的廣告政策</a>。</p>

<h3>同意現況與退出管道</h3>
<ul>
  <li><strong>目前版本沒有 UMP 同意表單</strong>，也沒有 App 內的廣告同意設定。在歐洲經濟區、英國等依法需同意之地區，廣告請求依 Google SDK 對該等地區的預設機制處理（非個人化廣告）。</li>
  <li><strong>正式發佈前會補上 Google 同意表單（User Messaging Platform）</strong>，屆時本頁會同步更新（第十節）。</li>
  <li><strong>重置或移除廣告識別碼</strong>：在裝置的「設定 → Google → 廣告」可以重置廣告識別碼或選擇停用廣告個人化；也可以解除安裝本 App。</li>
</ul>

<h2>五、使用情形統計：Google Firebase Analytics</h2>
<p>這個 App 內建 <strong>Google Firebase Analytics</strong>，用來了解哪些功能有人使用，作為改進 App 的依據。現況為<strong>預設收集</strong>（尚無同意閘門；正式發佈前會補同意機制並更新本頁）。它處理下列資料：</p>
<table>
  <thead>
    <tr><th>資料類別</th><th>內容</th><th>用途</th></tr>
  </thead>
  <tbody>
    <tr><td>App 活動</td><td>App 開啟、工作階段、畫面瀏覽、使用時間等事件</td><td>統計與改善 App</td></tr>
    <tr><td>App 資訊與效能</td><td>App 版本、裝置型號、作業系統版本、語言、螢幕大小</td><td>統計與改善 App</td></tr>
    <tr><td>裝置或其他識別碼</td><td>隨機產生的 App 執行個體 ID；裝置提供且你未重置／退出的廣告識別碼</td><td>統計與改善 App</td></tr>
    <tr><td>大致位置</td><td>由 IP 位址推得的大略國家／地區</td><td>統計與改善 App</td></tr>
  </tbody>
</table>
<p>這個 App <strong>不會</strong>把你輸入的數字或運算內容送進 Analytics。這些資料由 Google 的 Firebase 服務處理，依 <a href="https://firebase.google.com/support/privacy?hl=zh-TW">Firebase 的隱私權說明</a>與 <a href="https://policies.google.com/privacy?hl=zh-TW">Google 隱私權政策</a>。開發者看到的<strong>只有彙總統計</strong>（例如「這週有幾次開啟」），無法從中識別你個人。</p>
<p>退出管道：裝置的「設定 → Google → 廣告」（重置廣告識別碼／停用廣告個人化）、解除安裝本 App；同意機制上線後亦得經同意表單拒絕（第四節）。</p>

<h2>六、存放在裝置上的東西</h2>
<ul>
  <li>這個 App 沒有資料庫，也不寫入任何屬於你的使用者內容。</li>
  <li>會留在裝置上的只有五項設定：你在 App 內選擇的<strong>語系</strong>、<strong>捨入模式</strong>、<strong>小數位數</strong>、<strong>千分位開關</strong>與<strong>稅率</strong>。</li>
  <li>上述都會在<strong>解除安裝時一併清除</strong>。Android 的自動備份可能會把這些本機設定備份進你自己的 Google 帳號——那取決於你裝置的備份設定，不是我們發起的行為；你可以在裝置的備份設定裡關掉它。</li>
</ul>

<h2>七、資料分享</h2>
<p>由於我們不持有可以指認你個人的資料，因此不存在「我們把你的資料分享給第三方」這種事。廣告那一節的資料由 Google 依它自己的政策處理；使用情形統計由 Google Firebase 依它自己的政策處理（Google 是我們的資料處理者），開發者只會收到彙總報表。請以 Google 的說明為準。</p>

<h2>八、兒童</h2>
<p>這個 App 是通用工具，不針對 13 歲以下兒童設計，也不有意收集兒童的個人資料。</p>

<h2>九、你的權利怎麼行使</h2>
<p>要退出廣告識別碼相關收集、或要求處理任何與你有關的資料，可以用裝置的 Google 廣告設定、解除安裝 App，或直接寫信給我們。現況沒有 App 內同意設定；由於我們不持有可以指認你的資料，能做的處理限於這些設定與你主動提供給我們的內容。</p>

<h2>十、這份政策會更新</h2>
<p>如果 App 的資料處理方式改變（例如補上同意表單、新增功能或換掉廣告供應商），我們會更新本頁並在上方更新日期。</p>

<h2>十一、聯絡方式</h2>
<p>資料相關請求、隱私問題，或任何希望我們處理的事：<a href="mailto:wenhsiaoyi@gmail.com">wenhsiaoyi@gmail.com</a></p>

<hr>

<h1 lang="en">Privacy Policy</h1>
<p class="updated" lang="en">Jack Calculator — effective 15 November 2026</p>

<h2 lang="en">1. What this policy covers</h2>
<p lang="en">This policy covers the Jack Calculator Android application (package <code>com.wenhsiaoyi.jackcalculator</code> on Google Play) and this developer website. It explains what data the app accesses, where that data goes, and how you can control it.</p>

<h2 lang="en">2. What we (the developer) collect directly</h2>
<ul lang="en">
  <li>The app has <strong>no account system</strong>: no sign-up, and it never asks for your name, email, phone number, or anything else that identifies you.</li>
  <li>The app has <strong>no server of ours</strong>: apart from the ad SDK and usage-statistics network activity (sections 4 and 5), the app itself does not send any of your data off the device.</li>
  <li>We hold nothing that identifies you, so there is no personal data for us to sell or share.</li>
</ul>

<h2 lang="en">3. What the app accesses on your device</h2>
<ul lang="en">
  <li><strong>No location, sensor, or vibration permissions</strong>: a calculator does not need them. The app declares only the <code>INTERNET</code> permission, for the ad and usage-statistics SDKs' network activity.</li>
  <li><strong>Your calculations stay on the device</strong>: the numbers and operators you enter, and the GT memory, are computed and displayed locally. They are never uploaded or passed to us or any third party.</li>
</ul>

<h2 lang="en">4. Ads: what the Google Mobile Ads SDK collects</h2>
<p lang="en">This app uses <strong>Google AdMob (the Google Mobile Ads SDK)</strong> to serve two ad formats: a bottom banner (which hides itself 15 seconds after appearing) and a full-screen interstitial shown only when you tap "Support us" in Settings. That SDK <strong>itself</strong> collects and uses the following categories of data, for serving ads, measuring them, and fraud prevention and diagnostics:</p>
<table lang="en">
  <thead>
    <tr><th>Data category</th><th>What it includes</th><th>Purpose</th></tr>
  </thead>
  <tbody>
    <tr><td>Device or other IDs</td><td>Advertising ID, App Set ID, account IDs</td><td>Ads shown or served, analytics, fraud prevention / security / diagnostics</td></tr>
    <tr><td>Coarse location</td><td>Approximate location derived from the IP address</td><td>Ads shown or served, fraud prevention / security / diagnostics</td></tr>
    <tr><td>App activity</td><td>Your interactions with the product and with ads</td><td>Ads shown or served, analytics, fraud prevention / security / diagnostics</td></tr>
    <tr><td>App information and performance</td><td>Diagnostic information</td><td>Analytics, fraud prevention / security / diagnostics</td></tr>
  </tbody>
</table>
<p lang="en">Google collects this data directly through the SDK and handles it under the <a href="https://policies.google.com/privacy">Google Privacy Policy</a>; <strong>the developer cannot access it</strong> and is not a party to it. See also <a href="https://policies.google.com/technologies/ads">how Google uses ad-related data</a>.</p>

<h3 lang="en">Consent status and how to opt out</h3>
<ul lang="en">
  <li><strong>The current version has no UMP consent message</strong> and no in-app ad consent settings. In the EEA, the UK and other regions where consent is required by law, ad requests follow the Google SDK's default mechanism for those regions (non-personalised ads).</li>
  <li><strong>Before the production release we will add Google's consent message (User Messaging Platform)</strong> and update this page accordingly (section 10).</li>
  <li><strong>Reset or remove the Advertising ID</strong>: in your device's Settings → Google → Ads you can reset the advertising ID or opt out of personalised ads; uninstalling the app removes it from that app entirely.</li>
</ul>

<h2 lang="en">5. Usage statistics: Google Firebase Analytics</h2>
<p lang="en">The app bundles <strong>Google Firebase Analytics</strong> to understand which features are used, so we can improve the app. It currently <strong>collects by default</strong> (no consent gate yet; we will add a consent mechanism before the production release and update this page). It processes:</p>
<table lang="en">
  <thead>
    <tr><th>Data category</th><th>What it includes</th><th>Purpose</th></tr>
  </thead>
  <tbody>
    <tr><td>App activity</td><td>App opens, sessions, screen views, engagement time and similar events</td><td>Statistics and app improvement</td></tr>
    <tr><td>App information and performance</td><td>App version, device model, OS version, language, screen size</td><td>Statistics and app improvement</td></tr>
    <tr><td>Device or other IDs</td><td>A randomly generated app instance ID; the advertising ID if your device provides one and you have not reset or opted out of it</td><td>Statistics and app improvement</td></tr>
    <tr><td>Coarse location</td><td>Approximate country/region derived from the IP address</td><td>Statistics and app improvement</td></tr>
  </tbody>
</table>
<p lang="en">The app <strong>does not</strong> send the numbers or calculations you enter into Analytics. This data is processed by Google's Firebase service under the <a href="https://firebase.google.com/support/privacy">Firebase privacy documentation</a> and the <a href="https://policies.google.com/privacy">Google Privacy Policy</a>. The developer sees <strong>aggregate statistics only</strong> (for example, "this week the app was opened N times") and cannot identify you from them.</p>
<p lang="en">Opt-out routes: your device's Settings → Google → Ads (reset the advertising ID / opt out of ad personalisation), or uninstalling the app; once the consent mechanism ships, refusing via the consent message (section 4) will also stop collection.</p>

<h2 lang="en">6. What is stored on the device</h2>
<ul lang="en">
  <li>The app has no database and does not write any of your own content to storage.</li>
  <li>Only five settings stay on the device: your <strong>language</strong>, <strong>rounding mode</strong>, <strong>decimal places</strong>, <strong>thousands-separator toggle</strong> and <strong>tax rate</strong> chosen in the app.</li>
  <li>All of these are <strong>removed when you uninstall</strong> the app. Android's automatic backup may include these small settings in your own Google account backup (that follows your device's backup setting; we do not initiate it) — you can turn it off in your device's backup settings.</li>
</ul>

<h2 lang="en">7. Sharing</h2>
<p lang="en">Because we hold nothing that identifies you, there is no "we share your data with third parties" for us to disclose. The ad data described above is handled by Google under its own policy; the usage statistics are handled by Google Firebase under its own policy (Google acts as our data processor), and the developer receives aggregate reports only. Please refer to Google's documentation.</p>

<h2 lang="en">8. Children</h2>
<p lang="en">This app is a general-purpose tool. It is not designed for children under 13 and we do not knowingly collect their personal data.</p>

<h2 lang="en">9. Exercising your rights</h2>
<p lang="en">To opt out of advertising-ID-related collection, or to ask us about anything related to your data, use your device's Google Ads settings, uninstall the app, or email us. There is no in-app consent setting at present; because we hold nothing that identifies you, what we can do is limited to those settings and anything you voluntarily send us.</p>

<h2 lang="en">10. Updates to this policy</h2>
<p lang="en">If the app's data handling changes — adding a consent message, a new feature, or a different ad provider — we will update this page and the effective date above.</p>

<h2 lang="en">11. Contact</h2>
<p lang="en">Data requests, privacy questions, or anything else you would like us to handle: <a href="mailto:wenhsiaoyi@gmail.com">wenhsiaoyi@gmail.com</a></p>

<footer>
  <p>Privacy policy for Jack計算機. <a href="./index.html">開發者網站 Developer website</a> ｜ Last updated 2026-11-15.</p>
</footer>
```

- [ ] **Step 3: 跑檢查確認通過**

Run:
```bash
grep -c '<h2' site/public/privacy.html
grep -c '生效日期：2026 年 11 月 15 日' site/public/privacy.html
grep -c '預設收集' site/public/privacy.html
grep -c '目前版本沒有 UMP 同意表單' site/public/privacy.html
grep -c '同意後才' site/public/privacy.html
grep -c '預設關閉' site/public/privacy.html
grep -c 'enabled only after consent' site/public/privacy.html
grep -c './index.html' site/public/privacy.html
```
Expected: h2 ≥ 22；生效日 1；預設收集 ≥ 1；UMP 現況句 1；「同意後才」0；「預設關閉」0；en 不實句 0；index 連結 ≥ 1。

---

### Task 3: Firebase Hosting 部署與上線驗證

**Files:** 無新增（部署 Task 1–2 產出）。

**Interfaces:**
- Consumes: `site/` 全部檔案；firebase CLI 已登入、projects:list 含 jackcalculator-site。
- Produces: 上線 URL 兩條（Task 4 記入 AGENTS.md）。

- [ ] **Step 1: 部署**

Run（工作目錄 `site/`）:
```bash
firebase deploy --only hosting
```
Expected: 輸出含 `Hosting URL: https://jackcalculator-site.web.app`（或等義之 deploy complete 訊息）。若報 hosting 未初始化，依 CLI 提示接受預設 site 佈建。

- [ ] **Step 2: 上線驗證**

Run:
```bash
curl -s -o /dev/null -w '%{http_code}\n' https://jackcalculator-site.web.app/
curl -s -o /dev/null -w '%{http_code}\n' https://jackcalculator-site.web.app/privacy.html
curl -s --compressed https://jackcalculator-site.web.app/ | grep -c 'com.wenhsiaoyi.jackcalculator'
curl -s --compressed https://jackcalculator-site.web.app/privacy.html | grep -c 'Privacy Policy'
curl -s --compressed https://jackcalculator-site.web.app/ | grep -c './privacy.html'
```
Expected: 200、200；套件名 ≥ 1；Privacy Policy ≥ 1；privacy 連結 ≥ 2。

- [ ] **Step 3: 失敗處置**

若 404：等 30 秒重試一次（首部署傳播）；仍 404 讀 `firebase deploy` 完整輸出找 site 名稱差異，不要猜 URL。若 403：登入帳號權限問題，停下來回報使用者。

---

### Task 4: AGENTS.md 更新與總檢查

**Files:**
- Modify: `AGENTS.md`（新增網站節於 Firebase 節之後；Play 待辦補隱私 URL）

**Interfaces:**
- Consumes: Task 3 之上線 URL。
- Produces: 文件紀錄（Play listing 隱私 URL 來源）。

- [ ] **Step 1: 新增 AGENTS.md 網站節**

於 `## Firebase／Google Analytics` 節之後插入：

```markdown
## 開發者網站與 Firebase Hosting（2026-11-15 建立）

- **佈局**：`site/`（firebase.json、.firebaserc、.gitignore、public/index.html、public/privacy.html），鏡像 JackCompass `ads-txt/` 結構；純靜態雙語（繁中＋英文同頁）、無 JS。
- **URL**：`https://jackcalculator-site.web.app/` 與 `https://jackcalculator-site.web.app/privacy.html`（**Play Console listing 的隱私政策 URL 用後者**）。
- **部署**：於 `site/` 執行 `firebase deploy --only hosting`（CLI 已登入 wenhsiaoyi@gmail.com；專案 jackcalculator-site 與 App 的 Firebase／GA 同專案）。
- **隱私立場裁定（2026-11-15）**：照現況如实寫——無 UMP 同意表單、Analytics 預設收集（含裝置提供之廣告識別碼）、本機僅五項設定；**UMP／同意閘門落地時必須同步更新 privacy.html 與生效日**（政策第十節承諾）。
- **app-ads.txt 暫不放**：現仍測試廣告 ID；正式 ID 落地時依 JackCompass 格式（`google.com, pub-<ID>, DIRECT, f08c47fec0942fa0`）補於 public/。
- spec：`docs/superpowers/specs/2026-11-15-jack-calculator-site-design.md`；plan：`docs/superpowers/plans/2026-11-15-jack-calculator-site.md`。
```

- [ ] **Step 2: Play 待辦補隱私 URL**

於「### 本專案上架前待辦」清單加一項：
```markdown
5. **Listing 隱私政策 URL 已就緒**：`https://jackcalculator-site.web.app/privacy.html`（2026-11-15 上線）；Console 建 app 後填入 listing。
```

- [ ] **Step 3: 總檢查**

Run:
```bash
git status --short
grep -c 'jackcalculator-site.web.app/privacy.html' AGENTS.md
```
Expected: git status 僅 `site/`、`docs/`、`AGENTS.md` 相關路徑（無 lib/、android/ 等 app 變更）；grep ≥ 2。**不 commit**。