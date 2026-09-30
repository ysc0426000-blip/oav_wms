-- =====================================================
-- IM 庫存模組 交易數據
-- =====================================================
USE oav00_v2;
GO

IF OBJECT_ID('dbo.物料預留主檔','U') IS NULL
CREATE TABLE dbo.物料預留主檔 (
    預留編號   nvarchar(20)  NOT NULL,
    預留日期   date          NULL,
    工廠代碼   nvarchar(20)  NULL,
    物管編號   nvarchar(20)  NULL,
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_物料預留主檔 PRIMARY KEY (預留編號)
);
GO

IF OBJECT_ID('dbo.物料預留明細','U') IS NULL
CREATE TABLE dbo.物料預留明細 (
    預留編號   nvarchar(20)  NOT NULL,
    預留項次   nvarchar(4)   NOT NULL,
    物料編號   nvarchar(20)  NULL,
    預留數量   int           NOT NULL DEFAULT (0),
    預定交期   date          NULL,
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_物料預留明細 PRIMARY KEY (預留編號, 預留項次)
);
GO

IF OBJECT_ID('dbo.庫存領用主檔','U') IS NULL
CREATE TABLE dbo.庫存領用主檔 (
    領用編號   nvarchar(20)  NOT NULL,
    領用日期   date          NULL,
    工廠代碼   nvarchar(20)  NULL,
    物管編號   nvarchar(20)  NULL,
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_庫存領用主檔 PRIMARY KEY (領用編號)
);
GO

IF OBJECT_ID('dbo.庫存領用明細','U') IS NULL
CREATE TABLE dbo.庫存領用明細 (
    領用編號   nvarchar(20)  NOT NULL,
    領用項次   nvarchar(4)   NOT NULL,
    物料編號   nvarchar(20)  NULL,
    倉庫代碼   nvarchar(20)  NULL,
    領用數量   int           NOT NULL DEFAULT (0),
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_庫存領用明細 PRIMARY KEY (領用編號, 領用項次)
);
GO

IF OBJECT_ID('dbo.庫存繳庫主檔','U') IS NULL
CREATE TABLE dbo.庫存繳庫主檔 (
    繳庫編號   nvarchar(20)  NOT NULL,
    繳庫日期   date          NULL,
    工廠代碼   nvarchar(20)  NULL,
    物管編號   nvarchar(20)  NULL,
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_庫存繳庫主檔 PRIMARY KEY (繳庫編號)
);
GO

IF OBJECT_ID('dbo.庫存繳庫明細','U') IS NULL
CREATE TABLE dbo.庫存繳庫明細 (
    繳庫編號   nvarchar(20)  NOT NULL,
    繳庫項次   nvarchar(4)   NOT NULL,
    物料編號   nvarchar(20)  NULL,
    倉庫代碼   nvarchar(20)  NULL,
    繳庫數量   int           NOT NULL DEFAULT (0),
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_庫存繳庫明細 PRIMARY KEY (繳庫編號, 繳庫項次)
);
GO

-- Foreign keys
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_物料預留主檔_工廠代碼維護')
    ALTER TABLE dbo.物料預留主檔 ADD CONSTRAINT FK_物料預留主檔_工廠代碼維護 FOREIGN KEY (工廠代碼) REFERENCES dbo.工廠代碼維護(工廠代碼);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_物料預留主檔_物管資料維護')
    ALTER TABLE dbo.物料預留主檔 ADD CONSTRAINT FK_物料預留主檔_物管資料維護 FOREIGN KEY (物管編號) REFERENCES dbo.物管資料維護(物管編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_物料預留明細_物料預留主檔')
    ALTER TABLE dbo.物料預留明細 ADD CONSTRAINT FK_物料預留明細_物料預留主檔 FOREIGN KEY (預留編號) REFERENCES dbo.物料預留主檔(預留編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_物料預留明細_物料資料維護')
    ALTER TABLE dbo.物料預留明細 ADD CONSTRAINT FK_物料預留明細_物料資料維護 FOREIGN KEY (物料編號) REFERENCES dbo.物料資料維護(物料編號);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_庫存領用主檔_工廠代碼維護')
    ALTER TABLE dbo.庫存領用主檔 ADD CONSTRAINT FK_庫存領用主檔_工廠代碼維護 FOREIGN KEY (工廠代碼) REFERENCES dbo.工廠代碼維護(工廠代碼);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_庫存領用主檔_物管資料維護')
    ALTER TABLE dbo.庫存領用主檔 ADD CONSTRAINT FK_庫存領用主檔_物管資料維護 FOREIGN KEY (物管編號) REFERENCES dbo.物管資料維護(物管編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_庫存領用明細_庫存領用主檔')
    ALTER TABLE dbo.庫存領用明細 ADD CONSTRAINT FK_庫存領用明細_庫存領用主檔 FOREIGN KEY (領用編號) REFERENCES dbo.庫存領用主檔(領用編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_庫存領用明細_物料資料維護')
    ALTER TABLE dbo.庫存領用明細 ADD CONSTRAINT FK_庫存領用明細_物料資料維護 FOREIGN KEY (物料編號) REFERENCES dbo.物料資料維護(物料編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_庫存領用明細_工廠倉庫維護')
    ALTER TABLE dbo.庫存領用明細 ADD CONSTRAINT FK_庫存領用明細_工廠倉庫維護 FOREIGN KEY (倉庫代碼) REFERENCES dbo.工廠倉庫維護(倉庫代碼);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_庫存繳庫主檔_工廠代碼維護')
    ALTER TABLE dbo.庫存繳庫主檔 ADD CONSTRAINT FK_庫存繳庫主檔_工廠代碼維護 FOREIGN KEY (工廠代碼) REFERENCES dbo.工廠代碼維護(工廠代碼);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_庫存繳庫主檔_物管資料維護')
    ALTER TABLE dbo.庫存繳庫主檔 ADD CONSTRAINT FK_庫存繳庫主檔_物管資料維護 FOREIGN KEY (物管編號) REFERENCES dbo.物管資料維護(物管編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_庫存繳庫明細_庫存繳庫主檔')
    ALTER TABLE dbo.庫存繳庫明細 ADD CONSTRAINT FK_庫存繳庫明細_庫存繳庫主檔 FOREIGN KEY (繳庫編號) REFERENCES dbo.庫存繳庫主檔(繳庫編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_庫存繳庫明細_物料資料維護')
    ALTER TABLE dbo.庫存繳庫明細 ADD CONSTRAINT FK_庫存繳庫明細_物料資料維護 FOREIGN KEY (物料編號) REFERENCES dbo.物料資料維護(物料編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_庫存繳庫明細_工廠倉庫維護')
    ALTER TABLE dbo.庫存繳庫明細 ADD CONSTRAINT FK_庫存繳庫明細_工廠倉庫維護 FOREIGN KEY (倉庫代碼) REFERENCES dbo.工廠倉庫維護(倉庫代碼);
GO
