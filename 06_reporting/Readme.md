# Reporting Layer — Power BI Dashboard

## Overview

The Vizpro Dashboard is a 4-page Power BI report built on `VDWH_Auto`.
It covers the full business lifecycle — shop induction, digital collections,
BNPL financing, and support tickets (VL Connect).

Screenshots: [`screenshots/`](/06_reporting/ScreenShots)

---

## Pages

| # | Page Name | Business Domain |
|---|---|---|
| 1 | Induction | Shop enrollment & signup tracking |
| 2 | M2D | Digital collections performance |
| 3 | Financing | BNPL loans, KYC pipeline |
| 4 | VL Connect | Shopkeeper support tickets |

---

## Page 1 — Induction

![INDUCTION](/06_reporting/ScreenShots/induction.png)

**Purpose:** Track shop induction and digital signup rates across distributors, dist. centers, and principals.
**Visuals:**

| Visual Type | Title |
|---|---|
| Table | Distribution and Category Wise Performance |
| Line Chart | Inducted VizShops Trend |
| Combo Chart | Inducted VizShops Comparison (YoY) |
| Line Chart | Cumulative Inducted-VIZIDs by Year and Month |
| Cards (7) | Inducted_ShopCodes, Inducted_VIZIDs, Uniqu_Viz_Signup, SignUp%, Distributors, DistCenters, Principals |

**Slicers:** Date, DistCenter, Distributor, Principal, Year, Month

**KPIs (as of Jun 2025):**

| Measure | Value |
|---|---|
| Inducted_ShopCodes | 24,700 |
| Inducted_VIZIDs | 22,486 |
| Uniqu_Viz_Signup | 13,556 |
| SignUp%VIZ | 60% |
| Distributors | 8 |
| DistCenters | 18 |
| Principals | 9 |
---

## Page 2 — M2D (Money to Distributor)


![M2d](/06_reporting/ScreenShots/M2D.png)

**Purpose:** Track digital collection amounts and active shop counts over time, by shop category and payment type.

**Visuals:**

| Visual Type | Title |
|---|---|
| Combo Chart | M2D (VL) and ActiveShops Trend |
| Combo Chart | Active Shops and M2D Comparison (2024 vs 2025) |
| Combo Chart | Commulative Active Shops and M2D |
| Combo Chart | M2D and ActiveShops by Distribution Center |
| Pie Chart | M2D by PaymentType |
| Pie Chart | No. of Transactions by PaymentType |
| Table | ShopCategory Wise Performance |
| Cards (4) | ActiveDistributors, DigitalAmount, ActiveShops, TotalTransactions |

**Slicers:** Distributor, DistCenters, Date, Year, Month

**KPIs:**

| Measure | Value |
|---|---|
| DigitalAmount | 4.23 Billion |
| ActiveShops | 11K |
| Active Distributors | 7 |
| TotalTransactions | 192K |

---

## Page 3 — Financing


![Financing](/06_reporting/ScreenShots/financing.png)

**Purpose:** Track BNPL loan disbursements, KYC approval pipeline, and repayment health.

**Visuals:**

| Visual Type | Title |
|---|---|
| Combo Chart | LoanAmount and Drawdown Shops Trend |
| Combo Chart | Cum Measures (Cum_LoanAmount + Cum_DrawDownShops) |
| Combo Chart | KYC Submitted MonthWise |
| Table | Finance Details by Distcenter |
| Pie Chart | KYC Shops by KYC-Status |
| Cards (7) | TotalLoanAmount, DrawddownShops, CountLoanID, RecoveredLoan%, OverdueLoans, KYC_Approved_Shops, KYCApproval% |

**Slicers:** Date, Year, Month, DistCenter, Distributors

**KPIs:**

| Measure | Value |
|---|---|
| TotalLoanAmount | 104M |
| DrawddownShops | 891 |
| CountLoanID (Drawdowns) | 6,680 |
| RecoveredLoan% | 88.16% |
| OverdueLoans | 326 |
| KYC_Approved_Shops | 1,330 |
| KYCApproval% | 68.42% |

---

## Page 4 — VL Connect

![VLC_support_Tickets](/06_reporting/ScreenShots/VLC_tickets.png)

**Purpose:** Track shopkeeper support ticket volume and order amounts by category and query type.

**Visuals:**

| Visual Type | Title |
|---|---|
| Combo Chart | OrderAmount and ActiveShops Trend |
| Combo Chart | Commulative Measures |
| Table | ActiveShops and OrderAmount by ShopCategory |
| Pie Chart | ActiveShops by QueryType |
| Cards (2) | VLC_OrderAmount, Active Shops |

**Slicers:** Distributor, Month, Year

**KPIs:**

| Measure | Value |
|---|---|
| Cum_VLC_OrderAmount | 15.76M |
| Cum_VLC_VIZID (Active Shops) | 2,774 |

---

## DAX Measures — Complete List

These are the actual measure names extracted from the `.pbix` file.

### Induction Measures
```dax
-- Unique dist. center shop codes inducted
Inducted_ShopCodes = DISTINCTCOUNT(Dim_DistributorShop[ShopCode])

-- Unique vizlink shop IDs
Inducted_VIZIDs = DISTINCTCOUNT(Dim_Vizshops[VizShopId])

-- Shops with a registered user account
Uniqu_Viz_Signup = 
CALCULATE(
    DISTINCTCOUNT(Dim_Vizshops[VizShopId]),
    Dim_Vizshops[SignUp] = "Yes"
)

-- Signup percentage
SignUp%VIZ = DIVIDE([Uniqu_Viz_Signup], [Inducted_VIZIDs], 0)

-- Cumulative inducted VIZIDs (running total)
CumulativeInductedVIZIDs = 
CALCULATE(
    [Inducted_VIZIDs],
    FILTER(
        ALL(dim_date[FullDate]),
        dim_date[FullDate] <= MAX(dim_date[FullDate])
    )
)
```

### M2D (Collections) Measures
```dax
-- Total digital collection amount
DigitalAmount = SUM(PaymentData[PaidAmount])

-- Active shops (with at least one paid transaction)
ActiveShops = 
CALCULATE(
    DISTINCTCOUNT(PaymentData[ShopOrderKey]),
    PaymentData[ModifiedorActualStatus] = "Paid"
)

-- Active distributors
Active Distributors = DISTINCTCOUNT(PaymentData[DistributorName])

-- Total transactions count
TotalTransactions = COUNTROWS(PaymentData)

-- Total paid amount (alternate measure)
TotalPaidAmount = SUM(PaymentData[PaidAmount])

-- Cumulative M2D running total
Cum_M2d2 = 
CALCULATE(
    [DigitalAmount],
    FILTER(
        ALL(dim_date[FullDate]),
        dim_date[FullDate] <= MAX(dim_date[FullDate])
    )
)

-- Cumulative active shops running total
CumActiveShops = 
CALCULATE(
    [ActiveShops],
    FILTER(
        ALL(dim_date[FullDate]),
        dim_date[FullDate] <= MAX(dim_date[FullDate])
    )
)
```

### Financing Measures
```dax
-- Total loan amount disbursed
TotalLoanAmount = SUM(Fact_LenderFinancing[PrincipalAmount])

-- Shops that took at least one drawdown
DrawddownShops = 
CALCULATE(
    DISTINCTCOUNT(Fact_LenderFinancing[VizShopKey]),
    Fact_LenderFinancing[LoanStatus] = "Disbursed"
)

-- Total count of loan drawdowns
CountLoanID = 
CALCULATE(
    COUNTROWS(Fact_LenderFinancing),
    Fact_LenderFinancing[LoanStatus] = "Disbursed"
)

-- Loan recovery percentage
RecoveredLoan% = 
DIVIDE(
    CALCULATE(
        SUM(Fact_LenderRepayment[RepaymentAmount]),
        Fact_LenderRepayment[PaymentTransationStatus] = "Success"
    ),
    [TotalLoanAmount],
    0
) * 100

-- Overdue loans count
OverdueLoans = 
CALCULATE(
    COUNTROWS(Fact_LenderFinancing),
    Fact_LenderFinancing[LoanDueDate] < TODAY(),
    Fact_LenderFinancing[LoanRepaymentStatus] <> "Paid"
)

-- Cumulative loan amount
Cum_LoanAmount = 
CALCULATE(
    [TotalLoanAmount],
    FILTER(
        ALL(dim_date[FullDate]),
        dim_date[FullDate] <= MAX(dim_date[FullDate])
    )
)

-- Cumulative drawdown shops
Cum_DrawDownShops = 
CALCULATE(
    [DrawddownShops],
    FILTER(
        ALL(dim_date[FullDate]),
        dim_date[FullDate] <= MAX(dim_date[FullDate])
    )
)
```

### KYC Measures
```dax
-- All shops that submitted KYC
KYC_All_Shops = COUNTROWS(CreditBookKYCData)

-- Shops in KYC pipeline (distinct)
KYC_Shops = DISTINCTCOUNT(CreditBookKYCData[VizShopKey])

-- Shops with approved KYC
KYC_Approved_Shops = 
CALCULATE(
    DISTINCTCOUNT(CreditBookKYCData[VizShopKey]),
    CreditBookKYCData[KycStatus] = "Approved"
)

-- KYC approval rate
KYCApproval% = DIVIDE([KYC_Approved_Shops], [KYC_Shops], 0) * 100
```

### VL Connect Measures
```dax
-- Cumulative ticket order amount
Cum_VLC_OrderAmount = 
CALCULATE(
    SUM(fact_VLC_ext[OrderAmount]),
    FILTER(
        ALL(dim_date[FullDate]),
        dim_date[FullDate] <= MAX(dim_date[FullDate])
    )
)

-- Cumulative unique shop count
Cum_VLC_VIZID = 
CALCULATE(
    DISTINCTCOUNT(fact_VLC_ext[VizShopCode]),
    FILTER(
        ALL(dim_date[FullDate]),
        dim_date[FullDate] <= MAX(dim_date[FullDate])
    )
)
```

---

## Data Sources Used in Report

| Report Table | DWH Source |
|---|---|
| `PaymentData` | `Fact_ShopOrderTransactions` |
| `VizhopsData` | `Dim_Vizshops` |
| `LoanView` | `Fact_LenderFinancing` (view/query) |
| `CreditBookKYCData` | `Fact_LenderKYC` |
| `fact_VLC_ext` | `Fact_VLCTickets` / `fact_VLC_ext` |
| `Measures (2)` | Dedicated measures table |
| `VizshopsDistinct` | `Dim_Vizshops` (distinct query) |
| `dim_date` | `dim_date` |

---

## Notes

- All pages share `dim_date` as the central date filter
- `Measures (2)` is the dedicated measures table in the Power BI model
- Cumulative measures use `FILTER(ALL(dim_date[FullDate]), ...)` pattern
- `PaymentData` appears to be a view/named query over `Fact_ShopOrderTransactions`
- `LoanView` is a flattened view joining `Fact_LenderFinancing` with lender and dist center info
- Screenshots: save each page as `induction.png`, `m2d.png`, `financing.png`, `vlconnect.png`
