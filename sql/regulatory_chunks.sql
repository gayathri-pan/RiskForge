USE DATABASE RFR_COPILOT;
USE SCHEMA AI;
USE WAREHOUSE RFR_WH;

CREATE OR REPLACE TABLE REGULATORY_CHUNKS (
    CHUNK_ID VARCHAR(100),
    DOCUMENT_ID VARCHAR(50),
    DOCUMENT_TITLE VARCHAR(200),
    SECTION_NAME VARCHAR(200),
    CONTENT VARCHAR(5000),
    JURISDICTION VARCHAR(50),
    VERSION VARCHAR(20),
    EFFECTIVE_DATE DATE
);

INSERT INTO REGULATORY_CHUNKS (
    CHUNK_ID,
    DOCUMENT_ID,
    DOCUMENT_TITLE,
    SECTION_NAME,
    CONTENT,
    JURISDICTION,
    VERSION,
    EFFECTIVE_DATE
)
VALUES
(
    'RFR-POL-001-S1',
    'RFR-POL-001',
    'RiskForge Demo Transaction Monitoring Policy',
    'Transaction Velocity',
    'Financial institutions should monitor accounts for unusually high transaction frequency within short time periods. Multiple transactions occurring within a 15-minute period should be reviewed when activity is inconsistent with the customer profile.',
    'DEMO',
    '1.0',
    '2026-01-01'
),
(
    'RFR-POL-001-S2',
    'RFR-POL-001',
    'RiskForge Demo Transaction Monitoring Policy',
    'Unusual Transaction Amounts',
    'Transactions that materially differ from a customer''s established historical transaction behavior should be reviewed. Investigators should compare current transaction amounts with historical averages and transaction distributions.',
    'DEMO',
    '1.0',
    '2026-01-01'
),
(
    'RFR-POL-001-S3',
    'RFR-POL-001',
    'RiskForge Demo Transaction Monitoring Policy',
    'Near-Threshold Activity',
    'Multiple transactions occurring below a defined monitoring threshold within a short period may indicate potential structuring. Such activity should be reviewed together with transaction history and other risk indicators.',
    'DEMO',
    '1.0',
    '2026-01-01'
),
(
    'RFR-POL-001-S4',
    'RFR-POL-001',
    'RiskForge Demo Transaction Monitoring Policy',
    'Geographic Activity',
    'Rapid movement of transactions across multiple countries within a short period should be reviewed when the geographic pattern is inconsistent with the customer profile or expected account activity.',
    'DEMO',
    '1.0',
    '2026-01-01'
),
(
    'RFR-POL-001-S5',
    'RFR-POL-001',
    'RiskForge Demo Transaction Monitoring Policy',
    'Multiple Risk Indicators',
    'When multiple independent risk indicators are detected for the same customer or account, investigators should perform enhanced review and document the supporting evidence.',
    'DEMO',
    '1.0',
    '2026-01-01'
),
(
    'RFR-PROC-001-S1',
    'RFR-PROC-001',
    'RiskForge Demo Investigation Procedure',
    'Case Review',
    'Investigators should review the customer profile, account information, transaction history, detected risk signals, and supporting evidence.',
    'DEMO',
    '1.0',
    '2026-01-01'
),
(
    'RFR-PROC-001-S2',
    'RFR-PROC-001',
    'RiskForge Demo Investigation Procedure',
    'Evidence Documentation',
    'Investigation records should identify the customer or account, relevant transactions, detected indicators, supporting evidence, applicable policy sections, and investigation status.',
    'DEMO',
    '1.0',
    '2026-01-01'
),
(
    'RFR-PROC-001-S3',
    'RFR-PROC-001',
    'RiskForge Demo Investigation Procedure',
    'Escalation',
    'Cases containing multiple independent risk indicators should be escalated for enhanced investigation according to the organization''s internal review process.',
    'DEMO',
    '1.0',
    '2026-01-01'
),
(
    'RFR-PROC-001-S4',
    'RFR-PROC-001',
    'RiskForge Demo Investigation Procedure',
    'Analyst Caution',
    'Automated risk signals are indicators for investigation and should not by themselves be treated as a final determination of illicit activity.',
    'DEMO',
    '1.0',
    '2026-01-01'
);


SELECT
    COUNT(*) AS DOCUMENT_COUNT
FROM REGULATORY_DOCUMENTS;

SELECT
    COUNT(*) AS CHUNK_COUNT
FROM REGULATORY_CHUNKS;



CREATE OR REPLACE CORTEX SEARCH SERVICE RFR_COPILOT.AI.REGULATORY_SEARCH
    ON CONTENT
    PRIMARY KEY (CHUNK_ID)
    ATTRIBUTES
        DOCUMENT_ID,
        DOCUMENT_TITLE,
        SECTION_NAME,
        JURISDICTION,
        VERSION
    WAREHOUSE = RFR_WH
    TARGET_LAG = '1 hour'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-m-v1.5'
AS
(
    SELECT
        CHUNK_ID,
        DOCUMENT_ID,
        DOCUMENT_TITLE,
        SECTION_NAME,
        CONTENT,
        JURISDICTION,
        VERSION,
        EFFECTIVE_DATE
    FROM RFR_COPILOT.AI.REGULATORY_CHUNKS
);


SHOW CORTEX SEARCH SERVICES
IN RFR_COPILOT.AI;

DESC CORTEX SEARCH SERVICE RFR_COPILOT.AI.REGULATORY_SEARCH;


SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'RFR_COPILOT.AI.REGULATORY_SEARCH',
        '{
            "query": "multiple transactions below a monitoring threshold",
            "columns": [
                "CHUNK_ID",
                "DOCUMENT_TITLE",
                "SECTION_NAME",
                "CONTENT"
            ],
            "limit": 3
        }'
    )
)['results'] AS RESULTS;


USE DATABASE RFR_COPILOT;
USE SCHEMA ANALYTICS;

CREATE OR REPLACE VIEW INVESTIGATION_DATA AS
SELECT
    f.FINDING_ID,
    f.CUSTOMER_ID,
    f.ACCOUNT_ID,

    c.CUSTOMER_NAME,
    c.COUNTRY AS CUSTOMER_HOME_COUNTRY,
    c.CUSTOMER_TYPE,
    c.CUSTOMER_RISK_LEVEL,
    c.ANNUAL_INCOME,
    c.KYC_STATUS,
    c.PEP_FLAG,

    a.ACCOUNT_TYPE,
    a.CURRENCY,
    a.BALANCE,
    a.STATUS AS ACCOUNT_STATUS,

    f.FINDING_TYPE,
    f.RISK_LEVEL,
    f.RISK_SCORE,
    f.SIGNAL_COUNT,
    f.SIGNAL_TYPES,
    f.FINDING_TITLE,
    f.FINDING_SUMMARY,
    f.RECOMMENDED_ACTION,
    f.STATUS AS FINDING_STATUS,
    f.CREATED_AT

FROM RISK_FINDINGS f

LEFT JOIN RFR_COPILOT.RAW.CUSTOMERS c
    ON f.CUSTOMER_ID = c.CUSTOMER_ID

LEFT JOIN RFR_COPILOT.RAW.ACCOUNTS a
    ON f.ACCOUNT_ID = a.ACCOUNT_ID;


SELECT *
FROM INVESTIGATION_DATA
WHERE CUSTOMER_ID = 'C00506';


USE DATABASE RFR_COPILOT;
USE SCHEMA ANALYTICS;
USE WAREHOUSE RFR_WH;





CREATE OR REPLACE SEMANTIC VIEW RISK_INTELLIGENCE

TABLES (
    investigation AS RFR_COPILOT.ANALYTICS.INVESTIGATION_DATA
        PRIMARY KEY (FINDING_ID)
)

FACTS (
    investigation.risk_score AS investigation.RISK_SCORE,
    investigation.signal_count AS investigation.SIGNAL_COUNT,
    investigation.annual_income AS investigation.ANNUAL_INCOME,
    investigation.account_balance AS investigation.BALANCE
)

DIMENSIONS (
    investigation.customer_id_dim AS investigation.CUSTOMER_ID,
    investigation.customer_name_dim AS investigation.CUSTOMER_NAME,
    investigation.home_country_dim AS investigation.CUSTOMER_HOME_COUNTRY,
    investigation.customer_type_dim AS investigation.CUSTOMER_TYPE,
    investigation.customer_risk_dim AS investigation.CUSTOMER_RISK_LEVEL,
    investigation.account_id_dim AS investigation.ACCOUNT_ID,
    investigation.account_type_dim AS investigation.ACCOUNT_TYPE,
    investigation.currency_dim AS investigation.CURRENCY,
    investigation.finding_type_dim AS investigation.FINDING_TYPE,
    investigation.risk_level_dim AS investigation.RISK_LEVEL,
    investigation.signal_types_dim AS investigation.SIGNAL_TYPES,
    investigation.kyc_status_dim AS investigation.KYC_STATUS
);

SHOW SEMANTIC VIEWS
IN RFR_COPILOT.ANALYTICS;


DESC SEMANTIC VIEW RFR_COPILOT.ANALYTICS.RISK_INTELLIGENCE;

SELECT *
FROM SEMANTIC_VIEW(
    RFR_COPILOT.ANALYTICS.RISK_INTELLIGENCE
    DIMENSIONS
        customer_id_dim,
        customer_name_dim,
        risk_level_dim,
        signal_types_dim
    FACTS
        risk_score,
        signal_count
)
WHERE customer_id_dim = 'C00506';

SHOW GRANTS TO ROLE ACCOUNTADMIN;

SHOW AGENTS IN SCHEMA RFR_COPILOT.AI;

SHOW CREATE AGENT RFR_COPILOT.AI.RISKFORGE_AGENT;

USE ROLE ACCOUNTADMIN;

SHOW GRANTS ON SCHEMA RFR_COPILOT.AI;
