# Key Findings: E-Commerce Revenue & Customer Retention Analysis

## 1. Project Overview

This project uses MySQL to analyze e-commerce transaction data and
understand revenue performance, customer purchasing behavior,
customer retention, and customer segmentation.

The analysis focuses on identifying business trends and generating
actionable insights to support customer retention and revenue growth.

## 2. Key Business Metrics

| Metric | Result |
|---|---:|
| Total Customers | 4,339 |
| Total Orders | 19,960 |
| Total Revenue | £10,642,128.80 |
| Average Order Value (AOV) | £533.17 |

### Key Insight

These metrics establish the overall business performance and
provide a baseline for further analysis of customer behavior,
revenue trends, and retention.

## 3. New vs. Returning Customer Analysis

| Metric | New Customers | Returning Customers |
|---|---:|---:|
| Customers in Category | 4,339 | 2,844 |
| Orders | 4,353 | 15,616 |
| Revenue | £184,379.22 | £879,849.58 |
| Revenue per Customer | £424.84 | £3,093.79 |

### Key Findings

- Returning customers generated approximately 7.28 times more
  revenue per customer than customers classified as new.
- Returning customers accounted for substantially more orders
  and revenue in this comparison.
- The customer categories overlap because customers classified
  as new can subsequently become returning customers.

### Business Recommendation

Develop customer retention strategies that encourage first-time
buyers to make repeat purchases. Personalized recommendations,
follow-up campaigns, and relevant promotions may help increase
repeat purchasing.

## 4. Customer Retention and Cohort Analysis

The December 2010 customer cohort was analyzed to understand
retention over time.

| Cohort Month | Retention Rate |
|---|---:|
| Month 0 | 100.00% |
| Month 1 | 36.68% |
| Month 2 | 32.39% |
| Month 3 | 38.49% |
| Month 6 | 36.34% |
| Month 12 | 26.64% |

### Key Findings

- 36.68% of the December 2010 cohort returned in Month 1.
- Retention fluctuated across subsequent months rather than
  declining consistently.
- The cohort recorded a retention rate of 26.64% in Month 12.

### Business Recommendation

Analyze the purchasing behavior of customers who return regularly
and identify opportunities to re-engage inactive customers.
Cohort analysis can help evaluate whether retention initiatives
are associated with improved repeat purchasing.

## 5. RFM Customer Segmentation

RFM analysis segments customers using three behavioral metrics:

- **Recency:** How recently a customer made a purchase.
- **Frequency:** How often a customer made purchases.
- **Monetary:** How much a customer spent.

The project categorizes customers into the following segments:

- Champions
- Loyal / Active
- Recent Customers
- At Risk
- Needs Attention

### Business Applications

| Customer Segment | Potential Strategy |
|---|---|
| Champions | Encourage loyalty and referrals. |
| Loyal / Active | Promote repeat purchases and cross-selling. |
| Recent Customers | Encourage a second purchase. |
| At Risk | Test targeted re-engagement campaigns. |
| Needs Attention | Investigate inactivity and test relevant offers. |

These strategies are recommendations based on the segment
definitions. Their effectiveness would need to be measured
using actual campaign results.

## 6. Tools and SQL Techniques

### Technology

- MySQL
- SQL

### SQL Techniques

- Data cleaning and transformation
- Aggregate functions and GROUP BY
- Common Table Expressions (CTEs)
- Window functions
- Date and time functions
- Conditional logic
- Cohort retention analysis
- RFM customer segmentation

## 7. Overall Business Conclusions

The analysis highlights three important opportunities:

1. **Improve repeat purchasing:** Returning customers generated
   substantially more revenue per customer than new customers
   in the analyzed comparison.

2. **Monitor customer retention:** Cohort analysis provides a
   structured way to measure repeat purchasing over time and
   identify potential retention challenges.

3. **Personalize customer strategies:** RFM segmentation provides
   a framework for identifying valuable customers and customers
   who may benefit from re-engagement.

## 8. Project Scope

This repository focuses on SQL-based analysis. The findings
documented here reflect the calculated results currently available
from the project.

Further analysis of monthly revenue, country performance, and
individual RFM segment performance can extend these findings.
