-- =====================================================
-- PP 生產模組 交易數據
-- =====================================================
USE oav00_v2;
GO

IF OBJECT_ID('dbo.生產工單主檔','U') IS NULL
CREATE TABLE dbo.生產工單主檔 (
    工單編號   nvarchar(20)  NOT NULL,
    工單日期   date          NULL,
    工廠代碼   nvarchar(20)  NULL,
    預定完工   date          NULL,
    生產數量   int           NOT NULL DEFAULT (0),
    入庫數量   int           NOT NULL DEFAULT (0),
    物管編號   nvarchar(20)  NULL,
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_生產工單主檔 PRIMARY KEY (工單編號)
);
GO

IF OBJECT_ID('dbo.生產工單明細','U') IS NULL
CREATE TABLE dbo.生產工單明細 (
    工單編號   nvarchar(20)  NOT NULL,
    工單項次   nvarchar(4)   NOT NULL,
    物料編號   nvarchar(20)  NULL,
    應領用量   int           NOT NULL DEFAULT (0),
    已領用量   int           NOT NULL DEFAULT (0),
    預定領料   date          NULL,
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_生產工單明細 PRIMARY KEY (工單編號, 工單項次)
);
GO

IF OBJECT_ID('dbo.工單入庫主檔','U') IS NULL
CREATE TABLE dbo.工單入庫主檔 (
    入庫編號   nvarchar(20)  NOT NULL,
    入庫日期   date          NULL,
    工廠代碼   nvarchar(20)  NULL,
    物管編號   nvarchar(20)  NULL,
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_工單入庫主檔 PRIMARY KEY (入庫編號)
);
GO

IF OBJECT_ID('dbo.工單入庫明細','U') IS NULL
CREATE TABLE dbo.工單入庫明細 (
    入庫編號   nvarchar(20)  NOT NULL,
    入庫項次   nvarchar(4)   NOT NULL,
    工單編號   nvarchar(20)  NULL,
    物料編號   nvarchar(20)  NULL,
    倉庫代碼   nvarchar(20)  NULL,
    入庫數量   int           NOT NULL DEFAULT (0),
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_工單入庫明細 PRIMARY KEY (入庫編號, 入庫項次)
);
GO

IF OBJECT_ID('dbo.工單領料主檔','U') IS NULL
CREATE TABLE dbo.工單領料主檔 (
    領料編號   nvarchar(20)  NOT NULL,
    領料日期   date          NULL,
    工廠代碼   nvarchar(20)  NULL,
    物管編號   nvarchar(20)  NULL,
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_工單領料主檔 PRIMARY KEY (領料編號)
);
GO

IF OBJECT_ID('dbo.工單領料明細','U') IS NULL
CREATE TABLE dbo.工單領料明細 (
    領料編號   nvarchar(20)  NOT NULL,
    領料項次   nvarchar(4)   NOT NULL,
    工單編號   nvarchar(20)  NULL,
    物料編號   nvarchar(20)  NULL,
    倉庫代碼   nvarchar(20)  NULL,
    領料數量   int           NOT NULL DEFAULT (0),
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_工單領料明細 PRIMARY KEY (領料編號, 領料項次)
);
GO

-- Foreign keys
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_生產工單主檔_工廠代碼維護')
    ALTER TABLE dbo.生產工單主檔 ADD CONSTRAINT FK_生產工單主檔_工廠代碼維護 FOREIGN KEY (工廠代碼) REFERENCES dbo.工廠代碼維護(工廠代碼);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_生產工單主檔_物管資料維護')
    ALTER TABLE dbo.生產工單主檔 ADD CONSTRAINT FK_生產工單主檔_物管資料維護 FOREIGN KEY (物管編號) REFERENCES dbo.物管資料維護(物管編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_生產工單明細_生產工單主檔')
    ALTER TABLE dbo.生產工單明細 ADD CONSTRAINT FK_生產工單明細_生產工單主檔 FOREIGN KEY (工單編號) REFERENCES dbo.生產工單主檔(工單編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_生產工單明細_物料資料維護')
    ALTER TABLE dbo.生產工單明細 ADD CONSTRAINT FK_生產工單明細_物料資料維護 FOREIGN KEY (物料編號) REFERENCES dbo.物料資料維護(物料編號);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_工單入庫主檔_工廠代碼維護')
    ALTER TABLE dbo.工單入庫主檔 ADD CONSTRAINT FK_工單入庫主檔_工廠代碼維護 FOREIGN KEY (工廠代碼) REFERENCES dbo.工廠代碼維護(工廠代碼);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_工單入庫主檔_物管資料維護')
    ALTER TABLE dbo.工單入庫主檔 ADD CONSTRAINT FK_工單入庫主檔_物管資料維護 FOREIGN KEY (物管編號) REFERENCES dbo.物管資料維護(物管編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_工單入庫明細_工單入庫主檔')
    ALTER TABLE dbo.工單入庫明細 ADD CONSTRAINT FK_工單入庫明細_工單入庫主檔 FOREIGN KEY (入庫編號) REFERENCES dbo.工單入庫主檔(入庫編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_工單入庫明細_生產工單主檔')
    ALTER TABLE dbo.工單入庫明細 ADD CONSTRAINT FK_工單入庫明細_生產工單主檔 FOREIGN KEY (工單編號) REFERENCES dbo.生產工單主檔(工單編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_工單入庫明細_物料資料維護')
    ALTER TABLE dbo.工單入庫明細 ADD CONSTRAINT FK_工單入庫明細_物料資料維護 FOREIGN KEY (物料編號) REFERENCES dbo.物料資料維護(物料編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_工單入庫明細_工廠倉庫維護')
    ALTER TABLE dbo.工單入庫明細 ADD CONSTRAINT FK_工單入庫明細_工廠倉庫維護 FOREIGN KEY (倉庫代碼) REFERENCES dbo.工廠倉庫維護(倉庫代碼);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_工單領料主檔_工廠代碼維護')
    ALTER TABLE dbo.工單領料主檔 ADD CONSTRAINT FK_工單領料主檔_工廠代碼維護 FOREIGN KEY (工廠代碼) REFERENCES dbo.工廠代碼維護(工廠代碼);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_工單領料主檔_物管資料維護')
    ALTER TABLE dbo.工單領料主檔 ADD CONSTRAINT FK_工單領料主檔_物管資料維護 FOREIGN KEY (物管編號) REFERENCES dbo.物管資料維護(物管編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_工單領料明細_工單領料主檔')
    ALTER TABLE dbo.工單領料明細 ADD CONSTRAINT FK_工單領料明細_工單領料主檔 FOREIGN KEY (領料編號) REFERENCES dbo.工單領料主檔(領料編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_工單領料明細_生產工單主檔')
    ALTER TABLE dbo.工單領料明細 ADD CONSTRAINT FK_工單領料明細_生產工單主檔 FOREIGN KEY (工單編號) REFERENCES dbo.生產工單主檔(工單編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_工單領料明細_物料資料維護')
    ALTER TABLE dbo.工單領料明細 ADD CONSTRAINT FK_工單領料明細_物料資料維護 FOREIGN KEY (物料編號) REFERENCES dbo.物料資料維護(物料編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_工單領料明細_工廠倉庫維護')
    ALTER TABLE dbo.工單領料明細 ADD CONSTRAINT FK_工單領料明細_工廠倉庫維護 FOREIGN KEY (倉庫代碼) REFERENCES dbo.工廠倉庫維護(倉庫代碼);
GO
