-- =====================================================
-- 報表輸出 Views
-- =====================================================
USE oav00_v2;
GO

IF OBJECT_ID('dbo.已訂未出明細','V') IS NOT NULL DROP VIEW dbo.已訂未出明細;
GO
CREATE VIEW dbo.已訂未出明細
AS
SELECT *
FROM dbo.客戶訂單明細
WHERE 訂單數量 - 出貨數量 + 退回數量 > 0;
GO

IF OBJECT_ID('dbo.訂單出退分析','V') IS NOT NULL DROP VIEW dbo.訂單出退分析;
GO
CREATE VIEW dbo.訂單出退分析
AS
SELECT '出貨' AS 單據類型, 出貨編號 AS 單據編號, 出貨項次 AS 單據項次,
       訂單編號, 訂單項次, 物料編號, 倉庫代碼, 出貨數量 AS 數量, 備註說明
FROM dbo.訂單出貨明細
UNION ALL
SELECT '退回' AS 單據類型, 退回編號 AS 單據編號, 退回項次 AS 單據項次,
       訂單編號, 訂單項次, 物料編號, 倉庫代碼, -退回數量 AS 數量, 備註說明
FROM dbo.出貨退回明細;
GO

IF OBJECT_ID('dbo.已採未交明細','V') IS NOT NULL DROP VIEW dbo.已採未交明細;
GO
CREATE VIEW dbo.已採未交明細
AS
SELECT *
FROM dbo.廠商採購明細
WHERE 採購數量 - 收貨數量 + 退回數量 > 0;
GO

IF OBJECT_ID('dbo.採購收退分析','V') IS NOT NULL DROP VIEW dbo.採購收退分析;
GO
CREATE VIEW dbo.採購收退分析
AS
SELECT '收貨' AS 單據類型, 收貨編號 AS 單據編號, 收貨項次 AS 單據項次,
       採購編號, 採購項次, 物料編號, 倉庫代碼, 收貨數量 AS 數量, 備註說明
FROM dbo.採購收貨明細
UNION ALL
SELECT '退回' AS 單據類型, 退回編號 AS 單據編號, 退回項次 AS 單據項次,
       採購編號, 採購項次, 物料編號, 倉庫代碼, -退回數量 AS 數量, 備註說明
FROM dbo.收貨退回明細;
GO
