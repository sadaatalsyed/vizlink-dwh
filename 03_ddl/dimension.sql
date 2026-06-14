-- ============================================================
-- Vizlink Data Warehouse — Dimension Tables DDL
-- Database: VDWH_Auto
-- ============================================================

USE VDWH_Auto;

-- ------------------------------------------------------------
-- Dim_date
-- Standard date dimension for time-series analysis
-- DateKey format: YYYYMMDD
-- ------------------------------------------------------------
CREATE TABLE dim_date (
    DateKey              INT PRIMARY KEY,
    FullDate             DATE UNIQUE NOT NULL,
    Year                 INT NOT NULL,
    Quarter              INT NOT NULL,
    QuarterName          VARCHAR(6) NOT NULL,
    Month                INT NOT NULL,
    MonthName            VARCHAR(20) NOT NULL,
    MonthYear            VARCHAR(10),
    Day                  INT NOT NULL,
    DayOfWeek            INT NOT NULL,       -- 1 (Sunday) to 7 (Saturday)
    DayName              VARCHAR(10) NOT NULL,
    WeekOfYear           INT NOT NULL,
    DayOfYear            INT NOT NULL,
    IsWeekend            BIT NOT NULL,
    IsStartOfMonth       BIT NOT NULL,
    IsEndOfMonth         BIT NOT NULL,
    IsStartOfQuarter     BIT NOT NULL,
    IsEndOfQuarter       BIT NOT NULL,
    IsStartOfYear        BIT NOT NULL,
    IsEndOfYear          BIT NOT NULL
);

-- ------------------------------------------------------------
-- Dim_DistCenter
-- Distribution centers — link between principals and distributors
-- ------------------------------------------------------------
CREATE TABLE Dim_DistCenter (
    DistCenterKey        INT IDENTITY(1,1) PRIMARY KEY,
    DistCenterId         UNIQUEIDENTIFIER,
    DistCenterName       NVARCHAR(200),
    DistributorName      NVARCHAR(100),
    DistributorCity      NVARCHAR(50),
    PrincipalName        NVARCHAR(200)
);

-- ------------------------------------------------------------
-- Dim_Users
-- All platform users — RSOs, admins, managers
-- Source: AspNetUsers (Role 4 = RSO)
-- ------------------------------------------------------------
CREATE TABLE Dim_Users (
    UserKey              INT IDENTITY(1,1) PRIMARY KEY,
    UserId               NVARCHAR(450),
    FirstName            NVARCHAR(100),
    LastName             NVARCHAR(100),
    Username             NVARCHAR(256),
    CNIC                 NVARCHAR(100),
    SignupDate           DATETIME2(7),
    SignUpDateKey        INT,
    LastLoginDate        DATETIME2(7)
);

-- ------------------------------------------------------------
-- Dim_DMs
-- Delivery men — field agents who collect payments via QR
-- ------------------------------------------------------------
CREATE TABLE Dim_DMs (
    DMKey                INT IDENTITY(1,1) PRIMARY KEY,
    DMId                 NVARCHAR(450),
    FirstName            NVARCHAR(100),
    LastName             NVARCHAR(100),
    QRCode               NVARCHAR(50),
    DistCenterName       NVARCHAR(200)
);

-- ------------------------------------------------------------
-- Dim_Vizshops
-- Master record for every enrolled retailer on the platform
-- SignUp: whether shopkeeper has a registered user account
-- ------------------------------------------------------------
CREATE TABLE Dim_Vizshops (
    VizShopKey           INT IDENTITY(1,1) PRIMARY KEY,
    VizShopId            UNIQUEIDENTIFIER,
    VizShopCode          NVARCHAR(50),
    VizshopName          NVARCHAR(200),
    CNIC                 NVARCHAR(20),
    ShopCategory         NVARCHAR(500),
    Locality             NVARCHAR(200),
    Area                 NVARCHAR(500),
    SectorNumber         NVARCHAR(250),
    RsoName              NVARCHAR(100),
    InductionDate        DATETIME2(7),
    ModifiedDate         DATETIME2(7),
    SignUp               VARCHAR(20)       -- 'Yes' / 'No' — derived field
);

-- ------------------------------------------------------------
-- Dim_DistributorShop
-- Distributor customer list mapped to Vizlink shops
-- VizShopKey nullable — not all distributor shops are on Vizlink
-- ------------------------------------------------------------
CREATE TABLE Dim_DistributorShop (
    DistributorShopKey   INT IDENTITY(1,1) PRIMARY KEY,
    DistributorShopId    UNIQUEIDENTIFIER,
    DistCenterKey        INT,
    ShopCode             NVARCHAR(200),
    ShopName             NVARCHAR(200),
    VizShopKey           INT,
    RsoName              NVARCHAR(400)
);

-- ------------------------------------------------------------
-- Dim_Lender
-- Financial institutions providing BNPL credit
-- ------------------------------------------------------------
CREATE TABLE Dim_Lender (
    LenderKey            INT IDENTITY(1,1) PRIMARY KEY,
    LenderId             UNIQUEIDENTIFIER,
    LenderName           NVARCHAR(MAX)
);

-- ------------------------------------------------------------
-- Dim_LoanPlans
-- Loan product catalog per lender
-- Snowflake element — links to Dim_Lender
-- ------------------------------------------------------------
CREATE TABLE Dim_LoanPlans (
    LoanPlanKey          INT IDENTITY(1,1) PRIMARY KEY,
    LoanPlanId           UNIQUEIDENTIFIER,
    PlanName             NVARCHAR(MAX),
    PlanDuration         INT,
    LenderKey            INT
);

-- ------------------------------------------------------------
-- Dim_VLPEvents
-- Top-level loyalty program campaigns
-- ------------------------------------------------------------
CREATE TABLE Dim_VLPEvents (
    VLPEventKey          INT IDENTITY(1,1) PRIMARY KEY,
    EventId              UNIQUEIDENTIFIER,
    EventName            NVARCHAR(MAX)
);

-- ------------------------------------------------------------
-- Dim_VLPScheme
-- Sub-programs within a loyalty event
-- Snowflake element — links to Dim_VLPEvents
-- ------------------------------------------------------------
CREATE TABLE Dim_VLPScheme (
    VLPSchemeKey         INT IDENTITY(1,1) PRIMARY KEY,
    SchemeId             UNIQUEIDENTIFIER,
    SchemeName           NVARCHAR(MAX),
    VLPEventKey          INT,
    StartDate            DATETIME2(7),
    EndDate              DATETIME2(7)
);

-- ------------------------------------------------------------
-- Dim_VLCTicketCategory
-- Lookup for support ticket categories
-- ------------------------------------------------------------
CREATE TABLE Dim_VLCTicketCategory (
    CategoryCode         INT PRIMARY KEY,
    CategoryName         NVARCHAR(100)
);

-- ------------------------------------------------------------
-- Dim_CBKYBs
-- Compliance and risk assessment status from external KYC provider
-- ------------------------------------------------------------
CREATE TABLE Dim_CBKYBs (
    ExternalIdKey        INT IDENTITY(1,1) PRIMARY KEY,
    ExternalId           NVARCHAR(500),
    ComplianceStatus     NVARCHAR(300),
    ComplianceReason     NVARCHAR(MAX),
    RiskAssessmentStatus NVARCHAR(300),
    RiskReason           NVARCHAR(MAX)
);
