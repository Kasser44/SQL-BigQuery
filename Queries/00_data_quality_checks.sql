-- Query 0: Data Quality Checks
-- Business purpose: verify the dataset before building any analysis on top of it.
-- Two checks: (a) structural integrity of primary keys and timestamps,
-- (b) a targeted check on a pricing anomaly found during analysis (see README).

-- 0a: Row counts, duplicate keys, and nulls in core tables
SELECT
  'users' AS table_name,
  COUNT(*) AS total_rows,
  COUNT(DISTINCT id) AS distinct_ids,
  COUNTIF(id IS NULL) AS null_ids,
  COUNTIF(created_at IS NULL) AS null_created_at
FROM `bigquery-public-data.thelook_ecommerce.users`

UNION ALL

SELECT
  'orders' AS table_name,
  COUNT(*) AS total_rows,
  COUNT(DISTINCT order_id) AS distinct_ids,
  COUNTIF(order_id IS NULL) AS null_ids,
  COUNTIF(created_at IS NULL) AS null_created_at
FROM `bigquery-public-data.thelook_ecommerce.orders`;

-- 0b: Suspicious price pattern, found via manual inspection of Query 4 results.
-- An automated frequency-based detector was tried first (flagging any price
-- shared by an unusually high number of products) but produced too many false
-- positives: common retail price points (e.g. $25.00, $29.99) legitimately
-- repeat across hundreds of products by design. Verified directly instead.
SELECT
  retail_price,
  COUNT(*) AS num_products,
  COUNT(DISTINCT category) AS num_categories
FROM `bigquery-public-data.thelook_ecommerce.products`
WHERE retail_price = 903.0
GROUP BY retail_price;
