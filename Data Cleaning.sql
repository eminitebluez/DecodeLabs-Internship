-----------------------------------------------------------------------------------------------------------------------------------------------------
---QUICK PROFILE OF WHAT ACTUALLY NEEDS CLEANING---
-----------------------------------------------------------------------------------------------------------------------------------------------------
SELECT COUNT(*) AS TotalRows 
FROM dbo.Orders_Raw;
-----------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	SUM(CASE WHEN [OrderID]         IS NULL THEN 1 ELSE 0 END) AS Null_OrderID,
    SUM(CASE WHEN [Date]            IS NULL THEN 1 ELSE 0 END) AS Null_Date,
    SUM(CASE WHEN [CustomerID]      IS NULL THEN 1 ELSE 0 END) AS Null_CustomerID,
    SUM(CASE WHEN [Product]         IS NULL THEN 1 ELSE 0 END) AS Null_Product,
    SUM(CASE WHEN [Quantity]        IS NULL THEN 1 ELSE 0 END) AS Null_Quantity,
    SUM(CASE WHEN [UnitPrice]       IS NULL THEN 1 ELSE 0 END) AS Null_UnitPrice,
    SUM(CASE WHEN [ShippingAddress] IS NULL THEN 1 ELSE 0 END) AS Null_ShippingAddress,
    SUM(CASE WHEN [PaymentMethod]   IS NULL THEN 1 ELSE 0 END) AS Null_PaymentMethod,
    SUM(CASE WHEN [OrderStatus]     IS NULL THEN 1 ELSE 0 END) AS Null_OrderStatus,
    SUM(CASE WHEN [TrackingNumber]  IS NULL THEN 1 ELSE 0 END) AS Null_TrackingNumber,
    SUM(CASE WHEN [ItemsInCart]     IS NULL THEN 1 ELSE 0 END) AS Null_ItemsInCart,
    SUM(CASE WHEN [CouponCode]      IS NULL THEN 1 ELSE 0 END) AS Null_CouponCode,
    SUM(CASE WHEN [ReferralSource]  IS NULL THEN 1 ELSE 0 END) AS Null_ReferralSource,
    SUM(CASE WHEN [TotalPrice]      IS NULL THEN 1 ELSE 0 END) AS Null_TotalPrice
FROM dbo.Orders_Raw;
-----------------------------------------------------------------------------------------------------------------------------------------------------
---duplicate check---
-----------------------------------------------------------------------------------------------------------------------------------------------------
SELECT [OrderID], COUNT(*) AS Occurrences
FROM dbo.Orders_Raw
GROUP BY [OrderID]
HAVING COUNT(*) > 1;

-----------------------------------------------------------------------------------------------------------------------------------------------------
--PART 1 — BUILD THE CLEANED TABLE (no null values, correct data types)--
-----------------------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('dbo.Orders_Cleaned', 'U') IS NOT NULL
    DROP TABLE dbo.Orders_Cleaned;
 
SELECT
    [OrderID],
    CONVERT(DATE, [Date], 103)                         AS OrderDate,   -- style 103 = dd/mm/yyyy
    [CustomerID],
    LTRIM(RTRIM([Product]))                            AS Product,
    [Quantity],
    [UnitPrice],
    LTRIM(RTRIM([ShippingAddress]))                    AS ShippingAddress,
    LTRIM(RTRIM([PaymentMethod]))                      AS PaymentMethod,
    LTRIM(RTRIM([OrderStatus]))                        AS OrderStatus,
    [TrackingNumber],
    [ItemsInCart],
    ISNULL(LTRIM(RTRIM([CouponCode])), 'NO COUPON')    AS CouponCode,   -- fills the null coupon values
    LTRIM(RTRIM([ReferralSource]))                     AS ReferralSource,
    [TotalPrice],
    DATENAME(MONTH, CONVERT(DATE, [Date], 103))        AS MonthName,
    YEAR(CONVERT(DATE, [Date], 103))                   AS OrderYear
INTO dbo.Orders_Cleaned
FROM dbo.Orders_Raw;

-----------------------------------------------------------------------------------------------------------------------------------------------------
---Verify that there are no nulls anywhere in the cleaned table---
-----------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
    SUM(CASE WHEN [OrderID]        IS NULL THEN 1 ELSE 0 END) AS Null_OrderID,
    SUM(CASE WHEN [OrderDate]      IS NULL THEN 1 ELSE 0 END) AS Null_OrderDate,
    SUM(CASE WHEN [Product]        IS NULL THEN 1 ELSE 0 END) AS Null_Product,
    SUM(CASE WHEN [CouponCode]     IS NULL THEN 1 ELSE 0 END) AS Null_CouponCode,
    SUM(CASE WHEN [TotalPrice]     IS NULL THEN 1 ELSE 0 END) AS Null_TotalPrice
FROM dbo.Orders_Cleaned;
-----------------------------------------------------------------------------------------------------------------------------------------------------
---WE NOW HAVE A CLEANED DATA SET!--
-----------------------------------------------------------------------------------------------------------------------------------------------------
SELECT TOP 20 * 
FROM dbo.Orders_Cleaned 
ORDER BY OrderDate;
-----------------------------------------------------------------------------------------------------------------------------------------------------
--PART 2 — BASIC SELECT QUERIES--
-----------------------------------------------------------------------------------------------------------------------------------------------------
-- All columns, all rows--
SELECT * 
FROM dbo.Orders_Cleaned;

-- Specific columns only
SELECT OrderID, Product, Quantity, UnitPrice, TotalPrice
FROM dbo.Orders_Cleaned;

-- Rename columns in the output with aliases
SELECT
    OrderID       AS [Order Number],
    Product,
    TotalPrice    AS [Order Value]
FROM dbo.Orders_Cleaned;

-- Distinct values in a column (useful for spotting categories)
SELECT DISTINCT Product 
FROM dbo.Orders_Cleaned;

SELECT DISTINCT PaymentMethod 
FROM dbo.Orders_Cleaned;

SELECT DISTINCT OrderStatus 
FROM dbo.Orders_Cleaned;
-----------------------------------------------------------------------------------------------------------------------------------------------------
--PART 3 -- WHERE (filtering)
-----------------------------------------------------------------------------------------------------------------------------------------------------
-- Single condition
SELECT * 
FROM dbo.Orders_Cleaned 
WHERE Product = 'Laptop';

-- Numeric comparison
SELECT * 
FROM dbo.Orders_Cleaned 
WHERE TotalPrice > 1000;
 
-- Multiple conditions (AND / OR)
SELECT * 
FROM dbo.Orders_Cleaned
WHERE Product = 'Laptop' AND OrderStatus = 'Delivered';
 
SELECT * 
FROM dbo.Orders_Cleaned
WHERE OrderStatus = 'Cancelled' OR OrderStatus = 'Returned';
 
-- IN (shorthand for multiple ORs)
SELECT * 
FROM dbo.Orders_Cleaned
WHERE PaymentMethod IN ('Credit Card', 'Debit Card');
 
-- BETWEEN for ranges
SELECT * 
FROM dbo.Orders_Cleaned
WHERE TotalPrice BETWEEN 500 AND 1500;
 
-- Date filtering
SELECT * 
FROM dbo.Orders_Cleaned
WHERE OrderDate >= '2024-01-01' AND OrderDate < '2025-01-01';
 
-- Text pattern matching
SELECT * 
FROM dbo.Orders_Cleaned
WHERE ShippingAddress LIKE '%Main St%';
 
-- Checking the coupon cleanup worked
SELECT * 
FROM dbo.Orders_Cleaned 
WHERE CouponCode = 'NO COUPON';

-----------------------------------------------------------------------------------------------------------------------------------------------------
--PART 4 -- ORDER BY (sorting)
-----------------------------------------------------------------------------------------------------------------------------------------------------
-- Highest value orders first
SELECT OrderID, Product, TotalPrice
FROM dbo.Orders_Cleaned
ORDER BY TotalPrice DESC;
 
-- Sort by multiple columns
SELECT Product, OrderDate, TotalPrice
FROM dbo.Orders_Cleaned
ORDER BY Product ASC, TotalPrice DESC;
 
-- Sort by date (chronological)
SELECT OrderID, OrderDate, TotalPrice
FROM dbo.Orders_Cleaned
ORDER BY OrderDate;

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- PART 5--  GROUP BY (aggregating by category)--
-----------------------------------------------------------------------------------------------------------------------------------------------------
-- Orders and revenue per product
SELECT
    Product,
    COUNT(*)            AS OrderCount,
    SUM(TotalPrice)      AS TotalRevenue,
    AVG(TotalPrice)      AS AvgOrderValue
FROM dbo.Orders_Cleaned
GROUP BY Product
ORDER BY TotalRevenue DESC;
 
-- Orders per status
SELECT
    OrderStatus,
    COUNT(*) AS OrderCount
FROM dbo.Orders_Cleaned
GROUP BY OrderStatus
ORDER BY OrderCount DESC;
 
-- Revenue per payment method
SELECT
    PaymentMethod,
    COUNT(*)            AS OrderCount,
    SUM(TotalPrice)      AS TotalRevenue
FROM dbo.Orders_Cleaned
GROUP BY PaymentMethod
ORDER BY TotalRevenue DESC;
 
-- Revenue per month (chronological order)
SELECT
    OrderYear,
    MonthName,
    COUNT(*)            AS OrderCount,
    SUM(TotalPrice)      AS TotalRevenue
FROM dbo.Orders_Cleaned
GROUP BY OrderYear, MonthName, MONTH(OrderDate)
ORDER BY OrderYear, MONTH(OrderDate);
 
-- Group by two columns at once (Product x OrderStatus)
SELECT
    Product,
    OrderStatus,
    COUNT(*) AS OrderCount
FROM dbo.Orders_Cleaned
GROUP BY Product, OrderStatus
ORDER BY Product, OrderStatus;
 
-- GROUP BY with HAVING (filter on the aggregate, not the raw rows)
SELECT
    Product,
    COUNT(*) AS OrderCount,
    ROUND(SUM(TotalPrice),2) AS TotalRevenue  --using round for approximation to 2 decimal points
FROM dbo.Orders_Cleaned
GROUP BY Product
HAVING SUM(TotalPrice) > 150000
ORDER BY TotalRevenue DESC;

-----------------------------------------------------------------------------------------------------------------------------------------------------
--PART 6 -- BASIC AGGREGATIONS (COUNT, SUM, AVG, MIN, MAX) --
-----------------------------------------------------------------------------------------------------------------------------------------------------
-- Whole-table aggregates
SELECT
    COUNT(*)              AS TotalOrders,
    SUM(TotalPrice)       AS TotalRevenue,
    AVG(TotalPrice)       AS AvgOrderValue,
    MIN(TotalPrice)       AS SmallestOrder,
    MAX(TotalPrice)       AS LargestOrder
FROM dbo.Orders_Cleaned;
 
-- COUNT with a condition (only cancelled orders)
SELECT COUNT(*) AS CancelledOrders
FROM dbo.Orders_Cleaned
WHERE OrderStatus = 'Cancelled';
 
-- COUNT DISTINCT customers (unique buyers, not unique orders)
SELECT COUNT(DISTINCT CustomerID) AS UniqueCustomers
FROM dbo.Orders_Cleaned;
 
-- SUM and AVG filtered by a category
SELECT
    SUM(TotalPrice) AS LaptopRevenue,
    AVG(TotalPrice) AS AvgLaptopOrderValue
FROM dbo.Orders_Cleaned
WHERE Product = 'Laptop';
 
-- Combine WHERE + GROUP BY + aggregation: revenue by product, delivered orders only
SELECT
    Product,
    COUNT(*)        AS DeliveredOrders,
    SUM(TotalPrice) AS DeliveredRevenue,
    AVG(TotalPrice) AS AvgDeliveredOrderValue
FROM dbo.Orders_Cleaned
WHERE OrderStatus = 'Delivered'
GROUP BY Product
ORDER BY DeliveredRevenue DESC;