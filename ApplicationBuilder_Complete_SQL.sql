
/*
===============================================================================
APPLICATION BUILDER PLATFORM
Complete SQL Server Database Script
Target: SQL Server 2019/2022 / Azure SQL
Purpose: Metadata-driven enterprise application/form/workflow platform

Run this script against a NEW database.
===============================================================================
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================================================================
   1. DATABASE SCHEMA
   ============================================================================ */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'ab')
    EXEC('CREATE SCHEMA ab');
GO

/* ============================================================================
   2. APPLICATION / CONFIGURATION
   ============================================================================ */

CREATE TABLE ab.Application
(
    ApplicationId       INT IDENTITY(1,1) NOT NULL,
    ApplicationCode     NVARCHAR(50) NOT NULL,
    ApplicationName     NVARCHAR(200) NOT NULL,
    Description         NVARCHAR(1000) NULL,
    IconName            NVARCHAR(100) NULL,
    ThemeColor          NVARCHAR(20) NULL,
    OwnerUserId         NVARCHAR(100) NULL,
    SharePointLibrary   NVARCHAR(200) NULL,
    StatusCode          NVARCHAR(30) NOT NULL CONSTRAINT DF_Application_Status DEFAULT ('DRAFT'),
    DisplayOrder        INT NOT NULL CONSTRAINT DF_Application_DisplayOrder DEFAULT (0),
    IsActive            BIT NOT NULL CONSTRAINT DF_Application_IsActive DEFAULT (1),
    CreatedBy           NVARCHAR(100) NOT NULL,
    CreatedDate         DATETIME2(3) NOT NULL CONSTRAINT DF_Application_CreatedDate DEFAULT SYSUTCDATETIME(),
    ModifiedBy          NVARCHAR(100) NULL,
    ModifiedDate        DATETIME2(3) NULL,
    RowVersion          ROWVERSION NOT NULL,

    CONSTRAINT PK_Application PRIMARY KEY (ApplicationId),
    CONSTRAINT UQ_Application_Code UNIQUE (ApplicationCode)
);
GO

CREATE TABLE ab.ApplicationVersion
(
    ApplicationVersionId INT IDENTITY(1,1) NOT NULL,
    ApplicationId        INT NOT NULL,
    VersionNo            INT NOT NULL,
    VersionName          NVARCHAR(100) NULL,
    ConfigurationJson    NVARCHAR(MAX) NULL,
    StatusCode           NVARCHAR(30) NOT NULL CONSTRAINT DF_ApplicationVersion_Status DEFAULT ('DRAFT'),
    IsPublished          BIT NOT NULL CONSTRAINT DF_ApplicationVersion_IsPublished DEFAULT (0),
    PublishedBy          NVARCHAR(100) NULL,
    PublishedDate        DATETIME2(3) NULL,
    CreatedBy            NVARCHAR(100) NOT NULL,
    CreatedDate          DATETIME2(3) NOT NULL CONSTRAINT DF_ApplicationVersion_CreatedDate DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_ApplicationVersion PRIMARY KEY (ApplicationVersionId),
    CONSTRAINT FK_ApplicationVersion_Application
        FOREIGN KEY (ApplicationId) REFERENCES ab.Application(ApplicationId),
    CONSTRAINT UQ_ApplicationVersion UNIQUE (ApplicationId, VersionNo)
);
GO

/* ============================================================================
   3. FORM BUILDER
   ============================================================================ */

CREATE TABLE ab.Form
(
    FormId               INT IDENTITY(1,1) NOT NULL,
    ApplicationId        INT NOT NULL,
    FormCode             NVARCHAR(100) NOT NULL,
    FormName             NVARCHAR(200) NOT NULL,
    Description          NVARCHAR(1000) NULL,
    VersionNo             INT NOT NULL CONSTRAINT DF_Form_VersionNo DEFAULT (1),
    StatusCode            NVARCHAR(30) NOT NULL CONSTRAINT DF_Form_Status DEFAULT ('DRAFT'),
    IsPublished           BIT NOT NULL CONSTRAINT DF_Form_IsPublished DEFAULT (0),
    PublishedBy           NVARCHAR(100) NULL,
    PublishedDate         DATETIME2(3) NULL,
    LayoutJson            NVARCHAR(MAX) NULL,
    ConfigurationJson     NVARCHAR(MAX) NULL,
    CreatedBy              NVARCHAR(100) NOT NULL,
    CreatedDate            DATETIME2(3) NOT NULL CONSTRAINT DF_Form_CreatedDate DEFAULT SYSUTCDATETIME(),
    ModifiedBy             NVARCHAR(100) NULL,
    ModifiedDate           DATETIME2(3) NULL,
    RowVersion             ROWVERSION NOT NULL,

    CONSTRAINT PK_Form PRIMARY KEY (FormId),
    CONSTRAINT FK_Form_Application
        FOREIGN KEY (ApplicationId) REFERENCES ab.Application(ApplicationId),
    CONSTRAINT UQ_Form_Code UNIQUE (ApplicationId, FormCode)
);
GO

CREATE TABLE ab.FormSection
(
    SectionId              INT IDENTITY(1,1) NOT NULL,
    FormId                 INT NOT NULL,
    SectionKey             NVARCHAR(100) NOT NULL,
    SectionName            NVARCHAR(200) NOT NULL,
    Description             NVARCHAR(1000) NULL,
    DisplayOrder            INT NOT NULL CONSTRAINT DF_FormSection_DisplayOrder DEFAULT (0),
    IsCollapsible           BIT NOT NULL CONSTRAINT DF_FormSection_IsCollapsible DEFAULT (0),
    IsCollapsed             BIT NOT NULL CONSTRAINT DF_FormSection_IsCollapsed DEFAULT (0),
    IsActive                BIT NOT NULL CONSTRAINT DF_FormSection_IsActive DEFAULT (1),
    ConfigurationJson       NVARCHAR(MAX) NULL,

    CONSTRAINT PK_FormSection PRIMARY KEY (SectionId),
    CONSTRAINT FK_FormSection_Form
        FOREIGN KEY (FormId) REFERENCES ab.Form(FormId),
    CONSTRAINT UQ_FormSection_Key UNIQUE (FormId, SectionKey)
);
GO

CREATE TABLE ab.FormField
(
    FieldId                 INT IDENTITY(1,1) NOT NULL,
    SectionId               INT NOT NULL,
    FieldKey                NVARCHAR(100) NOT NULL,
    FieldLabel              NVARCHAR(200) NOT NULL,
    ControlType             NVARCHAR(60) NOT NULL,
    DataType                NVARCHAR(50) NOT NULL,
    Placeholder             NVARCHAR(500) NULL,
    HelpText                NVARCHAR(1000) NULL,
    DefaultValue            NVARCHAR(MAX) NULL,
    WidthSpan               INT NOT NULL CONSTRAINT DF_FormField_WidthSpan DEFAULT (24),
    DisplayOrder            INT NOT NULL CONSTRAINT DF_FormField_DisplayOrder DEFAULT (0),
    IsRequired              BIT NOT NULL CONSTRAINT DF_FormField_IsRequired DEFAULT (0),
    IsReadonly              BIT NOT NULL CONSTRAINT DF_FormField_IsReadonly DEFAULT (0),
    IsHidden                BIT NOT NULL CONSTRAINT DF_FormField_IsHidden DEFAULT (0),
    IsSearchable            BIT NOT NULL CONSTRAINT DF_FormField_IsSearchable DEFAULT (0),
    IsReportable            BIT NOT NULL CONSTRAINT DF_FormField_IsReportable DEFAULT (0),
    IsSortable              BIT NOT NULL CONSTRAINT DF_FormField_IsSortable DEFAULT (0),
    IsFilterable            BIT NOT NULL CONSTRAINT DF_FormField_IsFilterable DEFAULT (0),
    ValidationJson          NVARCHAR(MAX) NULL,
    ConfigurationJson       NVARCHAR(MAX) NULL,
    DataSourceJson          NVARCHAR(MAX) NULL,
    FormulaExpression       NVARCHAR(MAX) NULL,
    CreatedBy               NVARCHAR(100) NOT NULL,
    CreatedDate             DATETIME2(3) NOT NULL CONSTRAINT DF_FormField_CreatedDate DEFAULT SYSUTCDATETIME(),
    ModifiedBy              NVARCHAR(100) NULL,
    ModifiedDate            DATETIME2(3) NULL,

    CONSTRAINT PK_FormField PRIMARY KEY (FieldId),
    CONSTRAINT FK_FormField_Section
        FOREIGN KEY (SectionId) REFERENCES ab.FormSection(SectionId),
    CONSTRAINT UQ_FormField_Key UNIQUE (SectionId, FieldKey),
    CONSTRAINT CK_FormField_Width CHECK (WidthSpan IN (1,2,3,4,6,8,12,16,18,24))
);
GO

CREATE TABLE ab.FieldOption
(
    OptionId                INT IDENTITY(1,1) NOT NULL,
    FieldId                 INT NOT NULL,
    OptionValue              NVARCHAR(200) NOT NULL,
    OptionLabel              NVARCHAR(200) NOT NULL,
    ParentOptionValue        NVARCHAR(200) NULL,
    DisplayOrder             INT NOT NULL CONSTRAINT DF_FieldOption_DisplayOrder DEFAULT (0),
    IsDefault                BIT NOT NULL CONSTRAINT DF_FieldOption_IsDefault DEFAULT (0),
    IsActive                 BIT NOT NULL CONSTRAINT DF_FieldOption_IsActive DEFAULT (1),

    CONSTRAINT PK_FieldOption PRIMARY KEY (OptionId),
    CONSTRAINT FK_FieldOption_Field
        FOREIGN KEY (FieldId) REFERENCES ab.FormField(FieldId)
);
GO

CREATE TABLE ab.FieldRule
(
    FieldRuleId              INT IDENTITY(1,1) NOT NULL,
    FieldId                  INT NOT NULL,
    RuleName                  NVARCHAR(200) NOT NULL,
    RuleType                  NVARCHAR(50) NOT NULL,
    ConditionJson             NVARCHAR(MAX) NOT NULL,
    ActionJson                NVARCHAR(MAX) NOT NULL,
    ExecutionOrder            INT NOT NULL CONSTRAINT DF_FieldRule_Order DEFAULT (0),
    IsActive                  BIT NOT NULL CONSTRAINT DF_FieldRule_IsActive DEFAULT (1),

    CONSTRAINT PK_FieldRule PRIMARY KEY (FieldRuleId),
    CONSTRAINT FK_FieldRule_Field
        FOREIGN KEY (FieldId) REFERENCES ab.FormField(FieldId)
);
GO

/* ============================================================================
   4. MASTER DATA
   ============================================================================ */

CREATE TABLE ab.MasterData
(
    MasterDataId              INT IDENTITY(1,1) NOT NULL,
    MasterCode                NVARCHAR(100) NOT NULL,
    MasterName                NVARCHAR(200) NOT NULL,
    Description               NVARCHAR(1000) NULL,
    IsActive                  BIT NOT NULL CONSTRAINT DF_MasterData_IsActive DEFAULT (1),
    CreatedBy                 NVARCHAR(100) NOT NULL,
    CreatedDate               DATETIME2(3) NOT NULL CONSTRAINT DF_MasterData_CreatedDate DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_MasterData PRIMARY KEY (MasterDataId),
    CONSTRAINT UQ_MasterData_Code UNIQUE (MasterCode)
);
GO

CREATE TABLE ab.MasterDataItem
(
    MasterDataItemId          INT IDENTITY(1,1) NOT NULL,
    MasterDataId              INT NOT NULL,
    ItemCode                  NVARCHAR(100) NOT NULL,
    ItemName                  NVARCHAR(200) NOT NULL,
    ParentItemId              INT NULL,
    DisplayOrder              INT NOT NULL CONSTRAINT DF_MasterDataItem_Order DEFAULT (0),
    IsDefault                 BIT NOT NULL CONSTRAINT DF_MasterDataItem_IsDefault DEFAULT (0),
    IsActive                  BIT NOT NULL CONSTRAINT DF_MasterDataItem_IsActive DEFAULT (1),
    AdditionalDataJson        NVARCHAR(MAX) NULL,

    CONSTRAINT PK_MasterDataItem PRIMARY KEY (MasterDataItemId),
    CONSTRAINT FK_MasterDataItem_MasterData
        FOREIGN KEY (MasterDataId) REFERENCES ab.MasterData(MasterDataId),
    CONSTRAINT FK_MasterDataItem_Parent
        FOREIGN KEY (ParentItemId) REFERENCES ab.MasterDataItem(MasterDataItemId),
    CONSTRAINT UQ_MasterDataItem_Code UNIQUE (MasterDataId, ItemCode)
);
GO

/* ============================================================================
   5. BUSINESS RULES
   ============================================================================ */

CREATE TABLE ab.BusinessRule
(
    BusinessRuleId            INT IDENTITY(1,1) NOT NULL,
    ApplicationId             INT NOT NULL,
    RuleCode                  NVARCHAR(100) NOT NULL,
    RuleName                  NVARCHAR(200) NOT NULL,
    RuleType                  NVARCHAR(60) NOT NULL,
    ConditionJson             NVARCHAR(MAX) NOT NULL,
    ActionJson                NVARCHAR(MAX) NOT NULL,
    ExecutionOrder            INT NOT NULL CONSTRAINT DF_BusinessRule_Order DEFAULT (0),
    StopProcessing            BIT NOT NULL CONSTRAINT DF_BusinessRule_Stop DEFAULT (0),
    IsActive                  BIT NOT NULL CONSTRAINT DF_BusinessRule_IsActive DEFAULT (1),
    CreatedBy                 NVARCHAR(100) NOT NULL,
    CreatedDate               DATETIME2(3) NOT NULL CONSTRAINT DF_BusinessRule_CreatedDate DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_BusinessRule PRIMARY KEY (BusinessRuleId),
    CONSTRAINT FK_BusinessRule_Application
        FOREIGN KEY (ApplicationId) REFERENCES ab.Application(ApplicationId),
    CONSTRAINT UQ_BusinessRule_Code UNIQUE (ApplicationId, RuleCode)
);
GO

/* ============================================================================
   6. WORKFLOW DEFINITION
   ============================================================================ */

CREATE TABLE ab.Workflow
(
    WorkflowId                INT IDENTITY(1,1) NOT NULL,
    ApplicationId             INT NOT NULL,
    WorkflowCode              NVARCHAR(100) NOT NULL,
    WorkflowName              NVARCHAR(200) NOT NULL,
    Description               NVARCHAR(1000) NULL,
    VersionNo                 INT NOT NULL CONSTRAINT DF_Workflow_VersionNo DEFAULT (1),
    StatusCode                NVARCHAR(30) NOT NULL CONSTRAINT DF_Workflow_Status DEFAULT ('DRAFT'),
    IsPublished               BIT NOT NULL CONSTRAINT DF_Workflow_IsPublished DEFAULT (0),
    PublishedBy               NVARCHAR(100) NULL,
    PublishedDate             DATETIME2(3) NULL,
    ConfigurationJson         NVARCHAR(MAX) NULL,
    CreatedBy                 NVARCHAR(100) NOT NULL,
    CreatedDate               DATETIME2(3) NOT NULL CONSTRAINT DF_Workflow_CreatedDate DEFAULT SYSUTCDATETIME(),
    ModifiedBy                NVARCHAR(100) NULL,
    ModifiedDate              DATETIME2(3) NULL,
    RowVersion                ROWVERSION NOT NULL,

    CONSTRAINT PK_Workflow PRIMARY KEY (WorkflowId),
    CONSTRAINT FK_Workflow_Application
        FOREIGN KEY (ApplicationId) REFERENCES ab.Application(ApplicationId),
    CONSTRAINT UQ_Workflow_Code UNIQUE (ApplicationId, WorkflowCode, VersionNo)
);
GO

CREATE TABLE ab.WorkflowStage
(
    StageId                   INT IDENTITY(1,1) NOT NULL,
    WorkflowId                INT NOT NULL,
    StageCode                 NVARCHAR(100) NOT NULL,
    StageName                 NVARCHAR(200) NOT NULL,
    StageType                 NVARCHAR(50) NOT NULL,
    ApprovalMode              NVARCHAR(30) NULL,
    DisplayOrder              INT NOT NULL CONSTRAINT DF_WorkflowStage_Order DEFAULT (0),
    TimeoutHours              INT NULL,
    IsStartStage              BIT NOT NULL CONSTRAINT DF_WorkflowStage_Start DEFAULT (0),
    IsEndStage                BIT NOT NULL CONSTRAINT DF_WorkflowStage_End DEFAULT (0),
    ConfigurationJson         NVARCHAR(MAX) NULL,

    CONSTRAINT PK_WorkflowStage PRIMARY KEY (StageId),
    CONSTRAINT FK_WorkflowStage_Workflow
        FOREIGN KEY (WorkflowId) REFERENCES ab.Workflow(WorkflowId),
    CONSTRAINT UQ_WorkflowStage_Code UNIQUE (WorkflowId, StageCode)
);
GO

CREATE TABLE ab.WorkflowTransition
(
    TransitionId              INT IDENTITY(1,1) NOT NULL,
    WorkflowId                INT NOT NULL,
    FromStageId               INT NOT NULL,
    ToStageId                 INT NOT NULL,
    TransitionCode            NVARCHAR(100) NOT NULL,
    TransitionName            NVARCHAR(200) NULL,
    ConditionJson             NVARCHAR(MAX) NULL,
    ActionCode                NVARCHAR(50) NULL,
    DisplayOrder              INT NOT NULL CONSTRAINT DF_WorkflowTransition_Order DEFAULT (0),
    IsActive                  BIT NOT NULL CONSTRAINT DF_WorkflowTransition_IsActive DEFAULT (1),

    CONSTRAINT PK_WorkflowTransition PRIMARY KEY (TransitionId),
    CONSTRAINT FK_WorkflowTransition_Workflow
        FOREIGN KEY (WorkflowId) REFERENCES ab.Workflow(WorkflowId),
    CONSTRAINT FK_WorkflowTransition_FromStage
        FOREIGN KEY (FromStageId) REFERENCES ab.WorkflowStage(StageId),
    CONSTRAINT FK_WorkflowTransition_ToStage
        FOREIGN KEY (ToStageId) REFERENCES ab.WorkflowStage(StageId),
    CONSTRAINT UQ_WorkflowTransition_Code UNIQUE (WorkflowId, TransitionCode)
);
GO

CREATE TABLE ab.WorkflowApprover
(
    WorkflowApproverId        INT IDENTITY(1,1) NOT NULL,
    StageId                   INT NOT NULL,
    ApproverType               NVARCHAR(50) NOT NULL,
    ApproverValue              NVARCHAR(200) NULL,
    AssignmentRuleJson         NVARCHAR(MAX) NULL,
    ApprovalMode               NVARCHAR(30) NULL,
    SequenceNo                 INT NOT NULL CONSTRAINT DF_WorkflowApprover_Sequence DEFAULT (1),
    IsActive                  BIT NOT NULL CONSTRAINT DF_WorkflowApprover_IsActive DEFAULT (1),

    CONSTRAINT PK_WorkflowApprover PRIMARY KEY (WorkflowApproverId),
    CONSTRAINT FK_WorkflowApprover_Stage
        FOREIGN KEY (StageId) REFERENCES ab.WorkflowStage(StageId)
);
GO

/* ============================================================================
   7. SECURITY / ORGANIZATION
   ============================================================================ */

CREATE TABLE ab.AppRole
(
    RoleId                    INT IDENTITY(1,1) NOT NULL,
    RoleCode                  NVARCHAR(100) NOT NULL,
    RoleName                  NVARCHAR(200) NOT NULL,
    Description               NVARCHAR(1000) NULL,
    IsSystemRole              BIT NOT NULL CONSTRAINT DF_AppRole_System DEFAULT (0),
    IsActive                  BIT NOT NULL CONSTRAINT DF_AppRole_IsActive DEFAULT (1),

    CONSTRAINT PK_AppRole PRIMARY KEY (RoleId),
    CONSTRAINT UQ_AppRole_Code UNIQUE (RoleCode)
);
GO

CREATE TABLE ab.Permission
(
    PermissionId              INT IDENTITY(1,1) NOT NULL,
    PermissionCode            NVARCHAR(100) NOT NULL,
    PermissionName            NVARCHAR(200) NOT NULL,
    Description               NVARCHAR(1000) NULL,
    IsActive                  BIT NOT NULL CONSTRAINT DF_Permission_IsActive DEFAULT (1),

    CONSTRAINT PK_Permission PRIMARY KEY (PermissionId),
    CONSTRAINT UQ_Permission_Code UNIQUE (PermissionCode)
);
GO

CREATE TABLE ab.RolePermission
(
    RoleId                    INT NOT NULL,
    PermissionId              INT NOT NULL,

    CONSTRAINT PK_RolePermission PRIMARY KEY (RoleId, PermissionId),
    CONSTRAINT FK_RolePermission_Role
        FOREIGN KEY (RoleId) REFERENCES ab.AppRole(RoleId),
    CONSTRAINT FK_RolePermission_Permission
        FOREIGN KEY (PermissionId) REFERENCES ab.Permission(PermissionId)
);
GO

CREATE TABLE ab.OrganizationUnit
(
    OrganizationUnitId        INT IDENTITY(1,1) NOT NULL,
    UnitCode                  NVARCHAR(100) NOT NULL,
    UnitName                  NVARCHAR(200) NOT NULL,
    UnitType                  NVARCHAR(50) NOT NULL,
    ParentUnitId              INT NULL,
    IsActive                  BIT NOT NULL CONSTRAINT DF_OrganizationUnit_IsActive DEFAULT (1),

    CONSTRAINT PK_OrganizationUnit PRIMARY KEY (OrganizationUnitId),
    CONSTRAINT UQ_OrganizationUnit_Code UNIQUE (UnitCode),
    CONSTRAINT FK_OrganizationUnit_Parent
        FOREIGN KEY (ParentUnitId) REFERENCES ab.OrganizationUnit(OrganizationUnitId)
);
GO

CREATE TABLE ab.AppUser
(
    UserId                    NVARCHAR(100) NOT NULL,
    EmployeeCode              NVARCHAR(100) NULL,
    DisplayName               NVARCHAR(200) NOT NULL,
    Email                     NVARCHAR(320) NULL,
    JobTitle                  NVARCHAR(200) NULL,
    ManagerUserId             NVARCHAR(100) NULL,
    OrganizationUnitId        INT NULL,
    IsActive                  BIT NOT NULL CONSTRAINT DF_AppUser_IsActive DEFAULT (1),
    CreatedDate               DATETIME2(3) NOT NULL CONSTRAINT DF_AppUser_CreatedDate DEFAULT SYSUTCDATETIME(),
    ModifiedDate              DATETIME2(3) NULL,

    CONSTRAINT PK_AppUser PRIMARY KEY (UserId),
    CONSTRAINT FK_AppUser_Manager
        FOREIGN KEY (ManagerUserId) REFERENCES ab.AppUser(UserId),
    CONSTRAINT FK_AppUser_Organization
        FOREIGN KEY (OrganizationUnitId) REFERENCES ab.OrganizationUnit(OrganizationUnitId)
);
GO

CREATE TABLE ab.UserRole
(
    UserId                    NVARCHAR(100) NOT NULL,
    RoleId                    INT NOT NULL,
    ApplicationId             INT NULL,
    StartDate                 DATE NULL,
    EndDate                   DATE NULL,
    IsActive                  BIT NOT NULL CONSTRAINT DF_UserRole_IsActive DEFAULT (1),

    CONSTRAINT PK_UserRole PRIMARY KEY (UserId, RoleId, ApplicationId),
    CONSTRAINT FK_UserRole_User
        FOREIGN KEY (UserId) REFERENCES ab.AppUser(UserId),
    CONSTRAINT FK_UserRole_Role
        FOREIGN KEY (RoleId) REFERENCES ab.AppRole(RoleId),
    CONSTRAINT FK_UserRole_Application
        FOREIGN KEY (ApplicationId) REFERENCES ab.Application(ApplicationId)
);
GO

CREATE TABLE ab.ApplicationPermission
(
    ApplicationPermissionId   INT IDENTITY(1,1) NOT NULL,
    ApplicationId             INT NOT NULL,
    RoleId                    INT NOT NULL,
    PermissionId              INT NOT NULL,
    ScopeType                 NVARCHAR(50) NOT NULL CONSTRAINT DF_AppPermission_Scope DEFAULT ('APPLICATION'),
    ScopeJson                 NVARCHAR(MAX) NULL,
    IsActive                  BIT NOT NULL CONSTRAINT DF_AppPermission_IsActive DEFAULT (1),

    CONSTRAINT PK_ApplicationPermission PRIMARY KEY (ApplicationPermissionId),
    CONSTRAINT FK_AppPermission_Application
        FOREIGN KEY (ApplicationId) REFERENCES ab.Application(ApplicationId),
    CONSTRAINT FK_AppPermission_Role
        FOREIGN KEY (RoleId) REFERENCES ab.AppRole(RoleId),
    CONSTRAINT FK_AppPermission_Permission
        FOREIGN KEY (PermissionId) REFERENCES ab.Permission(PermissionId),
    CONSTRAINT UQ_ApplicationPermission UNIQUE (ApplicationId, RoleId, PermissionId)
);
GO

/* ============================================================================
   8. REQUEST / TRANSACTION
   ============================================================================ */

CREATE TABLE ab.Request
(
    RequestId                 BIGINT IDENTITY(1,1) NOT NULL,
    ApplicationId             INT NOT NULL,
    FormId                    INT NULL,
    FormVersionNo             INT NOT NULL,
    RequestNumber             NVARCHAR(100) NOT NULL,
    CreatedByUserId           NVARCHAR(100) NOT NULL,
    CurrentOwnerUserId        NVARCHAR(100) NULL,
    StatusCode                NVARCHAR(50) NOT NULL,
    FormDataJson              NVARCHAR(MAX) NULL,
    SearchText                NVARCHAR(MAX) NULL,
    CreatedDate               DATETIME2(3) NOT NULL CONSTRAINT DF_Request_CreatedDate DEFAULT SYSUTCDATETIME(),
    ModifiedDate              DATETIME2(3) NULL,
    SubmittedDate             DATETIME2(3) NULL,
    CompletedDate             DATETIME2(3) NULL,
    IsDeleted                 BIT NOT NULL CONSTRAINT DF_Request_IsDeleted DEFAULT (0),
    RowVersion                ROWVERSION NOT NULL,

    CONSTRAINT PK_Request PRIMARY KEY (RequestId),
    CONSTRAINT FK_Request_Application
        FOREIGN KEY (ApplicationId) REFERENCES ab.Application(ApplicationId),
    CONSTRAINT FK_Request_Form
        FOREIGN KEY (FormId) REFERENCES ab.Form(FormId),
    CONSTRAINT FK_Request_CreatedBy
        FOREIGN KEY (CreatedByUserId) REFERENCES ab.AppUser(UserId),
    CONSTRAINT FK_Request_Owner
        FOREIGN KEY (CurrentOwnerUserId) REFERENCES ab.AppUser(UserId),
    CONSTRAINT UQ_Request_Number UNIQUE (RequestNumber)
);
GO

CREATE TABLE ab.RequestValue
(
    RequestValueId           BIGINT IDENTITY(1,1) NOT NULL,
    RequestId                BIGINT NOT NULL,
    FieldId                  INT NOT NULL,
    FieldKey                 NVARCHAR(100) NOT NULL,
    StringValue              NVARCHAR(MAX) NULL,
    NumberValue              DECIMAL(38,10) NULL,
    DateValue                DATETIME2(3) NULL,
    BoolValue                BIT NULL,
    JsonValue                NVARCHAR(MAX) NULL,

    CONSTRAINT PK_RequestValue PRIMARY KEY (RequestValueId),
    CONSTRAINT FK_RequestValue_Request
        FOREIGN KEY (RequestId) REFERENCES ab.Request(RequestId),
    CONSTRAINT FK_RequestValue_Field
        FOREIGN KEY (FieldId) REFERENCES ab.FormField(FieldId)
);
GO

/* ============================================================================
   9. WORKFLOW RUNTIME
   ============================================================================ */

CREATE TABLE ab.WorkflowInstance
(
    WorkflowInstanceId       BIGINT IDENTITY(1,1) NOT NULL,
    RequestId                BIGINT NOT NULL,
    WorkflowId               INT NOT NULL,
    WorkflowVersionNo        INT NOT NULL,
    CurrentStageId           INT NULL,
    StatusCode               NVARCHAR(50) NOT NULL,
    StartedDate              DATETIME2(3) NOT NULL CONSTRAINT DF_WorkflowInstance_Started DEFAULT SYSUTCDATETIME(),
    CompletedDate            DATETIME2(3) NULL,

    CONSTRAINT PK_WorkflowInstance PRIMARY KEY (WorkflowInstanceId),
    CONSTRAINT FK_WorkflowInstance_Request
        FOREIGN KEY (RequestId) REFERENCES ab.Request(RequestId),
    CONSTRAINT FK_WorkflowInstance_Workflow
        FOREIGN KEY (WorkflowId) REFERENCES ab.Workflow(WorkflowId),
    CONSTRAINT FK_WorkflowInstance_Stage
        FOREIGN KEY (CurrentStageId) REFERENCES ab.WorkflowStage(StageId)
);
GO

CREATE TABLE ab.WorkflowTask
(
    WorkflowTaskId           BIGINT IDENTITY(1,1) NOT NULL,
    WorkflowInstanceId       BIGINT NOT NULL,
    StageId                  INT NOT NULL,
    AssignedUserId            NVARCHAR(100) NULL,
    AssignedRoleId            INT NULL,
    OriginalAssignedUserId    NVARCHAR(100) NULL,
    StatusCode               NVARCHAR(50) NOT NULL,
    DueDate                   DATETIME2(3) NULL,
    CreatedDate               DATETIME2(3) NOT NULL CONSTRAINT DF_WorkflowTask_Created DEFAULT SYSUTCDATETIME(),
    StartedDate               DATETIME2(3) NULL,
    CompletedDate             DATETIME2(3) NULL,
    Comments                  NVARCHAR(MAX) NULL,

    CONSTRAINT PK_WorkflowTask PRIMARY KEY (WorkflowTaskId),
    CONSTRAINT FK_WorkflowTask_Instance
        FOREIGN KEY (WorkflowInstanceId) REFERENCES ab.WorkflowInstance(WorkflowInstanceId),
    CONSTRAINT FK_WorkflowTask_Stage
        FOREIGN KEY (StageId) REFERENCES ab.WorkflowStage(StageId),
    CONSTRAINT FK_WorkflowTask_User
        FOREIGN KEY (AssignedUserId) REFERENCES ab.AppUser(UserId),
    CONSTRAINT FK_WorkflowTask_OriginalUser
        FOREIGN KEY (OriginalAssignedUserId) REFERENCES ab.AppUser(UserId),
    CONSTRAINT FK_WorkflowTask_Role
        FOREIGN KEY (AssignedRoleId) REFERENCES ab.AppRole(RoleId)
);
GO

CREATE TABLE ab.WorkflowAction
(
    WorkflowActionId         BIGINT IDENTITY(1,1) NOT NULL,
    WorkflowTaskId           BIGINT NOT NULL,
    ActionCode               NVARCHAR(50) NOT NULL,
    ActionByUserId            NVARCHAR(100) NOT NULL,
    Comments                  NVARCHAR(MAX) NULL,
    ActionDate               DATETIME2(3) NOT NULL CONSTRAINT DF_WorkflowAction_Date DEFAULT SYSUTCDATETIME(),
    MetadataJson              NVARCHAR(MAX) NULL,

    CONSTRAINT PK_WorkflowAction PRIMARY KEY (WorkflowActionId),
    CONSTRAINT FK_WorkflowAction_Task
        FOREIGN KEY (WorkflowTaskId) REFERENCES ab.WorkflowTask(WorkflowTaskId),
    CONSTRAINT FK_WorkflowAction_User
        FOREIGN KEY (ActionByUserId) REFERENCES ab.AppUser(UserId)
);
GO

/* ============================================================================
   10. DELEGATION
   ============================================================================ */

CREATE TABLE ab.Delegation
(
    DelegationId             BIGINT IDENTITY(1,1) NOT NULL,
    FromUserId               NVARCHAR(100) NOT NULL,
    ToUserId                 NVARCHAR(100) NOT NULL,
    ApplicationId            INT NULL,
    StartDate                DATETIME2(3) NOT NULL,
    EndDate                  DATETIME2(3) NOT NULL,
    Reason                   NVARCHAR(1000) NULL,
    IsActive                 BIT NOT NULL CONSTRAINT DF_Delegation_IsActive DEFAULT (1),
    CreatedBy                NVARCHAR(100) NOT NULL,
    CreatedDate              DATETIME2(3) NOT NULL CONSTRAINT DF_Delegation_CreatedDate DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_Delegation PRIMARY KEY (DelegationId),
    CONSTRAINT FK_Delegation_FromUser
        FOREIGN KEY (FromUserId) REFERENCES ab.AppUser(UserId),
    CONSTRAINT FK_Delegation_ToUser
        FOREIGN KEY (ToUserId) REFERENCES ab.AppUser(UserId),
    CONSTRAINT FK_Delegation_Application
        FOREIGN KEY (ApplicationId) REFERENCES ab.Application(ApplicationId),
    CONSTRAINT CK_Delegation_Dates CHECK (EndDate >= StartDate)
);
GO

/* ============================================================================
   11. ATTACHMENTS / SHAREPOINT
   ============================================================================ */

CREATE TABLE ab.SharePointLibrary
(
    SharePointLibraryId      INT IDENTITY(1,1) NOT NULL,
    ApplicationId            INT NOT NULL,
    SiteUrl                  NVARCHAR(2000) NOT NULL,
    LibraryTitle             NVARCHAR(200) NOT NULL,
    LibraryRelativeUrl       NVARCHAR(1000) NULL,
    DriveId                  NVARCHAR(200) NULL,
    IsActive                 BIT NOT NULL CONSTRAINT DF_SP_Library_IsActive DEFAULT (1),

    CONSTRAINT PK_SharePointLibrary PRIMARY KEY (SharePointLibraryId),
    CONSTRAINT FK_SharePointLibrary_Application
        FOREIGN KEY (ApplicationId) REFERENCES ab.Application(ApplicationId),
    CONSTRAINT UQ_SharePointLibrary UNIQUE (ApplicationId)
);
GO

CREATE TABLE ab.Attachment
(
    AttachmentId             BIGINT IDENTITY(1,1) NOT NULL,
    RequestId                BIGINT NOT NULL,
    SharePointLibraryId      INT NULL,
    FileName                 NVARCHAR(500) NOT NULL,
    OriginalFileName         NVARCHAR(500) NULL,
    ContentType              NVARCHAR(200) NULL,
    FileSizeBytes            BIGINT NULL,
    SharePointItemId         NVARCHAR(200) NULL,
    SharePointUniqueId       NVARCHAR(200) NULL,
    SharePointUrl            NVARCHAR(2000) NULL,
    UploadedByUserId         NVARCHAR(100) NOT NULL,
    UploadedDate             DATETIME2(3) NOT NULL CONSTRAINT DF_Attachment_Date DEFAULT SYSUTCDATETIME(),
    IsDeleted                BIT NOT NULL CONSTRAINT DF_Attachment_IsDeleted DEFAULT (0),

    CONSTRAINT PK_Attachment PRIMARY KEY (AttachmentId),
    CONSTRAINT FK_Attachment_Request
        FOREIGN KEY (RequestId) REFERENCES ab.Request(RequestId),
    CONSTRAINT FK_Attachment_Library
        FOREIGN KEY (SharePointLibraryId) REFERENCES ab.SharePointLibrary(SharePointLibraryId),
    CONSTRAINT FK_Attachment_User
        FOREIGN KEY (UploadedByUserId) REFERENCES ab.AppUser(UserId)
);
GO

/* ============================================================================
   12. HISTORY / AUDIT
   ============================================================================ */

CREATE TABLE ab.RequestHistory
(
    HistoryId                BIGINT IDENTITY(1,1) NOT NULL,
    RequestId                BIGINT NOT NULL,
    UserId                   NVARCHAR(100) NOT NULL,
    ActionCode               NVARCHAR(100) NOT NULL,
    PreviousStatus           NVARCHAR(50) NULL,
    NewStatus                NVARCHAR(50) NULL,
    Comments                 NVARCHAR(MAX) NULL,
    MetadataJson             NVARCHAR(MAX) NULL,
    CreatedDate              DATETIME2(3) NOT NULL CONSTRAINT DF_RequestHistory_Date DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_RequestHistory PRIMARY KEY (HistoryId),
    CONSTRAINT FK_RequestHistory_Request
        FOREIGN KEY (RequestId) REFERENCES ab.Request(RequestId),
    CONSTRAINT FK_RequestHistory_User
        FOREIGN KEY (UserId) REFERENCES ab.AppUser(UserId)
);
GO

CREATE TABLE ab.AuditLog
(
    AuditId                  BIGINT IDENTITY(1,1) NOT NULL,
    ApplicationId            INT NULL,
    RequestId                BIGINT NULL,
    UserId                   NVARCHAR(100) NOT NULL,
    ActionCode               NVARCHAR(100) NOT NULL,
    EntityName               NVARCHAR(200) NULL,
    EntityId                 NVARCHAR(100) NULL,
    OldValueJson             NVARCHAR(MAX) NULL,
    NewValueJson             NVARCHAR(MAX) NULL,
    IpAddress                 NVARCHAR(100) NULL,
    UserAgent                 NVARCHAR(1000) NULL,
    CreatedDate              DATETIME2(3) NOT NULL CONSTRAINT DF_AuditLog_Date DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_AuditLog PRIMARY KEY (AuditId),
    CONSTRAINT FK_AuditLog_Application
        FOREIGN KEY (ApplicationId) REFERENCES ab.Application(ApplicationId),
    CONSTRAINT FK_AuditLog_Request
        FOREIGN KEY (RequestId) REFERENCES ab.Request(RequestId),
    CONSTRAINT FK_AuditLog_User
        FOREIGN KEY (UserId) REFERENCES ab.AppUser(UserId)
);
GO

/* ============================================================================
   13. NOTIFICATIONS
   ============================================================================ */

CREATE TABLE ab.NotificationTemplate
(
    NotificationTemplateId   INT IDENTITY(1,1) NOT NULL,
    ApplicationId            INT NULL,
    TemplateCode             NVARCHAR(100) NOT NULL,
    TemplateName             NVARCHAR(200) NOT NULL,
    Channel                  NVARCHAR(30) NOT NULL,
    SubjectTemplate          NVARCHAR(1000) NULL,
    BodyTemplate             NVARCHAR(MAX) NOT NULL,
    IsActive                 BIT NOT NULL CONSTRAINT DF_NotificationTemplate_IsActive DEFAULT (1),
    CreatedBy                NVARCHAR(100) NOT NULL,
    CreatedDate              DATETIME2(3) NOT NULL CONSTRAINT DF_NotificationTemplate_Date DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_NotificationTemplate PRIMARY KEY (NotificationTemplateId),
    CONSTRAINT FK_NotificationTemplate_Application
        FOREIGN KEY (ApplicationId) REFERENCES ab.Application(ApplicationId),
    CONSTRAINT UQ_NotificationTemplate_Code UNIQUE (ApplicationId, TemplateCode)
);
GO

CREATE TABLE ab.NotificationQueue
(
    NotificationQueueId      BIGINT IDENTITY(1,1) NOT NULL,
    ApplicationId            INT NULL,
    RequestId                BIGINT NULL,
    TemplateId               INT NULL,
    RecipientUserId          NVARCHAR(100) NULL,
    RecipientEmail            NVARCHAR(320) NULL,
    Channel                  NVARCHAR(30) NOT NULL,
    Subject                  NVARCHAR(1000) NULL,
    Body                     NVARCHAR(MAX) NULL,
    StatusCode               NVARCHAR(30) NOT NULL CONSTRAINT DF_NotificationQueue_Status DEFAULT ('PENDING'),
    RetryCount               INT NOT NULL CONSTRAINT DF_NotificationQueue_Retry DEFAULT (0),
    ScheduledDate             DATETIME2(3) NULL,
    SentDate                  DATETIME2(3) NULL,
    ErrorMessage             NVARCHAR(2000) NULL,
    CreatedDate              DATETIME2(3) NOT NULL CONSTRAINT DF_NotificationQueue_Date DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_NotificationQueue PRIMARY KEY (NotificationQueueId),
    CONSTRAINT FK_NotificationQueue_Application
        FOREIGN KEY (ApplicationId) REFERENCES ab.Application(ApplicationId),
    CONSTRAINT FK_NotificationQueue_Request
        FOREIGN KEY (RequestId) REFERENCES ab.Request(RequestId),
    CONSTRAINT FK_NotificationQueue_Template
        FOREIGN KEY (TemplateId) REFERENCES ab.NotificationTemplate(NotificationTemplateId),
    CONSTRAINT FK_NotificationQueue_User
        FOREIGN KEY (RecipientUserId) REFERENCES ab.AppUser(UserId)
);
GO

/* ============================================================================
   14. REPORT BUILDER
   ============================================================================ */

CREATE TABLE ab.Report
(
    ReportId                 INT IDENTITY(1,1) NOT NULL,
    ApplicationId            INT NOT NULL,
    ReportCode               NVARCHAR(100) NOT NULL,
    ReportName               NVARCHAR(200) NOT NULL,
    Description              NVARCHAR(1000) NULL,
    QueryJson                NVARCHAR(MAX) NULL,
    ConfigurationJson        NVARCHAR(MAX) NULL,
    IsPublic                 BIT NOT NULL CONSTRAINT DF_Report_IsPublic DEFAULT (0),
    IsActive                 BIT NOT NULL CONSTRAINT DF_Report_IsActive DEFAULT (1),
    CreatedBy                NVARCHAR(100) NOT NULL,
    CreatedDate              DATETIME2(3) NOT NULL CONSTRAINT DF_Report_Date DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_Report PRIMARY KEY (ReportId),
    CONSTRAINT FK_Report_Application
        FOREIGN KEY (ApplicationId) REFERENCES ab.Application(ApplicationId),
    CONSTRAINT UQ_Report_Code UNIQUE (ApplicationId, ReportCode)
);
GO

CREATE TABLE ab.ReportColumn
(
    ReportColumnId           INT IDENTITY(1,1) NOT NULL,
    ReportId                 INT NOT NULL,
    FieldKey                 NVARCHAR(100) NULL,
    ColumnName               NVARCHAR(200) NOT NULL,
    DataType                 NVARCHAR(50) NULL,
    AggregateType             NVARCHAR(30) NULL,
    DisplayOrder              INT NOT NULL CONSTRAINT DF_ReportColumn_Order DEFAULT (0),
    IsVisible                BIT NOT NULL CONSTRAINT DF_ReportColumn_Visible DEFAULT (1),

    CONSTRAINT PK_ReportColumn PRIMARY KEY (ReportColumnId),
    CONSTRAINT FK_ReportColumn_Report
        FOREIGN KEY (ReportId) REFERENCES ab.Report(ReportId)
);
GO

CREATE TABLE ab.ReportFilter
(
    ReportFilterId            INT IDENTITY(1,1) NOT NULL,
    ReportId                  INT NOT NULL,
    FieldKey                  NVARCHAR(100) NOT NULL,
    Operator                  NVARCHAR(30) NOT NULL,
    DefaultValue              NVARCHAR(MAX) NULL,
    DisplayOrder              INT NOT NULL CONSTRAINT DF_ReportFilter_Order DEFAULT (0),
    IsRequired                BIT NOT NULL CONSTRAINT DF_ReportFilter_Required DEFAULT (0),

    CONSTRAINT PK_ReportFilter PRIMARY KEY (ReportFilterId),
    CONSTRAINT FK_ReportFilter_Report
        FOREIGN KEY (ReportId) REFERENCES ab.Report(ReportId)
);
GO

/* ============================================================================
   15. PDF TEMPLATES
   ============================================================================ */

CREATE TABLE ab.PdfTemplate
(
    PdfTemplateId             INT IDENTITY(1,1) NOT NULL,
    ApplicationId             INT NOT NULL,
    TemplateCode              NVARCHAR(100) NOT NULL,
    TemplateName              NVARCHAR(200) NOT NULL,
    TemplateHtml              NVARCHAR(MAX) NULL,
    ConfigurationJson         NVARCHAR(MAX) NULL,
    VersionNo                 INT NOT NULL CONSTRAINT DF_PdfTemplate_Version DEFAULT (1),
    IsActive                  BIT NOT NULL CONSTRAINT DF_PdfTemplate_IsActive DEFAULT (1),
    CreatedBy                 NVARCHAR(100) NOT NULL,
    CreatedDate               DATETIME2(3) NOT NULL CONSTRAINT DF_PdfTemplate_Date DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_PdfTemplate PRIMARY KEY (PdfTemplateId),
    CONSTRAINT FK_PdfTemplate_Application
        FOREIGN KEY (ApplicationId) REFERENCES ab.Application(ApplicationId),
    CONSTRAINT UQ_PdfTemplate_Code UNIQUE (ApplicationId, TemplateCode, VersionNo)
);
GO

/* ============================================================================
   16. INDEXES
   ============================================================================ */

CREATE INDEX IX_Application_Status
    ON ab.Application(StatusCode, IsActive, DisplayOrder);

CREATE INDEX IX_Form_Application
    ON ab.Form(ApplicationId, IsActive, StatusCode);

CREATE INDEX IX_FormSection_Form
    ON ab.FormSection(FormId, DisplayOrder);

CREATE INDEX IX_FormField_Section
    ON ab.FormField(SectionId, DisplayOrder);

CREATE INDEX IX_FieldOption_Field
    ON ab.FieldOption(FieldId, DisplayOrder);

CREATE INDEX IX_BusinessRule_Application
    ON ab.BusinessRule(ApplicationId, ExecutionOrder, IsActive);

CREATE INDEX IX_Workflow_Application
    ON ab.Workflow(ApplicationId, IsPublished, IsActive);

CREATE INDEX IX_WorkflowStage_Workflow
    ON ab.WorkflowStage(WorkflowId, DisplayOrder);

CREATE INDEX IX_WorkflowTransition_From
    ON ab.WorkflowTransition(FromStageId, IsActive);

CREATE INDEX IX_WorkflowApprover_Stage
    ON ab.WorkflowApprover(StageId, SequenceNo);

CREATE INDEX IX_AppUser_Manager
    ON ab.AppUser(ManagerUserId);

CREATE INDEX IX_AppUser_Organization
    ON ab.AppUser(OrganizationUnitId);

CREATE INDEX IX_UserRole_User
    ON ab.UserRole(UserId, IsActive);

CREATE INDEX IX_UserRole_Application
    ON ab.UserRole(ApplicationId, RoleId, IsActive);

CREATE INDEX IX_ApplicationPermission_AppRole
    ON ab.ApplicationPermission(ApplicationId, RoleId, IsActive);

CREATE INDEX IX_Request_Application_Status
    ON ab.Request(ApplicationId, StatusCode, CreatedDate DESC);

CREATE INDEX IX_Request_CreatedBy
    ON ab.Request(CreatedByUserId, CreatedDate DESC);

CREATE INDEX IX_Request_Owner
    ON ab.Request(CurrentOwnerUserId, StatusCode);

CREATE INDEX IX_Request_NotDeleted
    ON ab.Request(ApplicationId, IsDeleted, CreatedDate DESC);

CREATE INDEX IX_RequestValue_Request_Field
    ON ab.RequestValue(RequestId, FieldId);

CREATE INDEX IX_RequestValue_Field_String
    ON ab.RequestValue(FieldId, StringValue);

CREATE INDEX IX_WorkflowInstance_Request
    ON ab.WorkflowInstance(RequestId);

CREATE INDEX IX_WorkflowInstance_CurrentStage
    ON ab.WorkflowInstance(CurrentStageId, StatusCode);

CREATE INDEX IX_WorkflowTask_AssignedUser
    ON ab.WorkflowTask(AssignedUserId, StatusCode, DueDate);

CREATE INDEX IX_WorkflowTask_Role
    ON ab.WorkflowTask(AssignedRoleId, StatusCode, DueDate);

CREATE INDEX IX_WorkflowTask_Instance
    ON ab.WorkflowTask(WorkflowInstanceId, StatusCode);

CREATE INDEX IX_WorkflowAction_Task
    ON ab.WorkflowAction(WorkflowTaskId, ActionDate DESC);

CREATE INDEX IX_Delegation_UserDates
    ON ab.Delegation(FromUserId, StartDate, EndDate, IsActive);

CREATE INDEX IX_Attachment_Request
    ON ab.Attachment(RequestId, IsDeleted);

CREATE INDEX IX_RequestHistory_Request
    ON ab.RequestHistory(RequestId, CreatedDate DESC);

CREATE INDEX IX_AuditLog_Request
    ON ab.AuditLog(RequestId, CreatedDate DESC);

CREATE INDEX IX_AuditLog_User
    ON ab.AuditLog(UserId, CreatedDate DESC);

CREATE INDEX IX_NotificationQueue_Status
    ON ab.NotificationQueue(StatusCode, ScheduledDate);

CREATE INDEX IX_Report_Application
    ON ab.Report(ApplicationId, IsActive);
GO

/* ============================================================================
   17. SEED ROLES
   ============================================================================ */

INSERT INTO ab.AppRole
(
    RoleCode, RoleName, Description, IsSystemRole
)
SELECT v.RoleCode, v.RoleName, v.Description, 1
FROM
(
    VALUES
    ('ADMIN',              'Administrator',       'Full platform administration'),
    ('APPLICATION_ADMIN',  'Application Admin',   'Application configuration'),
    ('HR',                 'HR',                  'HR operational role'),
    ('DIVISION_HEAD',      'Division Head',       'Division level approver'),
    ('DEPARTMENT_HEAD',    'Department Head',     'Department level approver'),
    ('REPORTING_MANAGER',  'Reporting Manager',   'Reporting manager'),
    ('EMPLOYEE',           'Employee',            'Standard employee'),
    ('AUDITOR',            'Auditor',             'Read-only audit access'),
    ('INTERVIEWER',        'Interviewer',         'Interview/feedback role')
) v(RoleCode, RoleName, Description)
WHERE NOT EXISTS
(
    SELECT 1
    FROM ab.AppRole r
    WHERE r.RoleCode = v.RoleCode
);
GO

/* ============================================================================
   18. SEED PERMISSIONS
   ============================================================================ */

INSERT INTO ab.Permission
(
    PermissionCode, PermissionName, Description
)
SELECT v.PermissionCode, v.PermissionName, v.Description
FROM
(
    VALUES
    ('APPLICATION_VIEW',       'View Application',       'View application'),
    ('APPLICATION_CREATE',     'Create Request',        'Create request'),
    ('APPLICATION_EDIT',       'Edit Request',          'Edit request'),
    ('APPLICATION_DELETE',     'Delete Request',        'Delete request'),
    ('APPLICATION_SUBMIT',     'Submit Request',        'Submit request'),
    ('APPLICATION_APPROVE',    'Approve Request',       'Approve request'),
    ('APPLICATION_REJECT',     'Reject Request',        'Reject request'),
    ('APPLICATION_RETURN',     'Return Request',        'Return request'),
    ('APPLICATION_EXPORT',     'Export Data',           'Export data'),
    ('APPLICATION_PDF',        'Generate PDF',           'Generate PDF'),
    ('APPLICATION_ALL_RECORDS','View All Records',      'View all records'),
    ('FORM_ADMIN',             'Form Administration',   'Configure forms'),
    ('WORKFLOW_ADMIN',         'Workflow Administration','Configure workflows'),
    ('ROLE_ADMIN',             'Role Administration',   'Configure roles'),
    ('PERMISSION_ADMIN',       'Permission Administration','Configure permissions'),
    ('USER_ADMIN',             'User Administration',   'Configure users'),
    ('DELEGATION_ADMIN',       'Delegation Administration','Configure delegation'),
    ('REPORT_ADMIN',           'Report Administration', 'Configure reports'),
    ('AUDIT_VIEW',             'View Audit',             'View audit history'),
    ('MASTERDATA_ADMIN',       'Master Data Administration','Configure master data'),
    ('APPLICATION_ADMIN',      'Application Administration','Configure applications')
) v(PermissionCode, PermissionName, Description)
WHERE NOT EXISTS
(
    SELECT 1
    FROM ab.Permission p
    WHERE p.PermissionCode = v.PermissionCode
);
GO

/* ============================================================================
   19. SEED ROLE/PERMISSION MATRIX
   ============================================================================ */

INSERT INTO ab.RolePermission(RoleId, PermissionId)
SELECT r.RoleId, p.PermissionId
FROM ab.AppRole r
CROSS JOIN ab.Permission p
WHERE
    (
        r.RoleCode = 'ADMIN'
    )
    OR
    (
        r.RoleCode = 'APPLICATION_ADMIN'
        AND p.PermissionCode IN
        (
            'APPLICATION_VIEW',
            'APPLICATION_ALL_RECORDS',
            'FORM_ADMIN',
            'WORKFLOW_ADMIN',
            'DELEGATION_ADMIN',
            'REPORT_ADMIN',
            'MASTERDATA_ADMIN',
            'APPLICATION_ADMIN'
        )
    )
    OR
    (
        r.RoleCode IN ('DIVISION_HEAD','DEPARTMENT_HEAD','REPORTING_MANAGER')
        AND p.PermissionCode IN
        (
            'APPLICATION_VIEW',
            'APPLICATION_CREATE',
            'APPLICATION_EDIT',
            'APPLICATION_SUBMIT',
            'APPLICATION_APPROVE',
            'APPLICATION_REJECT',
            'APPLICATION_RETURN',
            'APPLICATION_PDF',
            'APPLICATION_EXPORT'
        )
    )
    OR
    (
        r.RoleCode = 'EMPLOYEE'
        AND p.PermissionCode IN
        (
            'APPLICATION_VIEW',
            'APPLICATION_CREATE',
            'APPLICATION_EDIT',
            'APPLICATION_DELETE',
            'APPLICATION_SUBMIT',
            'APPLICATION_PDF'
        )
    )
    OR
    (
        r.RoleCode = 'AUDITOR'
        AND p.PermissionCode IN
        (
            'APPLICATION_VIEW',
            'APPLICATION_ALL_RECORDS',
            'APPLICATION_EXPORT',
            'APPLICATION_PDF',
            'AUDIT_VIEW'
        )
    )
    OR
    (
        r.RoleCode = 'HR'
        AND p.PermissionCode IN
        (
            'APPLICATION_VIEW',
            'APPLICATION_CREATE',
            'APPLICATION_EDIT',
            'APPLICATION_SUBMIT',
            'APPLICATION_APPROVE',
            'APPLICATION_REJECT',
            'APPLICATION_RETURN',
            'APPLICATION_ALL_RECORDS',
            'APPLICATION_EXPORT',
            'APPLICATION_PDF'
        )
    )
    OR
    (
        r.RoleCode = 'INTERVIEWER'
        AND p.PermissionCode IN
        (
            'APPLICATION_VIEW',
            'APPLICATION_EDIT',
            'APPLICATION_SUBMIT',
            'APPLICATION_PDF'
        )
    )
AND NOT EXISTS
(
    SELECT 1
    FROM ab.RolePermission rp
    WHERE rp.RoleId = r.RoleId
      AND rp.PermissionId = p.PermissionId
);
GO

/* ============================================================================
   20. SEED MASTER DATA
   ============================================================================ */

INSERT INTO ab.MasterData
(
    MasterCode, MasterName, Description, CreatedBy
)
SELECT 'REQUEST_STATUS', 'Request Status', 'Common request statuses', 'SYSTEM'
WHERE NOT EXISTS
(
    SELECT 1 FROM ab.MasterData WHERE MasterCode = 'REQUEST_STATUS'
);

INSERT INTO ab.MasterData
(
    MasterCode, MasterName, Description, CreatedBy
)
SELECT 'TRAVEL_TYPE', 'Travel Type', 'Travel types', 'SYSTEM'
WHERE NOT EXISTS
(
    SELECT 1 FROM ab.MasterData WHERE MasterCode = 'TRAVEL_TYPE'
);

INSERT INTO ab.MasterData
(
    MasterCode, MasterName, Description, CreatedBy
)
SELECT 'CONTROL_TYPE', 'Control Type', 'Supported dynamic form controls', 'SYSTEM'
WHERE NOT EXISTS
(
    SELECT 1 FROM ab.MasterData WHERE MasterCode = 'CONTROL_TYPE'
);
GO

DECLARE @RequestStatusMasterId INT =
(
    SELECT MasterDataId FROM ab.MasterData WHERE MasterCode = 'REQUEST_STATUS'
);

INSERT INTO ab.MasterDataItem
(
    MasterDataId, ItemCode, ItemName, DisplayOrder, CreatedDate
)
SELECT @RequestStatusMasterId, v.ItemCode, v.ItemName, v.DisplayOrder, SYSUTCDATETIME()
FROM
(
    VALUES
    ('DRAFT','Draft',1),
    ('SUBMITTED','Submitted',2),
    ('PENDING_APPROVAL','Pending Approval',3),
    ('APPROVED','Approved',4),
    ('REJECTED','Rejected',5),
    ('RETURNED','Returned',6),
    ('CANCELLED','Cancelled',7),
    ('COMPLETED','Completed',8)
) v(ItemCode, ItemName, DisplayOrder)
WHERE NOT EXISTS
(
    SELECT 1
    FROM ab.MasterDataItem mdi
    WHERE mdi.MasterDataId = @RequestStatusMasterId
      AND mdi.ItemCode = v.ItemCode
);
GO

DECLARE @TravelMasterId INT =
(
    SELECT MasterDataId FROM ab.MasterData WHERE MasterCode = 'TRAVEL_TYPE'
);

INSERT INTO ab.MasterDataItem
(
    MasterDataId, ItemCode, ItemName, DisplayOrder
)
SELECT @TravelMasterId, v.ItemCode, v.ItemName, v.DisplayOrder
FROM
(
    VALUES
    ('DOMESTIC','Domestic',1),
    ('INTERNATIONAL','International',2)
) v(ItemCode, ItemName, DisplayOrder)
WHERE NOT EXISTS
(
    SELECT 1
    FROM ab.MasterDataItem mdi
    WHERE mdi.MasterDataId = @TravelMasterId
      AND mdi.ItemCode = v.ItemCode
);
GO

DECLARE @ControlMasterId INT =
(
    SELECT MasterDataId FROM ab.MasterData WHERE MasterCode = 'CONTROL_TYPE'
);

INSERT INTO ab.MasterDataItem
(
    MasterDataId, ItemCode, ItemName, DisplayOrder
)
SELECT @ControlMasterId, v.ItemCode, v.ItemName, v.DisplayOrder
FROM
(
    VALUES
    ('text','Text Box',1),
    ('textarea','Text Area',2),
    ('number','Number',3),
    ('decimal','Decimal',4),
    ('currency','Currency',5),
    ('date','Date',6),
    ('datetime','Date Time',7),
    ('time','Time',8),
    ('select','Dropdown',9),
    ('multiselect','Multi Select',10),
    ('radio','Radio',11),
    ('checkbox','Checkbox',12),
    ('switch','Switch',13),
    ('autocomplete','Auto Complete',14),
    ('userpicker','User Picker',15),
    ('employeePicker','Employee Picker',16),
    ('departmentpicker','Department Picker',17),
    ('lookup','Lookup',18),
    ('cascadingSelect','Cascading Dropdown',19),
    ('richtext','Rich Text',20),
    ('file','File',21),
    ('table','Dynamic Table',22),
    ('repeater','Repeating Section',23),
    ('parentChildGrid','Parent Child Grid',24),
    ('formula','Formula',25),
    ('label','Label',26),
    ('heading','Heading',27)
) v(ItemCode, ItemName, DisplayOrder)
WHERE NOT EXISTS
(
    SELECT 1
    FROM ab.MasterDataItem mdi
    WHERE mdi.MasterDataId = @ControlMasterId
      AND mdi.ItemCode = v.ItemCode
);
GO

/* ============================================================================
   21. OPTIONAL DEMO APPLICATION
   ============================================================================ */

IF NOT EXISTS
(
    SELECT 1 FROM ab.Application WHERE ApplicationCode = 'TRAVEL'
)
BEGIN
    INSERT INTO ab.Application
    (
        ApplicationCode,
        ApplicationName,
        Description,
        IconName,
        ThemeColor,
        SharePointLibrary,
        StatusCode,
        DisplayOrder,
        CreatedBy
    )
    VALUES
    (
        'TRAVEL',
        'Travel Request',
        'Employee travel request application',
        'CarOutlined',
        '#C00000',
        'TravelDocuments',
        'PUBLISHED',
        1,
        'SYSTEM'
    );
END;
GO

DECLARE @TravelAppId INT =
(
    SELECT ApplicationId
    FROM ab.Application
    WHERE ApplicationCode = 'TRAVEL'
);

IF NOT EXISTS
(
    SELECT 1 FROM ab.Form WHERE ApplicationId = @TravelAppId AND FormCode = 'TRAVEL_REQUEST'
)
BEGIN
    INSERT INTO ab.Form
    (
        ApplicationId,
        FormCode,
        FormName,
        Description,
        VersionNo,
        StatusCode,
        IsPublished,
        LayoutJson,
        CreatedBy
    )
    VALUES
    (
        @TravelAppId,
        'TRAVEL_REQUEST',
        'Travel Request',
        'Travel request form',
        1,
        'PUBLISHED',
        1,
        '{"layout":"vertical","columns":24}',
        'SYSTEM'
    );
END;
GO

DECLARE @TravelAppId2 INT =
(
    SELECT ApplicationId FROM ab.Application WHERE ApplicationCode = 'TRAVEL'
);

DECLARE @TravelFormId INT =
(
    SELECT FormId
    FROM ab.Form
    WHERE ApplicationId = @TravelAppId2
      AND FormCode = 'TRAVEL_REQUEST'
);

IF NOT EXISTS
(
    SELECT 1 FROM ab.FormSection
    WHERE FormId = @TravelFormId AND SectionKey = 'EMPLOYEE'
)
BEGIN
    INSERT INTO ab.FormSection
    (
        FormId, SectionKey, SectionName, DisplayOrder
    )
    VALUES
    (
        @TravelFormId, 'EMPLOYEE', 'Employee Information', 1
    );
END;

IF NOT EXISTS
(
    SELECT 1 FROM ab.FormSection
    WHERE FormId = @TravelFormId AND SectionKey = 'TRAVEL'
)
BEGIN
    INSERT INTO ab.FormSection
    (
        FormId, SectionKey, SectionName, DisplayOrder
    )
    VALUES
    (
        @TravelFormId, 'TRAVEL', 'Travel Details', 2
    );
END;
GO

/* ============================================================================
   22. DEMO FORM FIELDS
   ============================================================================ */

DECLARE @TravelFormId2 INT =
(
    SELECT FormId
    FROM ab.Form
    WHERE FormCode = 'TRAVEL_REQUEST'
);

DECLARE @EmployeeSectionId INT =
(
    SELECT SectionId
    FROM ab.FormSection
    WHERE FormId = @TravelFormId2
      AND SectionKey = 'EMPLOYEE'
);

DECLARE @TravelSectionId INT =
(
    SELECT SectionId
    FROM ab.FormSection
    WHERE FormId = @TravelFormId2
      AND SectionKey = 'TRAVEL'
);

IF NOT EXISTS
(
    SELECT 1 FROM ab.FormField
    WHERE SectionId = @EmployeeSectionId AND FieldKey = 'employeeName'
)
BEGIN
    INSERT INTO ab.FormField
    (
        SectionId, FieldKey, FieldLabel, ControlType, DataType,
        WidthSpan, DisplayOrder, IsRequired, IsReadonly, ConfigurationJson
    )
    VALUES
    (
        @EmployeeSectionId,
        'employeeName',
        'Employee Name',
        'employeePicker',
        'string',
        12, 1, 1, 1,
        '{"source":"entra","allowCurrentUser":true}'
    );
END;

IF NOT EXISTS
(
    SELECT 1 FROM ab.FormField
    WHERE SectionId = @EmployeeSectionId AND FieldKey = 'department'
)
BEGIN
    INSERT INTO ab.FormField
    (
        SectionId, FieldKey, FieldLabel, ControlType, DataType,
        WidthSpan, DisplayOrder, IsRequired
    )
    VALUES
    (
        @EmployeeSectionId,
        'department',
        'Department',
        'departmentpicker',
        'string',
        12, 2, 1
    );
END;

IF NOT EXISTS
(
    SELECT 1 FROM ab.FormField
    WHERE SectionId = @TravelSectionId AND FieldKey = 'travelType'
)
BEGIN
    INSERT INTO ab.FormField
    (
        SectionId, FieldKey, FieldLabel, ControlType, DataType,
        WidthSpan, DisplayOrder, IsRequired, DataSourceJson
    )
    VALUES
    (
        @TravelSectionId,
        'travelType',
        'Travel Type',
        'select',
        'string',
        12, 1, 1,
        '{"source":"master","masterCode":"TRAVEL_TYPE"}'
    );
END;

IF NOT EXISTS
(
    SELECT 1 FROM ab.FormField
    WHERE SectionId = @TravelSectionId AND FieldKey = 'fromDate'
)
BEGIN
    INSERT INTO ab.FormField
    (
        SectionId, FieldKey, FieldLabel, ControlType, DataType,
        WidthSpan, DisplayOrder, IsRequired
    )
    VALUES
    (
        @TravelSectionId,
        'fromDate',
        'From Date',
        'date',
        'date',
        12, 2, 1
    );
END;

IF NOT EXISTS
(
    SELECT 1 FROM ab.FormField
    WHERE SectionId = @TravelSectionId AND FieldKey = 'toDate'
)
BEGIN
    INSERT INTO ab.FormField
    (
        SectionId, FieldKey, FieldLabel, ControlType, DataType,
        WidthSpan, DisplayOrder, IsRequired
    )
    VALUES
    (
        @TravelSectionId,
        'toDate',
        'To Date',
        'date',
        'date',
        12, 3, 1
    );
END;

IF NOT EXISTS
(
    SELECT 1 FROM ab.FormField
    WHERE SectionId = @TravelSectionId AND FieldKey = 'reason'
)
BEGIN
    INSERT INTO ab.FormField
    (
        SectionId, FieldKey, FieldLabel, ControlType, DataType,
        WidthSpan, DisplayOrder, IsRequired
    )
    VALUES
    (
        @TravelSectionId,
        'reason',
        'Reason',
        'textarea',
        'string',
        24, 4, 1
    );
END;
GO

/* ============================================================================
   23. DEMO WORKFLOW
   ============================================================================ */

DECLARE @TravelAppId3 INT =
(
    SELECT ApplicationId FROM ab.Application WHERE ApplicationCode = 'TRAVEL'
);

IF NOT EXISTS
(
    SELECT 1 FROM ab.Workflow
    WHERE ApplicationId = @TravelAppId3
      AND WorkflowCode = 'TRAVEL_APPROVAL'
      AND VersionNo = 1
)
BEGIN
    INSERT INTO ab.Workflow
    (
        ApplicationId,
        WorkflowCode,
        WorkflowName,
        Description,
        VersionNo,
        StatusCode,
        IsPublished,
        CreatedBy
    )
    VALUES
    (
        @TravelAppId3,
        'TRAVEL_APPROVAL',
        'Travel Approval Workflow',
        'Reporting Manager -> Department Head -> Division Head',
        1,
        'PUBLISHED',
        1,
        'SYSTEM'
    );
END;
GO

DECLARE @TravelWorkflowId INT =
(
    SELECT WorkflowId
    FROM ab.Workflow
    WHERE WorkflowCode = 'TRAVEL_APPROVAL'
      AND VersionNo = 1
);

IF NOT EXISTS
(
    SELECT 1 FROM ab.WorkflowStage
    WHERE WorkflowId = @TravelWorkflowId
      AND StageCode = 'SUBMIT'
)
BEGIN
    INSERT INTO ab.WorkflowStage
    (
        WorkflowId, StageCode, StageName, StageType,
        DisplayOrder, IsStartStage
    )
    VALUES
    (
        @TravelWorkflowId, 'SUBMIT', 'Submit', 'START',
        1, 1
    );
END;

IF NOT EXISTS
(
    SELECT 1 FROM ab.WorkflowStage
    WHERE WorkflowId = @TravelWorkflowId
      AND StageCode = 'REPORTING_MANAGER'
)
BEGIN
    INSERT INTO ab.WorkflowStage
    (
        WorkflowId, StageCode, StageName, StageType,
        ApprovalMode, DisplayOrder
    )
    VALUES
    (
        @TravelWorkflowId,
        'REPORTING_MANAGER',
        'Reporting Manager',
        'APPROVAL',
        'ALL',
        2
    );
END;

IF NOT EXISTS
(
    SELECT 1 FROM ab.WorkflowStage
    WHERE WorkflowId = @TravelWorkflowId
      AND StageCode = 'DEPARTMENT_HEAD'
)
BEGIN
    INSERT INTO ab.WorkflowStage
    (
        WorkflowId, StageCode, StageName, StageType,
        ApprovalMode, DisplayOrder
    )
    VALUES
    (
        @TravelWorkflowId,
        'DEPARTMENT_HEAD',
        'Department Head',
        'APPROVAL',
        'ALL',
        3
    );
END;

IF NOT EXISTS
(
    SELECT 1 FROM ab.WorkflowStage
    WHERE WorkflowId = @TravelWorkflowId
      AND StageCode = 'DIVISION_HEAD'
)
BEGIN
    INSERT INTO ab.WorkflowStage
    (
        WorkflowId, StageCode, StageName, StageType,
        ApprovalMode, DisplayOrder
    )
    VALUES
    (
        @TravelWorkflowId,
        'DIVISION_HEAD',
        'Division Head',
        'APPROVAL',
        'ALL',
        4
    );
END;

IF NOT EXISTS
(
    SELECT 1 FROM ab.WorkflowStage
    WHERE WorkflowId = @TravelWorkflowId
      AND StageCode = 'COMPLETE'
)
BEGIN
    INSERT INTO ab.WorkflowStage
    (
        WorkflowId, StageCode, StageName, StageType,
        DisplayOrder, IsEndStage
    )
    VALUES
    (
        @TravelWorkflowId,
        'COMPLETE',
        'Completed',
        'END',
        5,
        1
    );
END;
GO

/* ============================================================================
   24. DEMO WORKFLOW APPROVERS
   ============================================================================ */

DECLARE @WFId INT =
(
    SELECT WorkflowId
    FROM ab.Workflow
    WHERE WorkflowCode = 'TRAVEL_APPROVAL'
      AND VersionNo = 1
);

DECLARE @RMStage INT =
(
    SELECT StageId FROM ab.WorkflowStage
    WHERE WorkflowId = @WFId AND StageCode = 'REPORTING_MANAGER'
);

DECLARE @DHStage INT =
(
    SELECT StageId FROM ab.WorkflowStage
    WHERE WorkflowId = @WFId AND StageCode = 'DEPARTMENT_HEAD'
);

DECLARE @DivHStage INT =
(
    SELECT StageId FROM ab.WorkflowStage
    WHERE WorkflowId = @WFId AND StageCode = 'DIVISION_HEAD'
);

IF NOT EXISTS
(
    SELECT 1 FROM ab.WorkflowApprover
    WHERE StageId = @RMStage
)
BEGIN
    INSERT INTO ab.WorkflowApprover
    (
        StageId, ApproverType, ApproverValue, ApprovalMode, SequenceNo
    )
    VALUES
    (
        @RMStage, 'REPORTING_MANAGER', NULL, 'ALL', 1
    );
END;

IF NOT EXISTS
(
    SELECT 1 FROM ab.WorkflowApprover
    WHERE StageId = @DHStage
)
BEGIN
    INSERT INTO ab.WorkflowApprover
    (
        StageId, ApproverType, ApproverValue, ApprovalMode, SequenceNo
    )
    VALUES
    (
        @DHStage, 'DEPARTMENT_HEAD', NULL, 'ALL', 1
    );
END;

IF NOT EXISTS
(
    SELECT 1 FROM ab.WorkflowApprover
    WHERE StageId = @DivHStage
)
BEGIN
    INSERT INTO ab.WorkflowApprover
    (
        StageId, ApproverType, ApproverValue, ApprovalMode, SequenceNo
    )
    VALUES
    (
        @DivHStage, 'DIVISION_HEAD', NULL, 'ALL', 1
    );
END;
GO

/* ============================================================================
   25. DEMO WORKFLOW TRANSITIONS
   ============================================================================ */

DECLARE @WFId2 INT =
(
    SELECT WorkflowId
    FROM ab.Workflow
    WHERE WorkflowCode = 'TRAVEL_APPROVAL'
      AND VersionNo = 1
);

DECLARE @SubmitStage INT =
(
    SELECT StageId FROM ab.WorkflowStage
    WHERE WorkflowId = @WFId2 AND StageCode = 'SUBMIT'
);

DECLARE @RMStage2 INT =
(
    SELECT StageId FROM ab.WorkflowStage
    WHERE WorkflowId = @WFId2 AND StageCode = 'REPORTING_MANAGER'
);

DECLARE @DHStage2 INT =
(
    SELECT StageId FROM ab.WorkflowStage
    WHERE WorkflowId = @WFId2 AND StageCode = 'DEPARTMENT_HEAD'
);

DECLARE @DivStage2 INT =
(
    SELECT StageId FROM ab.WorkflowStage
    WHERE WorkflowId = @WFId2 AND StageCode = 'DIVISION_HEAD'
);

DECLARE @CompleteStage INT =
(
    SELECT StageId FROM ab.WorkflowStage
    WHERE WorkflowId = @WFId2 AND StageCode = 'COMPLETE'
);

IF NOT EXISTS
(
    SELECT 1 FROM ab.WorkflowTransition
    WHERE WorkflowId = @WFId2 AND TransitionCode = 'SUBMIT_TO_RM'
)
BEGIN
    INSERT INTO ab.WorkflowTransition
    (
        WorkflowId, FromStageId, ToStageId,
        TransitionCode, TransitionName, ActionCode
    )
    VALUES
    (
        @WFId2, @SubmitStage, @RMStage2,
        'SUBMIT_TO_RM', 'Submit to Reporting Manager', 'SUBMIT'
    );
END;

IF NOT EXISTS
(
    SELECT 1 FROM ab.WorkflowTransition
    WHERE WorkflowId = @WFId2 AND TransitionCode = 'RM_TO_DH'
)
BEGIN
    INSERT INTO ab.WorkflowTransition
    (
        WorkflowId, FromStageId, ToStageId,
        TransitionCode, TransitionName, ActionCode
    )
    VALUES
    (
        @WFId2, @RMStage2, @DHStage2,
        'RM_TO_DH', 'Reporting Manager Approval', 'APPROVE'
    );
END;

IF NOT EXISTS
(
    SELECT 1 FROM ab.WorkflowTransition
    WHERE WorkflowId = @WFId2 AND TransitionCode = 'DH_TO_DIV'
)
BEGIN
    INSERT INTO ab.WorkflowTransition
    (
        WorkflowId, FromStageId, ToStageId,
        TransitionCode, TransitionName, ActionCode
    )
    VALUES
    (
        @WFId2, @DHStage2, @DivStage2,
        'DH_TO_DIV', 'Department Head Approval', 'APPROVE'
    );
END;

IF NOT EXISTS
(
    SELECT 1 FROM ab.WorkflowTransition
    WHERE WorkflowId = @WFId2 AND TransitionCode = 'DIV_TO_COMPLETE'
)
BEGIN
    INSERT INTO ab.WorkflowTransition
    (
        WorkflowId, FromStageId, ToStageId,
        TransitionCode, TransitionName, ActionCode
    )
    VALUES
    (
        @WFId2, @DivStage2, @CompleteStage,
        'DIV_TO_COMPLETE', 'Division Head Approval', 'APPROVE'
    );
END;
GO

/* ============================================================================
   26. DEMO SHAREPOINT LIBRARY
   ============================================================================ */

DECLARE @TravelApplicationId INT =
(
    SELECT ApplicationId FROM ab.Application WHERE ApplicationCode = 'TRAVEL'
);

IF NOT EXISTS
(
    SELECT 1 FROM ab.SharePointLibrary
    WHERE ApplicationId = @TravelApplicationId
)
BEGIN
    INSERT INTO ab.SharePointLibrary
    (
        ApplicationId,
        SiteUrl,
        LibraryTitle,
        LibraryRelativeUrl
    )
    VALUES
    (
        @TravelApplicationId,
        'https://YOURTENANT.sharepoint.com/sites/ApplicationPortal',
        'TravelDocuments',
        '/sites/ApplicationPortal/TravelDocuments'
    );
END;
GO

/* ============================================================================
   27. VIEWS
   ============================================================================ */

CREATE OR ALTER VIEW ab.vw_ApplicationDashboard
AS
SELECT
    a.ApplicationId,
    a.ApplicationCode,
    a.ApplicationName,
    a.IconName,
    a.ThemeColor,
    a.StatusCode,
    a.DisplayOrder,
    a.IsActive,
    COUNT(DISTINCT r.RequestId) AS TotalRequests
FROM ab.Application a
LEFT JOIN ab.Request r
    ON r.ApplicationId = a.ApplicationId
   AND r.IsDeleted = 0
GROUP BY
    a.ApplicationId,
    a.ApplicationCode,
    a.ApplicationName,
    a.IconName,
    a.ThemeColor,
    a.StatusCode,
    a.DisplayOrder,
    a.IsActive;
GO

CREATE OR ALTER VIEW ab.vw_PendingWorkflowTasks
AS
SELECT
    wt.WorkflowTaskId,
    wt.WorkflowInstanceId,
    wi.RequestId,
    r.RequestNumber,
    r.ApplicationId,
    a.ApplicationName,
    wt.StageId,
    ws.StageName,
    wt.AssignedUserId,
    wt.AssignedRoleId,
    wt.StatusCode,
    wt.DueDate,
    wt.CreatedDate
FROM ab.WorkflowTask wt
INNER JOIN ab.WorkflowInstance wi
    ON wi.WorkflowInstanceId = wt.WorkflowInstanceId
INNER JOIN ab.Request r
    ON r.RequestId = wi.RequestId
INNER JOIN ab.Application a
    ON a.ApplicationId = r.ApplicationId
INNER JOIN ab.WorkflowStage ws
    ON ws.StageId = wt.StageId
WHERE wt.StatusCode IN ('PENDING','IN_PROGRESS');
GO

/* ============================================================================
   28. STORED PROCEDURE - NEXT REQUEST NUMBER
   ============================================================================ */

CREATE OR ALTER PROCEDURE ab.usp_CreateRequestNumber
    @ApplicationId INT,
    @RequestNumber NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Code NVARCHAR(50);
    DECLARE @Next BIGINT;

    SELECT @Code = ApplicationCode
    FROM ab.Application
    WHERE ApplicationId = @ApplicationId;

    /*
      NOTE:
      For very high concurrency, the .NET service should use a dedicated
      sequence/counter table. This procedure is intended as a baseline.
    */

    SELECT @Next = ISNULL(MAX(RequestId), 0) + 1
    FROM ab.Request WITH (UPDLOCK, HOLDLOCK);

    SET @RequestNumber =
        @Code + '-' + RIGHT('000000' + CAST(@Next AS VARCHAR(20)), 6);
END;
GO

/* ============================================================================
   29. VALIDATION SUMMARY
   ============================================================================ */

SELECT
    'Tables' AS ObjectType,
    COUNT(*) AS ObjectCount
FROM sys.tables
WHERE schema_id = SCHEMA_ID('ab');

SELECT
    'Indexes' AS ObjectType,
    COUNT(*) AS ObjectCount
FROM sys.indexes
WHERE object_id IN
(
    SELECT object_id
    FROM sys.tables
    WHERE schema_id = SCHEMA_ID('ab')
);

SELECT
    'Applications' AS ObjectType,
    COUNT(*) AS ObjectCount
FROM ab.Application;

SELECT
    'Roles' AS ObjectType,
    COUNT(*) AS ObjectCount
FROM ab.AppRole;

SELECT
    'Permissions' AS ObjectType,
    COUNT(*) AS ObjectCount
FROM ab.Permission;

SELECT
    'Forms' AS ObjectType,
    COUNT(*) AS ObjectCount
FROM ab.Form;

SELECT
    'Workflows' AS ObjectType,
    COUNT(*) AS ObjectCount
FROM ab.Workflow;
GO

/*
===============================================================================
END OF SCRIPT

IMPORTANT PRODUCTION NOTES

1. Do not store SharePoint files in SQL Server.
   Store only SharePoint metadata in ab.Attachment.

2. Do not hard-code approval hierarchy in React.
   Workflow Service resolves REPORTING_MANAGER, DEPARTMENT_HEAD,
   DIVISION_HEAD etc. using AppUser/OrganizationUnit.

3. FormDataJson is the flexible payload.
   RequestValue is the reporting/search projection.

4. Never modify a published Form/Workflow definition in-place when existing
   requests depend on it. Create a new version.

5. Entra ID/JWT validation belongs in .NET API middleware.

6. API authorization must be enforced server-side.

7. Replace YOURTENANT in SharePoint configuration before production.

8. For production-scale request numbering, replace the MAX(RequestId)
   approach with a dedicated counter/sequence service.

9. For 50 applications, this schema is intentionally shared/configurable;
   do not create 50 separate databases or 50 separate form tables.
===============================================================================
*/
