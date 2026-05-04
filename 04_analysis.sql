-- ================================================
-- 04_analysis.sql
-- SQL analysis queries for Credit Card Transaction Analytics
-- ================================================

-- ================================================
-- 1. Basic dataset overview
-- ================================================

SELECT
COUNT(*) AS transactions_count,
COUNT(DISTINCT customer_id) AS customers_count,
COUNT(DISTINCT merchant) AS merchants_count,
COUNT(DISTINCT category) AS categories_count,
MIN(transaction_time) AS first_transaction_time,
MAX(transaction_time) AS last_transaction_time,
SUM(amount) AS total_amount,
AVG(amount) AS avg_transaction
FROM clean.transactions;

-- ================================================
-- 2. Top 10 customers by total spending
-- ================================================

SELECT
customer_id,
transactions_count,
total_spent,
avg_transaction,
first_transaction_time,
last_transaction_time
FROM mart.customer_metrics
ORDER BY total_spent DESC
LIMIT 10;

-- ================================================
-- 3. Category performance
-- ================================================

SELECT
category,
transactions_count,
unique_customers,
total_spent,
avg_check,
fraud_transactions_count,
fraud_rate
FROM mart.category_metrics
ORDER BY total_spent DESC;

-- ================================================
-- 4. Category share of total spending
-- ================================================

SELECT
category,
total_spent,
ROUND(
total_spent / SUM(total_spent) OVER (),
4
) AS spending_share
FROM mart.category_metrics
ORDER BY spending_share DESC;

-- ================================================
-- 5. Daily dynamics
-- ================================================

SELECT
transaction_date,
transactions_count,
unique_customers,
total_amount,
avg_transaction,
fraud_transactions_count,
fraud_rate
FROM mart.daily_metrics
ORDER BY transaction_date;

-- ================================================
-- 6. Cumulative transaction amount over time
-- ================================================

SELECT
transaction_date,
total_amount,
SUM(total_amount) OVER (
ORDER BY transaction_date
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS cumulative_amount
FROM mart.daily_metrics
ORDER BY transaction_date;

-- ================================================
-- 7. Daily amount change compared to previous day
-- ================================================

SELECT
transaction_date,
total_amount,
LAG(total_amount) OVER (ORDER BY transaction_date) AS previous_day_amount,
total_amount - LAG(total_amount) OVER (ORDER BY transaction_date) AS amount_diff,
ROUND(
(total_amount - LAG(total_amount) OVER (ORDER BY transaction_date))
/ NULLIF(LAG(total_amount) OVER (ORDER BY transaction_date), 0),
4
) AS amount_growth_rate
FROM mart.daily_metrics
ORDER BY transaction_date;

-- ================================================
-- 8. Customer segmentation by total spending
-- ================================================

SELECT
customer_id,
transactions_count,
total_spent,
avg_transaction,
CASE
WHEN total_spent >= 10000 THEN 'VIP'
WHEN total_spent >= 3000 THEN 'MID'
ELSE 'LOW'
END AS spending_segment
FROM mart.customer_metrics
ORDER BY total_spent DESC;

-- ================================================
-- 9. RFM customer segments
-- ================================================

SELECT
customer_segment,
COUNT(*) AS customers_count,
AVG(recency_days) AS avg_recency_days,
AVG(frequency) AS avg_frequency,
AVG(monetary) AS avg_monetary,
SUM(monetary) AS total_segment_monetary
FROM mart.customer_rfm
GROUP BY customer_segment
ORDER BY total_segment_monetary DESC;

-- ================================================
-- 10. Fraud overview
-- ================================================

SELECT
COUNT(*) AS transactions_count,
SUM(is_fraud) AS fraud_transactions_count,
ROUND(
SUM(is_fraud)::NUMERIC / NULLIF(COUNT(*), 0),
4
) AS fraud_rate,
SUM(amount) AS total_amount,
SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END) AS fraud_amount
FROM clean.transactions;

-- ================================================
-- 11. Fraud by category
-- ================================================

SELECT
category,
SUM(transactions_count) AS transactions_count,
SUM(fraud_transactions_count) AS fraud_transactions_count,
ROUND(
SUM(fraud_transactions_count)::NUMERIC / NULLIF(SUM(transactions_count), 0),
4
) AS fraud_rate,
SUM(total_amount) AS total_amount,
SUM(fraud_amount) AS fraud_amount
FROM mart.fraud_metrics
GROUP BY category
ORDER BY fraud_rate DESC, fraud_transactions_count DESC;

-- ================================================
-- 12. Fraud by state
-- ================================================

SELECT
state,
SUM(transactions_count) AS transactions_count,
SUM(fraud_transactions_count) AS fraud_transactions_count,
ROUND(
SUM(fraud_transactions_count)::NUMERIC / NULLIF(SUM(transactions_count), 0),
4
) AS fraud_rate,
SUM(total_amount) AS total_amount,
SUM(fraud_amount) AS fraud_amount
FROM mart.fraud_metrics
GROUP BY state
ORDER BY fraud_rate DESC, fraud_transactions_count DESC;

-- ================================================
-- 13. Large transactions compared to global average
-- ================================================

SELECT
transaction_id,
customer_id,
transaction_time,
merchant,
category,
state,
amount,
ROUND(
amount / NULLIF(AVG(amount) OVER (), 0),
2
) AS amount_to_avg_ratio,
is_fraud
FROM clean.transactions
WHERE amount > (
SELECT AVG(amount) * 5
FROM clean.transactions
)
ORDER BY amount DESC;

-- ================================================
-- 14. Large transactions compared to customer's own average
-- ================================================

WITH customer_avg AS (
SELECT
customer_id,
AVG(amount) AS avg_customer_amount
FROM clean.transactions
GROUP BY customer_id
)
SELECT
t.transaction_id,
t.customer_id,
t.transaction_time,
t.merchant,
t.category,
t.amount,
c.avg_customer_amount,
ROUND(
t.amount / NULLIF(c.avg_customer_amount, 0),
2
) AS amount_to_customer_avg_ratio,
t.is_fraud
FROM clean.transactions t
JOIN customer_avg c
ON t.customer_id = c.customer_id
WHERE t.amount > c.avg_customer_amount * 5
ORDER BY amount_to_customer_avg_ratio DESC;

-- ================================================
-- 15. Top merchants by transaction amount
-- ================================================

SELECT
merchant,
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
GROUP BY merchant
ORDER BY total_amount DESC
LIMIT 20;

-- ================================================
-- 16. Category ranking inside each state
-- ================================================

WITH category_state_metrics AS (
SELECT
state,
category,
COUNT(*) AS transactions_count,
SUM(amount) AS total_amount
FROM clean.transactions
GROUP BY state, category
),
ranked AS (
SELECT
*,
RANK() OVER (
PARTITION BY state
ORDER BY total_amount DESC
) AS category_rank
FROM category_state_metrics
)
SELECT
state,
category,
transactions_count,
total_amount,
category_rank
FROM ranked
WHERE category_rank <= 3
ORDER BY state, category_rank;

-- ================================================
-- 17. Monthly transaction dynamics
-- ================================================

SELECT
DATE_TRUNC('month', transaction_time)::DATE AS transaction_month,
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
GROUP BY DATE_TRUNC('month', transaction_time)::DATE
ORDER BY transaction_month;

-- ================================================
-- 18. Repeat customer activity
-- ================================================

SELECT
CASE
WHEN transactions_count = 1 THEN 'one_transaction'
WHEN transactions_count BETWEEN 2 AND 5 THEN '2_to_5_transactions'
WHEN transactions_count BETWEEN 6 AND 20 THEN '6_to_20_transactions'
ELSE 'more_than_20_transactions'
END AS activity_segment,
COUNT(*) AS customers_count,
AVG(total_spent) AS avg_total_spent,
SUM(total_spent) AS segment_total_spent
FROM mart.customer_metrics
GROUP BY activity_segment
ORDER BY segment_total_spent DESC;
