/* =========================================================
PROJECT: Customer Retention & Revenue Leakage Analysis
STACK: MySQL
AUTHOR: Indranil Bhosale
DESCRIPTION:
Production-style analytics pipeline:
RAW DATA → FACTS → AGGREGATES → POWER BI READY VIEWS
========================================================= */

/* =========================================================
SECTION 1: UTILITY FUNCTION
Purpose: Standardize product descriptions into Proper Case
========================================================= */
DROP FUNCTION IF EXISTS proper_case;
DELIMITER $$
CREATE FUNCTION proper_case(str VARCHAR(255)) RETURNS VARCHAR(255) DETERMINISTIC
BEGIN
DECLARE result VARCHAR(255) DEFAULT '';
DECLARE word VARCHAR(50);
DECLARE pos INT;
SET str = TRIM(str);
WHILE LENGTH(str) > 0 DO
SET word = SUBSTRING_INDEX(str,' ',1);
SET result = CONCAT(result,IF(result='','',' '),CONCAT(UPPER(LEFT(word,1)),LOWER(SUBSTRING(word,2))));
SET pos = LOCATE(' ',str);
IF pos = 0 THEN SET str=''; ELSE SET str = SUBSTRING(str,pos+1); END IF;
END WHILE;
RETURN result;
END$$
DELIMITER ;

/* =========================================================
SECTION 2: FACT TABLES
Purpose: Create clean, typed, atomic business facts
========================================================= */

/* ---------- FACT: COMPLETED SALES TRANSACTIONS ---------- */
CREATE OR REPLACE VIEW fact_sales AS
SELECT id,invoice,stockcode,
proper_case(REGEXP_REPLACE(REPLACE(REGEXP_REPLACE(description,'\\s*\\+\\s*',' + '),' ,',','),'\\s+',' ')) AS product_description,
CAST(quantity AS SIGNED) AS quantity,
STR_TO_DATE(invoicedate,'%Y-%m-%d %H:%i:%s') AS invoice_datetime,
CAST(price AS DECIMAL(10,2)) AS unit_price,
CAST(quantity AS SIGNED)*CAST(price AS DECIMAL(10,2)) AS revenue,
CAST(REPLACE(customer_id,'.0','') AS UNSIGNED) AS customer_id,
CASE country
WHEN 'United Kingdom' THEN 'UK'
WHEN 'United Arab Emirates' THEN 'UAE'
WHEN 'Czech Republic' THEN 'CZ'
WHEN 'European Community' THEN 'EU'
WHEN 'Channel Islands' THEN 'CI'
ELSE country END AS country
FROM online_retail
WHERE invoice NOT LIKE 'C%' AND quantity<>0 AND price<>0 AND customer_id<>0;

/* ---------- FACT: RETURNS / CANCELLATIONS ---------- */
CREATE OR REPLACE VIEW fact_returns AS
SELECT id,invoice,stockcode,
proper_case(REGEXP_REPLACE(REPLACE(REGEXP_REPLACE(description,'\\s*\\+\\s*',' + '),' ,',','),'\\s+',' ')) AS product_description,
ABS(CAST(quantity AS SIGNED)) AS return_quantity,
STR_TO_DATE(invoicedate,'%Y-%m-%d %H:%i:%s') AS return_datetime,
CAST(price AS DECIMAL(10,2)) AS unit_price,
ABS(CAST(quantity AS SIGNED)*CAST(price AS DECIMAL(10,2))) AS return_value,
CAST(REPLACE(customer_id,'.0','') AS UNSIGNED) AS customer_id,
CASE country
WHEN 'United Kingdom' THEN 'UK'
WHEN 'United Arab Emirates' THEN 'UAE'
WHEN 'Czech Republic' THEN 'CZ'
WHEN 'European Community' THEN 'EU'
WHEN 'Channel Islands' THEN 'CI'
ELSE country END AS country
FROM online_retail
WHERE invoice LIKE 'C%' AND quantity<>0 AND price<>0 AND customer_id<>0;

/* =========================================================
SECTION 3: AGGREGATED FACTS & DIMENSIONS
Purpose: Analytical summaries for invoices and customers
========================================================= */

/* ---------- FACT: INVOICE-LEVEL SUMMARY ---------- */
CREATE OR REPLACE VIEW fact_invoice_summary AS
SELECT invoice,customer_id,DATE(MIN(invoice_datetime)) AS invoice_date,
COUNT(DISTINCT stockcode) AS unique_products,
SUM(quantity) AS total_quantity,
SUM(revenue) AS invoice_revenue,
country
FROM fact_sales
GROUP BY invoice,customer_id,country;

/* ---------- DIMENSION: CUSTOMER METRICS ---------- */
CREATE OR REPLACE VIEW dim_customer_metrics AS
SELECT customer_id,
COUNT(DISTINCT invoice) AS total_orders,
SUM(revenue) AS total_revenue,
AVG(revenue) AS avg_order_value,
DATE(MIN(invoice_datetime)) AS first_purchase_date,
DATE(MAX(invoice_datetime)) AS last_purchase_date,
DATEDIFF(DATE(MAX(invoice_datetime)),DATE(MIN(invoice_datetime))) AS customer_lifetime_days
FROM fact_sales
GROUP BY customer_id;

/* =========================================================
SECTION 4: POWER BI OPTIMIZED VIEWS
Purpose: Pre-aggregated, dashboard-ready datasets
========================================================= */

/* ---------- KPI OVERVIEW (EXECUTIVE SUMMARY) ---------- */
CREATE OR REPLACE VIEW bi_kpi_overview AS
SELECT COUNT(DISTINCT customer_id) AS total_customers,
COUNT(DISTINCT invoice) AS total_orders,
ROUND(SUM(revenue),2) AS total_revenue,
ROUND(SUM(revenue)/COUNT(DISTINCT invoice),2) AS avg_order_value
FROM fact_sales;

/* ---------- MONTHLY REVENUE & MOM GROWTH ---------- */
CREATE OR REPLACE VIEW bi_monthly_revenue AS
WITH m AS (
SELECT DATE_FORMAT(invoice_datetime,'%Y-%m') AS month,SUM(revenue) AS monthly_revenue
FROM fact_sales GROUP BY month
)
SELECT month,monthly_revenue,
LAG(monthly_revenue) OVER (ORDER BY month) AS prev_month_revenue,
ROUND((monthly_revenue-LAG(monthly_revenue) OVER (ORDER BY month))/
LAG(monthly_revenue) OVER (ORDER BY month)*100,2) AS mom_growth_pct
FROM m;

/* ---------- NEW VS REPEAT CUSTOMER REVENUE ---------- */
CREATE OR REPLACE VIEW bi_new_vs_repeat_revenue AS
WITH fp AS (
SELECT customer_id,MIN(invoice_datetime) AS first_purchase_datetime
FROM fact_sales GROUP BY customer_id
)
SELECT DATE_FORMAT(f.invoice_datetime,'%Y-%m') AS month,
CASE WHEN f.invoice_datetime=fp.first_purchase_datetime
THEN 'New Customer Revenue'
ELSE 'Repeat Customer Revenue' END AS revenue_type,
SUM(f.revenue) AS total_revenue
FROM fact_sales f JOIN fp ON f.customer_id=fp.customer_id
GROUP BY month,revenue_type;

/* ---------- CUSTOMER RETENTION (COHORT AGE) ---------- */
CREATE OR REPLACE VIEW bi_customer_retention AS
WITH c AS (
SELECT customer_id,MIN(invoice_datetime) AS first_purchase_datetime
FROM fact_sales GROUP BY customer_id
)
SELECT PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM f.invoice_datetime),
EXTRACT(YEAR_MONTH FROM c.first_purchase_datetime)) AS cohort_age,
COUNT(DISTINCT f.customer_id) AS active_customers
FROM fact_sales f JOIN c ON f.customer_id=c.customer_id
GROUP BY cohort_age ORDER BY cohort_age;

/* ---------- REVENUE RETENTION (VALUE DECAY) ---------- */
CREATE OR REPLACE VIEW bi_revenue_retention AS
WITH c AS (
SELECT customer_id,MIN(invoice_datetime) AS first_purchase_datetime
FROM fact_sales GROUP BY customer_id
),
r AS (
SELECT PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM f.invoice_datetime),
EXTRACT(YEAR_MONTH FROM c.first_purchase_datetime)) AS cohort_age,
SUM(f.revenue) AS revenue
FROM fact_sales f JOIN c ON f.customer_id=c.customer_id
GROUP BY cohort_age
),
b AS (SELECT revenue AS base_revenue FROM r WHERE cohort_age=0)
SELECT r.cohort_age,r.revenue,
ROUND(r.revenue/b.base_revenue*100,2) AS revenue_retention_pct
FROM r CROSS JOIN b ORDER BY r.cohort_age;

/* ---------- RETURNS & REVENUE LEAKAGE ---------- */
CREATE OR REPLACE VIEW bi_returns_overview AS
SELECT ROUND(SUM(return_value),2) AS total_return_value,
ROUND(SUM(return_value)/(SELECT SUM(revenue) FROM fact_sales)*100,2) AS return_rate_pct
FROM fact_returns;

/* ---------- HIGH-RISK RETURN CUSTOMERS ---------- */
CREATE OR REPLACE VIEW bi_high_return_customers AS
SELECT customer_id,
COUNT(DISTINCT invoice) AS total_returns,
SUM(return_value) AS total_return_value
FROM fact_returns
GROUP BY customer_id
ORDER BY total_return_value DESC;
