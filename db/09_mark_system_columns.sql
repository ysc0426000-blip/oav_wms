-- =====================================================
-- 標記由觸發程序自動維護的欄位（extended property），
-- 前端表單據此自動隱藏，不需要任何前端硬編碼表名/欄位名。
-- =====================================================
USE oav00_v2;
GO

CREATE OR ALTER PROCEDURE dbo.usp_MarkSystemMaintained
    @table nvarchar(128), @column nvarchar(128)
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM sys.extended_properties ep
        JOIN sys.columns c ON c.object_id = ep.major_id AND c.column_id = ep.minor_id
        WHERE ep.name = 'system_maintained' AND ep.major_id = OBJECT_ID(@table) AND c.name = @column
    )
        RETURN;

    EXEC sys.sp_addextendedproperty
        @name = N'system_maintained', @value = 1,
        @level0type = N'SCHEMA', @level0name = N'dbo',
        @level1type = N'TABLE',  @level1name = @table,
        @level2type = N'COLUMN', @level2name = @column;
END
GO

EXEC dbo.usp_MarkSystemMaintained N'客戶訂單明細', N'出貨數量';
EXEC dbo.usp_MarkSystemMaintained N'客戶訂單明細', N'退回數量';
EXEC dbo.usp_MarkSystemMaintained N'廠商採購明細', N'收貨數量';
EXEC dbo.usp_MarkSystemMaintained N'廠商採購明細', N'退回數量';
EXEC dbo.usp_MarkSystemMaintained N'生產工單明細', N'已領用量';
EXEC dbo.usp_MarkSystemMaintained N'生產工單主檔', N'入庫數量';
GO
