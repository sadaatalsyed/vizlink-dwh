-- ============================================================
-- Vizlink Data Warehouse — Fact Tables DDL
-- Database: VDWH_Auto
-- Load order: Run dimensions.sql first
-- ============================================================

USE VDWH_Auto;

-- ------------------------------------------------------------
-- Fact_ShopOrders
-- Grain: one row per order placed by a shopkeeper
-- ------------------------------------------------------------
CREATE TABLE Fact_ShopOrders (
    ShopOrderKey             INT IDENTITY(1,1) PRIMARY KEY,
    ShopOrderId              UNIQUEIDENTIFIER,
    DistributorShopKey       INT,          -- FK → Dim_DistributorShop
    DistCenterKey            INT,          -- FK → Dim_DistCenter
    VizshopKey               INT,          -- FK → Dim_Vizshops
    DeliveryManId            NVARCHAR(MAX),
    DeliveryManName          NVARCHAR(1000),
    OrderDate                DATETIME2(7),
    OrderDeliveryDate        DATETIME2(7),
    NetSales                 DECIMAL(18,2),      -- Invoice amount
    OriginalNetSales         DECIMAL(18,2),      -- Amount uploaded by distributor
    InvoiceNumber            NVARCHAR(20),
    DistributorInvoiceNumber NVARCHAR(50),
    OrderAmountToPay         BIGINT,
    AmountPaid               BIGINT,
    OrderStatus              NVARCHAR(20)
);

-- ------------------------------------------------------------
-- Fact_ShopOrderTransactions
-- Grain: one row per digital payment transaction
-- ------------------------------------------------------------
CREATE TABLE Fact_ShopOrderTransactions (
    ShopTransactionKey       INT IDENTITY(1,1) PRIMARY KEY,
    ShopTransactionId        UNIQUEIDENTIFIER,
    AmountPaid               DECIMAL(18,2),
    TransactionStatus        NVARCHAR(20),
    PaymentDate              DATETIME2(7),
    MfiType                  NVARCHAR(MAX),
    TransactionId            NVARCHAR(MAX),       -- MFI transaction ID
    PaymentType              NVARCHAR(MAX),
    TillId                   NVARCHAR(MAX),
    SenderContactNo          NVARCHAR(40),
    DeliveryQRCode           NVARCHAR(50),
    DeliverymanName          NVARCHAR(200),
    ModifiedorActualStatus   VARCHAR(20),         -- Status after reconciliation
    JazzTRID                 NVARCHAR(50),
    ShopOrderKey             INT              -- FK → Fact_ShopOrders
);

-- ------------------------------------------------------------
-- Fact_LenderFinancing
-- Grain: one row per BNPL loan disbursed to a shopkeeper
-- LoanStatus stored as decoded string (decoded in ETL)
-- ------------------------------------------------------------
CREATE TABLE Fact_LenderFinancing (
    FinancingKey             INT IDENTITY(1,1) PRIMARY KEY,
    FinancingId              UNIQUEIDENTIFIER,
    PrincipalAmount          DECIMAL(18,2),
    LoanDate                 DATETIME2(7),
    Lender_LoanId            NVARCHAR(MAX),
    LoanDisplayId            VARCHAR(15),
    LoanStatus               VARCHAR(50),         -- Decoded: 'Disbursed', 'Completed', etc.
    LoanRepaymentStatus      INT,
    LoanDueAmount            DECIMAL(18,2),
    LoanDueDate              DATETIME2(7),
    LenderKey                INT,             -- FK → Dim_Lender
    ShopTransactionKey       INT,             -- FK → Fact_ShopOrderTransactions
    UserKey                  INT,             -- FK → Dim_Users
    LoanPlanKey              INT,             -- FK → Dim_LoanPlans
    VizShopKey               INT              -- FK → Dim_Vizshops
);

-- ------------------------------------------------------------
-- Fact_LenderRepayment
-- Grain: one row per loan repayment installment
-- ------------------------------------------------------------
CREATE TABLE Fact_LenderRepayment (
    RepaymentKey             INT IDENTITY(1,1) PRIMARY KEY,
    RepaymentId              UNIQUEIDENTIFIER,
    RepaymentAmount          DECIMAL(18,2),
    RepaymentDate            DATETIME2(7),
    PaymentTransationStatus  VARCHAR(100),        -- Decoded: 'Success', 'Failed', etc.
    MFIType                  NVARCHAR(MAX),
    MFITransactionId         NVARCHAR(MAX),
    SenderContactNo          NVARCHAR(MAX),
    LenderFinancingKey       INT              -- FK → Fact_LenderFinancing
);

-- ------------------------------------------------------------
-- Fact_LenderKYC
-- Grain: one row per KYC submission by a shopkeeper to a lender
-- KycStatus stored as decoded string (decoded in ETL)
-- ------------------------------------------------------------
CREATE TABLE Fact_LenderKYC (
    KycKey                   INT IDENTITY(1,1) PRIMARY KEY,
    KycId                    UNIQUEIDENTIFIER,
    VizshopKey               INT,             -- FK → Dim_Vizshops
    LenderKey                INT,             -- FK → Dim_Lender
    KycCNIC                  NVARCHAR(100),
    KycCellNo                NVARCHAR(100),
    CreatedDate              DATETIME2(7),
    ModifieddDate            DATETIME2(7),
    KycStatus                VARCHAR(100),        -- Decoded: 'Approved', 'Rejected', etc.
    ContractStatus           NVARCHAR(MAX),
    Reason                   NVARCHAR(300),
    KycBusinessName          NVARCHAR(800),
    CreditLimit              DECIMAL(18,2),
    ExternalIdKey            NVARCHAR(500)
);

-- ------------------------------------------------------------
-- Fact_VLPLedger
-- Grain: one row per loyalty point credit or debit event
-- VlpOpenAmount/VlpCloseAmount track running balance
-- ------------------------------------------------------------
CREATE TABLE Fact_VLPLedger (
    LedgerKey                INT IDENTITY(1,1) PRIMARY KEY,
    LedgerId                 UNIQUEIDENTIFIER,
    LedgerType               NVARCHAR(MAX),
    VLPAmount                DECIMAL(18,2),
    VlpOpenAmount            DECIMAL(18,2),
    VlpCloseAmount           DECIMAL(18,2),
    LedgerDate               DATETIME2(7),
    VLPEventKey              INT,             -- FK → Dim_VLPEvents
    VLPSchemeKey             INT,             -- FK → Dim_VLPScheme
    UserKey                  INT,             -- FK → Dim_Users
    ShopTransactionKey       INT,             -- FK → Fact_ShopOrderTransactions
    VizShopKey               INT              -- FK → Dim_Vizshops
);

-- ------------------------------------------------------------
-- Fact_VLCTickets
-- Grain: one row per support ticket raised by a shopkeeper
-- TicketStatus decoded in ETL
-- ------------------------------------------------------------
CREATE TABLE Fact_VLCTickets (
    TicketKey                INT IDENTITY(1,1) PRIMARY KEY,
    TicketId                 UNIQUEIDENTIFIER,
    CreateDate               DATETIME2(7),
    VizshopKey               INT,             -- FK → Dim_Vizshops
    DistCenterKey            INT,             -- FK → Dim_DistCenter
    CategoryCode             NVARCHAR(MAX),   -- FK → Dim_VLCTicketCategory
    OrderAmount              DECIMAL(18,2),
    TicketText               NVARCHAR(MAX),
    TicketStatus             VARCHAR(100),        -- Decoded: 'Resolved', 'InProgress', etc.
    TicketCode               NVARCHAR(MAX),
    FinalResponse            NVARCHAR(MAX)
);
