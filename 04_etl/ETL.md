# ETL Pipeline

## Overview

Data is extracted from the live OLTP database (`vizlink-live`) and loaded into the data warehouse (`VDWH_Auto`) using SSIS (SQL Server Integration Services) pipelines. Each pipeline runs on a scheduled basis and follows an incremental load pattern.

---

## Tool: SSIS (SQL Server Integration Services)

SSIS packages handle the orchestration — each dimension and fact table has a dedicated data flow task. The SELECT queries in [`dim_loads.sql`](dim_loads.sql) and [`fact_loads.sql`](fact_loads.sql) are the source queries used inside these SSIS data flows.

---

## Load Pattern: Incremental Insert

No full truncate-and-reload. Every load query checks for new records only:

```sql
WHERE source.Id NOT IN (
    SELECT BusinessKey FROM VDWH_Auto.dbo.Dim_TableName
)
```

This means:
- Production OLTP database is never burdened by a full read
- Historical DWH data is never wiped
- Load times stay fast even as volume grows

---

## Load Order

Dimension tables must be loaded before fact tables. Fact tables reference surrogate keys from dimensions — if a dimension isn't loaded yet, the key resolution returns NULL.

```
Step 1 — Dimensions (order within this step matters for snowflake dims)

  Dim_date                ← no dependencies
  Dim_DistCenter          ← no dependencies
  Dim_Users               ← no dependencies
  Dim_DMs                 ← depends on DistCenters (source join)
  Dim_Vizshops            ← depends on Users (RSO join)
  Dim_DistributorShop     ← depends on Dim_DistCenter, Dim_Vizshops, Dim_Users
  Dim_Lender              ← no dependencies
  Dim_LoanPlans           ← depends on Dim_Lender
  Dim_VLPEvents           ← no dependencies
  Dim_VLPScheme           ← depends on Dim_VLPEvents
  Dim_VLCTicketCategory   ← no dependencies

Step 2 — Facts (strict order — chain dependency)

  Fact_ShopOrders              ← needs Dim_DistCenter, Dim_Vizshops, Dim_DistributorShop
  Fact_ShopOrderTransactions   ← needs Fact_ShopOrders, Dim_DMs
  Fact_LenderFinancing         ← needs Fact_ShopOrderTransactions, Dim_Lender, Dim_LoanPlans, Dim_Users, Dim_Vizshops
  Fact_LenderRepayment         ← needs Fact_LenderFinancing
  Fact_VLPLedger               ← needs Dim_Users, Dim_VLPEvents, Dim_VLPScheme, Fact_ShopOrderTransactions
  Fact_VLCTickets              ← needs Dim_Vizshops, Dim_DistCenter, Dim_VLCTicketCategory
  Fact_LenderKYC               ← needs Dim_Vizshops, Dim_Lender
```

---

## Key Transformations

### Surrogate Key Resolution
Source OLTP uses `uniqueidentifier` (GUID) business keys. During ETL, these are resolved to integer surrogate keys from the DWH dimension tables:

```sql
-- Example: resolving VizShopKey from GUID
LEFT JOIN VDWH_Auto.dbo.Dim_Vizshops V ON V.VizShopId = O.VizShopId
-- → V.VizShopKey (int) is inserted into the fact table, not the GUID
```

### Status Code Decoding
OLTP stores statuses as integers. ETL decodes them to readable strings:

```sql
CASE
    WHEN LF.LoanStatus = 5 THEN 'Approved'
    WHEN LF.LoanStatus = 6 THEN 'Disbursed'
    WHEN LF.LoanStatus = 7 THEN 'Completed'
    ...
END AS LoanStatus
```

Full mapping: [05_business_logic/status_mappings.md](../05_business_logic/status_mappings.md)

### JSON Field Extraction
Lender KYC responses are stored as JSON strings in OLTP. ETL extracts specific fields:

```sql
JSON_VALUE(JsonProcessResponse, '$.reason')    AS Reason
JSON_VALUE(JsonObject, '$.businessName')       AS KYCBusinessName
```

### Test Data Filtering
Test distributor records are excluded at source to keep DWH clean:

```sql
WHERE d.DistributorName NOT LIKE '%Tech%'
  AND d.DistributorName NOT LIKE '%Vizpro Test Distributor%'
```

### SignUp Flag Derivation
Whether a shopkeeper has a Vizlink user account is derived via a subquery join — not stored directly in OLTP:

```sql
CASE
    WHEN temp.VizShopCode IS NULL THEN 'No'
    WHEN temp.VizShopCode IS NOT NULL THEN 'Yes'
END AS SignUp
```

---

## Files

| File | Contents |
|---|---|
| `dim_loads.sql` | SELECT queries for all dimension tables |
| `fact_loads.sql` | SELECT queries for all fact tables |

Each query is the source query used inside the corresponding SSIS data flow task.
