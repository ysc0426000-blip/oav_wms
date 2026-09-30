-- =====================================================
-- Triggers：由 SQL Server 自動維護明細累計欄位，
-- 前端完全不必計算「已出貨/已收貨/已領用/已入庫」數量。
-- =====================================================
USE oav00_v2;
GO

IF OBJECT_ID('dbo.TR_訂單出貨明細_更新出貨數量','TR') IS NOT NULL DROP TRIGGER dbo.TR_訂單出貨明細_更新出貨數量;
GO
CREATE TRIGGER dbo.TR_訂單出貨明細_更新出貨數量
ON dbo.訂單出貨明細
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH affected AS (
        SELECT 訂單編號, 訂單項次 FROM inserted WHERE 訂單編號 IS NOT NULL AND 訂單項次 IS NOT NULL
        UNION
        SELECT 訂單編號, 訂單項次 FROM deleted WHERE 訂單編號 IS NOT NULL AND 訂單項次 IS NOT NULL
    )
    UPDATE d
    SET 出貨數量 = ISNULL((SELECT SUM(s.出貨數量) FROM dbo.訂單出貨明細 s WHERE s.訂單編號 = d.訂單編號 AND s.訂單項次 = d.訂單項次), 0)
    FROM dbo.客戶訂單明細 d
    INNER JOIN affected a ON a.訂單編號 = d.訂單編號 AND a.訂單項次 = d.訂單項次;
END
GO

IF OBJECT_ID('dbo.TR_出貨退回明細_更新退回數量','TR') IS NOT NULL DROP TRIGGER dbo.TR_出貨退回明細_更新退回數量;
GO
CREATE TRIGGER dbo.TR_出貨退回明細_更新退回數量
ON dbo.出貨退回明細
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH affected AS (
        SELECT 訂單編號, 訂單項次 FROM inserted WHERE 訂單編號 IS NOT NULL AND 訂單項次 IS NOT NULL
        UNION
        SELECT 訂單編號, 訂單項次 FROM deleted WHERE 訂單編號 IS NOT NULL AND 訂單項次 IS NOT NULL
    )
    UPDATE d
    SET 退回數量 = ISNULL((SELECT SUM(s.退回數量) FROM dbo.出貨退回明細 s WHERE s.訂單編號 = d.訂單編號 AND s.訂單項次 = d.訂單項次), 0)
    FROM dbo.客戶訂單明細 d
    INNER JOIN affected a ON a.訂單編號 = d.訂單編號 AND a.訂單項次 = d.訂單項次;
END
GO

IF OBJECT_ID('dbo.TR_採購收貨明細_更新收貨數量','TR') IS NOT NULL DROP TRIGGER dbo.TR_採購收貨明細_更新收貨數量;
GO
CREATE TRIGGER dbo.TR_採購收貨明細_更新收貨數量
ON dbo.採購收貨明細
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH affected AS (
        SELECT 採購編號, 採購項次 FROM inserted WHERE 採購編號 IS NOT NULL AND 採購項次 IS NOT NULL
        UNION
        SELECT 採購編號, 採購項次 FROM deleted WHERE 採購編號 IS NOT NULL AND 採購項次 IS NOT NULL
    )
    UPDATE d
    SET 收貨數量 = ISNULL((SELECT SUM(s.收貨數量) FROM dbo.採購收貨明細 s WHERE s.採購編號 = d.採購編號 AND s.採購項次 = d.採購項次), 0)
    FROM dbo.廠商採購明細 d
    INNER JOIN affected a ON a.採購編號 = d.採購編號 AND a.採購項次 = d.採購項次;
END
GO

IF OBJECT_ID('dbo.TR_收貨退回明細_更新退回數量','TR') IS NOT NULL DROP TRIGGER dbo.TR_收貨退回明細_更新退回數量;
GO
CREATE TRIGGER dbo.TR_收貨退回明細_更新退回數量
ON dbo.收貨退回明細
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH affected AS (
        SELECT 採購編號, 採購項次 FROM inserted WHERE 採購編號 IS NOT NULL AND 採購項次 IS NOT NULL
        UNION
        SELECT 採購編號, 採購項次 FROM deleted WHERE 採購編號 IS NOT NULL AND 採購項次 IS NOT NULL
    )
    UPDATE d
    SET 退回數量 = ISNULL((SELECT SUM(s.退回數量) FROM dbo.收貨退回明細 s WHERE s.採購編號 = d.採購編號 AND s.採購項次 = d.採購項次), 0)
    FROM dbo.廠商採購明細 d
    INNER JOIN affected a ON a.採購編號 = d.採購編號 AND a.採購項次 = d.採購項次;
END
GO

IF OBJECT_ID('dbo.TR_工單領料明細_更新已領用量','TR') IS NOT NULL DROP TRIGGER dbo.TR_工單領料明細_更新已領用量;
GO
CREATE TRIGGER dbo.TR_工單領料明細_更新已領用量
ON dbo.工單領料明細
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH affected AS (
        SELECT 工單編號, 物料編號 FROM inserted WHERE 工單編號 IS NOT NULL AND 物料編號 IS NOT NULL
        UNION
        SELECT 工單編號, 物料編號 FROM deleted WHERE 工單編號 IS NOT NULL AND 物料編號 IS NOT NULL
    )
    UPDATE d
    SET 已領用量 = ISNULL((SELECT SUM(s.領料數量) FROM dbo.工單領料明細 s WHERE s.工單編號 = d.工單編號 AND s.物料編號 = d.物料編號), 0)
    FROM dbo.生產工單明細 d
    INNER JOIN affected a ON a.工單編號 = d.工單編號 AND a.物料編號 = d.物料編號;
END
GO

IF OBJECT_ID('dbo.TR_工單入庫明細_更新入庫數量','TR') IS NOT NULL DROP TRIGGER dbo.TR_工單入庫明細_更新入庫數量;
GO
CREATE TRIGGER dbo.TR_工單入庫明細_更新入庫數量
ON dbo.工單入庫明細
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH affected AS (
        SELECT 工單編號 FROM inserted WHERE 工單編號 IS NOT NULL
        UNION
        SELECT 工單編號 FROM deleted WHERE 工單編號 IS NOT NULL
    )
    UPDATE d
    SET 入庫數量 = ISNULL((SELECT SUM(s.入庫數量) FROM dbo.工單入庫明細 s WHERE s.工單編號 = d.工單編號), 0)
    FROM dbo.生產工單主檔 d
    INNER JOIN affected a ON a.工單編號 = d.工單編號;
END
GO
