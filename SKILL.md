# 操作手冊（如何在這個專案上做事）

## 啟動開發環境
```
cd server
npm install               # 第一次才需要
cp .env.example .env      # 第一次才需要，填入真實密碼
node run-sql.js           # 套用/更新資料庫 schema（可重複執行）
node server.js            # 啟動 API + PWA，預設 http://localhost:3000
```
手機測試：與電腦同一個 Wi-Fi，開 `http://<電腦的區網IP>:3000`，可「加到主畫面」安裝成 PWA。

## 跑一次驗証準則自動測試
```
# 先確定 server.js 正在跑，另開一個終端機
cd server
node verify.js
```
會依序建立訂單→出貨→退回→採購→收貨→生產工單→領料→入庫，並印出每個累計欄位與每日餘額視圖的結果，可對照使用者給的 `<驗証準則>` 手動核對。

## 新增一張「單表維護」畫面（組織架構/主數據類型）
1. 在對應的 `db/0X_create_tables_*.sql` 加上 `CREATE TABLE`（含 PK），重跑 `node run-sql.js`。
2. 在 `server/menu.json` 對應模組的 section 加一個項目：
   ```json
   { "label": "XX維護", "type": "lookup", "table": "XX資料表名稱" }
   ```
3. 重啟 `node server.js`（menu.json 是 `require()` 進來的，會被 Node 快取，改完一定要重啟）。
4. 完成——不用寫任何前端程式碼，`Grid.renderLookup` 會自動用 metadata 產生表單/表格。

## 新增一組「主檔+明細」交易維護畫面
1. 建立兩張表（主檔＋明細），明細表要有 FK 指回主檔（`Grid.renderDoc` 靠這個 FK 自動找出主檔-明細關聯，不用額外設定）。
2. `menu.json` 加：`{ "label": "...", "type": "doc", "header": "...主檔", "detail": "...明細" }`。
3. 如果有需要自動累計的欄位（像出貨數量／已領用量），在 `db/08_create_triggers.sql` 依樣式加一個 AFTER INSERT/UPDATE/DELETE 觸發程序，並在 `db/09_mark_system_columns.sql` 呼叫 `usp_MarkSystemMaintained` 把該欄位標記為系統維護——前端表單會自動把它藏起來，不會被使用者手動覆蓋。

## 新增一份報表（唯讀檢視）
1. 在 `db/07_create_views.sql`（或新檔案）寫 `CREATE VIEW`。
2. `menu.json` 加：`{ "label": "...", "type": "report", "view": "檢視名稱" }`。
3. 完成，`Grid.renderReport` 自動渲染。

## 新增一份樞紐分析／帶參數報表
1. 寫一個 `CREATE OR ALTER PROCEDURE`，參數用 `@年度 int` 這種明確型別。
2. 呼叫 `EXEC dbo.usp_MarkExposedReport N'你的預存程序名稱'`，標記成可被通用 API 呼叫（安全機制：沒標記的 SP 一律不能透過 `/api/proc/:name` 執行）。
3. `menu.json` 加：`{ "label": "...", "type": "pivot", "proc": "你的預存程序名稱" }`。
4. 完成，`Grid.renderPivot` 會自動依 `sys.parameters` 產生查詢輸入欄位。

## 上 GitHub
```
git add -A
git commit -m "說明這次做了什麼"
git push
```
每次功能段落完成後都要做這一步，並記得同步更新 `CLAUDE.md` / `SKILL.md` / `AGENT.md`。
