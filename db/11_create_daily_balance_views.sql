-- =====================================================
-- 每日庫存餘額 / 每日供需餘額
-- 兩者的「期末/可用」欄位都用公式算出，天生滿足驗証準則：
--   期初數量 + 本期入庫 - 本期出庫 = 期末數量
--   在手數量 + 供給入庫 - 需求入庫 = 可用數量
-- =====================================================
USE oav00_v2;
GO

IF OBJECT_ID('dbo.每日庫存餘額','V') IS NOT NULL DROP VIEW dbo.每日庫存餘額;
GO
CREATE VIEW dbo.每日庫存餘額
AS
WITH movements AS (
    SELECT d.物料編號, d.倉庫代碼, h.收貨日期 AS 日期, d.收貨數量 AS 入庫量, 0 AS 出庫量
    FROM dbo.採購收貨明細 d JOIN dbo.採購收貨主檔 h ON h.收貨編號 = d.收貨編號
    WHERE d.倉庫代碼 IS NOT NULL AND h.收貨日期 IS NOT NULL
    UNION ALL
    SELECT d.物料編號, d.倉庫代碼, h.入庫日期, d.入庫數量, 0
    FROM dbo.工單入庫明細 d JOIN dbo.工單入庫主檔 h ON h.入庫編號 = d.入庫編號
    WHERE d.倉庫代碼 IS NOT NULL AND h.入庫日期 IS NOT NULL
    UNION ALL
    SELECT d.物料編號, d.倉庫代碼, h.繳庫日期, d.繳庫數量, 0
    FROM dbo.庫存繳庫明細 d JOIN dbo.庫存繳庫主檔 h ON h.繳庫編號 = d.繳庫編號
    WHERE d.倉庫代碼 IS NOT NULL AND h.繳庫日期 IS NOT NULL
    UNION ALL
    SELECT d.物料編號, d.倉庫代碼, h.退回日期, d.退回數量, 0
    FROM dbo.出貨退回明細 d JOIN dbo.出貨退回主檔 h ON h.退回編號 = d.退回編號
    WHERE d.倉庫代碼 IS NOT NULL AND h.退回日期 IS NOT NULL
    UNION ALL
    SELECT d.物料編號, d.倉庫代碼, h.出貨日期, 0, d.出貨數量
    FROM dbo.訂單出貨明細 d JOIN dbo.訂單出貨主檔 h ON h.出貨編號 = d.出貨編號
    WHERE d.倉庫代碼 IS NOT NULL AND h.出貨日期 IS NOT NULL
    UNION ALL
    SELECT d.物料編號, d.倉庫代碼, h.領用日期, 0, d.領用數量
    FROM dbo.庫存領用明細 d JOIN dbo.庫存領用主檔 h ON h.領用編號 = d.領用編號
    WHERE d.倉庫代碼 IS NOT NULL AND h.領用日期 IS NOT NULL
    UNION ALL
    SELECT d.物料編號, d.倉庫代碼, h.退回日期, 0, d.退回數量
    FROM dbo.收貨退回明細 d JOIN dbo.收貨退回主檔 h ON h.退回編號 = d.退回編號
    WHERE d.倉庫代碼 IS NOT NULL AND h.退回日期 IS NOT NULL
),
daily AS (
    SELECT 物料編號, 倉庫代碼, 日期, SUM(入庫量) AS 本期入庫, SUM(出庫量) AS 本期出庫
    FROM movements
    GROUP BY 物料編號, 倉庫代碼, 日期
)
SELECT
    物料編號, 倉庫代碼, 日期,
    ISNULL(SUM(本期入庫 - 本期出庫) OVER (
        PARTITION BY 物料編號, 倉庫代碼 ORDER BY 日期
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS 期初數量,
    本期入庫,
    本期出庫,
    SUM(本期入庫 - 本期出庫) OVER (
        PARTITION BY 物料編號, 倉庫代碼 ORDER BY 日期
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS 期末數量
FROM daily;
GO

-- 註：廠商採購單未記錄「工廠代碼」，供給入庫（未交採購）無法依工廠拆分，
-- 此處視為全公司共用同一採購池。如需依工廠精確拆分，須先在採購單加上工廠欄位。
IF OBJECT_ID('dbo.每日供需餘額','V') IS NOT NULL DROP VIEW dbo.每日供需餘額;
GO
CREATE VIEW dbo.每日供需餘額
AS
WITH 在手明細 AS (
    SELECT 物料編號, 倉庫代碼, 期末數量,
           ROW_NUMBER() OVER (PARTITION BY 物料編號, 倉庫代碼 ORDER BY 日期 DESC) AS rn
    FROM dbo.每日庫存餘額
),
工廠物料 AS (
    SELECT DISTINCT w.工廠代碼, b.物料編號
    FROM dbo.工廠倉庫維護 w
    JOIN 在手明細 b ON b.倉庫代碼 = w.倉庫代碼 AND b.rn = 1
    UNION
    SELECT r.工廠代碼, d.物料編號
    FROM dbo.物料預留主檔 r JOIN dbo.物料預留明細 d ON d.預留編號 = r.預留編號
    UNION
    SELECT s.工廠代碼, d.物料編號
    FROM dbo.庫存領用主檔 s JOIN dbo.庫存領用明細 d ON d.領用編號 = s.領用編號
    UNION
    SELECT o.工廠代碼, d.物料編號
    FROM dbo.生產工單主檔 o JOIN dbo.生產工單明細 d ON d.工單編號 = o.工單編號
),
在手 AS (
    SELECT w.工廠代碼, b.物料編號, SUM(b.期末數量) AS 在手數量
    FROM dbo.工廠倉庫維護 w
    JOIN 在手明細 b ON b.倉庫代碼 = w.倉庫代碼 AND b.rn = 1
    GROUP BY w.工廠代碼, b.物料編號
),
未交採購 AS (
    SELECT 物料編號, SUM(採購數量 - 收貨數量 + 退回數量) AS 數量
    FROM dbo.廠商採購明細
    WHERE 採購數量 - 收貨數量 + 退回數量 > 0
    GROUP BY 物料編號
),
未領物料 AS (
    SELECT o.工廠代碼, d.物料編號, SUM(d.應領用量 - d.已領用量) AS 數量
    FROM dbo.生產工單主檔 o JOIN dbo.生產工單明細 d ON d.工單編號 = o.工單編號
    WHERE d.應領用量 - d.已領用量 > 0
    GROUP BY o.工廠代碼, d.物料編號
),
未領預留 AS (
    SELECT r.工廠代碼, d.物料編號, SUM(d.預留數量) AS 數量
    FROM dbo.物料預留主檔 r JOIN dbo.物料預留明細 d ON d.預留編號 = r.預留編號
    GROUP BY r.工廠代碼, d.物料編號
)
SELECT
    fp.物料編號, fp.工廠代碼,
    CAST(GETDATE() AS date) AS 日期,
    ISNULL(o.在手數量, 0) AS 在手數量,
    ISNULL(po.數量, 0) AS 供給入庫,
    ISNULL(wo.數量, 0) + ISNULL(rv.數量, 0) AS 需求入庫,
    ISNULL(o.在手數量, 0) + ISNULL(po.數量, 0) - (ISNULL(wo.數量, 0) + ISNULL(rv.數量, 0)) AS 可用數量
FROM 工廠物料 fp
LEFT JOIN 在手 o ON o.工廠代碼 = fp.工廠代碼 AND o.物料編號 = fp.物料編號
LEFT JOIN 未交採購 po ON po.物料編號 = fp.物料編號
LEFT JOIN 未領物料 wo ON wo.工廠代碼 = fp.工廠代碼 AND wo.物料編號 = fp.物料編號
LEFT JOIN 未領預留 rv ON rv.工廠代碼 = fp.工廠代碼 AND rv.物料編號 = fp.物料編號;
GO
