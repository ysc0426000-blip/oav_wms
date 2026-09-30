-- =====================================================
-- MM 採購模組 交易數據
-- 註：原始規格書「廠商採購主檔」欄位寫的是「客戶編號」，
--     依業務邏輯應為「廠商編號」，此處已修正，請確認。
-- =====================================================
USE oav00_v2;
GO

IF OBJECT_ID('dbo.廠商採購主檔','U') IS NULL
CREATE TABLE dbo.廠商採購主檔 (
    採購編號   nvarchar(20)  NOT NULL,
    採購日期   date          NULL,
    採購組織   nvarchar(20)  NULL,
    廠商編號   nvarchar(20)  NULL,
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_廠商採購主檔 PRIMARY KEY (採購編號)
);
GO

IF OBJECT_ID('dbo.廠商採購明細','U') IS NULL
CREATE TABLE dbo.廠商採購明細 (
    採購編號   nvarchar(20)  NOT NULL,
    採購項次   nvarchar(4)   NOT NULL,
    物料編號   nvarchar(20)  NULL,
    採購數量   int           NOT NULL DEFAULT (0),
    收貨數量   int           NOT NULL DEFAULT (0),
    退回數量   int           NOT NULL DEFAULT (0),
    預定交期   date          NULL,
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_廠商採購明細 PRIMARY KEY (採購編號, 採購項次)
);
GO

IF OBJECT_ID('dbo.採購收貨主檔','U') IS NULL
CREATE TABLE dbo.採購收貨主檔 (
    收貨編號   nvarchar(20)  NOT NULL,
    收貨日期   date          NULL,
    採購組織   nvarchar(20)  NULL,
    廠商編號   nvarchar(20)  NULL,
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_採購收貨主檔 PRIMARY KEY (收貨編號)
);
GO

IF OBJECT_ID('dbo.採購收貨明細','U') IS NULL
CREATE TABLE dbo.採購收貨明細 (
    收貨編號   nvarchar(20)  NOT NULL,
    收貨項次   nvarchar(4)   NOT NULL,
    採購編號   nvarchar(20)  NULL,
    採購項次   nvarchar(4)   NULL,
    物料編號   nvarchar(20)  NULL,
    倉庫代碼   nvarchar(20)  NULL,
    收貨數量   int           NOT NULL DEFAULT (0),
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_採購收貨明細 PRIMARY KEY (收貨編號, 收貨項次)
);
GO

IF OBJECT_ID('dbo.收貨退回主檔','U') IS NULL
CREATE TABLE dbo.收貨退回主檔 (
    退回編號   nvarchar(20)  NOT NULL,
    退回日期   date          NULL,
    採購組織   nvarchar(20)  NULL,
    廠商編號   nvarchar(20)  NULL,
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_收貨退回主檔 PRIMARY KEY (退回編號)
);
GO

IF OBJECT_ID('dbo.收貨退回明細','U') IS NULL
CREATE TABLE dbo.收貨退回明細 (
    退回編號   nvarchar(20)  NOT NULL,
    退回項次   nvarchar(4)   NOT NULL,
    採購編號   nvarchar(20)  NULL,
    採購項次   nvarchar(4)   NULL,
    物料編號   nvarchar(20)  NULL,
    倉庫代碼   nvarchar(20)  NULL,
    退回數量   int           NOT NULL DEFAULT (0),
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_收貨退回明細 PRIMARY KEY (退回編號, 退回項次)
);
GO

-- Foreign keys
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_廠商採購主檔_採購組織')
    ALTER TABLE dbo.廠商採購主檔 ADD CONSTRAINT FK_廠商採購主檔_採購組織 FOREIGN KEY (採購組織) REFERENCES dbo.採購組織維護(採購組織);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_廠商採購主檔_廠商資料維護')
    ALTER TABLE dbo.廠商採購主檔 ADD CONSTRAINT FK_廠商採購主檔_廠商資料維護 FOREIGN KEY (廠商編號) REFERENCES dbo.廠商資料維護(廠商編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_廠商採購明細_廠商採購主檔')
    ALTER TABLE dbo.廠商採購明細 ADD CONSTRAINT FK_廠商採購明細_廠商採購主檔 FOREIGN KEY (採購編號) REFERENCES dbo.廠商採購主檔(採購編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_廠商採購明細_物料資料維護')
    ALTER TABLE dbo.廠商採購明細 ADD CONSTRAINT FK_廠商採購明細_物料資料維護 FOREIGN KEY (物料編號) REFERENCES dbo.物料資料維護(物料編號);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_採購收貨主檔_採購組織')
    ALTER TABLE dbo.採購收貨主檔 ADD CONSTRAINT FK_採購收貨主檔_採購組織 FOREIGN KEY (採購組織) REFERENCES dbo.採購組織維護(採購組織);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_採購收貨主檔_廠商資料維護')
    ALTER TABLE dbo.採購收貨主檔 ADD CONSTRAINT FK_採購收貨主檔_廠商資料維護 FOREIGN KEY (廠商編號) REFERENCES dbo.廠商資料維護(廠商編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_採購收貨明細_採購收貨主檔')
    ALTER TABLE dbo.採購收貨明細 ADD CONSTRAINT FK_採購收貨明細_採購收貨主檔 FOREIGN KEY (收貨編號) REFERENCES dbo.採購收貨主檔(收貨編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_採購收貨明細_廠商採購明細')
    ALTER TABLE dbo.採購收貨明細 ADD CONSTRAINT FK_採購收貨明細_廠商採購明細 FOREIGN KEY (採購編號, 採購項次) REFERENCES dbo.廠商採購明細(採購編號, 採購項次);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_採購收貨明細_物料資料維護')
    ALTER TABLE dbo.採購收貨明細 ADD CONSTRAINT FK_採購收貨明細_物料資料維護 FOREIGN KEY (物料編號) REFERENCES dbo.物料資料維護(物料編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_採購收貨明細_工廠倉庫維護')
    ALTER TABLE dbo.採購收貨明細 ADD CONSTRAINT FK_採購收貨明細_工廠倉庫維護 FOREIGN KEY (倉庫代碼) REFERENCES dbo.工廠倉庫維護(倉庫代碼);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_收貨退回主檔_採購組織')
    ALTER TABLE dbo.收貨退回主檔 ADD CONSTRAINT FK_收貨退回主檔_採購組織 FOREIGN KEY (採購組織) REFERENCES dbo.採購組織維護(採購組織);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_收貨退回主檔_廠商資料維護')
    ALTER TABLE dbo.收貨退回主檔 ADD CONSTRAINT FK_收貨退回主檔_廠商資料維護 FOREIGN KEY (廠商編號) REFERENCES dbo.廠商資料維護(廠商編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_收貨退回明細_收貨退回主檔')
    ALTER TABLE dbo.收貨退回明細 ADD CONSTRAINT FK_收貨退回明細_收貨退回主檔 FOREIGN KEY (退回編號) REFERENCES dbo.收貨退回主檔(退回編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_收貨退回明細_廠商採購明細')
    ALTER TABLE dbo.收貨退回明細 ADD CONSTRAINT FK_收貨退回明細_廠商採購明細 FOREIGN KEY (採購編號, 採購項次) REFERENCES dbo.廠商採購明細(採購編號, 採購項次);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_收貨退回明細_物料資料維護')
    ALTER TABLE dbo.收貨退回明細 ADD CONSTRAINT FK_收貨退回明細_物料資料維護 FOREIGN KEY (物料編號) REFERENCES dbo.物料資料維護(物料編號);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_收貨退回明細_工廠倉庫維護')
    ALTER TABLE dbo.收貨退回明細 ADD CONSTRAINT FK_收貨退回明細_工廠倉庫維護 FOREIGN KEY (倉庫代碼) REFERENCES dbo.工廠倉庫維護(倉庫代碼);
GO
