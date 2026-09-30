-- =====================================================
-- 組織架構 Organization tables
-- =====================================================
USE oav00_v2;
GO

IF OBJECT_ID('dbo.銷售組織維護','U') IS NULL
CREATE TABLE dbo.銷售組織維護 (
    銷售組織   nvarchar(20)  NOT NULL,
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_銷售組織維護 PRIMARY KEY (銷售組織)
);
GO

IF OBJECT_ID('dbo.採購組織維護','U') IS NULL
CREATE TABLE dbo.採購組織維護 (
    採購組織   nvarchar(20)  NOT NULL,
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_採購組織維護 PRIMARY KEY (採購組織)
);
GO

IF OBJECT_ID('dbo.工廠代碼維護','U') IS NULL
CREATE TABLE dbo.工廠代碼維護 (
    工廠代碼   nvarchar(20)  NOT NULL,
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_工廠代碼維護 PRIMARY KEY (工廠代碼)
);
GO

IF OBJECT_ID('dbo.工廠倉庫維護','U') IS NULL
CREATE TABLE dbo.工廠倉庫維護 (
    工廠代碼   nvarchar(20)  NOT NULL,
    倉庫代碼   nvarchar(20)  NOT NULL,
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_工廠倉庫維護 PRIMARY KEY (倉庫代碼)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_工廠倉庫維護_工廠代碼維護')
    ALTER TABLE dbo.工廠倉庫維護
    ADD CONSTRAINT FK_工廠倉庫維護_工廠代碼維護 FOREIGN KEY (工廠代碼) REFERENCES dbo.工廠代碼維護(工廠代碼);
GO
