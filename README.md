# Customer Retention & Revenue Leakage Analysis

## 📌 Project Overview
This project analyzes **customer retention, revenue trends, and revenue leakage due to returns** using a real-world retail dataset.  
The goal is to move beyond topline revenue and uncover **why revenue fluctuates, where customers churn, and how returns impact profitability**.

The project follows a **production-style analytics pipeline**:
Raw data → Cleaned SQL views → Analytical SQL outputs → Power BI dashboard.

---

## 🛠 Tech Stack
- **Database:** MySQL  
- **Querying & Modeling:** SQL (CTEs, Window Functions, Views)  
- **Visualization:** Power BI  
- **Data Source:** Online Retail / Superstore-style transactional dataset

---

## 📂 Repository Structure

---

## 🔹 Key Business Questions Answered
- How healthy is the business beyond topline revenue?
- How many customers churn after their first purchase?
- Is growth driven by new customers or repeat customers?
- How does customer revenue decay over time?
- How much revenue is lost due to returns and cancellations?
- Are returns concentrated among specific customers?

---

## 🔹 SQL Architecture & Design
- **Raw data left untouched** (CSV-style TEXT columns)
- **Clean analytical views** created for:
  - Completed sales (`online_retail_clean`)
  - Returns & cancellations (`online_retail_returns`)
- Separate **invoice-level** and **customer-level** summary views
- Cohort and retention logic handled **entirely in SQL**
- Returns modeled as a **separate fact**, not mixed with sales

This design mirrors real-world analytics best practices.

---

## 📊 Core Analyses Performed

### 1️⃣ Business KPIs
- Total Revenue, Customers, Orders, Average Order Value

### 2️⃣ Customer Behavior
- Order frequency distribution
- One-time vs repeat buyers

### 3️⃣ Retention & Cohort Analysis
- Customer retention by cohort age
- Revenue retention curve (value decay over time)

### 4️⃣ Revenue Trends
- Monthly revenue
- Month-over-Month (MoM) growth using window functions

### 5️⃣ Revenue Leakage (Returns Analysis)
- Total return value
- Return rate (% of revenue lost)
- High-risk customers with abnormal return behavior

---

## 📈 Power BI Dashboard
The Power BI dashboard focuses on **executive storytelling**, not raw data.

### Key visuals include:
- KPI summary (Revenue, Customers, AOV, Return Rate)
- Monthly Revenue & MoM Growth
- New vs Repeat Revenue Contribution
- Customer Retention Curve
- Revenue Retention Curve (Cohorts)
- Top Customers by Return Value

All business logic remains in SQL; Power BI is used purely for visualization.

---

## 💡 Key Insights
- Over **75% of customers churn after their first month**
- Revenue is **heavily dependent on repeat customers**
- Revenue shows strong **seasonality and volatility**
- Customer revenue **decays significantly over time**
- ~**6% of total revenue is lost due to returns**
- Returns are **highly concentrated among a small group of customers**

**Conclusion:**  
This is primarily a **retention and post-purchase experience problem**, not an acquisition problem.

---

## 🧠 Skills Demonstrated
- SQL data cleaning & transformation
- CTEs and window functions
- Cohort & retention analysis
- Revenue leakage modeling
- Analytical data modeling
- Power BI dashboard design
- Business-first data storytelling

---

## 🚀 Future Improvements
- Product-level return analysis
- Customer segmentation (RFM)
- Predictive churn modeling
- Integration with marketing or logistics data

---

## 👤 Author
**Indranil Bhosale**  
Aspiring Data Analyst | SQL • Power BI • Analytics

