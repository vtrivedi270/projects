/* =====================================================================
   Referral Hub - upgrade v3 (run AFTER v1 and v2; safe to re-run)
   1. Candidate joining date on a selected referral
   2. Referral bonus: policy default per department, request/approve/pay, history
   3. ADMIN role for master data management (no new tables needed - Employee,
      Department, Division, Location, Skill, AppRole/EmployeeRole already exist
      from v1; this section only adds the role and a couple of audit columns)
   ===================================================================== */
USE ReferralHub;
GO

/* ---------- 1. Joining date ---------- */
IF COL_LENGTH('rp.Referral', 'JoinedOn') IS NULL
    ALTER TABLE rp.Referral ADD JoinedOn date NULL;
IF COL_LENGTH('rp.Referral', 'JoinedConfirmedByEmployeeId') IS NULL
    ALTER TABLE rp.Referral ADD JoinedConfirmedByEmployeeId int NULL
        CONSTRAINT FK_Referral_JoinConfirm REFERENCES rp.Employee(EmployeeId);
GO

/* ---------- 2. Referral bonus ---------- */
IF COL_LENGTH('rp.Department', 'DefaultBonusAmount') IS NULL
    ALTER TABLE rp.Department ADD DefaultBonusAmount decimal(10,2) NULL;   -- suggested amount for a hire in this department; NULL = no default
GO

IF OBJECT_ID('rp.ReferralBonus') IS NULL
CREATE TABLE rp.ReferralBonus(
    BonusId             int IDENTITY(1,1) CONSTRAINT PK_ReferralBonus PRIMARY KEY,
    ReferralId          int NOT NULL CONSTRAINT UQ_ReferralBonus_Referral UNIQUE
                        CONSTRAINT FK_ReferralBonus_Referral REFERENCES rp.Referral(ReferralId),   -- one bonus request per referral
    RequestedByEmployeeId int NOT NULL CONSTRAINT FK_ReferralBonus_By REFERENCES rp.Employee(EmployeeId),
    RequestedAmount     decimal(10,2) NULL,        -- the department's default at the time of request, shown to the employee as a guide
    ApprovedAmount      decimal(10,2) NULL,        -- set when HR approves; can differ from RequestedAmount
    Status              varchar(10) NOT NULL CONSTRAINT DF_ReferralBonus_Status DEFAULT 'Requested'
                        CONSTRAINT CK_ReferralBonus_Status CHECK (Status IN ('Requested','Approved','Rejected','Paid')),
    Comments             nvarchar(500) NULL,        -- rejection reason, or a note from HR/finance
    RequestedOn          datetime2(0) NOT NULL CONSTRAINT DF_ReferralBonus_ReqOn DEFAULT SYSUTCDATETIME(),
    DecidedByEmployeeId  int NULL CONSTRAINT FK_ReferralBonus_DecidedBy REFERENCES rp.Employee(EmployeeId),
    DecidedOn            datetime2(0) NULL,
    PaidByEmployeeId     int NULL CONSTRAINT FK_ReferralBonus_PaidBy REFERENCES rp.Employee(EmployeeId),
    PaidOn               datetime2(0) NULL,
    PayoutReference      nvarchar(100) NULL,        -- payroll batch or voucher number, not an account number
    RowVer                rowversion
);
GO
CREATE INDEX IX_ReferralBonus_Status ON rp.ReferralBonus(Status);
CREATE INDEX IX_ReferralBonus_By ON rp.ReferralBonus(RequestedByEmployeeId);
GO

/* Append-only audit trail, same pattern as rp.RequisitionHistory */
IF OBJECT_ID('rp.ReferralBonusHistory') IS NULL
CREATE TABLE rp.ReferralBonusHistory(
    HistoryId       bigint IDENTITY(1,1) CONSTRAINT PK_ReferralBonusHistory PRIMARY KEY,
    BonusId         int NOT NULL CONSTRAINT FK_BonusHistory_Bonus REFERENCES rp.ReferralBonus(BonusId),
    EventType       varchar(20) NOT NULL,      -- Requested, Approved, Rejected, Paid
    ActorEmployeeId int NOT NULL CONSTRAINT FK_BonusHistory_Actor REFERENCES rp.Employee(EmployeeId),
    Comments        nvarchar(500) NULL,
    CreatedOn       datetime2(0) NOT NULL CONSTRAINT DF_BonusHistory_On DEFAULT SYSUTCDATETIME()
);
CREATE INDEX IX_BonusHistory_Bonus ON rp.ReferralBonusHistory(BonusId, CreatedOn);
GO

CREATE OR ALTER TRIGGER rp.trg_ReferralBonusHistory_AppendOnly ON rp.ReferralBonusHistory
INSTEAD OF UPDATE, DELETE AS
BEGIN
    RAISERROR('Referral bonus history is append-only.', 16, 1);
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
END
GO

/* ---------- 3. Admin role for master data ---------- */
IF NOT EXISTS (SELECT 1 FROM rp.AppRole WHERE Code = 'ADMIN')
    INSERT rp.AppRole(RoleId, Code, Name) VALUES (8, 'ADMIN', 'Administrator');
GO

/* Who last changed a master record - useful in the admin screens */
IF COL_LENGTH('rp.Employee', 'UpdatedOn') IS NULL
    ALTER TABLE rp.Employee ADD UpdatedOn datetime2(0) NULL;
IF COL_LENGTH('rp.Department', 'UpdatedOn') IS NULL
    ALTER TABLE rp.Department ADD UpdatedOn datetime2(0) NULL;
IF COL_LENGTH('rp.Division', 'UpdatedOn') IS NULL
    ALTER TABLE rp.Division ADD UpdatedOn datetime2(0) NULL;
GO

/* ---------- Example: make someone an admin (edit the email) ----------
INSERT rp.EmployeeRole(EmployeeId, RoleId)
SELECT EmployeeId, 8 FROM rp.Employee WHERE Email = 'suresh@yourtenant.com'
  AND NOT EXISTS (SELECT 1 FROM rp.EmployeeRole x WHERE x.EmployeeId = rp.Employee.EmployeeId AND x.RoleId = 8);

-- optional: set a default bonus amount per department
UPDATE rp.Department SET DefaultBonusAmount = 25000 WHERE Name = 'Engineering';
---------------------------------------------------------------------- */
