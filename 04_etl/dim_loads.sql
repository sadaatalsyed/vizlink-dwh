-- ============================================================
-- Vizlink DWH — Dimension Load Queries
-- These SELECT queries are used as source queries inside
-- SSIS Data Flow tasks for each dimension table.
-- Pattern: incremental insert — new records only
-- ============================================================

-- ------------------------------------------------------------
-- Dim_DistCenter
-- Source: DistCenters → Distributors → Principals
-- Excludes: test distributor records
-- ------------------------------------------------------------
SELECT
    dc.Id               AS DistCenterId,
    dc.DistCenterName,
    d.DistributorName,
    d.City              AS DistributorCity,
    p.PrincipalName
FROM [vizlink-live].[dbo].DistCenters dc
INNER JOIN [vizlink-live].[dbo].Distributors d  ON d.Id = dc.DistributorId
INNER JOIN [vizlink-live].[dbo].Principals p    ON p.Id = dc.PrincipalId
WHERE dc.Id NOT IN (SELECT DistCenterId FROM VDWH_Auto.dbo.Dim_DistCenter)
  AND d.DistributorName NOT LIKE '%Tech%'
  AND d.DistributorName NOT LIKE '%fjjdhrefc%'
  AND d.DistributorName NOT LIKE '%Vizpro Test Distributor%';

-- ------------------------------------------------------------
-- Dim_Users
-- Source: AspNetUsers — Role 4 = RSO (field sales officers)
-- Includes: SignUpDateKey for date dimension join
-- ------------------------------------------------------------
SELECT
    u.Id                                        AS UserId,
    u.FirstName,
    u.LastName,
    u.UserName                                  AS Username,
    u.CNIC,
    u.CreatedDate                               AS SignupDate,
    CONVERT(NVARCHAR, u.CreatedDate, 112)       AS SignupDateKey,
    u.LastLogin                                 AS LastLoginDate
FROM [vizlink-live].[dbo].AspNetUsers u
WHERE u.Id NOT IN (SELECT UserId FROM VDWH_Auto.dbo.Dim_Users)
  AND u.Id IN (
      SELECT DISTINCT ur.UserId
      FROM AspNetUsers u2
      INNER JOIN AspNetUserRoles ur ON ur.UserId = u2.Id
      WHERE ur.RoleId = 4
  );

-- ------------------------------------------------------------
-- Dim_DMs
-- Source: AspNetUsers joined to DistCenters for center name
-- Represents delivery men identified by QRCode
-- ------------------------------------------------------------
SELECT
    u.Id            AS DMId,
    u.FirstName,
    u.LastName,
    u.QRCode,
    dc.DistCenterName
FROM [vizlink-live].[dbo].AspNetUsers u
INNER JOIN [vizlink-live].[dbo].DistCenters dc ON dc.Id = u.DistCenterId
WHERE u.Id NOT IN (SELECT DMId FROM VDWH_Auto.dbo.Dim_DMs);

-- ------------------------------------------------------------
-- Dim_Vizshops
-- Source: VizShops → AspNetUsers (RSO) + signup subquery
-- SignUp: derived field — whether shopkeeper has a user account
-- ------------------------------------------------------------
SELECT
    vs.Id                                               AS VizShopId,
    vs.VizShopCode,
    vs.VizShopName                                      AS VizshopName,
    vs.CNIC,
    vs.ShopCategory,
    0                                                   AS SectorNumber,
    rso.FirstName + ' ' + rso.LastName                 AS RsoName,
    vs.CreatedDate                                      AS InductionDate,
    vs.ModifiedDate,
    vs.Locality,
    vs.Area,
    CASE
        WHEN signup.VizShopCode IS NULL     THEN 'No'
        WHEN signup.VizShopCode IS NOT NULL THEN 'Yes'
    END                                                 AS SignUp
FROM [vizlink-live].[dbo].VizShops vs
LEFT JOIN [vizlink-live].[dbo].AspNetUsers rso ON rso.Id = vs.RsoId
LEFT JOIN (
    SELECT DISTINCT v.VizShopCode
    FROM [vizlink-live].[dbo].VizShops v
    INNER JOIN [vizlink-live].[dbo].AspNetUsers u ON v.CNIC = u.CNIC
) AS signup ON vs.VizShopCode = signup.VizShopCode
WHERE vs.Id NOT IN (SELECT VizShopId FROM VDWH_Auto.dbo.Dim_Vizshops);

-- ------------------------------------------------------------
-- Dim_DistributorShop
-- Source: DistributorShops → Dim_DistCenter + Dim_Vizshops + Dim_Users
-- VizShopKey nullable — not all distributor shops are on Vizlink
-- ------------------------------------------------------------
SELECT
    ds.Id                                       AS DistributorShopId,
    dc.DistCenterKey,
    ds.ShopCode,
    ds.ShopName,
    v.VizShopKey,
    u.FirstName + ' ' + u.LastName              AS RsoName
FROM [vizlink-live].[dbo].DistributorShops ds
LEFT JOIN VDWH_Auto.dbo.Dim_Vizshops v      ON v.VizShopId   = ds.VizShopId
LEFT JOIN VDWH_Auto.dbo.Dim_DistCenter dc   ON dc.DistCenterId = ds.DistCenterId
LEFT JOIN VDWH_Auto.dbo.Dim_Users u         ON u.UserId       = ds.InductionRsoId
WHERE ds.Id NOT IN (SELECT DistributorShopId FROM VDWH_Auto.dbo.Dim_DistributorShop);

-- ------------------------------------------------------------
-- Dim_Lender
-- Source: Lender — active lenders only
-- ------------------------------------------------------------
SELECT
    Id          AS LenderId,
    LenderName
FROM [vizlink-live].[dbo].Lender
WHERE IsActive = 1
  AND Id NOT IN (SELECT LenderId FROM VDWH_Auto.dbo.Dim_Lender);

-- ------------------------------------------------------------
-- Dim_LoanPlans
-- Source: LenderLoanPlans — resolves LenderKey from Dim_Lender
-- ------------------------------------------------------------
SELECT
    lp.Id           AS LoanPlanId,
    lp.PlanName,
    lp.duration     AS PlanDuration,
    l.LenderKey
FROM [vizlink-live].[dbo].LenderLoanPlans lp
INNER JOIN VDWH_Auto.dbo.Dim_Lender l ON l.LenderId = lp.LenderId
WHERE lp.Id NOT IN (SELECT LoanPlanId FROM VDWH_Auto.dbo.Dim_LoanPlans);

-- ------------------------------------------------------------
-- Dim_VLPEvents
-- Source: VLPEvents
-- ------------------------------------------------------------
SELECT
    Id      AS EventId,
    Name    AS EventName
FROM [vizlink-live].[dbo].VLPEvents e
WHERE e.Id NOT IN (SELECT EventId FROM VDWH_Auto.dbo.Dim_VLPEvents);

-- ------------------------------------------------------------
-- Dim_VLPScheme
-- Source: VLPSchemes — resolves VLPEventKey from Dim_VLPEvents
-- ------------------------------------------------------------
SELECT
    s.Id            AS SchemeId,
    s.Name          AS SchemeName,
    e.VLPEventKey,
    s.StartDate,
    s.EndDate
FROM [vizlink-live].[dbo].VLPSchemes s
LEFT JOIN VDWH_Auto.dbo.Dim_VLPEvents e ON e.EventId = s.VLPEventId
WHERE s.Id NOT IN (SELECT SchemeId FROM VDWH_Auto.dbo.Dim_VLPScheme);

-- ------------------------------------------------------------
-- Dim_VLCTicketCategory
-- Source: VLCTicketCategory — reference/lookup table
-- ------------------------------------------------------------
INSERT INTO Dim_VLCTicketCategory (CategoryCode, CategoryName)
SELECT
    Code    AS CategoryCode,
    Name    AS CategoryName
FROM [vizlink-live].[dbo].VLCTicketCategory
WHERE Code NOT IN (SELECT CategoryCode FROM VDWH_Auto.dbo.Dim_VLCTicketCategory);
