# Customer Retention & Revenue Leakage Analysis (SQL + Power BI)

## 📌 Project Overview
This project analyzes **customer retention, revenue trends, and revenue leakage due to returns** using a real-world online retail dataset.

Instead of focusing only on topline revenue, the analysis answers deeper business questions:
- Why does revenue fluctuate?
- How quickly do customers churn?
- Is growth driven by new or repeat customers?
- How much revenue is silently lost through returns?

The project follows a **production-style analytics pipeline**:  
**Raw Data → SQL Fact Views → Analytical Aggregations → Power BI Dashboards**

---

## 🛠 Tech Stack
- **Database:** MySQL  
- **Querying & Modeling:** SQL (Views, CTEs, Window Functions)  
- **Visualization:** Power BI  
- **Data Source:** Public Online Retail transactional dataset (`online_retail.csv`)

---

## 📂 Data Architecture & Design

### 🔹 Raw Data Layer
- Raw CSV data is ingested into MySQL **without modification**
- All columns remain **TEXT**, preserving source fidelity
- Table: `online_retail`

> This mirrors real-world ingestion pipelines where raw data is never mutated.

---

### 🔹 Fact Layer (Business Events)
Clean, typed, and business-meaningful fact views are created from raw data:

| View Name | Description |
|----------|-------------|
| `fact_sales` | Completed sales transactions only |
| `fact_returns` | Returns / cancellations modeled as a **separate fact** |

**Key design decisions:**
- Sales and returns are **never mixed**
- Revenue is calculated in SQL
- `DATETIME` is preserved in fact tables for future extensibility
- All cleaning and casting happens in views, not raw tables

---

### 🔹 Aggregated Facts & Dimensions

| View Name | Purpose |
|----------|---------|
| `fact_invoice_summary` | Invoice-level metrics (revenue, quantity, products) |
| `dim_customer_metrics` | Customer lifetime metrics (orders, revenue, tenure) |

These views form the **analytical foundation** for KPIs and behavioral analysis.

---

### 🔹 Power BI Optimized Views
Power BI connects **only** to pre-aggregated, dashboard-ready views:

| View Name | Business Purpose |
|----------|------------------|
| `bi_kpi_overview` | Executive KPIs (Revenue, Customers, Orders, AOV) |
| `bi_monthly_revenue` | Monthly revenue & MoM growth |
| `bi_new_vs_repeat_revenue` | Revenue split by customer type |
| `bi_customer_retention` | Customer retention by cohort age |
| `bi_revenue_retention` | Revenue retention (value decay over time) |
| `bi_returns_overview` | Total returns & return rate |
| `bi_high_return_customers` | Customers with abnormal return behavior |

> All business logic lives in SQL. Power BI is used **only for visualization and storytelling**.

---

## 🔍 Key Business Questions Answered
- How healthy is the business beyond topline revenue?
- What percentage of customers churn after their first purchase?
- Is growth driven by acquisition or retention?
- How does customer revenue decay over time?
- How much revenue is lost due to returns?
- Are returns concentrated among specific customers?

---

## 📊 Core Analyses Performed

### 1️⃣ Business Health (KPIs)
- Total Revenue
- Total Customers
- Total Orders
- Average Order Value (AOV)

### 2️⃣ Customer Behavior
- Order frequency distribution
- One-time vs repeat customers
- Customer lifetime value patterns

### 3️⃣ Retention & Cohort Analysis
- Customer retention by cohort age
- Revenue retention curve (value decay)
- Identification of early churn risk

### 4️⃣ Revenue Trends
- Monthly revenue trends
- Month-over-Month (MoM) growth using window functions
- Seasonality and volatility analysis

### 5️⃣ Revenue Leakage (Returns)
- Total return value
- Return rate (% of revenue lost)
- High-risk customers with excessive returns

---

## 📈 Power BI Dashboard (Executive Storytelling)

The dashboard is designed for **decision-makers**, not raw exploration.

### 🔹 Key Visuals
- KPI cards (Revenue, Customers, AOV, Return Rate)
- Monthly Revenue & MoM Growth (Line charts)
- New vs Repeat Revenue Contribution
- Customer Retention Curve
- Revenue Retention Curve
- Top Customers by Return Value

> The dashboard highlights that this is a **retention and post-purchase experience problem**, not an acquisition problem.

---

## 💡 Key Insights
- Over **75% of customers churn after their first month**
- Revenue is heavily dependent on repeat customers
- Customer revenue decays sharply over time
- Revenue shows strong seasonality and volatility
- Approximately **6% of total revenue is lost due to returns**
- Returns are highly concentrated among a small group of customers

**Conclusion:**  
Improving **customer retention and post-purchase experience** will have a significantly higher ROI than focusing purely on customer acquisition.

---

## 🧠 Skills Demonstrated
- SQL data cleaning & transformation
- Fact vs dimension modeling
- CTEs and window functions
- Cohort & retention analysis
- Revenue leakage modeling
- Analytical data modeling
- Power BI dashboard design
- Business-first data storytelling

---

## 🚀 Future Enhancements
- Product-level return analysis
- RFM customer segmentation
- Predictive churn modeling
- Marketing or logistics data integration
- Migration to a full warehouse schema (if required)

---

## 👤 Author
**Indranil Bhosale**  
Aspiring Data Analyst  
SQL • Power BI • Analytics
