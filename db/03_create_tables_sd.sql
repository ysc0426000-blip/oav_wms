-- =====================================================
-- SD 訂單模組 交易數據
-- =====================================================
USE oav00_v2;
GO

IF OBJECT_ID('dbo.客戶訂單主檔','U') IS NULL
CREATE TABLE dbo.客戶訂單主檔 (
    訂單編號   nvarchar(20)  NOT NULL,
    訂單日期   date          NULL,
    銷售組織   nvarchar(20)  NULL,
    客戶編號   nvarchar(20)  NULL,
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_客戶訂單主檔 PRIMARY KEY (訂單編號)
);
GO

IF OBJECT_ID('dbo.客戶訂單明細','U') IS NULL
CREATE TABLE dbo.客戶訂單明細 (
    訂單編號   nvarchar(20)  NOT NULL,
    訂單項次   nvarchar(4)   NOT NULL,
    物料編號   nvarchar(20)  NULL,
    訂單數量   int           NOT NULL DEFAULT (0),
    出貨數量   int           NOT NULL DEFAULT (0),
    退回數量   int           NOT NULL DEFAULT (0),
    預定交期   date          NULL,
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_客戶訂單明細 PRIMARY KEY (訂單編號, 訂單項次)
);
GO

IF OBJECT_ID('dbo.訂單出貨主檔','U') IS NULL
CREATE TABLE dbo.訂單出貨主檔 (
    出貨編號   nvarchar(20)  NOT NULL,
    出貨日期   date          NULL,
    銷售組織   nvarchar(20)  NULL,
    客戶編號   nvarchar(20)  NULL,
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_訂單出貨主檔 PRIMARY KEY (出貨編號)
);
GO

IF OBJECT_ID('dbo.訂單出貨明細','U') IS NULL
CREATE TABLE dbo.訂單出貨明細 (
    出貨編號   nvarchar(20)  NOT NULL,
    出貨項次   nvarchar(4)   NOT NULL,
    訂單編號   nvarchar(20)  NULL,
    訂單項次   nvarchar(4)   NULL,
    物料編號   nvarchar(20)  NULL,
    倉庫代碼   nvarchar(20)  NULL,
    出貨數量   int           NOT NULL DEFAULT (0),
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_訂單出貨明細 PRIMARY KEY (出貨編號, 出貨項次)
);
GO

IF OBJECT_ID('dbo.出貨退回主檔','U') IS NULL
CREATE TABLE dbo.出貨退回主檔 (
    退回編號   nvarchar(20)  NOT NULL,
    退回日期   date          NULL,
    銷售組織   nvarchar(20)  NULL,
    客戶編號   nvarchar(20)  NULL,
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_出貨退回主檔 PRIMARY KEY (退回編號)
);
GO

IF OBJECT_ID('dbo.出貨退回明細','U') IS NULL
CREATE TABLE dbo.出貨退回明細 (
    退回編號   nvarchar(20)  NOT NULL,
    退回項次   nvarchar(4)   NOT NULL,
    訂單編號   nvarchar(20)  NULL,
    訂單項次   nvarchar(4)   NULL,
    物料編號   nvarchar(20)  NULL,
    倉庫代碼   nvarchar(20)  NULL,
    退回數量   int           NOT NULL DEFAULT (0),
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_出貨退回明細 PRIMARY KEY (退回編號, 退回項次)
);
GO

-- Foreign keys
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_客戶訂單主檔_銷售組織')
    ALTER TABLE dbo.客戶訂單主檔 ADD CONSTRAINT FK_客戶訂單主檔_銷售組織 FOREIGN KEY (銷售組織) REFERENCES dbo.銷售組織維護(銷售組織);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_客戶訂單主檔_客戶資料維護')
    ALTER TABLE dbo.客戶訂單主檔 ADD CONSTRAINT FK_客戶訂單主檔_客戶資料維護 FOREIGN KEY (客戶編號) REFERENCES dbo.客戶資料維護(客戶編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_客戶訂單明細_客戶訂單主檔')
    ALTER TABLE dbo.客戶訂單明細 ADD CONSTRAINT FK_客戶訂單明細_客戶訂單主檔 FOREIGN KEY (訂單編號) REFERENCES dbo.客戶訂單主檔(訂單編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_客戶訂單明細_物料資料維護')
    ALTER TABLE dbo.客戶訂單明細 ADD CONSTRAINT FK_客戶訂單明細_物料資料維護 FOREIGN KEY (物料編號) REFERENCES dbo.物料資料維護(物料編號);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_訂單出貨主檔_銷售組織')
    ALTER TABLE dbo.訂單出貨主檔 ADD CONSTRAINT FK_訂單出貨主檔_銷售組織 FOREIGN KEY (銷售組織) REFERENCES dbo.銷售組織維護(銷售組織);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_訂單出貨主檔_客戶資料維護')
    ALTER TABLE dbo.訂單出貨主檔 ADD CONSTRAINT FK_訂單出貨主檔_客戶資料維護 FOREIGN KEY (客戶編號) REFERENCES dbo.客戶資料維護(客戶編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_訂單出貨明細_訂單出貨主檔')
    ALTER TABLE dbo.訂單出貨明細 ADD CONSTRAINT FK_訂單出貨明細_訂單出貨主檔 FOREIGN KEY (出貨編號) REFERENCES dbo.訂單出貨主檔(出貨編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_訂單出貨明細_客戶訂單明細')
    ALTER TABLE dbo.訂單出貨明細 ADD CONSTRAINT FK_訂單出貨明細_客戶訂單明細 FOREIGN KEY (訂單編號, 訂單項次) REFERENCES dbo.客戶訂單明細(訂單編號, 訂單項次);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_訂單出貨明細_物料資料維護')
    ALTER TABLE dbo.訂單出貨明細 ADD CONSTRAINT FK_訂單出貨明細_物料資料維護 FOREIGN KEY (物料編號) REFERENCES dbo.物料資料維護(物料編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_訂單出貨明細_工廠倉庫維護')
    ALTER TABLE dbo.訂單出貨明細 ADD CONSTRAINT FK_訂單出貨明細_工廠倉庫維護 FOREIGN KEY (倉庫代碼) REFERENCES dbo.工廠倉庫維護(倉庫代碼);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_出貨退回主檔_銷售組織')
    ALTER TABLE dbo.出貨退回主檔 ADD CONSTRAINT FK_出貨退回主檔_銷售組織 FOREIGN KEY (銷售組織) REFERENCES dbo.銷售組織維護(銷售組織);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_出貨退回主檔_客戶資料維護')
    ALTER TABLE dbo.出貨退回主檔 ADD CONSTRAINT FK_出貨退回主檔_客戶資料維護 FOREIGN KEY (客戶編號) REFERENCES dbo.客戶資料維護(客戶編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_出貨退回明細_出貨退回主檔')
    ALTER TABLE dbo.出貨退回明細 ADD CONSTRAINT FK_出貨退回明細_出貨退回主檔 FOREIGN KEY (退回編號) REFERENCES dbo.出貨退回主檔(退回編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_出貨退回明細_客戶訂單明細')
    ALTER TABLE dbo.出貨退回明細 ADD CONSTRAINT FK_出貨退回明細_客戶訂單明細 FOREIGN KEY (訂單編號, 訂單項次) REFERENCES dbo.客戶訂單明細(訂單編號, 訂單項次);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_出貨退回明細_物料資料維護')
    ALTER TABLE dbo.出貨退回明細 ADD CONSTRAINT FK_出貨退回明細_物料資料維護 FOREIGN KEY (物料編號) REFERENCES dbo.物料資料維護(物料編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_出貨退回明細_工廠倉庫維護')
    ALTER TABLE dbo.出貨退回明細 ADD CONSTRAINT FK_出貨退回明細_工廠倉庫維護 FOREIGN KEY (倉庫代碼) REFERENCES dbo.工廠倉庫維護(倉庫代碼);
GO
