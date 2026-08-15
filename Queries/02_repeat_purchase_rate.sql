-- Query 2: Repeat Purchase Rate (within 30 days of first order)
-- Business question: Of users who make a first purchase, what share return
-- to buy again within 30 days?

WITH user_orders_ranked AS (
  SELECT
    user_id,
    order_id,
    created_at,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at ASC) AS order_seq
  FROM `bigquery-public-data.thelook_ecommerce.orders`
),

first_orders AS (
  SELECT user_id, created_at AS first_order_date
  FROM user_orders_ranked
  WHERE order_seq = 1
),

repeat_check AS (
  SELECT
    f.user_id,
    f.first_order_date,
    COUNT(DISTINCT o.order_id) AS orders_within_30d
  FROM first_orders f
  JOIN `bigquery-public-data.thelook_ecommerce.orders` o
    ON f.user_id = o.user_id
    AND o.created_at > f.first_order_date
    AND o.created_at <= TIMESTAMP_ADD(f.first_order_date, INTERVAL 30 DAY)
  GROUP BY f.user_id, f.first_order_date
)

SELECT
  COUNT(DISTINCT f.user_id) AS total_first_time_buyers,
  COUNT(DISTINCT r.user_id) AS repeat_within_30d,
  ROUND(100 * COUNT(DISTINCT r.user_id) / COUNT(DISTINCT f.user_id), 2) AS pct_repeat_30d
FROM first_orders f
LEFT JOIN repeat_check r
  ON f.user_id = r.user_id;
