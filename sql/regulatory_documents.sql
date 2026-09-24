USE DATABASE RFR_COPILOT;
USE SCHEMA AI;
USE WAREHOUSE RFR_WH;

CREATE OR REPLACE TABLE REGULATORY_DOCUMENTS (
    DOCUMENT_ID VARCHAR(50),
    DOCUMENT_TITLE VARCHAR(200),
    DOCUMENT_TYPE VARCHAR(50),
    JURISDICTION VARCHAR(50),
    VERSION VARCHAR(20),
    EFFECTIVE_DATE DATE,
    CONTENT VARCHAR(10000),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

INSERT INTO REGULATORY_DOCUMENTS (
    DOCUMENT_ID,
    DOCUMENT_TITLE,
    DOCUMENT_TYPE,
    JURISDICTION,
    VERSION,
    EFFECTIVE_DATE,
    CONTENT
)
VALUES
(
    'RFR-POL-001',
    'RiskForge Demo Transaction Monitoring Policy',
    'DEMO_AML_POLICY',
    'DEMO',
    '1.0',
    '2026-01-01',

    'SECTION 1 - TRANSACTION VELOCITY
Financial institutions should monitor accounts for unusually high transaction frequency within short time periods. Multiple transactions occurring within a 15-minute period should be reviewed when activity is inconsistent with the customer profile.

SECTION 2 - UNUSUAL TRANSACTION AMOUNTS
Transactions that materially differ from a customer''s established historical transaction behavior should be reviewed. Investigators should compare current transaction amounts with historical averages and transaction distributions.

SECTION 3 - NEAR-THRESHOLD ACTIVITY
Multiple transactions occurring below a defined monitoring threshold within a short period may indicate potential structuring. Such activity should be reviewed together with transaction history and other risk indicators.

SECTION 4 - GEOGRAPHIC ACTIVITY
Rapid movement of transactions across multiple countries within a short period should be reviewed when the geographic pattern is inconsistent with the customer profile or expected account activity.

SECTION 5 - MULTIPLE RISK INDICATORS
When multiple independent risk indicators are detected for the same customer or account, investigators should perform enhanced review and document the supporting evidence.'
),

(
    'RFR-PROC-001',
    'RiskForge Demo Investigation Procedure',
    'DEMO_PROCEDURE',
    'DEMO',
    '1.0',
    '2026-01-01',

    'SECTION 1 - CASE REVIEW
Investigators should review the customer profile, account information, transaction history, detected risk signals, and supporting evidence.

SECTION 2 - EVIDENCE DOCUMENTATION
Investigation records should identify the customer or account, relevant transactions, detected indicators, supporting evidence, applicable policy sections, and investigation status.

SECTION 3 - ESCALATION
Cases containing multiple independent risk indicators should be escalated for enhanced investigation according to the organization''s internal review process.

SECTION 4 - ANALYST CAUTION
Automated risk signals are indicators for investigation and should not by themselves be treated as a final determination of illicit activity.'
);