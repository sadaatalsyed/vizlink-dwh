
# Data Model

Schema type: **Galaxy Schema (Fact Constellation)**

Multiple fact tables share conformed dimensions. This pattern was chosen because Vizlink covers several distinct business domains — collections, BNPL financing, loyalty points, and support tickets — each requiring its own fact table while sharing the same shops, users, and distribution center dimensions.


![Schema](/02_data_modeling/vizlink_schema_diagram.png)


## Dimension Tables

### `Dim_date`
Standard date dimension. Every date-based analysis (daily/weekly/monthly trends) joins to this table via `DateKey (YYYYMMDD)`.

| Column | Description |
|---|---|
| `DateKey` | Surrogate key — format YYYYMMDD |
| `FullDate` | Actual date |
| `Year / Quarter / Month / Day` | Calendar breakdowns |
| `DayName / MonthName` | Human-readable labels |
| `IsWeekend` | Weekend flag for filtering |
| `IsStartOfMonth / IsEndOfMonth` | Period boundary flags |

---

### `Dim_Vizshops`
Master record for every retailer (shopkeeper) enrolled on the Vizlink platform.

| Column | Description |
|---|---|
| `VizShopKey` | Surrogate key |
| `VizShopId` | Business key from OLTP |
| `VizShopCode` | Human-readable shop code |
| `CNIC` | Shopkeeper national ID |
| `ShopCategory` | Type of retail outlet |
| `Locality / Area` | Geographic hierarchy |
| `RsoName` | RSO who inducted this shop |
| `InductionDate` | When shop joined the platform |
| `SignUp` | Whether shopkeeper has a user account (`Yes/No`) |

---

### `Dim_DistCenter`
Distribution centers — the link between principals (FMCG companies) and distributors.

| Column | Description |
|---|---|
| `DistCenterKey` | Surrogate key |
| `DistCenterId` | Business key |
| `DistCenterName` | Name of the dist. center |
| `DistributorName` | Parent distributor |
| `DistributorCity` | City of operation |
| `PrincipalName` | FMCG principal (e.g. Unilever, P&G) |

---

### `Dim_DistributorShop`
Maps a distributor's customer list to Vizlink shops. This is the bridge between the distributor ERP world and the Vizlink platform.

| Column | Description |
|---|---|
| `DistributorShopKey` | Surrogate key |
| `DistCenterKey` | FK → Dim_DistCenter |
| `VizShopKey` | FK → Dim_Vizshops (nullable — not all distributor shops are on Vizlink) |
| `ShopCode` | Distributor's internal shop code |
| `RsoName` | Responsible RSO |

---

### `Dim_Users`
All platform users — RSOs, admins, managers.

| Column | Description |
|---|---|
| `UserKey` | Surrogate key |
| `UserId` | Business key (ASP.NET Identity) |
| `FirstName / LastName / Username` | Identity fields |
| `CNIC` | National ID |
| `SignupDate / SignUpDateKey` | When user joined |
| `LastLoginDate` | Activity tracking |

---

### `Dim_DMs`
Delivery men — the field agents who collect payments.

| Column | Description |
|---|---|
| `DMKey` | Surrogate key |
| `DMId` | Business key |
| `QRCode` | Unique QR used for transaction identification |
| `DistCenterName` | Which dist. center they belong to |

---

### `Dim_Lender`
Financial institutions providing BNPL credit to shopkeepers.

| Column | Description |
|---|---|
| `LenderKey` | Surrogate key |
| `LenderId` | Business key |
| `LenderName` | Name of lending institution |

---

### `Dim_LoanPlans`
Loan product catalog per lender. Snowflake element — links to `Dim_Lender`.

| Column | Description |
|---|---|
| `LoanPlanKey` | Surrogate key |
| `PlanName` | Product name |
| `PlanDuration` | Loan term in days |
| `LenderKey` | FK → Dim_Lender |

---

### `Dim_VLPEvents` + `Dim_VLPScheme`
Loyalty program structure. Events are top-level campaigns; schemes are sub-programs within an event. Snowflake element — scheme links to event.

---

### `Dim_VLCTicketCategory`
Lookup table for support ticket categories.

---

## Fact Tables

### `Fact_ShopOrders`
One row per order placed by a shopkeeper through the Vizlink platform.

**Grain:** One order

**Foreign Keys:** `DistributorShopKey`, `DistCenterKey`, `VizShopKey`

**Key Measures:**
- `NetSales` — invoice amount
- `OriginalNetSales` — amount uploaded by distributor
- `OrderAmountToPay / AmountPaid` — payment tracking
- `OrderStatus` — current order state

---

### `Fact_ShopOrderTransactions`
One row per digital payment transaction (MFI payment against an order).

**Grain:** One payment transaction

**Foreign Keys:** `ShopOrderKey` → Fact_ShopOrders

**Key Measures:**
- `AmountPaid`
- `TransactionStatus / ModifiedorActualStatus` — pre and post reconciliation status
- `MfiType` — which mobile financial service (Jazz, Easypaisa, etc.)
- `PaymentType` — payment channel

---

### `Fact_LenderFinancing`
One row per BNPL loan disbursed to a shopkeeper.

**Grain:** One loan

**Foreign Keys:** `LenderKey`, `LoanPlanKey`, `ShopTransactionKey`, `UserKey`, `VizShopKey`

**Key Measures:**
- `PrincipalAmount`
- `LoanStatus` — decoded (Under Review → Disbursed → Completed)
- `LoanDueAmount / LoanDueDate`
- `LoanRepaymentStatus`

---

### `Fact_LenderRepayment`
One row per loan repayment installment.

**Grain:** One repayment

**Foreign Keys:** `LenderFinancingKey` → Fact_LenderFinancing

**Key Measures:**
- `RepaymentAmount`
- `PaymentTransationStatus` — Pending / Success / Failed
- `MFIType / MFITransactionId`

---

### `Fact_VLPLedger`
Loyalty points ledger — one row per credit or debit event.

**Grain:** One ledger entry

**Foreign Keys:** `VLPEventKey`, `VLPSchemeKey`, `UserKey`, `ShopTransactionKey`, `VizShopKey`

**Key Measures:**
- `VLPAmount` — points in this transaction
- `VlpOpenAmount / VlpCloseAmount` — running balance

---

### `Fact_VLCTickets`
Support tickets raised by shopkeepers.

**Grain:** One ticket

**Foreign Keys:** `VizShopKey`, `DistCenterKey`, `CategoryCode`

**Key Measures:**
- `TicketStatus` — Incomplete / Allocated / InProgress / Resolved
- `OrderAmount` — order value related to the complaint
- `TicketText / FinalResponse` — free-text fields

---

## Relationships Summary

```
Dim_DistCenter ←── Fact_ShopOrders ──→ Dim_Vizshops
                          │
                          ↓
               Fact_ShopOrderTransactions
                          │
                          ↓
               Fact_LenderFinancing ──→ Dim_Lender
                          │              Dim_LoanPlans
                          ↓              Dim_Users
               Fact_LenderRepayment

Dim_VLPEvents ←── Fact_VLPLedger ──→ Dim_VLPScheme
Dim_Vizshops  ←── Fact_VLCTickets ──→ Dim_DistCenter

Dim_date ──→ (shared across all fact tables via date columns)
```
