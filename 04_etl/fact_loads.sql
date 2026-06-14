-- ============================================================
-- Vizlink DWH — Fact Table Load Queries
-- Run dim_loads.sql first — facts depend on dimension keys
-- Pattern: incremental insert — new records only
-- ============================================================

-- ------------------------------------------------------------
-- Fact_ShopOrders
-- Grain: one row per shopkeeper order
-- Resolves: DistributorShopKey, DistCenterKey, VizShopKey
-- ------------------------------------------------------------
SELECT
    o.Id                    AS ShopOrderId,
    ds.DistributorShopKey,
    dc.DistCenterKey,
    v.VizShopKey,
    o.DeliveryManId,
    o.DeliveryManName,
    o.OrderDate,
    o.OrderDeliveryDate,
    o.NetSales,
    o.OriginalNetSales,
    o.InvoiceNumber,
    o.VizproInvoiceNumber   AS DistributorInvoiceNumber,
    o.OrderAmountToPay,
    o.AmountPaid,
    o.OrderStatus
FROM [vizlink-live].[dbo].ShopOrders o
LEFT JOIN VDWH_Auto.dbo.Dim_DistributorShop ds  ON ds.DistributorShopId = o.ShopId
LEFT JOIN VDWH_Auto.dbo.Dim_DistCenter dc        ON dc.DistCenterId      = o.DistCenterId
LEFT JOIN VDWH_Auto.dbo.Dim_Vizshops v           ON v.VizShopId          = o.VizshopId
WHERE o.Id NOT IN (SELECT ShopOrderId FROM VDWH_Auto.dbo.Fact_ShopOrders);

-- ------------------------------------------------------------
-- Fact_ShopOrderTransactions
-- Grain: one row per digital payment (MFI) against an order
-- Resolves: ShopOrderKey from Fact_ShopOrders
-- Filter: Paid transactions only
-- Status 'ModifiedorActualStatus' defaults to 'Paid' at load
-- ------------------------------------------------------------
SELECT DISTINCT
    tr.Id                                           AS ShopTransactionId,
    tr.TransactionId,
    tr.PaymentType,
    tr.Amount                                       AS AmountPaid,
    tr.OrderStatus                                  AS TransactionStatus,
    tr.CreatedDate                                  AS PaymentDate,
    tr.MfiType,
    tr.TillId,
    tr.SenderContactNo,
    tr.DeliveryQRCode,
    dm.FirstName + ' ' + dm.LastName                AS DeliverymanName,
    'Paid'                                          AS ModifiedorActualStatus,
    0                                               AS JazzTRID,
    o.ShopOrderKey
FROM [vizlink-live].[dbo].ShopOrderTransactions tr
INNER JOIN VDWH_Auto.dbo.Fact_ShopOrders o      ON o.ShopOrderId  = tr.ShopOrderId
INNER JOIN VDWH_Auto.dbo.Dim_DMs dm             ON dm.QRCode      = tr.DeliveryQRCode
WHERE tr.OrderStatus = 'Paid'
  AND tr.Id NOT IN (SELECT ShopTransactionId FROM VDWH_Auto.dbo.Fact_ShopOrderTransactions);

-- ------------------------------------------------------------
-- Fact_LenderFinancing
-- Grain: one row per BNPL loan disbursed
-- LoanStatus decoded from integer to string at load time
-- ------------------------------------------------------------
SELECT
    lf.Id                   AS FinancingId,
    lf.PrincipalAmount,
    lf.CreatedDate          AS LoanDate,
    lf.Lender_LoanId,
    lf.LoanDisplayId,
    CASE
        WHEN lf.LoanStatus = 0 THEN 'Internal Approved'
        WHEN lf.LoanStatus = 1 THEN 'Under Review'
        WHEN lf.LoanStatus = 2 THEN 'Need More Info'
        WHEN lf.LoanStatus = 3 THEN 'Rejected'
        WHEN lf.LoanStatus = 4 THEN 'Cancelled'
        WHEN lf.LoanStatus = 5 THEN 'Approved'
        WHEN lf.LoanStatus = 6 THEN 'Disbursed'
        WHEN lf.LoanStatus = 7 THEN 'Completed'
        WHEN lf.LoanStatus = 8 THEN 'Error'
    END                     AS LoanStatus,
    lf.LoanRepaymentStatus,
    lf.LoanDueAmount,
    lf.LoanDueDate,
    l.LenderKey,
    tr.ShopTransactionKey,
    u.UserKey,
    lp.LoanPlanKey,
    v.VizShopKey
FROM [vizlink-live].[dbo].LenderFinancing lf
INNER JOIN VDWH_Auto.dbo.Dim_Lender l                    ON l.LenderId          = lf.LenderId
INNER JOIN VDWH_Auto.dbo.Fact_ShopOrderTransactions tr   ON tr.ShopTransactionId = lf.ShopOrderTransactionId
INNER JOIN VDWH_Auto.dbo.Dim_Users u                     ON u.UserId             = lf.CreatedBy
INNER JOIN VDWH_Auto.dbo.Dim_LoanPlans lp                ON lp.LoanPlanId        = lf.LenderLoandPlanId
INNER JOIN VDWH_Auto.dbo.Dim_Vizshops v                  ON v.VizShopId          = lf.VizShopId
WHERE lf.Id NOT IN (SELECT FinancingId FROM VDWH_Auto.dbo.Fact_LenderFinancing);

-- ------------------------------------------------------------
-- Fact_LenderRepayment
-- Grain: one row per repayment installment
-- PaymentTransationStatus decoded from integer at load time
-- ------------------------------------------------------------
SELECT
    lfr.Id              AS RepaymentId,
    lfr.Amount          AS RepaymentAmount,
    lfr.CreatedDate     AS RepaymentDate,
    CASE
        WHEN lfr.PaymentTransationStatus = 1 THEN 'Pending'
        WHEN lfr.PaymentTransationStatus = 2 THEN 'Success'
        WHEN lfr.PaymentTransationStatus = 3 THEN 'Failed'
        ELSE NULL
    END                 AS PaymentTransationStatus,
    lfr.MFIType,
    lfr.MFITransactionId,
    lfr.SenderContactNo,
    lf.FinancingKey     AS LenderFinancingKey
FROM [vizlink-live].[dbo].LenderFinancingRepayment lfr
INNER JOIN VDWH_Auto.dbo.Fact_LenderFinancing lf ON lf.FinancingId = lfr.LenderFinancingId
WHERE lfr.Id NOT IN (SELECT RepaymentId FROM VDWH_Auto.dbo.Fact_LenderRepayment);

-- ------------------------------------------------------------
-- Fact_LenderKYC
-- Grain: one row per KYC submission
-- KycStatus decoded from integer at load time
-- JSON fields extracted from OLTP JSON columns
-- ------------------------------------------------------------
SELECT
    kyc.Id              AS KycId,
    v.VizShopKey,
    l.LenderKey,
    kyc.KycCNIC,
    kyc.KycCellNo,
    kyc.CreatedDate,
    kyc.ModifiedDate    AS ModifieddDate,
    CASE
        WHEN kyc.KycStatus = 5 THEN 'Pending'
        WHEN kyc.KycStatus = 6 THEN 'Approved'
        WHEN kyc.KycStatus = 7 THEN 'Rejected'
        WHEN kyc.KycStatus = 8 THEN 'Need More Info'
        ELSE 'Not Known'
    END                 AS KycStatus,
    kyc.ContractStatus,
    JSON_VALUE(kyc.JsonProcessResponse, '$.reason')     AS Reason,
    JSON_VALUE(kyc.JsonObject, '$.businessName')        AS KycBusinessName,
    kyc.CreditLimit,
    kyc.CreatedBy       AS ExternalIdKey
FROM [vizlink-live].[dbo].LenderKYC kyc
INNER JOIN VDWH_Auto.dbo.Dim_Vizshops v ON v.VizShopId  = kyc.VizShopId
INNER JOIN VDWH_Auto.dbo.Dim_Lender l   ON l.LenderId   = kyc.LenderId
WHERE kyc.Id NOT IN (SELECT KycId FROM VDWH_Auto.dbo.Fact_LenderKYC);

-- ------------------------------------------------------------
-- Fact_VLPLedger
-- Grain: one row per loyalty point credit or debit
-- VizShopKey loaded as 0 where shop-level linkage unavailable
-- Batched with TOP to manage large volume loads
-- ------------------------------------------------------------
SELECT DISTINCT TOP (100000)
    l.Id                AS LedgerId,
    l.LedgerType,
    l.VLPAmount,
    l.VlpOpenAmount,
    l.VlpCloseAmount,
    l.CreatedDate       AS LedgerDate,
    e.VLPEventKey,
    s.VLPSchemeKey,
    u.UserKey,
    tr.ShopTransactionKey,
    0                   AS VizShopKey   -- shop-level linkage via future enhancement
FROM [vizlink-live].[dbo].VLPLedger l
INNER JOIN VDWH_Auto.dbo.Dim_Users u                    ON u.UserId             = l.UserId
LEFT JOIN VDWH_Auto.dbo.Dim_VLPEvents e                 ON e.EventId            = l.VlpEventId
LEFT JOIN VDWH_Auto.dbo.Dim_VLPScheme s                 ON s.SchemeId           = l.VLPSchemeId
LEFT JOIN VDWH_Auto.dbo.Fact_ShopOrderTransactions tr   ON tr.ShopTransactionId = l.ShopOrderTransactionId
WHERE l.Id NOT IN (SELECT LedgerId FROM VDWH_Auto.dbo.Fact_VLPLedger);

-- ------------------------------------------------------------
-- Fact_VLCTickets
-- Grain: one row per shopkeeper support ticket
-- TicketStatus decoded from integer at load time
-- Only tickets with a CategoryCode are loaded
-- ------------------------------------------------------------
SELECT DISTINCT
    t.Id                    AS TicketId,
    t.CreatedDate,
    v.VizShopKey,
    dc.DistCenterKey,
    h.TicketCategoryCode    AS CategoryCode,
    0.00                    AS OrderAmount,
    t.TicketText,
    t.TicketCode,
    CASE
        WHEN t.Status = 1 THEN 'Incomplete'
        WHEN t.Status = 2 THEN 'Allocated'
        WHEN t.Status = 3 THEN 'InProgress'
        WHEN t.Status = 4 THEN 'Resolved'
    END                     AS TicketStatus
FROM [vizlink-live].[dbo].VLCShopKeeperTicket t
INNER JOIN VDWH_Auto.dbo.Dim_Vizshops v                             ON v.VizShopId    = t.VizShopId
INNER JOIN VDWH_Auto.dbo.Dim_DistCenter dc                          ON dc.DistCenterId = t.DistCenterId
INNER JOIN [vizlink-live].[dbo].VLCShopKeeperTicketHandler h        ON h.VLCShopKeeperTicketId = t.Id
WHERE h.TicketCategoryCode IS NOT NULL
  AND t.Id NOT IN (SELECT TicketId FROM VDWH_Auto.dbo.Fact_VLCTickets);
