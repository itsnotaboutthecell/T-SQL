USE AdventureWorksLT;

-- Creates a sequential Numbers table if one does not exist
IF NOT EXISTS (
    SELECT
    *
FROM
    sys.objects
WHERE
        OBJECT_ID = OBJECT_ID(N'[dbo].[Numbers]')
    AND type = 'U'
) BEGIN
    CREATE TABLE dbo.Numbers
    (
        NUMBER INT NOT NULL PRIMARY KEY
    );

    DECLARE @i INT = 0, @j INT = 0, @k INT = 100;
    SET NOCOUNT ON;

    BEGIN TRANSACTION
    WHILE @i < @k BEGIN
        SET
    @j = 0;

        WHILE @j < @k BEGIN
            INSERT INTO Numbers
                (number)
            VALUES
                (@j * @k + @i);

            SET @j += 1;

        END
        COMMIT;

        BEGIN TRANSACTION;
        SET @i += 1;

    END
    COMMIT
END
GO
IF OBJECT_ID('SalesLT.SalesOrderHeaderEnlarged') IS NOT NULL DROP TABLE SalesLT.SalesOrderHeaderEnlarged;

GO
CREATE TABLE SalesLT.SalesOrderHeaderEnlarged
(
    SalesOrderID int NOT NULL IDENTITY (1, 1) NOT FOR REPLICATION,
    RevisionNumber tinyint NOT NULL,
    OrderDate datetime NOT NULL,
    DueDate datetime NOT NULL,
    ShipDate datetime NULL,
    Status tinyint NOT NULL,
    OnlineOrderFlag dbo.Flag NOT NULL,
    SalesOrderNumber AS (
            isnull(
                N'SO' + CONVERT([nvarchar](23), [SalesOrderID], 0),
                N'*** ERROR ***'
            )
        ),
    PurchaseOrderNumber dbo.OrderNumber NULL,
    AccountNumber dbo.AccountNumber NULL,
    CustomerID int NOT NULL,
    BillToAddressID int NOT NULL,
    ShipToAddressID int NOT NULL,
    ShipMethodID int NULL,
    CreditCardApprovalCode varchar(15) NULL,
    CurrencyRateID int NULL,
    SubTotal money NOT NULL,
    TaxAmt money NOT NULL,
    Freight money NOT NULL,
    TotalDue AS (isnull(([SubTotal] + [TaxAmt]) + [Freight],(0))),
    Comment nvarchar(128) NULL,
    rowguid uniqueidentifier NOT NULL ROWGUIDCOL,
    ModifiedDate datetime NOT NULL
) ON [PRIMARY]
GO
SET
    IDENTITY_INSERT SalesLT.SalesOrderHeaderEnlarged ON
GO
INSERT INTO
    SalesLT.SalesOrderHeaderEnlarged
    (
    SalesOrderID,
    RevisionNumber,
    OrderDate,
    DueDate,
    ShipDate,
    Status,
    OnlineOrderFlag,
    PurchaseOrderNumber,
    AccountNumber,
    CustomerID,
    BillToAddressID,
    ShipToAddressID,
    CreditCardApprovalCode,
    SubTotal,
    TaxAmt,
    Freight,
    Comment,
    rowguid,
    ModifiedDate
    )
SELECT
    SalesOrderID,
    RevisionNumber,
    OrderDate,
    DueDate,
    ShipDate,
    Status,
    OnlineOrderFlag,
    PurchaseOrderNumber,
    AccountNumber,
    CustomerID,
    BillToAddressID,
    ShipToAddressID,
    CreditCardApprovalCode,
    SubTotal,
    TaxAmt,
    Freight,
    Comment,
    rowguid,
    ModifiedDate
FROM
    SalesLT.SalesOrderHeader WITH (HOLDLOCK TABLOCKX)
GO
SET
    IDENTITY_INSERT SalesLT.SalesOrderHeaderEnlarged OFF
GO
ALTER TABLE
    SalesLT.SalesOrderHeaderEnlarged
ADD
    CONSTRAINT PK_SalesOrderHeaderEnlarged_SalesOrderID PRIMARY KEY CLUSTERED (SalesOrderID) WITH(
        STATISTICS_NORECOMPUTE = OFF,
        IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON,
        ALLOW_PAGE_LOCKS = ON
    ) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX AK_SalesOrderHeaderEnlarged_rowguid ON SalesLT.SalesOrderHeaderEnlarged (rowguid) WITH(
        STATISTICS_NORECOMPUTE = OFF,
        IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON,
        ALLOW_PAGE_LOCKS = ON
    ) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX AK_SalesOrderHeaderEnlarged_SalesOrderNumber ON SalesLT.SalesOrderHeaderEnlarged (SalesOrderNumber) WITH(
        STATISTICS_NORECOMPUTE = OFF,
        IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON,
        ALLOW_PAGE_LOCKS = ON
    ) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX IX_SalesOrderHeaderEnlarged_CustomerID ON SalesLT.SalesOrderHeaderEnlarged (CustomerID) WITH(
        STATISTICS_NORECOMPUTE = OFF,
        IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON,
        ALLOW_PAGE_LOCKS = ON
    ) ON [PRIMARY]
GO
IF OBJECT_ID('SalesLT.SalesOrderDetailEnlarged') IS NOT NULL DROP TABLE SalesLT.SalesOrderDetailEnlarged;

GO
CREATE TABLE SalesLT.SalesOrderDetailEnlarged
(
    SalesOrderID int NOT NULL,
    SalesOrderDetailID int NOT NULL IDENTITY (1, 1),
    CarrierTrackingNumber nvarchar(25) NULL,
    OrderQty smallint NOT NULL,
    ProductID int NOT NULL,
    SpecialOfferID int NULL,
    UnitPrice money NOT NULL,
    UnitPriceDiscount money NOT NULL,
    LineTotal AS (
            isnull(
                ([UnitPrice] *((1.0) - [UnitPriceDiscount])) * [OrderQty],
                (0.0)
            )
        ),
    rowguid uniqueidentifier NOT NULL ROWGUIDCOL,
    ModifiedDate datetime NOT NULL
) ON [PRIMARY]
GO
SET
    IDENTITY_INSERT SalesLT.SalesOrderDetailEnlarged ON
GO
INSERT INTO
    SalesLT.SalesOrderDetailEnlarged
    (
    SalesOrderID,
    SalesOrderDetailID,
    OrderQty,
    ProductID,
    UnitPrice,
    UnitPriceDiscount,
    rowguid,
    ModifiedDate
    )
SELECT
    SalesOrderID,
    SalesOrderDetailID,
    OrderQty,
    ProductID,
    UnitPrice,
    UnitPriceDiscount,
    rowguid,
    ModifiedDate
FROM
    SalesLT.SalesOrderDetail WITH (HOLDLOCK TABLOCKX)
GO
SET
    IDENTITY_INSERT SalesLT.SalesOrderDetailEnlarged OFF
GO
ALTER TABLE
    SalesLT.SalesOrderDetailEnlarged
ADD
    CONSTRAINT PK_SalesOrderDetailEnlarged_SalesOrderID_SalesOrderDetailID PRIMARY KEY CLUSTERED (SalesOrderID, SalesOrderDetailID) WITH(
        STATISTICS_NORECOMPUTE = OFF,
        IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON,
        ALLOW_PAGE_LOCKS = ON
    ) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX AK_SalesOrderDetailEnlarged_rowguid ON SalesLT.SalesOrderDetailEnlarged (rowguid) WITH(
        STATISTICS_NORECOMPUTE = OFF,
        IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON,
        ALLOW_PAGE_LOCKS = ON
    ) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX IX_SalesOrderDetailEnlarged_ProductID ON SalesLT.SalesOrderDetailEnlarged (ProductID) WITH(
        STATISTICS_NORECOMPUTE = OFF,
        IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON,
        ALLOW_PAGE_LOCKS = ON
    ) ON [PRIMARY]
GO

-- Creating sample records, can be enlarged via the @TotalRecords parameter
BEGIN TRANSACTION
DECLARE @TableVar TABLE (OrigSalesOrderID int,
    NewSalesOrderID int);
DECLARE @TotalRecords INT = 100, @TotalResults INT = (SELECT MAX(number) + 1
FROM Numbers);
INSERT INTO
    SalesLT.SalesOrderHeaderEnlarged
    (
    RevisionNumber,
    OrderDate,
    DueDate,
    ShipDate,
    Status,
    OnlineOrderFlag,
    PurchaseOrderNumber,
    AccountNumber,
    CustomerID,
    BillToAddressID,
    ShipToAddressID,
    CreditCardApprovalCode,
    SubTotal,
    TaxAmt,
    Freight,
    Comment,
    rowguid,
    ModifiedDate
    )
OUTPUT inserted.Comment,
    inserted.SalesOrderID INTO @TableVar
SELECT
    RevisionNumber,
    DATEADD(dd, number, OrderDate) AS OrderDate,
    DATEADD(dd, number, DueDate),
    DATEADD(dd, number, ShipDate),
    Status,
    OnlineOrderFlag,
    PurchaseOrderNumber,
    AccountNumber,
    CustomerID,
    BillToAddressID,
    ShipToAddressID,
    CreditCardApprovalCode,
    SubTotal,
    TaxAmt,
    Freight,
    SalesOrderID,
    NEWID(),
    DATEADD(dd, number, ModifiedDate)
FROM
    SalesLT.SalesOrderHeader AS soh WITH (HOLDLOCK TABLOCKX)
    CROSS JOIN (
        SELECT
        number
    FROM
        (
                                                                    SELECT
                TOP (@TotalRecords)
                number
            FROM
                dbo.Numbers
            WHERE
                    number < @TotalResults
            ORDER BY
                    NEWID() DESC
        UNION
            SELECT
                TOP (@TotalRecords)
                number
            FROM
                dbo.Numbers
            WHERE
                    number < @TotalResults
            ORDER BY
                    NEWID() DESC
        UNION
            SELECT
                TOP (@TotalRecords)
                number
            FROM
                dbo.Numbers
            WHERE
                    number < @TotalResults
            ORDER BY
                    NEWID() DESC
        UNION
            SELECT
                TOP (@TotalRecords)
                number
            FROM
                dbo.Numbers
            WHERE
                    number < @TotalResults
            ORDER BY
                    NEWID() DESC
            ) AS tab
    ) AS Randomizer
ORDER BY
    OrderDate,
    number
INSERT INTO
    SalesLT.SalesOrderDetailEnlarged
    (
    SalesOrderID,
    OrderQty,
    ProductID,
    UnitPrice,
    UnitPriceDiscount,
    rowguid,
    ModifiedDate
    )
SELECT
    tv.NewSalesOrderID,
    OrderQty,
    ProductID,
    UnitPrice,
    UnitPriceDiscount,
    NEWID(),
    ModifiedDate
FROM
    SalesLT.SalesOrderDetail AS sod
    JOIN @TableVar AS tv ON sod.SalesOrderID = tv.OrigSalesOrderID
ORDER BY
    sod.SalesOrderDetailID
COMMIT;
