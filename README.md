# E-Commerce Revenue & Customer Retention Analysis

An end-to-end e-commerce analytics project focused on revenue performance, customer purchasing behavior, retention patterns, and customer segmentation using SQL, Python, and Power BI.

## Business Problem

E-commerce businesses need to understand what drives revenue, whether customers return after their first purchase, and which customer groups generate the most value.

This project analyzes transactional data to identify revenue trends, evaluate customer retention, and generate actionable insights for business decision-making.

## Project Objectives

- Analyze revenue performance and key business KPIs.
- Understand customer purchasing behavior.
- Measure customer retention using cohort analysis.
- Compare new and returning customer revenue.
- Segment customers using RFM analysis.
- Develop insights that can support customer retention and revenue growth strategies.

## Tools & Technologies

- **SQL (MySQL):** Data cleaning, transformations, KPI calculations, cohort analysis, and RFM segmentation.
- **Python:** Data exploration and analysis.
- **Power BI:** Interactive dashboards and business performance visualization.

## Key Analyses

### 1. Revenue Analysis
- Total revenue
- Total orders
- Average order value (AOV)
- Monthly revenue trends

### 2. Customer Analysis
- Customer purchasing behavior
- New versus returning customer analysis
- Revenue contribution by customer type

### 3. Cohort Retention Analysis
- Group customers by their first purchase month.
- Track subsequent purchasing activity.
- Calculate monthly retention rates.

### 4. RFM Customer Segmentation
- **Recency:** How recently a customer purchased.
- **Frequency:** How often a customer purchased.
- **Monetary:** How much revenue a customer generated.

RFM scores help distinguish high-value customers from customers who may need re-engagement.

## Key Findings

The initial SQL analysis identified the following results:

| Metric | Result |
|---|---:|
| Total customers | 4,339 |
| Total orders | 19,960 |
| Total revenue | £10,642,128.80 |
| Average order value | £533.17 |

### Customer Value

Returning customers generated approximately **7.3 times more revenue per customer** than customers classified as new in the analysis.

This highlights the potential business value of encouraging repeat purchases and strengthening customer relationships.

*Note: Customer classification follows the logic implemented in the SQL analysis. Results should be interpreted within the dataset's coverage and the project's definitions.*

## Repository Structure

```text
ecommerce-revenue-retention-analysis/
├── data/
├── sql/
├── python/
├── powerbi/
├── docs/
└── README.md
