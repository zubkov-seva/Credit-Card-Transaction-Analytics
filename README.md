Project Overview

This project demonstrates an end-to-end workflow for processing and analyzing credit card transaction data.
The main objective is to transform raw, unstructured transaction logs into clean, structured data and build analytical data marts for business insights.

The project simulates a real-world data engineering / BI task:

ingest raw data
clean and normalize it
build analytical tables
compute key business metrics

Objectives

Load raw transaction data into PostgreSQL
Clean and normalize inconsistent and noisy data
Design structured tables for analysis
Build analytical marts for business insights
Perform SQL-based analysis on customer behavior

Architecture

The project follows a simplified data warehouse approach:

RAW (Bronze) → CLEAN (Silver) → MART (Gold)
Layers:
RAW: unprocessed transaction data
CLEAN: cleaned and standardized dataset
MART: aggregated tables for analytics
📂 Project Structure
project/
├── data/
│   └── transactions.csv
├── sql/
│   ├── 01_create_raw.sql
│   ├── 02_clean_data.sql
│   ├── 03_marts.sql
│   ├── 04_analysis.sql
├── docs/
│   └── README.md

Data Description

The dataset contains credit card transactions with fields such as:

transaction timestamp
card number (customer identifier)
merchant name
category
transaction amount
customer demographics
fraud flag

The dataset is intentionally dirty:

inconsistent formatting
text values in numeric fields
malformed rows

This reflects real-world data conditions.

Implementation

1. RAW Layer

Raw data is loaded into PostgreSQL without transformations.

Example schema:

CREATE TABLE raw.transactions_raw (
    trans_date_trans_time TEXT,
    cc_num TEXT,
    merchant TEXT,
    category TEXT,
    amt TEXT,
    first TEXT,
    last TEXT,
    gender TEXT,
    city TEXT,
    state TEXT,
    lat TEXT,
    long TEXT,
    city_pop TEXT,
    job TEXT,
    dob TEXT,
    trans_num TEXT,
    unix_time TEXT,
    is_fraud TEXT
);
2. CLEAN Layer

Data is cleaned and normalized:

type casting
string normalization
filtering invalid rows
standardizing categories
CREATE TABLE clean.transactions AS
SELECT
    trans_num::TEXT AS transaction_id,
    cc_num::BIGINT AS customer_id,
    CAST(amt AS NUMERIC) AS amount,
    CAST(trans_date_trans_time AS TIMESTAMP) AS transaction_time,
    LOWER(TRIM(merchant)) AS merchant,
    LOWER(category) AS category,
    city,
    state,
    CASE 
        WHEN is_fraud = '1' THEN 1 
        ELSE 0 
    END AS is_fraud
FROM raw.transactions_raw
WHERE amt IS NOT NULL
  AND cc_num IS NOT NULL;
3. MART Layer

Analytical tables are created for business use.

Customer Metrics
CREATE TABLE mart.customer_metrics AS
SELECT
    customer_id,
    COUNT(*) AS transactions_count,
    SUM(amount) AS total_spent,
    AVG(amount) AS avg_transaction,
    MAX(transaction_time) AS last_transaction
FROM clean.transactions
GROUP BY customer_id;
Category Metrics
CREATE TABLE mart.category_metrics AS
SELECT
    category,
    COUNT(*) AS transactions_count,
    SUM(amount) AS total_spent,
    AVG(amount) AS avg_check
FROM clean.transactions
GROUP BY category;
Daily Metrics
CREATE TABLE mart.daily_metrics AS
SELECT
    DATE(transaction_time) AS date,
    COUNT(*) AS transactions_count,
    SUM(amount) AS revenue,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM clean.transactions
GROUP BY DATE(transaction_time);

Analysis Examples

Top Customers
SELECT *
FROM mart.customer_metrics
ORDER BY total_spent DESC
LIMIT 10;
Category Share
SELECT
    category,
    SUM(total_spent) / SUM(SUM(total_spent)) OVER () AS share
FROM mart.category_metrics
GROUP BY category;
Cumulative Revenue
SELECT
    date,
    SUM(revenue) OVER (ORDER BY date) AS cumulative_revenue
FROM mart.daily_metrics;
Customer Segmentation
SELECT
    customer_id,
    total_spent,
    CASE
        WHEN total_spent > 5000 THEN 'VIP'
        WHEN total_spent > 1000 THEN 'MID'
        ELSE 'LOW'
    END AS segment
FROM mart.customer_metrics;

Additional Features

Fraud Analysis
SELECT *
FROM clean.transactions
WHERE is_fraud = 1;
Anomaly Detection
SELECT *
FROM clean.transactions
WHERE amount > (
    SELECT AVG(amount) * 5 FROM clean.transactions
);
RFM Analysis
SELECT
    customer_id,
    MAX(transaction_time) AS recency,
    COUNT(*) AS frequency,
    SUM(amount) AS monetary
FROM clean.transactions
GROUP BY customer_id;

Tech Stack

PostgreSQL
SQL
DBeaver (for database interaction)

Key Takeaways

This project demonstrates:

working with raw, unstructured data
data cleaning and normalization
building analytical data models
writing complex SQL queries
deriving business insights from data

Result

The final output is a set of structured tables and analytical queries that allow:

understanding customer behavior
identifying top-performing categories
tracking revenue trends
detecting anomalies and fraud patterns
📌 Notes

This project focuses on SQL and data processing logic rather than machine learning or visualization tools.
It reflects typical entry-level data engineering and BI tasks.
