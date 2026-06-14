# Business Logic — Status Mappings

The OLTP source stores status values as integer codes. These are decoded to human-readable strings during ETL load. This document is the single source of truth for all status mappings in the warehouse.

---

## Loan Status — `Fact_LenderFinancing.LoanStatus`

| Code | Decoded Value | Description |
|---|---|---|
| `0` | Internal Approved | Approved internally, not yet sent to lender |
| `1` | Under Review | Lender is reviewing the application |
| `2` | Need More Info | Lender has requested additional documents |
| `3` | Rejected | Application rejected by lender |
| `4` | Cancelled | Cancelled by the platform or shopkeeper |
| `5` | Approved | Lender approved the loan |
| `6` | Disbursed | Funds sent to shopkeeper |
| `7` | Completed | Loan fully repaid |
| `8` | Error | System error during processing |

---

## KYC Status — `Fact_LenderKYC.KycStatus`

| Code | Decoded Value | Description |
|---|---|---|
| `5` | Pending | KYC submitted, awaiting review |
| `6` | Approved | KYC passed — shopkeeper eligible for financing |
| `7` | Rejected | KYC failed |
| `8` | Need More Info | Additional documents required |
| other | Not Known | Unrecognized status code |

---

## Loan Repayment Status — `Fact_LenderRepayment.PaymentTransationStatus`

| Code | Decoded Value | Description |
|---|---|---|
| `1` | Pending | Payment initiated, not confirmed |
| `2` | Success | Payment confirmed by MFI |
| `3` | Failed | Payment failed |
| `NULL` | — | Status unavailable |

---

## Support Ticket Status — `Fact_VLCTickets.TicketStatus`

| Code | Decoded Value | Description |
|---|---|---|
| `1` | Incomplete | Ticket raised but not yet assigned |
| `2` | Allocated | Assigned to an agent |
| `3` | InProgress | Agent is actively working on it |
| `4` | Resolved | Issue resolved |

---

## SignUp Flag — `Dim_Vizshops.SignUp`

Derived field — not a direct OLTP column.

| Value | Meaning |
|---|---|
| `Yes` | Shopkeeper has a registered Vizlink user account |
| `No` | Shop is enrolled but shopkeeper has no account |

**Derivation logic:**
```sql
CASE
    WHEN temp.VizShopCode IS NULL     THEN 'No'
    WHEN temp.VizShopCode IS NOT NULL THEN 'Yes'
END AS SignUp
```

Where `temp` is a subquery joining `VizShops` to `AspNetUsers` on CNIC — i.e. whether the shop's CNIC has a corresponding user account.

---

## Notes

- All decoding happens at ETL load time in SSIS, not at query/report time
- Power BI reports use the decoded string values directly — no SWITCH/IF logic needed in DAX for status fields
- If new status codes are added in OLTP, the SSIS source query must be updated and the DWH re-loaded for affected rows
