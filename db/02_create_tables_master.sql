-- =====================================================
-- 主數據 Master data tables
-- =====================================================
USE oav00_v2;
GO

IF OBJECT_ID('dbo.客戶資料維護','U') IS NULL
CREATE TABLE dbo.客戶資料維護 (
    客戶編號   nvarchar(20)  NOT NULL,
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_客戶資料維護 PRIMARY KEY (客戶編號)
);
GO

IF OBJECT_ID('dbo.廠商資料維護','U') IS NULL
CREATE TABLE dbo.廠商資料維護 (
    廠商編號   nvarchar(20)  NOT NULL,
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_廠商資料維護 PRIMARY KEY (廠商編號)
);
GO

IF OBJECT_ID('dbo.物料資料維護','U') IS NULL
CREATE TABLE dbo.物料資料維護 (
    物料編號   nvarchar(20)  NOT NULL,
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_物料資料維護 PRIMARY KEY (物料編號)
);
GO

IF OBJECT_ID('dbo.物管資料維護','U') IS NULL
CREATE TABLE dbo.物管資料維護 (
    物管編號   nvarchar(20)  NOT NULL,
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_物管資料維護 PRIMARY KEY (物管編號)
);
GO

IF OBJECT_ID('dbo.用量清單維護','U') IS NULL
CREATE TABLE dbo.用量清單維護 (
    主階編號   nvarchar(20)  NOT NULL,
    子階編號   nvarchar(20)  NOT NULL,
    標準用量   int           NOT NULL DEFAULT (0),
    備註說明   nvarchar(20)  NULL,
    CONSTRAINT PK_用量清單維護 PRIMARY KEY (主階編號, 子階編號)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_用量清單維護_物管資料維護')
    ALTER TABLE dbo.用量清單維護
    ADD CONSTRAINT FK_用量清單維護_物管資料維護 FOREIGN KEY (主階編號) REFERENCES dbo.物管資料維護(物管編號);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_用量清單維護_物料資料維護')
    ALTER TABLE dbo.用量清單維護
    ADD CONSTRAINT FK_用量清單維護_物料資料維護 FOREIGN KEY (子階編號) REFERENCES dbo.物料資料維護(物料編號);
GO
