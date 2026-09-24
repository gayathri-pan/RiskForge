USE DATABASE RFR_COPILOT;
USE SCHEMA ANALYTICS;

TRUNCATE TABLE RISK_FINDINGS;

INSERT INTO RISK_FINDINGS (
    FINDING_ID,
    CUSTOMER_ID,
    ACCOUNT_ID,
    FINDING_TYPE,
    RISK_LEVEL,
    RISK_SCORE,
    SIGNAL_COUNT,
    SIGNAL_TYPES,
    FINDING_TITLE,
    FINDING_SUMMARY,
    EVIDENCE_SUMMARY,
    RECOMMENDED_ACTION,
    STATUS
)

WITH signal_rollup AS (
    SELECT
        CUSTOMER_ID,
        ACCOUNT_ID,

        COUNT(*) AS SIGNAL_COUNT,

        COUNT(DISTINCT SIGNAL_TYPE) AS SIGNAL_TYPE_COUNT,

        LISTAGG(
            DISTINCT SIGNAL_TYPE,
            ', '
        ) WITHIN GROUP (
            ORDER BY SIGNAL_TYPE
        ) AS SIGNAL_TYPES,

        MAX(SIGNAL_SCORE) AS MAX_SIGNAL_SCORE,

        LISTAGG(
            SIGNAL_TYPE
            || ' [' || SIGNAL_SEVERITY
            || ', score=' || SIGNAL_SCORE
            || ']: '
            || EVIDENCE,
            ' | '
        ) WITHIN GROUP (
            ORDER BY SIGNAL_TYPE, SIGNAL_SCORE DESC
        ) AS EVIDENCE_SUMMARY

    FROM RISK_SIGNALS

    GROUP BY
        CUSTOMER_ID,
        ACCOUNT_ID
),

classified AS (
    SELECT
        *,

        CASE
            WHEN SIGNAL_TYPE_COUNT >= 4 THEN 100
            WHEN SIGNAL_TYPE_COUNT = 3 THEN 90
            WHEN SIGNAL_TYPE_COUNT = 2 THEN 80
            ELSE MAX_SIGNAL_SCORE
        END AS CALCULATED_RISK_SCORE

    FROM signal_rollup
)

SELECT
    'FIND_' || CUSTOMER_ID || '_' || ACCOUNT_ID,

    CUSTOMER_ID,

    ACCOUNT_ID,

    'SUSPICIOUS_ACTIVITY',

    CASE
        WHEN CALCULATED_RISK_SCORE >= 90 THEN 'CRITICAL'
        WHEN CALCULATED_RISK_SCORE >= 75 THEN 'HIGH'
        WHEN CALCULATED_RISK_SCORE >= 50 THEN 'MEDIUM'
        ELSE 'LOW'
    END,

    CALCULATED_RISK_SCORE,

    SIGNAL_COUNT,

    SIGNAL_TYPES,

    'Multiple risk indicators detected for customer '
        || CUSTOMER_ID,

    'Customer '
        || CUSTOMER_ID
        || ' and account '
        || ACCOUNT_ID
        || ' generated '
        || SIGNAL_COUNT
        || ' risk signals across '
        || SIGNAL_TYPE_COUNT
        || ' independent detection categories: '
        || SIGNAL_TYPES,

    EVIDENCE_SUMMARY,

    CASE
        WHEN CALCULATED_RISK_SCORE >= 90
        THEN 'Perform enhanced investigation, review supporting transactions and applicable AML policy, and document the investigation evidence.'

        WHEN CALCULATED_RISK_SCORE >= 75
        THEN 'Perform investigator review of the detected activity and supporting evidence.'

        WHEN CALCULATED_RISK_SCORE >= 50
        THEN 'Review the relevant transactions and monitor subsequent activity.'

        ELSE 'Monitor customer activity.'
    END,

    'OPEN'

FROM classified;


SELECT
    CUSTOMER_ID,
    ACCOUNT_ID,
    RISK_LEVEL,
    RISK_SCORE,
    SIGNAL_COUNT,
    SIGNAL_TYPES,
    FINDING_SUMMARY
FROM RISK_FINDINGS
WHERE CUSTOMER_ID IN (
    'C00102',
    'C00203',
    'C00304',
    'C00405',
    'C00506'
)
ORDER BY RISK_SCORE DESC, CUSTOMER_ID;

SELECT
    CUSTOMER_ID,
    ACCOUNT_ID,
    RISK_LEVEL,
    RISK_SCORE,
    SIGNAL_COUNT,
    SIGNAL_TYPES,
    EVIDENCE_SUMMARY,
    RECOMMENDED_ACTION
FROM RISK_FINDINGS
WHERE CUSTOMER_ID = 'C00506';