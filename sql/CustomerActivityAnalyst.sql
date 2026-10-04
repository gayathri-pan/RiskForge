USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE VIEW RFR_COPILOT.ANALYTICS.CUSTOMER_ACTIVITY_OVERVIEW AS

WITH transaction_summary AS (

    SELECT
        CUSTOMER_ID,

        COUNT(*) AS TRANSACTION_COUNT,

        SUM(AMOUNT) AS TOTAL_TRANSACTION_AMOUNT,

        MIN(TRANSACTION_TIMESTAMP) AS FIRST_TRANSACTION_TIMESTAMP,

        MAX(TRANSACTION_TIMESTAMP) AS LAST_TRANSACTION_TIMESTAMP

    FROM RFR_COPILOT.RAW.TRANSACTIONS

    GROUP BY CUSTOMER_ID
),

account_summary AS (

    SELECT
        CUSTOMER_ID,

        COUNT(*) AS ACCOUNT_COUNT,

        SUM(
            CASE
                WHEN STATUS = 'ACTIVE'
                THEN 1
                ELSE 0
            END
        ) AS ACTIVE_ACCOUNT_COUNT

    FROM RFR_COPILOT.RAW.ACCOUNTS

    GROUP BY CUSTOMER_ID
),

signal_summary AS (

    SELECT
        CUSTOMER_ID,

        COUNT(DISTINCT SIGNAL_ID) AS ACTIVE_SIGNAL_COUNT,

        COUNT(
            DISTINCT SIGNAL_TYPE
        ) AS SIGNAL_TYPE_COUNT,

        LISTAGG(
            DISTINCT SIGNAL_TYPE,
            ', '
        ) WITHIN GROUP (
            ORDER BY SIGNAL_TYPE
        ) AS SIGNAL_TYPES

    FROM RFR_COPILOT.ANALYTICS.INVESTIGATION_SIGNAL_EVIDENCE

    GROUP BY CUSTOMER_ID
)

SELECT

    c.CUSTOMER_ID,

    c.CUSTOMER_NAME,

    c.COUNTRY AS HOME_COUNTRY,

    c.CUSTOMER_TYPE,

    c.CUSTOMER_RISK_LEVEL,

    c.ANNUAL_INCOME,

    c.CUSTOMER_SINCE,

    c.KYC_STATUS,

    c.PEP_FLAG,

    COALESCE(
        a.ACCOUNT_COUNT,
        0
    ) AS ACCOUNT_COUNT,

    COALESCE(
        a.ACTIVE_ACCOUNT_COUNT,
        0
    ) AS ACTIVE_ACCOUNT_COUNT,

    COALESCE(
        t.TRANSACTION_COUNT,
        0
    ) AS TRANSACTION_COUNT,

    COALESCE(
        t.TOTAL_TRANSACTION_AMOUNT,
        0
    ) AS TOTAL_TRANSACTION_AMOUNT,

    t.FIRST_TRANSACTION_TIMESTAMP,

    t.LAST_TRANSACTION_TIMESTAMP,

    COALESCE(
        s.ACTIVE_SIGNAL_COUNT,
        0
    ) AS ACTIVE_SIGNAL_COUNT,

    COALESCE(
        s.SIGNAL_TYPE_COUNT,
        0
    ) AS SIGNAL_TYPE_COUNT,

    COALESCE(
        s.SIGNAL_TYPES,
        'NONE'
    ) AS SIGNAL_TYPES,

    CASE

        WHEN COALESCE(
            s.ACTIVE_SIGNAL_COUNT,
            0
        ) = 0

        THEN 'NO_ACTIVE_RISK_SIGNAL'

        ELSE 'RISK_SIGNAL_PRESENT'

    END AS ACTIVITY_RISK_STATUS

FROM RFR_COPILOT.RAW.CUSTOMERS c

LEFT JOIN account_summary a
    ON c.CUSTOMER_ID = a.CUSTOMER_ID

LEFT JOIN transaction_summary t
    ON c.CUSTOMER_ID = t.CUSTOMER_ID

LEFT JOIN signal_summary s
    ON c.CUSTOMER_ID = s.CUSTOMER_ID;


SELECT
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CUSTOMER_RISK_LEVEL,
    TRANSACTION_COUNT,
    TOTAL_TRANSACTION_AMOUNT,
    ACTIVE_SIGNAL_COUNT,
    SIGNAL_TYPES,
    ACTIVITY_RISK_STATUS

FROM RFR_COPILOT.ANALYTICS.CUSTOMER_ACTIVITY_OVERVIEW

WHERE ACTIVE_SIGNAL_COUNT = 0

ORDER BY
    TRANSACTION_COUNT DESC

LIMIT 10;


SELECT
    ACTIVITY_RISK_STATUS,
    COUNT(*) AS CUSTOMER_COUNT

FROM RFR_COPILOT.ANALYTICS.CUSTOMER_ACTIVITY_OVERVIEW

GROUP BY
    ACTIVITY_RISK_STATUS;

SELECT
    CUSTOMER_ID,
    CUSTOMER_NAME,
    TRANSACTION_COUNT,
    TOTAL_TRANSACTION_AMOUNT,
    ACTIVE_SIGNAL_COUNT

FROM RFR_COPILOT.ANALYTICS.CUSTOMER_ACTIVITY_OVERVIEW

WHERE ACTIVE_SIGNAL_COUNT = 0

ORDER BY
    TRANSACTION_COUNT DESC

LIMIT 5;

SELECT
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CUSTOMER_RISK_LEVEL,
    TRANSACTION_COUNT,
    TOTAL_TRANSACTION_AMOUNT,
    ACTIVE_SIGNAL_COUNT,
    SIGNAL_TYPES,
    ACTIVITY_RISK_STATUS
FROM RFR_COPILOT.ANALYTICS.CUSTOMER_ACTIVITY_OVERVIEW
WHERE ACTIVE_SIGNAL_COUNT = 0
ORDER BY TRANSACTION_COUNT DESC
LIMIT 5;


USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE SEMANTIC VIEW
    RFR_COPILOT.ANALYTICS.CUSTOMER_ACTIVITY_INTELLIGENCE

TABLES (
    customer_activity
        AS RFR_COPILOT.ANALYTICS.CUSTOMER_ACTIVITY_OVERVIEW
        PRIMARY KEY (CUSTOMER_ID)
)

DIMENSIONS (

    customer_activity.customer_id_dim
        AS CUSTOMER_ID
        COMMENT = 'Unique customer identifier',

    customer_activity.customer_name_dim
        AS CUSTOMER_NAME
        COMMENT = 'Customer name',

    customer_activity.home_country_dim
        AS HOME_COUNTRY
        COMMENT = 'Customer home country',

    customer_activity.customer_type_dim
        AS CUSTOMER_TYPE
        COMMENT = 'Customer segment/type',

    customer_activity.customer_risk_dim
        AS CUSTOMER_RISK_LEVEL
        COMMENT = 'Baseline customer risk classification',

    customer_activity.kyc_status_dim
        AS KYC_STATUS
        COMMENT = 'Customer KYC status',

    customer_activity.signal_types_dim
        AS SIGNAL_TYPES
        COMMENT = 'Risk signal types associated with the customer',

    customer_activity.activity_risk_status_dim
        AS ACTIVITY_RISK_STATUS
        COMMENT = 'Whether the customer has active risk signals',

    customer_activity.first_transaction_dim
        AS FIRST_TRANSACTION_TIMESTAMP
        COMMENT = 'Timestamp of first recorded transaction',

    customer_activity.last_transaction_dim
        AS LAST_TRANSACTION_TIMESTAMP
        COMMENT = 'Timestamp of most recent recorded transaction'
)

METRICS (

    customer_activity.customer_count
        AS COUNT(CUSTOMER_ID),

    customer_activity.transaction_count
        AS SUM(TRANSACTION_COUNT),

    customer_activity.total_transaction_amount
        AS SUM(TOTAL_TRANSACTION_AMOUNT),

    customer_activity.account_count
        AS SUM(ACCOUNT_COUNT),

    customer_activity.active_account_count
        AS SUM(ACTIVE_ACCOUNT_COUNT),

    customer_activity.active_signal_count
        AS SUM(ACTIVE_SIGNAL_COUNT),

    customer_activity.signal_type_count
        AS SUM(SIGNAL_TYPE_COUNT),

    customer_activity.average_annual_income
        AS AVG(ANNUAL_INCOME)
)

COMMENT = 'Customer population and activity intelligence for baseline, comparison, and no-active-signal analysis';

DESC SEMANTIC VIEW
RFR_COPILOT.ANALYTICS.CUSTOMER_ACTIVITY_INTELLIGENCE;

SELECT *
FROM SEMANTIC_VIEW(
    RFR_COPILOT.ANALYTICS.CUSTOMER_ACTIVITY_INTELLIGENCE

    DIMENSIONS
        customer_activity.customer_id_dim,
        customer_activity.customer_name_dim,
        customer_activity.customer_risk_dim,
        customer_activity.signal_types_dim,
        customer_activity.activity_risk_status_dim

    METRICS
        customer_activity.transaction_count,
        customer_activity.total_transaction_amount,
        customer_activity.active_signal_count
)

WHERE ACTIVITY_RISK_STATUS_DIM = 'NO_ACTIVE_RISK_SIGNAL'

ORDER BY TRANSACTION_COUNT DESC

LIMIT 5;