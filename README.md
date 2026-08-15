# E-commerce SQL Analysis — BigQuery

A small set of SQL queries analyzing user behavior and revenue patterns using
`bigquery-public-data.thelook_ecommerce`, a public e-commerce dataset on
BigQuery (users, orders, order items, products).

This project was built to demonstrate practical SQL and BigQuery skills —
query design, use of CTEs, window functions, and data quality reasoning —
applied to a real, queryable dataset. SQL is a skill I am actively
developing; this repo reflects hands-on practice, not a claim of long-term
expertise.

## Dataset

`bigquery-public-data.thelook_ecommerce` — a free public dataset on BigQuery
simulating an e-commerce business (users, orders, order items, products,
inventory, distribution centers). Chosen for its thematic fit with
purchase-behavior and e-commerce analysis.

## Approach

Each query is framed as a short business case: **business question → SQL
method → insight**. Priority was placed on query quality and honest,
data-grounded interpretation over volume — this repo intentionally contains
5 queries rather than a long, shallow list.

All results below come directly from running each query in BigQuery. No
numbers are estimated or invented.

Before running queries, BigQuery's built-in byte-estimator (shown before
executing any query) was checked to avoid scanning full tables unnecessarily
— all queries here run well within BigQuery's free monthly processing tier.

## Data quality note

While reviewing category-level revenue results (Query 4), a suspiciously
repeated retail price of **$903.00** was found across 23 unrelated products
spanning 7 categories (activewear, outerwear, socks, intimates, and others)
— inconsistent with normal retail pricing conventions (real prices cluster
around endings like `.99`, `.95`, `.50`). An attempt to build a generic
automated detector for this kind of anomaly (flagging high-frequency,
non-standard price points) produced too many false positives, since
legitimate catalog prices also repeat often by design (e.g. $25.00 appears
on 1,091 products across 23 categories). The value was verified directly
(Query 0) and excluded from price-sensitive analysis (Queries 3 and 4).

## Queries

### 0. Data Quality Checks — [`00_data_quality_checks.sql`](queries/00_data_quality_checks.sql)
**Question:** Is the dataset structurally sound, and are there any pricing
anomalies that would distort downstream analysis?
**Method:** Row counts vs. distinct primary keys, null checks on key fields,
and a direct check on the `$903.00` anomaly described above.
**Result:** No duplicate or null records in primary keys or timestamps
across `users` (100,000 rows) and `orders` (124,985 rows). Confirmed 23
products priced at exactly $903.00 across 7 unrelated categories.

### 1. Dormant / Sleeping Accounts — [`01_dormant_accounts.sql`](queries/01_dormant_accounts.sql)
**Question:** What share of users have gone quiet, or never purchased at all?
**Method:** `LEFT JOIN` + CTEs to find each user's last order date, classified
against the dataset's own most recent order date (not the real-world
calendar date, since this is a static snapshot) using a `CASE` statement and
a `SUM() OVER()` window function for percentage share. Same "dormant
account" logic used in my BI work at EssilorLuxottica, applied here to a new
dataset.
**Result:** 19.92% of users never completed a single order (a conversion
problem). Among those who did purchase, the large majority show no activity
within 90 days of the dataset's latest order — though this figure is
inflated by the dataset being a static snapshot rather than live data.

### 2. Repeat Purchase Rate — [`02_repeat_purchase_rate.sql`](queries/02_repeat_purchase_rate.sql)
**Question:** Of first-time buyers, what share return to buy again within 30 days?
**Method:** `ROW_NUMBER()` to isolate each user's first order, then a JOIN
with a date-range condition (not simple key equality) to count repeat
orders within a 30-day window.
**Result:** Only 4.97% of first-time buyers (3,980 of 80,084) placed a
second order within 30 days — low relative to typical e-commerce
benchmarks, which may reflect the synthetic nature of this dataset rather
than a real business pattern.

### 3. Revenue Concentration by Category — [`03_revenue_concentration_by_category.sql`](queries/03_revenue_concentration_by_category.sql)
**Question:** Is revenue concentrated in a few categories, or spread out?
**Method:** JOIN + `HAVING` to filter out negligible categories, excluding
cancelled/returned line items, with two stacked window functions to compute
individual and cumulative revenue share (a Pareto-style analysis).
**Result:** Revenue is unusually evenly distributed — no single category
exceeds 11.9% of total revenue, and it takes 13 of 26 categories (half) to
reach 80% cumulative revenue. This is the opposite of a typical Pareto
pattern, suggesting low category-dependency risk but no standout category
to prioritize for growth investment.

### 4. Top Products by Category — [`04_top_products_by_category.sql`](queries/04_top_products_by_category.sql)
**Question:** Which products drive the most revenue within their category,
and how do they compare to the category's average price?
**Method:** `RANK()` (rather than `ROW_NUMBER()`, to preserve genuine ties —
e.g. two products tied at $1,431.00 in the "Suits" category) partitioned by
category, plus a correlated subquery to compute each category's average
price for comparison.
**Result:** Top products per category vary widely in price positioning —
some (e.g. Canada Goose jackets in Active/Outerwear) sell far above their
category average, indicating premium items driving disproportionate revenue
within otherwise mid-priced categories.

## Tools used

SQL (BigQuery Standard SQL), Google Cloud Console. No other tools (Python,
dbt, etc.) were used in this project — see my CV for that experience
separately.

## Notes on process

This project was built iteratively, including a case where an initial
automated approach to detecting pricing anomalies (Query 0) failed and was
revised after producing too many false positives — documented above rather
than hidden, since that revision reflects the actual analysis process.
