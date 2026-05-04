-- ================================================
-- 03_marts.sql
-- Create MART (Gold) layer for transaction analytics
-- ================================================

-- 1. Create schema
CREATE SCHEMA IF NOT EXISTS mart;

-- 2. Drop marts if exists (for reruns)
DROP TABLE IF EXISTS mart.daily_metrics;
DROP TABLE IF EXISTS mart.category_metrics;
DROP TABLE IF EXISTS mart.customer_metrics;
DROP TABLE IF EXISTS mart.customer_rfm;
DROP TABLE IF EXISTS mart.fraud_metrics;

-- ================================================
-- Customer metrics
-- ================================================

CREATE TABLE mart.customer_metrics AS
SELECT
customer_id,
COUNT(*) AS transactions_count,
SUM(amount) AS total_spent,
AVG(amount) AS avg_transaction,
MIN(transaction_time) AS first_transaction_time,
MAX(transaction_time) AS last_transaction_time,
COUNT(DISTINCT category) AS categories_count,
SUM(is_fraud) AS fraud_transactions_count,
ROUND(
SUM(is_fraud)::NUMERIC / NULLIF(COUNT(*), 0),
4
) AS fraud_rate
FROM clean.transactions
GROUP BY customer_id;

-- ================================================
-- Category metrics
-- ================================================

CREATE TABLE mart.category_metrics AS
SELECT
category,
COUNT(*) AS transactions_count,
COUNT(DISTINCT customer_id) AS unique_customers,
SUM(amount) AS total_spent,
AVG(amount) AS avg_check,
MIN(amount) AS min_check,
MAX(amount) AS max_check,
SUM(is_fraud) AS fraud_transactions_count,
ROUND(
SUM(is_fraud)::NUMERIC / NULLIF(COUNT(*), 0),
4
) AS fraud_rate
FROM clean.transactions
GROUP BY category;

-- ================================================
-- Daily metrics
-- ================================================

CREATE TABLE mart.daily_metrics AS
SELECT
DATE(transaction_time) AS transaction_date,
COUNT(*) AS transactions_count,
COUNT(DISTINCT customer_id) AS unique_customers,
SUM(amount) AS total_amount,
AVG(amount) AS avg_transaction,
SUM(is_fraud) AS fraud_transactions_count,
ROUND(
SUM(is_fraud)::NUMERIC / NULLIF(COUNT(*), 0),
4
) AS fraud_rate
FROM clean.transactions
GROUP BY DATE(transaction_time);

-- ================================================
-- RFM metrics
-- ================================================

CREATE TABLE mart.customer_rfm AS
WITH max_date AS (
SELECT MAX(transaction_time)::DATE AS analysis_date
FROM clean.transactions
),
rfm_base AS (
SELECT
t.customer_id,
(m.analysis_date - MAX(t.transaction_time)::DATE) AS recency_days,
COUNT(*) AS frequency,
SUM(t.amount) AS monetary
FROM clean.transactions t
CROSS JOIN max_date m
GROUP BY t.customer_id, m.analysis_date
),
rfm_scores AS (
SELECT
*,
NTILE(5) OVER (ORDER BY recency_days DESC) AS recency_score,
NTILE(5) OVER (ORDER BY frequency ASC) AS frequency_score,
NTILE(5) OVER (ORDER BY monetary ASC) AS monetary_score
FROM rfm_base
)
SELECT
customer_id,
recency_days,
frequency,
monetary,
recency_score,
frequency_score,
monetary_score,
recency_score + frequency_score + monetary_score AS rfm_score,
CASE
WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'best_customers'
WHEN frequency_score >= 4 AND monetary_score >= 4 THEN 'loyal_high_value'
WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'at_risk'
WHEN monetary_score >= 4 THEN 'high_value'
ELSE 'regular'
END AS customer_segment
FROM rfm_scores;

-- ================================================
-- Fraud metrics
-- ================================================

CREATE TABLE mart.fraud_metrics AS
SELECT
category,
state,
COUNT(*) AS transactions_count,
SUM(is_fraud) AS fraud_transactions_count,
ROUND(
SUM(is_fraud)::NUMERIC / NULLIF(COUNT(*), 0),
4
) AS fraud_rate,
SUM(amount) AS total_amount,
SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END) AS fraud_amount
FROM clean.transactions
GROUP BY category, state;

-- ================================================
-- Optional checks
-- ================================================

SELECT 'mart tables created successfully' AS status;

SELECT 'customer_metrics' AS table_name, COUNT(*) AS rows_count FROM mart.customer_metrics
UNION ALL
SELECT 'category_metrics', COUNT(*) FROM mart.category_metrics
UNION ALL
SELECT 'daily_metrics', COUNT(*) FROM mart.daily_metrics
UNION ALL
SELECT 'customer_rfm', COUNT(*) FROM mart.customer_rfm
UNION ALL
SELECT 'fraud_metrics', COUNT(*) FROM mart.fraud_metrics;
