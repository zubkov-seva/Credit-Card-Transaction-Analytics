-- ================================================
-- 02_clean_data.sql
-- Create CLEAN (Silver) layer for transactions data
-- ================================================

-- 1. Create schema
CREATE SCHEMA IF NOT EXISTS clean;

-- 2. Drop table if exists (for reruns)
DROP TABLE IF EXISTS clean.transactions;

-- 3. Create cleaned transactions table
CREATE TABLE clean.transactions AS
SELECT
trans_num::TEXT AS transaction_id,

```
-- card number is used as a customer identifier
cc_num::BIGINT AS customer_id,

-- transaction fields
CAST(trans_date_trans_time AS TIMESTAMP) AS transaction_time,
CAST(amt AS NUMERIC(12, 2)) AS amount,

-- merchant and category normalization
LOWER(TRIM(REPLACE(merchant, 'fraud_', ''))) AS merchant,
LOWER(TRIM(category)) AS category,

-- customer fields
INITCAP(TRIM(first)) AS first_name,
INITCAP(TRIM(last)) AS last_name,
UPPER(TRIM(gender)) AS gender,
TRIM(street) AS street,
TRIM(city) AS city,
UPPER(TRIM(state)) AS state,
zip::TEXT AS zip,

-- geography
CAST(lat AS NUMERIC(10, 6)) AS customer_lat,
CAST(long AS NUMERIC(10, 6)) AS customer_long,
CAST(merch_lat AS NUMERIC(10, 6)) AS merchant_lat,
CAST(merch_long AS NUMERIC(10, 6)) AS merchant_long,

-- additional attributes
CAST(city_pop AS INTEGER) AS city_population,
TRIM(job) AS job,
CAST(dob AS DATE) AS date_of_birth,
CAST(unix_time AS BIGINT) AS unix_time,

-- target flag
CASE
    WHEN is_fraud = '1' THEN 1
    ELSE 0
END AS is_fraud
```

FROM raw.transactions_raw
WHERE trans_num IS NOT NULL
AND cc_num IS NOT NULL
AND amt IS NOT NULL
AND trans_date_trans_time IS NOT NULL
AND amt ~ '^[0-9]+(.[0-9]+)?$'
AND cc_num ~ '^[0-9]+$'
AND lat ~ '^-?[0-9]+(.[0-9]+)?$'
AND long ~ '^-?[0-9]+(.[0-9]+)?$'
AND merch_lat ~ '^-?[0-9]+(.[0-9]+)?$'
AND merch_long ~ '^-?[0-9]+(.[0-9]+)?$'
AND city_pop ~ '^[0-9]+$'
AND unix_time ~ '^[0-9]+$';

-- 4. Remove duplicate transactions if any
DROP TABLE IF EXISTS clean.transactions_deduplicated;

CREATE TABLE clean.transactions_deduplicated AS
SELECT *
FROM (
SELECT
*,
ROW_NUMBER() OVER (
PARTITION BY transaction_id
ORDER BY transaction_time DESC
) AS rn
FROM clean.transactions
) t
WHERE rn = 1;

ALTER TABLE clean.transactions_deduplicated
DROP COLUMN rn;

DROP TABLE clean.transactions;

ALTER TABLE clean.transactions_deduplicated
RENAME TO transactions;

-- 5. Optional checks
SELECT 'clean.transactions created successfully' AS status;

SELECT COUNT(*) AS clean_rows
FROM clean.transactions;
