# 戀途 v0.6.0

Cloudflare Worker + 靜態檔案。Worker 名稱 `love`。

## 資料夾結構（不要改）

```
wrangler.jsonc          ← Worker 設定，一定要在 repo 根目錄
src/index.js            ← 只處理 /api/ig，其餘丟給靜態檔案
public/
  index.html
  config.js             ← 填你的 Supabase 網址和金鑰
  sw.js
  manifest.webmanifest
  icon.svg
  icon.png
schema.sql              ← 貼到 Supabase SQL Editor（全新專案）
migrate.sql             ← 已經跑過舊版 schema 的話跑這支
```

靜態檔案預設優先比對，比對不到才進 `src/index.js`。所以 `/api/ig` 會走 Worker，`/`、`/sw.js`、`/icon.png` 全部直接從 `public/` 送出去。

## 怎麼更新

你的 repo 已經接上 Workers Builds，push 上去就會自動部署。

用 GitHub 網頁上傳的話：進 repo → Add file → Upload files → **把整包拖進去**（資料夾結構會保留）→ Commit。

Cloudflare Dashboard → Workers & Pages → love → Deployments，看到新的一筆就是好了。

## 網址

Workers & Pages → love → 右上角 **Visit**，那個就是正確網址。

## 版本

改版時**三個地方要一起改**：
- `public/index.html` 的 `const VERSION`
- `public/index.html` 底部的 `<script src="config.js?v=...">`
- `public/sw.js` 第一行的 `CACHE`

兩邊不一致的話手機會一直吃舊快取。

App 裡按 ⚙ 最下面看得到目前版本和執行環境（主畫面 App / 瀏覽器），還有一顆**清除快取並重新載入**。

## 跨裝置

一個空間最多 **4 台裝置**。同一個人的手機和電腦各算一台。

在新裝置上開同一個網址 → 選「我有邀請碼」→ 輸入邀請碼 → 資料就同步過去了。

⚙ 裡看得到所有裝置，✕ 可以移除。移除自己等於離開空間，之後要用邀請碼才接得回來。

## Supabase 檢查清單

1. SQL Editor 跑過 `schema.sql`（或 `migrate.sql`）
2. Authentication → Sign In / Providers → **Anonymous sign-ins 打開**
3. `public/config.js` 填好 Project URL 和 `sb_publishable_...` 金鑰

三項都做完，App 標題列右邊的小圓點才會變綠色。
