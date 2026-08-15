-- Query 3: Revenue Concentration by Product Category
-- Business question: How concentrated is revenue across product categories?
-- Are we dependent on a small number of categories, or is revenue spread out?
-- Data quality note: excludes retail_price = 903.0, a placeholder value
-- identified in Query 0 that inflates revenue via order_items.sale_price.

WITH category_revenue AS (
  SELECT
    p.category,
    ROUND(SUM(oi.sale_price), 2) AS total_revenue,
    COUNT(DISTINCT oi.order_id) AS num_orders
  FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
  JOIN `bigquery-public-data.thelook_ecommerce.products` p
    ON oi.product_id = p.id
  WHERE oi.status NOT IN ('Cancelled', 'Returned')
    AND p.retail_price != 903.0
  GROUP BY p.category
  HAVING SUM(oi.sale_price) > 1000
)

SELECT
  category,
  total_revenue,
  num_orders,
  ROUND(100 * total_revenue / SUM(total_revenue) OVER (), 2) AS pct_of_total_revenue,
  ROUND(100 * SUM(total_revenue) OVER (ORDER BY total_revenue DESC) / SUM(total_revenue) OVER (), 2) AS cumulative_pct
FROM category_revenue
ORDER BY total_revenue DESC;
