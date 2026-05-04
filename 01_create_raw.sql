-- ================================================
-- 01_create_raw.sql
-- Create RAW (Bronze) layer for transactions data
-- ================================================

-- 1. Create schema
CREATE SCHEMA IF NOT EXISTS raw;

-- 2. Drop table if exists (for reruns)
DROP TABLE IF EXISTS raw.transactions_raw;

-- 3. Create raw table (all fields as TEXT for flexibility)
CREATE TABLE raw.transactions_raw (
trans_date_trans_time TEXT,
cc_num TEXT,
merchant TEXT,
category TEXT,
amt TEXT,
first TEXT,
last TEXT,
gender TEXT,
street TEXT,
city TEXT,
state TEXT,
zip TEXT,
lat TEXT,
long TEXT,
city_pop TEXT,
job TEXT,
dob TEXT,
trans_num TEXT,
unix_time TEXT,
merch_lat TEXT,
merch_long TEXT,
is_fraud TEXT
);

-- 4. Optional: quick check
SELECT 'raw.transactions_raw created successfully' AS status;
