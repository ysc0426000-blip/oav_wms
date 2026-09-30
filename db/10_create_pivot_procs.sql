-- =====================================================
-- 樞紐分析：訂單出退分析 / 採購收退分析
-- 縱軸=客戶/廠商編號，橫軸=月份(1~12)，統計欄位=出貨(收貨)數量+退回數量
-- 月份固定 12 欄，直接用靜態 PIVOT，不需要動態 SQL。
-- =====================================================
USE oav00_v2;
GO

CREATE OR ALTER PROCEDURE dbo.usp_訂單出退分析樞紐 @年度 int
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH src AS (
        SELECT h.客戶編號, MONTH(h.出貨日期) AS 月份, d.出貨數量 AS 數量
        FROM dbo.訂單出貨明細 d
        JOIN dbo.訂單出貨主檔 h ON h.出貨編號 = d.出貨編號
        WHERE YEAR(h.出貨日期) = @年度
        UNION ALL
        SELECT h.客戶編號, MONTH(h.退回日期), r.退回數量
        FROM dbo.出貨退回明細 r
        JOIN dbo.出貨退回主檔 h ON h.退回編號 = r.退回編號
        WHERE YEAR(h.退回日期) = @年度
    )
    SELECT 客戶編號,
        ISNULL([1],0)  AS [1月],  ISNULL([2],0)  AS [2月],  ISNULL([3],0)  AS [3月],
        ISNULL([4],0)  AS [4月],  ISNULL([5],0)  AS [5月],  ISNULL([6],0)  AS [6月],
        ISNULL([7],0)  AS [7月],  ISNULL([8],0)  AS [8月],  ISNULL([9],0)  AS [9月],
        ISNULL([10],0) AS [10月], ISNULL([11],0) AS [11月], ISNULL([12],0) AS [12月],
        ISNULL([1],0)+ISNULL([2],0)+ISNULL([3],0)+ISNULL([4],0)+ISNULL([5],0)+ISNULL([6],0)
        +ISNULL([7],0)+ISNULL([8],0)+ISNULL([9],0)+ISNULL([10],0)+ISNULL([11],0)+ISNULL([12],0) AS 全年合計
    FROM src
    PIVOT (SUM(數量) FOR 月份 IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])) AS p
    ORDER BY 客戶編號;
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_採購收退分析樞紐 @年度 int
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH src AS (
        SELECT h.廠商編號, MONTH(h.收貨日期) AS 月份, d.收貨數量 AS 數量
        FROM dbo.採購收貨明細 d
        JOIN dbo.採購收貨主檔 h ON h.收貨編號 = d.收貨編號
        WHERE YEAR(h.收貨日期) = @年度
        UNION ALL
        SELECT h.廠商編號, MONTH(h.退回日期), r.退回數量
        FROM dbo.收貨退回明細 r
        JOIN dbo.收貨退回主檔 h ON h.退回編號 = r.退回編號
        WHERE YEAR(h.退回日期) = @年度
    )
    SELECT 廠商編號,
        ISNULL([1],0)  AS [1月],  ISNULL([2],0)  AS [2月],  ISNULL([3],0)  AS [3月],
        ISNULL([4],0)  AS [4月],  ISNULL([5],0)  AS [5月],  ISNULL([6],0)  AS [6月],
        ISNULL([7],0)  AS [7月],  ISNULL([8],0)  AS [8月],  ISNULL([9],0)  AS [9月],
        ISNULL([10],0) AS [10月], ISNULL([11],0) AS [11月], ISNULL([12],0) AS [12月],
        ISNULL([1],0)+ISNULL([2],0)+ISNULL([3],0)+ISNULL([4],0)+ISNULL([5],0)+ISNULL([6],0)
        +ISNULL([7],0)+ISNULL([8],0)+ISNULL([9],0)+ISNULL([10],0)+ISNULL([11],0)+ISNULL([12],0) AS 全年合計
    FROM src
    PIVOT (SUM(數量) FOR 月份 IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])) AS p
    ORDER BY 廠商編號;
END
GO

-- 標記為可透過通用 API 執行的報表程序
CREATE OR ALTER PROCEDURE dbo.usp_MarkExposedReport @proc nvarchar(128)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE name = 'exposed_report' AND major_id = OBJECT_ID(@proc) AND minor_id = 0)
        RETURN;
    EXEC sys.sp_addextendedproperty
        @name = N'exposed_report', @value = 1,
        @level0type = N'SCHEMA', @level0name = N'dbo',
        @level1type = N'PROCEDURE', @level1name = @proc;
END
GO

EXEC dbo.usp_MarkExposedReport N'usp_訂單出退分析樞紐';
EXEC dbo.usp_MarkExposedReport N'usp_採購收退分析樞紐';
GO
