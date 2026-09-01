# 戀途 — 上線與安裝

檔案清單：`index.html` `config.js` `manifest.webmanifest` `sw.js` `icon.svg` `icon.png` `schema.sql` `migrate.sql` `functions/api/ig.js`

> **已經跑過舊版 schema.sql 的話**，去 SQL Editor 再跑一次 `migrate.sql`（幫想去清單加欄位，並讓成員變動即時同步）。

---

## 一、Supabase（雙人同步，10 分鐘）

先做這步，因為 config.js 要填的東西從這裡來。

1. **開專案** — supabase.com → New project。Region 選 **Southeast Asia (Singapore)**，延遲最低。密碼隨便設，之後用不到。
2. **建資料表** — 左側 SQL Editor → New query → 把 `schema.sql` 整份貼進去 → Run。跑完是 Success，沒有紅字。
3. **開匿名登入** — Authentication → Sign In / Providers → 找到 **Anonymous sign-ins** → 打開。
   > 漏掉這步 App 會一直停在單機模式。這是最常忘記的一步。
4. **抄金鑰** — Project Settings → API，複製兩樣東西：
   - Project URL（`https://xxxx.supabase.co`）
   - `anon` `public` key（很長那串 `eyJ...`）
5. **填進 config.js**：

```js
window.LIANTO_CONFIG = {
  url:     "https://xxxx.supabase.co",
  anonKey: "eyJhbGciOiJIUzI1NiIs..."
};
```

anon key 放前端是正常的，Supabase 本來就這樣設計 — 真正的保護在 RLS，`schema.sql` 已經把每張表鎖成「只看得到自己那對的資料」。

---

## 二、上線（Cloudflare Pages，5 分鐘）

1. 開一個 GitHub repo，把整個資料夾推上去
2. Cloudflare Dashboard → **Workers & Pages** → Create → **Pages** → Connect to Git
3. 選那個 repo
4. **Framework preset: None，Build command 留空，Build output directory 填 `/`**
5. Save and Deploy

大概 30 秒，拿到 `https://xxx.pages.dev`。

**想用自己的網域**：Pages 專案 → Custom domains → Set up a domain。網域在 Cloudflare 的話 DNS 自動搞定。

> 不想碰 Git：Pages → Create → **Upload assets**，直接把資料夾拖上去。之後改東西要重拖一次。

---

## 三、安裝到手機

不是去 App Store。這是 PWA，從瀏覽器裝。

**iPhone** — 用 **Safari** 開你的網址（Chrome 不行，iOS 只有 Safari 能加到主畫面）→ 底部分享鈕 → 加入主畫面 → 加入。

**Android** — Chrome 開網址 → 右上角三個點 → 安裝應用程式（通常會自己跳橫幅）。

裝完會有圖示，開起來沒有網址列，跟原生 App 一樣。**IG 分享選單裡的「戀途」也是裝完才會出現。**

---

## 三之二、從 IG 存「想去的地方」

看到別人推薦的景點文章，在 IG 按 **分享 → 戀途**，App 會先問一句：

- **想去** — 存進想去清單，不會點亮縣市
- **去過了** — 直接記成打卡

`functions/api/ig.js` 會去 Meta 的 oEmbed 把貼文文案抓回來，自動猜地點名稱和縣市填好，你只要確認。這支 Function 是 Cloudflare Pages 自動部署的，資料夾結構不要動。

真的去了之後，在想去清單按左邊的圈圈打勾 → 會問要不要記成打卡 → 說好就順便抓當下位置、點亮縣市。整個循環就接起來了。

---

## 四、兩個人接起來

1. 你先裝好開起來 → 跳出「你們的空間」→ 按 **建立空間** → 輸入你的暱稱
2. 拿到 6 碼邀請碼（右上角 ⚙ 隨時看得到）
3. 女友裝好她的 → 按 **我有邀請碼** → 輸入邀請碼和她的暱稱
4. 她一加入，你這邊會跳出「○○○ 加入了」，標題列變成「和 ○○○ ・…」

按右上角 ⚙ 隨時看得到**這個空間裡有誰**，暱稱也在那裡改。每一筆打卡和想去的地方都會標是誰記的。

接起來之後，打卡、想去清單、XP、等級全部共用。她那邊新增，你這邊幾秒內自己出現，不用重整。

**一個空間上限兩個人**，第三個人輸入同一組碼會被擋掉。

如果你在建立空間之前就先自己記了幾筆，建立時會自動把本機資料推上去，不會不見。

---

## 五、iPhone 的 IG 分享捷徑

iOS Safari 不支援 Web Share Target，要用捷徑補。好處是能順便抓當下位置。

捷徑 App → 新增 → 右上 ⓘ → 開「**顯示於分享工作表**」→ 接受類型只勾 **URL**。

四個動作：

| # | 動作 | 設定 |
|---|---|---|
| 1 | 取得目前位置 | 預設 |
| 2 | 取得詳細位置資訊 | 從「目前位置」取**緯度** |
| 3 | 取得詳細位置資訊 | 從「目前位置」取**經度** |
| 4 | 打開 URL | 見下 |

第 4 步的網址用「文字」動作組出來（方括號是拖進去的變數，不是打字）：

```
https://你的網址/?url=[捷徑輸入]&lat=[緯度]&lng=[經度]
```

命名「存進戀途」。之後 IG 按 分享 → 存進戀途。

**Android 不用做這步**，裝完 PWA 就直接出現在分享選單。

---

## 六、額度會不會爆

Supabase 免費方案：資料庫 500MB、儲存空間 1GB、每月流量 5GB。

照片壓到 760px、約 70KB 一張，1GB 大概放得下 **14,000 次打卡**。兩個人一輩子用不完。

唯一要注意：**免費專案閒置 7 天會被暫停**。你們一週內有人開過 App 就不會。真被停了去 Dashboard 按 Restore，資料不會掉。

---

## 七、已知的坑

- **IG 貼文一定要公開**，私人帳號的貼文嵌入會是空白框
- **地圖磚和 IG 嵌入需要連網**，離線時縣市進度照常記錄，地圖會空著
- **縣市是用最近的縣市中心點推算的**，雙北交界可能猜錯，存的時候手動改
- **匿名登入的 session 存在瀏覽器**。清掉瀏覽器資料等於登出，重開會變成新的匿名帳號 → 要重新輸入邀請碼才接得回原本的空間。**邀請碼記起來**
- 改完 `config.js` 之後手機上沒反應：Service Worker 在快取。把 App 從主畫面刪掉重裝一次，或改 `sw.js` 第一行的 `lianto-v2` 為 `v3`
