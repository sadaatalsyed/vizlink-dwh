# Reporting Layer — Power BI Dashboard

## Overview

The Vizpro Dashboard is a 4-page Power BI report built on top of the `VDWH_Auto` data warehouse. It covers the full business lifecycle — shop induction, digital collections, BNPL financing, and support tickets.

Screenshots: [`screenshots/`](/06_reporting/ScreenShots/)

---

## Dashboard Pages

### Page 1 — Distribution & Shop Induction Performance

**Purpose:** Track how many shops have been inducted onto the Vizlink platform and how many have signed up digitally, broken down by distributor.

**Key KPI Cards:**

| Measure | Value (as of Jun 2025) |
|---|---|
| Inducted ShopCodes | 24,700 |
| Inducted VIZIDs | 22,486 |
| Unique Viz Signups | 13,556 |
| Signup % | 60% |
| Distributors | 8 |
| DistCenters | 18 |
| Principals | 9 |

**Visuals:**
- Distribution & Category Wise Performance table — per-distributor breakdown of inducted vs signed-up shops
- Inducted VizShops Trend — monthly bar chart (Jan 2023 – Jun 2025)
- Inducted VizShops Comparison — year-over-year monthly comparison (2023 vs 2024 vs 2025)
- Cumulative Inducted VIZIDs by Year and Month — running total line chart

**Filters:** Date range, DistCenter, Distributor, Principal, Year, Month

---

### Page 2 — Collections Performance (M2D)

**Purpose:** Track digital collection amounts (Money to Distributor) and active shop counts over time, by shop category.

**Key KPI Cards:**

| Measure | Value |
|---|---|
| Digital Amount | 4.23 Billion |
| Active Shops | 11K |
| Active Distributors | 7 |
| Total Transactions | 192K |

**Visuals:**
- M2D (VL) and ActiveShops Trend — combo chart (bar = M2D amount, line = active shops) Jan 2024–Jun 2025
- Active Shops and M2D Comparison — side-by-side 2024 vs 2025 bar chart (Jan–Jun)
- Cumulative Active Shops and M2D — running total showing growth to 4.17bn
- ShopCategory Wise Performance table — 12 categories showing ActiveShops, DigitalAmount, % of Total

**Top Shop Categories by Digital Amount:**

| Category | Digital Amount | Share |
|---|---|---|
| Wholesale | 1,090.90M | 29.51% |
| General Store | 1,084.95M | 29.35% |
| Mart | 438.30M | 11.86% |
| Pharmacy | 395.58M | 10.70% |
| Pan Shop | 245.36M | 6.64% |

**Filters:** Distributor, DistCenters, Date, Year, Month

---

### Page 3 — BNPL Financing & KYC

**Purpose:** Track loan disbursements, KYC approval pipeline, and repayment health across lenders and distribution centers.

**Key KPI Cards:**

| Measure | Value |
|---|---|
| Total Loan Amount | 104M |
| Drawdown Shops | 891 |
| Total Drawdowns | 6,680 |
| Recovered Loan % | 88.16% |
| Overdue Loans | 326 |
| KYC Approved Shops | 1,330 |
| KYC Approval % | 68.42% |

**Visuals:**
- Loan Amount and Drawdown Shops Trend — Oct 2024–Jul 2025 (peak: March 2025, 548 shops, 21.9M)
- Cumulative Measures — running Cum_LoanAmount and Cum_DrawDownShops
- KYC Submitted MonthWise — stacked bar showing submitted vs approved + approval rate line
- Lender Performance table — KYC shops, active shops, loan amount per lender/dist center
- KYC Shops by KYC-Status — pie chart (Approved 68.42%, Rejected 18.67%, Need More Info 9.72%, Pending 3.19%)

**Lender Breakdown:**

| Lender | KYC Shops | Active Shops | Loan Amount |
|---|---|---|---|
| CreditBook (total) | 1,330 | 891 | 103.91M |
| Katarband Nestle | 357 | 226 | 31.95M |
| Unilever Harbanspura | 331 | 251 | 24.02M |
| Nestle Kamaha | 418 | 220 | 23.28M |
| Unilever Kamaha | 347 | 213 | 22.35M |

**Filters:** Distributors, DistCenter, Month, Year, Date

---

### Page 4 — Support Tickets (VLC)

**Purpose:** Track shopkeeper support ticket volume, order amounts linked to complaints, and query type distribution.

**Key KPI Cards:**

| Measure | Value |
|---|---|
| VLC Order Amount | 15.76M |
| Active Shops | 2,774 |

**Visuals:**
- ActiveShops and OrderAmount by ShopCategory — hierarchical table (Pharmacy top at 53.07% order amount share)
- ActiveShops by QueryType — pie chart (Information 45.70%, Order 23.15%, Complain 20.83%, Other 10.31%)
- OrderAmount and ActiveShops Trend — May 2024–Jun 2025 (peak: Oct 2024, 293 shops, 3.2M)
- Cumulative Measures — running order amount and shop count

**Top Categories by Order Amount:**

| Category | Active Shops | Order Amount | Share |
|---|---|---|---|
| Pharmacy | 627 | 8.363M | 53.07% |
| General Store | 1,245 | 3.052M | 19.37% |
| Wholesale | 34 | 0.924M | 5.86% |

**Filters:** Distributor, Month, Year

---

## DAX Measures

### Induction & Signup

```dax
-- Total inducted shop IDs on the platform
Inducted_VIZIDs = DISTINCTCOUNT(Dim_Vizshops[VizShopId])

-- Shops that have signed up (have a user account)
Uniqu_Viz_Signup = 
CALCULATE(
    DISTINCTCOUNT(Dim_Vizshops[VizShopId]),
    Dim_Vizshops[SignUp] = "Yes"
)

-- Signup percentage
Signup_VizShops% = 
DIVIDE(
    [Uniqu_Viz_Signup],
    [Inducted_VIZIDs],
    0
)

-- Total distributor shop codes inducted
Inducted_ShopCodes = DISTINCTCOUNT(Dim_DistributorShop[ShopCode])
```

---

### Collections (M2D)

```dax
-- Total digital collection amount
DigitalAmount = SUM(Fact_ShopOrderTransactions[AmountPaid])

-- Active shops (shops with at least one paid transaction)
ActiveShops = 
CALCULATE(
    DISTINCTCOUNT(Fact_ShopOrderTransactions[ShopOrderKey]),
    Fact_ShopOrderTransactions[ModifiedorActualStatus] = "Paid"
)

-- Total transaction count
TotalTransactions = COUNTROWS(Fact_ShopOrderTransactions)

-- Cumulative digital amount (running total)
Cumulative_M2D = 
CALCULATE(
    [DigitalAmount],
    FILTER(
        ALL(Dim_date[FullDate]),
        Dim_date[FullDate] <= MAX(Dim_date[FullDate])
    )
)

-- Cumulative active shops (running total)
Commulative_ActiveShops = 
CALCULATE(
    [ActiveShops],
    FILTER(
        ALL(Dim_date[FullDate]),
        Dim_date[FullDate] <= MAX(Dim_date[FullDate])
    )
)

-- % of total digital amount by shop category
%_of_Total_Digital = 
DIVIDE(
    [DigitalAmount],
    CALCULATE([DigitalAmount], ALL(Dim_Vizshops[ShopCategory])),
    0
)
```

---

### BNPL Financing

```dax
-- Total loan amount disbursed
TotalLoanAmount = SUM(Fact_LenderFinancing[PrincipalAmount])

-- Count of unique shops that took a drawdown
DrawdownShops = 
CALCULATE(
    DISTINCTCOUNT(Fact_LenderFinancing[VizShopKey]),
    Fact_LenderFinancing[LoanStatus] = "Disbursed"
)

-- Total number of loan drawdowns
Drawdowns = 
CALCULATE(
    COUNTROWS(Fact_LenderFinancing),
    Fact_LenderFinancing[LoanStatus] = "Disbursed"
)

-- Recovered loan percentage
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
    Fact_LenderFinancing[LoanRepaymentStatus] <> "Paid",
    Fact_LenderFinancing[LoanDueDate] < TODAY()
)

-- Cumulative loan amount
Cum_LoanAmount = 
CALCULATE(
    [TotalLoanAmount],
    FILTER(
        ALL(Dim_date[FullDate]),
        Dim_date[FullDate] <= MAX(Dim_date[FullDate])
    )
)

-- Cumulative drawdown shops
Cum_DrawDownShops = 
CALCULATE(
    [DrawdownShops],
    FILTER(
        ALL(Dim_date[FullDate]),
        Dim_date[FullDate] <= MAX(Dim_date[FullDate])
    )
)
```

---

### KYC

```dax
-- Shops that submitted KYC
KYC_Submitted = COUNTROWS(Fact_LenderKYC)

-- Shops approved for financing
KYC_Approved_Shops = 
CALCULATE(
    DISTINCTCOUNT(Fact_LenderKYC[VizshopKey]),
    Fact_LenderKYC[KycStatus] = "Approved"
)

-- KYC approval rate
KYCApproval% = 
DIVIDE(
    [KYC_Approved_Shops],
    [KYC_Submitted],
    0
) * 100
```

---

### Support Tickets (VLC)

```dax
-- Total order amount from support tickets
VLC_OrderAmount = SUM(Fact_VLCTickets[OrderAmount])

-- Active shops with tickets
VLC_ActiveShops = DISTINCTCOUNT(Fact_VLCTickets[VizshopKey])

-- % share of order amount by category
%GT_OrderAmount = 
DIVIDE(
    [VLC_OrderAmount],
    CALCULATE([VLC_OrderAmount], ALL(Dim_VLCTicketCategory[CategoryName])),
    0
)
```

---

## Notes

- All date filtering uses `Dim_date` — slicer connects via `DateKey`
- `M2D` = Money to Distributor — the core digital collection metric
- Cumulative measures use `FILTER(ALL(...))` pattern for running totals across any filter context
- Screenshots for each dashboard page are in the [`screenshots/`](screenshots/) folder — add them as `page1_induction.png`, `page2_collections.png`, `page3_financing.png`, `page4_tickets.png`
