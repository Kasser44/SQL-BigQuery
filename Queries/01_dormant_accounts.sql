-- Query 1: Dormant / Sleeping Accounts
-- Business question: What share of users have gone quiet (or never purchased),
-- using the dataset's own most recent activity as the reference point rather
-- than the real-world calendar date (this dataset is a static snapshot, not
-- live data, so CURRENT_DATE() would misclassify nearly every account).

WITH user_last_order AS (
  SELECT
    u.id AS user_id,
    MAX(o.created_at) AS last_order_date
  FROM `bigquery-public-data.thelook_ecommerce.users` u
  LEFT JOIN `bigquery-public-data.thelook_ecommerce.orders` o
    ON u.id = o.user_id
  GROUP BY u.id
),

reference_date AS (
  SELECT MAX(created_at) AS ref_date
  FROM `bigquery-public-data.thelook_ecommerce.orders`
),

classified AS (
  SELECT
    ulo.user_id,
    ulo.last_order_date,
    CASE
      WHEN ulo.last_order_date IS NULL THEN 'never_purchased'
      WHEN DATE_DIFF(DATE(rd.ref_date), DATE(ulo.last_order_date), DAY) > 90 THEN 'dormant_90d'
      ELSE 'active'
    END AS account_status
  FROM user_last_order ulo
  CROSS JOIN reference_date rd
)

SELECT
  account_status,
  COUNT(*) AS num_users,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_total_users
FROM classified
GROUP BY account_status
ORDER BY num_users DESC;
