/*
===============================================================================
PROJECT: E-Commerce Revenue & Customer Retention Analysis
DATABASE: MySQL 8.0+
SOURCE: Online Retail transaction CSV
PURPOSE:
  1. Load and validate raw transaction data.
  2. Build a cleaned transaction table with revenue.
  3. Analyze revenue, orders, customers, and new/returning customer behavior.
  4. Build monthly customer cohorts and retention metrics.
  5. Calculate RFM metrics for customer segmentation.
===============================================================================

IMPORTANT SETUP NOTES
- Update the LOAD DATA INFILE path to the CSV location on your computer.
- Ensure the MySQL server account can read that path and that local/server
  LOAD DATA permissions are configured appropriately.
- This script is organized into sections. Run the setup/loading section once,
  then rerun analytical SELECT statements as needed.
- The script drops and recreates derived tables when their CREATE TABLE
  statements are rerun. Export or back up any results you need to preserve.
- Negative quantities and prices are excluded from the cleaned sales table.
  This is a project-specific decision; returns/cancellations should be
  analyzed separately if they are in scope.
*/

-- =============================================================================
-- 01. DATABASE SETUP
-- =============================================================================

CREATE DATABASE IF NOT EXISTS retail_analytics;
USE retail_analytics;

-- =============================================================================
-- 02. RAW TABLE
-- Keep invoice timestamp as TEXT initially so date parsing can be validated.
-- =============================================================================

CREATE TABLE IF NOT EXISTS transaction_raw (
    invoice_no   VARCHAR(20),
    stock_code   VARCHAR(20),
    description  TEXT,
    quantity     INT,
    invoice_ts   VARCHAR(30),
    unit_price   DECIMAL(10, 2),
    customer_id  VARCHAR(20),
    country      VARCHAR(100)
);

-- Load the source CSV into transaction_raw.
-- Change the path below to match your machine. If the table already contains
-- data, TRUNCATE it before reloading to avoid importing duplicate rows.
--
-- TRUNCATE TABLE transaction_raw;
--
-- LOAD DATA INFILE 'C:/path/to/online_retail_II.csv'
-- INTO TABLE transaction_raw
-- CHARACTER SET latin1
-- FIELDS TERMINATED BY ','
-- OPTIONALLY ENCLOSED BY '"'
-- LINES TERMINATED BY '\\n'
-- IGNORE 1 ROWS
-- (invoice_no, stock_code, description, quantity, invoice_ts,
--  unit_price, customer_id, country);

-- =============================================================================
-- 03. RAW DATA QUALITY CHECKS
-- Run these checks before cleaning.
-- =============================================================================

-- Row count
SELECT COUNT(*) AS raw_row_count
FROM transaction_raw;

-- Date range as raw text (visual inspection)
SELECT invoice_ts
FROM transaction_raw
WHERE invoice_ts IS NOT NULL
LIMIT 10;

-- Missing values by important field
SELECT
    COUNT(*) AS total_rows,
    SUM(invoice_no IS NULL OR TRIM(invoice_no) = '') AS missing_invoice_no,
    SUM(stock_code IS NULL OR TRIM(stock_code) = '') AS missing_stock_code,
    SUM(description IS NULL OR TRIM(description) = '') AS missing_description,
    SUM(invoice_ts IS NULL OR TRIM(invoice_ts) = '') AS missing_invoice_ts,
    SUM(customer_id IS NULL OR TRIM(customer_id) = '') AS missing_customer_id,
    SUM(quantity IS NULL) AS missing_quantity,
    SUM(unit_price IS NULL) AS missing_unit_price
FROM transaction_raw;

-- Check distinct countries
SELECT DISTINCT country
FROM transaction_raw
ORDER BY country;

-- Inspect returns/cancellations and negative prices separately
SELECT *
FROM transaction_raw
WHERE quantity < 0
LIMIT 100;

SELECT *
FROM transaction_raw
WHERE unit_price < 0
LIMIT 100;

-- Identify possible repeated line items. This flags groups for investigation;
-- it does not prove that every repeated line is an erroneous duplicate.
SELECT
    invoice_no,
    stock_code,
    quantity,
    COUNT(*) AS duplicate_count
FROM transaction_raw
GROUP BY invoice_no, stock_code, quantity
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Check whether timestamps can be parsed with the expected source format.
SELECT
    invoice_ts,
    STR_TO_DATE(invoice_ts, '%d-%m-%Y %H:%i') AS parsed_invoice_datetime
FROM transaction_raw
WHERE invoice_ts IS NOT NULL
LIMIT 20;

-- Count rows where the expected date format fails
SELECT COUNT(*) AS unparseable_timestamp_rows
FROM transaction_raw
WHERE invoice_ts IS NOT NULL
  AND STR_TO_DATE(invoice_ts, '%d-%m-%Y %H:%i') IS NULL;

-- =============================================================================
-- 04. CREATE CLEAN TRANSACTION TABLE
-- Notes:
-- - DISTINCT removes rows that are identical across the selected fields.
-- - Rows without customer IDs are excluded from customer-level analysis.
-- - Negative/zero quantities and non-positive prices are excluded from sales.
-- - Date parsing is explicit; unparseable dates are excluded.
-- =============================================================================

DROP TABLE IF EXISTS transaction_clean;

CREATE TABLE transaction_clean AS
SELECT DISTINCT
    TRIM(invoice_no) AS invoice_no,
    TRIM(stock_code) AS stock_code,
    NULLIF(TRIM(description), '') AS description,
    quantity,
    STR_TO_DATE(invoice_ts, '%d-%m-%Y %H:%i') AS invoice_datetime,
    unit_price,
    NULLIF(TRIM(customer_id), '') AS customer_id,
    TRIM(country) AS country,
    CAST(quantity * unit_price AS DECIMAL(12, 2)) AS revenue
FROM transaction_raw
WHERE NULLIF(TRIM(customer_id), '') IS NOT NULL
  AND NULLIF(TRIM(invoice_no), '') IS NOT NULL
  AND STR_TO_DATE(invoice_ts, '%d-%m-%Y %H:%i') IS NOT NULL
  AND quantity > 0
  AND unit_price > 0;

-- Helpful indexes for joins and common analysis filters
CREATE INDEX idx_transaction_clean_customer
    ON transaction_clean (customer_id);

CREATE INDEX idx_transaction_clean_datetime
    ON transaction_clean (invoice_datetime);

CREATE INDEX idx_transaction_clean_invoice
    ON transaction_clean (invoice_no);

-- Validate the cleaned table
SELECT COUNT(*) AS cleaned_row_count
FROM transaction_clean;

SELECT
    MIN(invoice_datetime) AS first_transaction_datetime,
    MAX(invoice_datetime) AS last_transaction_datetime
FROM transaction_clean;

SELECT
    SUM(customer_id IS NULL) AS missing_customer_ids,
    SUM(invoice_datetime IS NULL) AS missing_dates,
    SUM(revenue IS NULL) AS missing_revenue,
    SUM(quantity <= 0) AS non_positive_quantities,
    SUM(unit_price <= 0) AS non_positive_prices
FROM transaction_clean;

-- Check exact duplicates remaining after cleaning
SELECT
    invoice_no,
    stock_code,
    description,
    quantity,
    invoice_datetime,
    unit_price,
    customer_id,
    country,
    COUNT(*) AS duplicate_count
FROM transaction_clean
GROUP BY
    invoice_no, stock_code, description, quantity,
    invoice_datetime, unit_price, customer_id, country
HAVING COUNT(*) > 1;

-- =============================================================================
-- 05. EXECUTIVE KPIs
-- Revenue here is line-item revenue: quantity * unit_price.
-- Order count uses distinct invoice numbers.
-- =============================================================================

SELECT
    COUNT(DISTINCT customer_id) AS total_customers,
    COUNT(DISTINCT invoice_no) AS total_orders,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(SUM(revenue) / NULLIF(COUNT(DISTINCT invoice_no), 0), 2)
        AS average_order_value,
    ROUND(SUM(quantity), 0) AS units_sold
FROM transaction_clean;

-- Monthly revenue, orders, customers, and AOV
SELECT
    DATE_FORMAT(invoice_datetime, '%Y-%m') AS month,
    ROUND(SUM(revenue), 2) AS total_revenue,
    COUNT(DISTINCT invoice_no) AS total_orders,
    COUNT(DISTINCT customer_id) AS active_customers,
    ROUND(SUM(revenue) / NULLIF(COUNT(DISTINCT invoice_no), 0), 2)
        AS average_order_value
FROM transaction_clean
GROUP BY DATE_FORMAT(invoice_datetime, '%Y-%m')
ORDER BY month;

-- Revenue by country
SELECT
    country,
    COUNT(DISTINCT invoice_no) AS total_orders,
    COUNT(DISTINCT customer_id) AS customers,
    ROUND(SUM(revenue), 2) AS total_revenue
FROM transaction_clean
GROUP BY country
ORDER BY total_revenue DESC;

-- =============================================================================
-- 06. CUSTOMER FIRST PURCHASE AND NEW/RETURNING ANALYSIS
-- A customer is considered "New" on their first purchase date and "Returning"
-- on later purchase dates. A customer can appear in both categories across
-- the full period, so category customer counts are not additive.
-- =============================================================================

DROP TABLE IF EXISTS customer_first_purchases;

CREATE TABLE customer_first_purchases AS
SELECT
    customer_id,
    MIN(invoice_datetime) AS first_purchase_date
FROM transaction_clean
GROUP BY customer_id;

ALTER TABLE customer_first_purchases
    ADD PRIMARY KEY (customer_id);

DROP TABLE IF EXISTS transaction_customer_type;

CREATE TABLE transaction_customer_type AS
SELECT
    t.invoice_no,
    t.stock_code,
    t.description,
    t.quantity,
    t.invoice_datetime,
    t.unit_price,
    t.customer_id,
    t.country,
    t.revenue,
    f.first_purchase_date,
    CASE
        WHEN DATE(t.invoice_datetime) = DATE(f.first_purchase_date)
            THEN 'New'
        ELSE 'Returning'
    END AS customer_type
FROM transaction_clean AS t
JOIN customer_first_purchases AS f
    ON t.customer_id = f.customer_id;

CREATE INDEX idx_customer_type_datetime
    ON transaction_customer_type (invoice_datetime);

CREATE INDEX idx_customer_type_customer
    ON transaction_customer_type (customer_id);

-- Overall revenue and order contribution by transaction customer type
SELECT
    customer_type,
    COUNT(DISTINCT invoice_no) AS total_orders,
    COUNT(DISTINCT customer_id) AS customers_seen_in_category,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(
        SUM(revenue) / NULLIF(COUNT(DISTINCT customer_id), 0),
        2
    ) AS revenue_per_customer,
    ROUND(
        SUM(revenue) / NULLIF(COUNT(DISTINCT invoice_no), 0),
        2
    ) AS average_order_value
FROM transaction_customer_type
GROUP BY customer_type
ORDER BY total_revenue DESC;

-- Monthly new vs returning performance
SELECT
    DATE_FORMAT(invoice_datetime, '%Y-%m') AS month,
    customer_type,
    COUNT(DISTINCT customer_id) AS customers_seen_in_category,
    COUNT(DISTINCT invoice_no) AS orders,
    ROUND(SUM(revenue), 2) AS total_revenue
FROM transaction_customer_type
GROUP BY DATE_FORMAT(invoice_datetime, '%Y-%m'), customer_type
ORDER BY month, customer_type;

-- Monthly share of revenue attributed to returning-customer transactions
SELECT
    month,
    ROUND(
        100.0 * SUM(
            CASE WHEN customer_type = 'Returning'
                 THEN total_revenue ELSE 0 END
        ) / NULLIF(SUM(total_revenue), 0),
        2
    ) AS returning_revenue_percentage
FROM (
    SELECT
        DATE_FORMAT(invoice_datetime, '%Y-%m') AS month,
        customer_type,
        SUM(revenue) AS total_revenue
    FROM transaction_customer_type
    GROUP BY DATE_FORMAT(invoice_datetime, '%Y-%m'), customer_type
) AS monthly_customer_revenue
GROUP BY month
ORDER BY month;

-- =============================================================================
-- 07. CUSTOMER COHORT RETENTION
-- Cohort month = month of a customer's first recorded purchase.
-- Purchase month = month in which the customer made a purchase.
-- A customer is counted once per cohort/purchase month.
-- =============================================================================

DROP TABLE IF EXISTS customer_cohort_monthly;

CREATE TABLE customer_cohort_monthly AS
SELECT DISTINCT
    t.customer_id,
    DATE_FORMAT(f.first_purchase_date, '%Y-%m') AS cohort_month,
    DATE_FORMAT(t.invoice_datetime, '%Y-%m') AS purchase_month
FROM transaction_clean AS t
JOIN customer_first_purchases AS f
    ON t.customer_id = f.customer_id;

CREATE INDEX idx_cohort_monthly_cohort
    ON customer_cohort_monthly (cohort_month);

CREATE INDEX idx_cohort_monthly_purchase
    ON customer_cohort_monthly (purchase_month);

-- Long-form cohort table: one row per cohort and lifecycle month
WITH customer_months AS (
    SELECT
        customer_id,
        cohort_month,
        purchase_month,
        TIMESTAMPDIFF(
            MONTH,
            STR_TO_DATE(CONCAT(cohort_month, '-01'), '%Y-%m-%d'),
            STR_TO_DATE(CONCAT(purchase_month, '-01'), '%Y-%m-%d')
        ) AS months_since_first_purchase
    FROM customer_cohort_monthly
),
monthly_cohorts AS (
    SELECT
        cohort_month,
        months_since_first_purchase,
        COUNT(DISTINCT customer_id) AS customers
    FROM customer_months
    GROUP BY cohort_month, months_since_first_purchase
),
cohort_sizes AS (
    SELECT
        cohort_month,
        months_since_first_purchase,
        customers,
        MAX(
            CASE WHEN months_since_first_purchase = 0
                 THEN customers END
        ) OVER (PARTITION BY cohort_month) AS cohort_size
    FROM monthly_cohorts
)
SELECT
    cohort_month,
    months_since_first_purchase,
    customers,
    cohort_size,
    ROUND(100.0 * customers / NULLIF(cohort_size, 0), 2) AS retention_rate
FROM cohort_sizes
ORDER BY cohort_month, months_since_first_purchase;

-- Pivoted retention matrix M0-M12 for a heatmap
WITH customer_months AS (
    SELECT
        customer_id,
        cohort_month,
        purchase_month,
        TIMESTAMPDIFF(
            MONTH,
            STR_TO_DATE(CONCAT(cohort_month, '-01'), '%Y-%m-%d'),
            STR_TO_DATE(CONCAT(purchase_month, '-01'), '%Y-%m-%d')
        ) AS months_since_first_purchase
    FROM customer_cohort_monthly
),
monthly_cohorts AS (
    SELECT
        cohort_month,
        months_since_first_purchase,
        COUNT(DISTINCT customer_id) AS customers
    FROM customer_months
    GROUP BY cohort_month, months_since_first_purchase
),
cohort_sizes AS (
    SELECT
        cohort_month,
        months_since_first_purchase,
        customers,
        MAX(
            CASE WHEN months_since_first_purchase = 0
                 THEN customers END
        ) OVER (PARTITION BY cohort_month) AS cohort_size
    FROM monthly_cohorts
),
retentions AS (
    SELECT
        cohort_month,
        months_since_first_purchase,
        ROUND(100.0 * customers / NULLIF(cohort_size, 0), 2)
            AS retention_rate
    FROM cohort_sizes
)
SELECT
    cohort_month,
    MAX(CASE WHEN months_since_first_purchase = 0 THEN retention_rate END) AS M0,
    MAX(CASE WHEN months_since_first_purchase = 1 THEN retention_rate END) AS M1,
    MAX(CASE WHEN months_since_first_purchase = 2 THEN retention_rate END) AS M2,
    MAX(CASE WHEN months_since_first_purchase = 3 THEN retention_rate END) AS M3,
    MAX(CASE WHEN months_since_first_purchase = 4 THEN retention_rate END) AS M4,
    MAX(CASE WHEN months_since_first_purchase = 5 THEN retention_rate END) AS M5,
    MAX(CASE WHEN months_since_first_purchase = 6 THEN retention_rate END) AS M6,
    MAX(CASE WHEN months_since_first_purchase = 7 THEN retention_rate END) AS M7,
    MAX(CASE WHEN months_since_first_purchase = 8 THEN retention_rate END) AS M8,
    MAX(CASE WHEN months_since_first_purchase = 9 THEN retention_rate END) AS M9,
    MAX(CASE WHEN months_since_first_purchase = 10 THEN retention_rate END) AS M10,
    MAX(CASE WHEN months_since_first_purchase = 11 THEN retention_rate END) AS M11,
    MAX(CASE WHEN months_since_first_purchase = 12 THEN retention_rate END) AS M12
FROM retentions
GROUP BY cohort_month
ORDER BY cohort_month;

-- Average retention by lifecycle month, with cohort coverage.
-- Later months have fewer eligible cohorts; interpret those averages carefully.
WITH customer_months AS (
    SELECT
        customer_id,
        cohort_month,
        purchase_month,
        TIMESTAMPDIFF(
            MONTH,
            STR_TO_DATE(CONCAT(cohort_month, '-01'), '%Y-%m-%d'),
            STR_TO_DATE(CONCAT(purchase_month, '-01'), '%Y-%m-%d')
        ) AS months_since_first_purchase
    FROM customer_cohort_monthly
),
monthly_cohorts AS (
    SELECT
        cohort_month,
        months_since_first_purchase,
        COUNT(DISTINCT customer_id) AS customers
    FROM customer_months
    GROUP BY cohort_month, months_since_first_purchase
),
cohort_sizes AS (
    SELECT
        cohort_month,
        months_since_first_purchase,
        customers,
        MAX(
            CASE WHEN months_since_first_purchase = 0
                 THEN customers END
        ) OVER (PARTITION BY cohort_month) AS cohort_size
    FROM monthly_cohorts
),
retentions AS (
    SELECT
        cohort_month,
        months_since_first_purchase,
        100.0 * customers / NULLIF(cohort_size, 0) AS retention_rate
    FROM cohort_sizes
)
SELECT
    months_since_first_purchase,
    COUNT(DISTINCT cohort_month) AS number_of_cohorts,
    ROUND(AVG(retention_rate), 2) AS average_retention
FROM retentions
GROUP BY months_since_first_purchase
ORDER BY months_since_first_purchase;

-- Best M1 retention by cohort
WITH customer_months AS (
    SELECT
        customer_id,
        cohort_month,
        purchase_month,
        TIMESTAMPDIFF(
            MONTH,
            STR_TO_DATE(CONCAT(cohort_month, '-01'), '%Y-%m-%d'),
            STR_TO_DATE(CONCAT(purchase_month, '-01'), '%Y-%m-%d')
        ) AS months_since_first_purchase
    FROM customer_cohort_monthly
),
monthly_cohorts AS (
    SELECT
        cohort_month,
        months_since_first_purchase,
        COUNT(DISTINCT customer_id) AS customers
    FROM customer_months
    GROUP BY cohort_month, months_since_first_purchase
),
cohort_sizes AS (
    SELECT
        cohort_month,
        months_since_first_purchase,
        customers,
        MAX(
            CASE WHEN months_since_first_purchase = 0
                 THEN customers END
        ) OVER (PARTITION BY cohort_month) AS cohort_size
    FROM monthly_cohorts
),
retentions AS (
    SELECT
        cohort_month,
        months_since_first_purchase,
        100.0 * customers / NULLIF(cohort_size, 0) AS retention_rate
    FROM cohort_sizes
)
SELECT
    cohort_month,
    ROUND(retention_rate, 2) AS m1_retention
FROM retentions
WHERE months_since_first_purchase = 1
ORDER BY retention_rate DESC;

-- =============================================================================
-- 08. RFM CUSTOMER SEGMENTATION
-- Recency reference date is one day after the latest transaction date in the
-- cleaned data. Frequency is distinct invoices; Monetary is summed revenue.
-- Scores use NTILE(5). Recency is reversed so more recent customers score 5.
-- Segment labels below are rule-based examples and can be adjusted.
-- =============================================================================

DROP TABLE IF EXISTS customer_rfm;

CREATE TABLE customer_rfm AS
WITH reference_date AS (
    SELECT DATE_ADD(MAX(invoice_datetime), INTERVAL 1 DAY) AS analysis_date
    FROM transaction_clean
),
rfm_base AS (
    SELECT
        t.customer_id,
        DATEDIFF(r.analysis_date, MAX(t.invoice_datetime)) AS recency_days,
        COUNT(DISTINCT t.invoice_no) AS frequency,
        ROUND(SUM(t.revenue), 2) AS monetary
    FROM transaction_clean AS t
    CROSS JOIN reference_date AS r
    GROUP BY t.customer_id, r.analysis_date
),
rfm_scores AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        6 - NTILE(5) OVER (ORDER BY recency_days ASC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
)
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
            THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3
            THEN 'Loyal / Active'
        WHEN r_score >= 4 AND f_score <= 2
            THEN 'Recent Customers'
        WHEN r_score <= 2 AND f_score >= 3
            THEN 'At Risk'
        ELSE 'Needs Attention'
    END AS customer_segment
FROM rfm_scores;

-- RFM segment summary
SELECT
    customer_segment,
    COUNT(*) AS customers,
    ROUND(SUM(monetary), 2) AS total_revenue,
    ROUND(AVG(monetary), 2) AS average_customer_revenue,
    ROUND(AVG(frequency), 2) AS average_orders_per_customer,
    ROUND(AVG(recency_days), 1) AS average_recency_days
FROM customer_rfm
GROUP BY customer_segment
ORDER BY total_revenue DESC;

-- =============================================================================
-- 09. FINAL VALIDATION / PROJECT CHECKS
-- Compare these outputs with the KPI queries above after the script runs.
-- =============================================================================

SELECT
    (SELECT COUNT(*) FROM transaction_raw) AS raw_rows,
    (SELECT COUNT(*) FROM transaction_clean) AS cleaned_rows,
    (SELECT COUNT(DISTINCT customer_id) FROM transaction_clean) AS customers,
    (SELECT COUNT(DISTINCT invoice_no) FROM transaction_clean) AS orders,
    (SELECT ROUND(SUM(revenue), 2) FROM transaction_clean) AS revenue;

-- End of project SQL script.
