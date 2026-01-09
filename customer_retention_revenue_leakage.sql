/* =========================================================
   PROJECT: Customer Retention & Revenue Leakage Analysis
   STACK: MySQL
   AUTHOR: Indranil Bhosale
   DESCRIPTION:
   End-to-end SQL pipeline covering data cleaning, sales,
   returns, retention cohorts, revenue trends, and leakage.
   ========================================================= */

/* ===================== 1.0 UTILITY FUNCTION ===================== */
DROP FUNCTION IF EXISTS PROPER_CASE;
DELIMITER $$
CREATE FUNCTION PROPER_CASE(str VARCHAR(255)) RETURNS VARCHAR(255) DETERMINISTIC
BEGIN
DECLARE result VARCHAR(255) DEFAULT ''; DECLARE word VARCHAR(50); DECLARE pos INT;
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

/* ===================== 2.0 SALES VIEW (EXCLUDES CANCELLATIONS) ===================== */
CREATE OR REPLACE VIEW online_retail_clean AS
SELECT id,invoice,stockcode,
CASE WHEN description IS NULL THEN NULL ELSE PROPER_CASE(REGEXP_REPLACE(REPLACE(REGEXP_REPLACE(description,'\\s*\\+\\s*',' + '),' ,',','),'\\s+',' ')) END AS product_description,
CAST(quantity AS SIGNED) AS quantity,
STR_TO_DATE(invoicedate,'%Y-%m-%d %H:%i:%s') AS invoice_date,
CAST(price AS DECIMAL(8,2)) AS unit_price,
CAST(quantity AS SIGNED)*CAST(price AS DECIMAL(8,2)) AS revenue,
CAST(REPLACE(customer_id,'.0','') AS UNSIGNED) AS customer_id,
CASE country WHEN 'United Kingdom' THEN 'UK' WHEN 'United Arab Emirates' THEN 'UAE' WHEN 'Czech Republic' THEN 'CZ' WHEN 'European Community' THEN 'EU' WHEN 'Channel Islands' THEN 'CI' ELSE country END AS country
FROM online_retail
WHERE invoice NOT LIKE 'C%' AND quantity<>0 AND price<>0 AND customer_id<>0;

/* ===================== 2.1 RETURNS VIEW (CANCELLATIONS) ===================== */
CREATE OR REPLACE VIEW online_retail_returns AS
SELECT id,invoice,stockcode,
CASE WHEN description IS NULL THEN NULL ELSE PROPER_CASE(REGEXP_REPLACE(REPLACE(REGEXP_REPLACE(description,'\\s*\\+\\s*',' + '),' ,',','),'\\s+',' ')) END AS product_description,
ABS(CAST(quantity AS SIGNED)) AS return_quantity,
STR_TO_DATE(invoicedate,'%Y-%m-%d %H:%i:%s') AS return_date,
CAST(price AS DECIMAL(8,2)) AS unit_price,
ABS(CAST(quantity AS SIGNED)*CAST(price AS DECIMAL(8,2))) AS return_value,
CAST(REPLACE(customer_id,'.0','') AS UNSIGNED) AS customer_id,
CASE country WHEN 'United Kingdom' THEN 'UK' WHEN 'United Arab Emirates' THEN 'UAE' WHEN 'Czech Republic' THEN 'CZ' WHEN 'European Community' THEN 'EU' WHEN 'Channel Islands' THEN 'CI' ELSE country END AS country
FROM online_retail
WHERE invoice LIKE 'C%' AND quantity<>0 AND price<>0 AND customer_id<>0;

/* ===================== 3.0 INVOICE SUMMARY ===================== */
CREATE OR REPLACE VIEW invoice_summary AS
SELECT invoice,customer_id,MIN(invoice_date) AS invoice_date,
COUNT(DISTINCT stockcode) AS unique_products,
SUM(quantity) AS total_quantity,
SUM(revenue) AS invoice_revenue,country
FROM online_retail_clean
GROUP BY invoice,customer_id,country;

/* ===================== 3.1 CUSTOMER SUMMARY ===================== */
CREATE OR REPLACE VIEW customer_summary AS
SELECT customer_id,
COUNT(DISTINCT invoice) AS total_orders,
SUM(revenue) AS total_revenue,
AVG(revenue) AS avg_order_value,
MIN(invoice_date) AS first_purchase_date,
MAX(invoice_date) AS last_purchase_date,
DATEDIFF(MAX(invoice_date),MIN(invoice_date)) AS customer_lifetime_days
FROM online_retail_clean
GROUP BY customer_id;

/* ===================== 4.1 PHASE 1 KPIs ===================== */
SELECT COUNT(DISTINCT customer_id) AS total_customers,
COUNT(DISTINCT invoice) AS total_orders,
SUM(revenue) AS total_revenue,
ROUND(SUM(revenue)/COUNT(DISTINCT invoice),2) AS avg_order_value
FROM online_retail_clean;

/* ===================== 4.2 ORDER DISTRIBUTION ===================== */
SELECT total_orders,COUNT(*) AS customer_count
FROM customer_summary
GROUP BY total_orders
ORDER BY total_orders;

/* ===================== 5.1 COHORT AGE MAPPING ===================== */
WITH customer_cohorts AS (
SELECT customer_id,MIN(invoice_date) AS first_purchase_date
FROM online_retail_clean GROUP BY customer_id
)
SELECT o.customer_id,
PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM o.invoice_date),EXTRACT(YEAR_MONTH FROM c.first_purchase_date)) AS cohort_age
FROM online_retail_clean o JOIN customer_cohorts c ON o.customer_id=c.customer_id;

/* ===================== 5.2 RETENTION COUNTS ===================== */
WITH customer_cohorts AS (
SELECT customer_id,MIN(invoice_date) AS first_purchase_date
FROM online_retail_clean GROUP BY customer_id
)
SELECT PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM o.invoice_date),EXTRACT(YEAR_MONTH FROM c.first_purchase_date)) AS cohort_age,
COUNT(DISTINCT o.customer_id) AS active_customers
FROM online_retail_clean o JOIN customer_cohorts c ON o.customer_id=c.customer_id
GROUP BY cohort_age ORDER BY cohort_age;

/* ===================== 6.1 MONTHLY REVENUE & MoM ===================== */
WITH monthly_revenue AS (
SELECT DATE_FORMAT(invoice_date,'%Y-%m') AS month,SUM(revenue) AS monthly_revenue
FROM online_retail_clean GROUP BY month
)
SELECT month,monthly_revenue,
LAG(monthly_revenue) OVER (ORDER BY month) AS prev_month,
ROUND((monthly_revenue-LAG(monthly_revenue) OVER (ORDER BY month))/
LAG(monthly_revenue) OVER (ORDER BY month)*100,2) AS mom_growth_pct
FROM monthly_revenue;

/* ===================== 6.2 NEW VS REPEAT REVENUE ===================== */
WITH first_purchase AS (
SELECT customer_id,MIN(invoice_date) AS first_purchase_date
FROM online_retail_clean GROUP BY customer_id
)
SELECT DATE_FORMAT(o.invoice_date,'%Y-%m') AS month,
CASE WHEN o.invoice_date=f.first_purchase_date THEN 'New Customer Revenue'
ELSE 'Repeat Customer Revenue' END AS revenue_type,
SUM(o.revenue) AS total_revenue
FROM online_retail_clean o JOIN first_purchase f ON o.customer_id=f.customer_id
GROUP BY month,revenue_type;

/* ===================== 6.3 COHORT REVENUE RETENTION ===================== */
CREATE OR REPLACE VIEW cohort_revenue_retention AS
WITH customer_cohorts AS (
SELECT customer_id,MIN(invoice_date) AS first_purchase_date
FROM online_retail_clean GROUP BY customer_id
),
cohort_revenue AS (
SELECT PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM o.invoice_date),EXTRACT(YEAR_MONTH FROM c.first_purchase_date)) AS cohort_age,
SUM(o.revenue) AS revenue
FROM online_retail_clean o JOIN customer_cohorts c ON o.customer_id=c.customer_id
GROUP BY cohort_age
),
base_revenue AS (
SELECT revenue AS base_revenue FROM cohort_revenue WHERE cohort_age=0
)
SELECT cr.cohort_age,cr.revenue,
ROUND(cr.revenue/br.base_revenue*100,2) AS revenue_retention_pct
FROM cohort_revenue cr CROSS JOIN base_revenue br
ORDER BY cr.cohort_age;

/* ===================== 7.1 TOTAL RETURNS ===================== */
SELECT ROUND(SUM(return_value),2) AS total_return_value
FROM online_retail_returns;

/* ===================== 7.2 RETURN RATE ===================== */
WITH sales AS (SELECT SUM(revenue) AS total_sales FROM online_retail_clean),
returns AS (SELECT SUM(return_value) AS total_returns FROM online_retail_returns)
SELECT total_sales,total_returns,ROUND(total_returns/total_sales*100,2) AS return_rate_pct
FROM sales CROSS JOIN returns;

/* ===================== 7.3 HIGH RETURN CUSTOMERS ===================== */
SELECT customer_id,COUNT(DISTINCT invoice) AS total_returns,
SUM(return_value) AS total_return_value
FROM online_retail_returns
GROUP BY customer_id
ORDER BY total_return_value DESC;
