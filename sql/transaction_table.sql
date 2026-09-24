USE DATABASE RFR_COPILOT;
USE SCHEMA RAW;
USE WAREHOUSE RFR_WH;

INSERT INTO TRANSACTIONS (
    TRANSACTION_ID,
    ACCOUNT_ID,
    CUSTOMER_ID,
    TRANSACTION_TIMESTAMP,
    AMOUNT,
    CURRENCY,
    TRANSACTION_TYPE,
    CHANNEL,
    MERCHANT,
    COUNTRY
)
WITH generated AS (
    SELECT SEQ4() AS N
    FROM TABLE(GENERATOR(ROWCOUNT => 50000))
),
account_map AS (
    SELECT
        ACCOUNT_ID,
        CUSTOMER_ID,
        CURRENCY,
        COUNTRY,
        ROW_NUMBER() OVER (ORDER BY ACCOUNT_ID) - 1 AS ACCOUNT_INDEX
    FROM (
        SELECT
            a.ACCOUNT_ID,
            a.CUSTOMER_ID,
            a.CURRENCY,
            c.COUNTRY
        FROM ACCOUNTS a
        JOIN CUSTOMERS c
            ON a.CUSTOMER_ID = c.CUSTOMER_ID
        WHERE a.STATUS = 'ACTIVE'
    )
),
account_count AS (
    SELECT COUNT(*) AS CNT
    FROM account_map
)
SELECT
    'TX' || LPAD(g.N + 1, 9, '0') AS TRANSACTION_ID,

    a.ACCOUNT_ID,

    a.CUSTOMER_ID,

    DATEADD(
        MINUTE,
        -UNIFORM(1, 60 * 24 * 45, RANDOM()),
        CURRENT_TIMESTAMP()
    ) AS TRANSACTION_TIMESTAMP,

    ROUND(
        UNIFORM(500, 50000, RANDOM()),
        2
    ) AS AMOUNT,

    a.CURRENCY,

    CASE UNIFORM(1,4,RANDOM())
        WHEN 1 THEN 'CARD_PAYMENT'
        WHEN 2 THEN 'ONLINE_PAYMENT'
        WHEN 3 THEN 'TRANSFER'
        ELSE 'CASH_WITHDRAWAL'
    END AS TRANSACTION_TYPE,

    CASE UNIFORM(1,4,RANDOM())
        WHEN 1 THEN 'MOBILE'
        WHEN 2 THEN 'WEB'
        WHEN 3 THEN 'ATM'
        ELSE 'BRANCH'
    END AS CHANNEL,

    CASE UNIFORM(1,5,RANDOM())
        WHEN 1 THEN 'Retail'
        WHEN 2 THEN 'Online Marketplace'
        WHEN 3 THEN 'Utilities'
        WHEN 4 THEN 'Travel'
        ELSE 'Money Transfer'
    END AS MERCHANT,

    CASE UNIFORM(1,5,RANDOM())
        WHEN 1 THEN 'India'
        WHEN 2 THEN 'Singapore'
        WHEN 3 THEN 'Germany'
        WHEN 4 THEN 'United Kingdom'
        ELSE 'United Arab Emirates'
    END AS COUNTRY

FROM generated g
JOIN account_map a
    ON a.ACCOUNT_INDEX =
       MOD(g.N, (SELECT CNT FROM account_count));

SELECT
    COUNT(*) AS TRANSACTION_COUNT,
    COUNT(DISTINCT CUSTOMER_ID) AS CUSTOMER_COUNT,
    COUNT(DISTINCT ACCOUNT_ID) AS ACCOUNT_COUNT,
    MIN(TRANSACTION_TIMESTAMP) AS FIRST_TRANSACTION,
    MAX(TRANSACTION_TIMESTAMP) AS LAST_TRANSACTION
FROM TRANSACTIONS;

SELECT
    c.CUSTOMER_ID,
    c.CUSTOMER_NAME,
    COUNT(a.ACCOUNT_ID) AS TOTAL_ACCOUNTS,
    COUNT_IF(a.STATUS = 'ACTIVE') AS ACTIVE_ACCOUNTS
FROM RFR_COPILOT.RAW.CUSTOMERS c
LEFT JOIN RFR_COPILOT.RAW.ACCOUNTS a
    ON c.CUSTOMER_ID = a.CUSTOMER_ID
LEFT JOIN RFR_COPILOT.RAW.TRANSACTIONS t
    ON c.CUSTOMER_ID = t.CUSTOMER_ID
WHERE t.CUSTOMER_ID IS NULL
GROUP BY
    c.CUSTOMER_ID,
    c.CUSTOMER_NAME;


SELECT
    CUSTOMER_ID,
    COUNT(*) AS TRANSACTION_COUNT
FROM RFR_COPILOT.RAW.TRANSACTIONS
WHERE CUSTOMER_ID IN
(
    'C00102',
    'C00203',
    'C00304',
    'C00405',
    'C00506'
)
GROUP BY CUSTOMER_ID
ORDER BY CUSTOMER_ID;


USE DATABASE RFR_COPILOT;
USE SCHEMA RAW;
USE WAREHOUSE RFR_WH;

INSERT INTO TRANSACTIONS (
    TRANSACTION_ID,
    ACCOUNT_ID,
    CUSTOMER_ID,
    TRANSACTION_TIMESTAMP,
    AMOUNT,
    CURRENCY,
    TRANSACTION_TYPE,
    CHANNEL,
    MERCHANT,
    COUNTRY
)

WITH scenario_data AS (

    /* =========================================================
       C00102 — RAPID TRANSACTION VELOCITY
       10 transactions within 15 minutes
       Total = 450,000
       ========================================================= */
    SELECT
        'SC102_001' AS TRANSACTION_ID,
        'C00102' AS CUSTOMER_ID,
        DATEADD(MINUTE,-14,CURRENT_TIMESTAMP()) AS TRANSACTION_TIMESTAMP,
        45000 AS AMOUNT,
        'TRANSFER' AS TRANSACTION_TYPE,
        'MOBILE' AS CHANNEL,
        'Business Transfer' AS MERCHANT,
        'Singapore' AS COUNTRY

    UNION ALL SELECT
        'SC102_002','C00102',
        DATEADD(MINUTE,-13,CURRENT_TIMESTAMP()),
        43000,'TRANSFER','MOBILE','Business Transfer','Singapore'

    UNION ALL SELECT
        'SC102_003','C00102',
        DATEADD(MINUTE,-11,CURRENT_TIMESTAMP()),
        47000,'TRANSFER','MOBILE','Business Transfer','Singapore'

    UNION ALL SELECT
        'SC102_004','C00102',
        DATEADD(MINUTE,-10,CURRENT_TIMESTAMP()),
        44000,'TRANSFER','MOBILE','Business Transfer','Singapore'

    UNION ALL SELECT
        'SC102_005','C00102',
        DATEADD(MINUTE,-8,CURRENT_TIMESTAMP()),
        46000,'TRANSFER','MOBILE','Business Transfer','Singapore'

    UNION ALL SELECT
        'SC102_006','C00102',
        DATEADD(MINUTE,-7,CURRENT_TIMESTAMP()),
        45000,'TRANSFER','MOBILE','Business Transfer','Singapore'

    UNION ALL SELECT
        'SC102_007','C00102',
        DATEADD(MINUTE,-6,CURRENT_TIMESTAMP()),
        42000,'TRANSFER','MOBILE','Business Transfer','Singapore'

    UNION ALL SELECT
        'SC102_008','C00102',
        DATEADD(MINUTE,-4,CURRENT_TIMESTAMP()),
        48000,'TRANSFER','MOBILE','Business Transfer','Singapore'

    UNION ALL SELECT
        'SC102_009','C00102',
        DATEADD(MINUTE,-2,CURRENT_TIMESTAMP()),
        40000,'TRANSFER','MOBILE','Business Transfer','Singapore'

    UNION ALL SELECT
        'SC102_010','C00102',
        DATEADD(MINUTE,-1,CURRENT_TIMESTAMP()),
        50000,'TRANSFER','MOBILE','Business Transfer','Singapore'


    /* =========================================================
       C00203 — GEOGRAPHIC ANOMALY
       India → UK → Singapore within 35 minutes
       ========================================================= */

    UNION ALL SELECT
        'SC203_001','C00203',
        DATEADD(MINUTE,-35,CURRENT_TIMESTAMP()),
        25000,'TRANSFER','MOBILE','Cross Border Transfer','India'

    UNION ALL SELECT
        'SC203_002','C00203',
        DATEADD(MINUTE,-20,CURRENT_TIMESTAMP()),
        28000,'TRANSFER','MOBILE','Cross Border Transfer','United Kingdom'

    UNION ALL SELECT
        'SC203_003','C00203',
        DATEADD(MINUTE,-1,CURRENT_TIMESTAMP()),
        30000,'TRANSFER','MOBILE','Cross Border Transfer','Singapore'


    /* =========================================================
       C00304 — STRUCTURING
       Five transactions below 100,000 within 30 minutes
       ========================================================= */

    UNION ALL SELECT
        'SC304_001','C00304',
        DATEADD(MINUTE,-25,CURRENT_TIMESTAMP()),
        98000,'TRANSFER','WEB','International Transfer','India'

    UNION ALL SELECT
        'SC304_002','C00304',
        DATEADD(MINUTE,-20,CURRENT_TIMESTAMP()),
        96500,'TRANSFER','WEB','International Transfer','India'

    UNION ALL SELECT
        'SC304_003','C00304',
        DATEADD(MINUTE,-15,CURRENT_TIMESTAMP()),
        99000,'TRANSFER','WEB','International Transfer','India'

    UNION ALL SELECT
        'SC304_004','C00304',
        DATEADD(MINUTE,-10,CURRENT_TIMESTAMP()),
        97500,'TRANSFER','WEB','International Transfer','India'

    UNION ALL SELECT
        'SC304_005','C00304',
        DATEADD(MINUTE,-5,CURRENT_TIMESTAMP()),
        95000,'TRANSFER','WEB','International Transfer','India'


    /* =========================================================
       C00405 — BEHAVIORAL ANOMALY
       Historical activity is normal; sudden 450K transaction
       ========================================================= */

    UNION ALL SELECT
        'SC405_F01','C00405',
        CURRENT_TIMESTAMP(),
        450000,'TRANSFER','WEB','Large Business Transfer','India'


    /* =========================================================
       C00506 — HERO MULTI-SIGNAL CASE

       5 transactions
       - within 15 minutes
       - near threshold
       - geographically unusual
       - materially above normal behavior

       Expected signals:
       VELOCITY
       AMOUNT ANOMALY
       STRUCTURING
       GEOGRAPHIC ANOMALY
       ========================================================= */

    UNION ALL SELECT
        'SC506_001','C00506',
        DATEADD(MINUTE,-14,CURRENT_TIMESTAMP()),
        98000,'TRANSFER','WEB','International Transfer','India'

    UNION ALL SELECT
        'SC506_002','C00506',
        DATEADD(MINUTE,-11,CURRENT_TIMESTAMP()),
        97500,'TRANSFER','WEB','International Transfer','United Kingdom'

    UNION ALL SELECT
        'SC506_003','C00506',
        DATEADD(MINUTE,-8,CURRENT_TIMESTAMP()),
        99000,'TRANSFER','WEB','International Transfer','Singapore'

    UNION ALL SELECT
        'SC506_004','C00506',
        DATEADD(MINUTE,-5,CURRENT_TIMESTAMP()),
        96500,'TRANSFER','WEB','International Transfer','United Kingdom'

    UNION ALL SELECT
        'SC506_005','C00506',
        DATEADD(MINUTE,-2,CURRENT_TIMESTAMP()),
        98500,'TRANSFER','WEB','International Transfer','Singapore'
)

SELECT
    s.TRANSACTION_ID,
    a.ACCOUNT_ID,
    s.CUSTOMER_ID,
    s.TRANSACTION_TIMESTAMP,
    s.AMOUNT,
    a.CURRENCY,
    s.TRANSACTION_TYPE,
    s.CHANNEL,
    s.MERCHANT,
    s.COUNTRY

FROM scenario_data s

JOIN (
    SELECT
        ACCOUNT_ID,
        CUSTOMER_ID,
        CURRENCY
    FROM ACCOUNTS
    WHERE STATUS = 'ACTIVE'
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY CUSTOMER_ID
        ORDER BY ACCOUNT_ID
    ) = 1
) a
    ON s.CUSTOMER_ID = a.CUSTOMER_ID;


SELECT
    CUSTOMER_ID,
    COUNT(*) AS SCENARIO_TRANSACTIONS,
    SUM(AMOUNT) AS TOTAL_AMOUNT
FROM TRANSACTIONS
WHERE TRANSACTION_ID LIKE 'SC%'
GROUP BY CUSTOMER_ID
ORDER BY CUSTOMER_ID;