-- Query 4: Top Products by Revenue Within Each Category
-- Business question: Which products generate the most revenue within their
-- own category, and how does their price compare to the category average?
-- Data quality note: excludes retail_price = 903.0, identified in Query 0
-- as a placeholder value repeated across 23 unrelated products.

WITH product_revenue AS (
  SELECT
    p.id AS product_id,
    p.name AS product_name,
    p.category,
    p.retail_price,
    ROUND(SUM(oi.sale_price), 2) AS total_revenue,
    RANK() OVER (PARTITION BY p.category ORDER BY SUM(oi.sale_price) DESC) AS category_rank
  FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
  JOIN `bigquery-public-data.thelook_ecommerce.products` p
    ON oi.product_id = p.id
  WHERE oi.status NOT IN ('Cancelled', 'Returned')
    AND p.retail_price != 903.0
  GROUP BY p.id, p.name, p.category, p.retail_price
)

SELECT
  category,
  product_name,
  retail_price,
  total_revenue,
  category_rank,
  -- Correlated subquery: average retail price within this product's category
  ROUND((
    SELECT AVG(p2.retail_price)
    FROM `bigquery-public-data.thelook_ecommerce.products` p2
    WHERE p2.category = product_revenue.category
      AND p2.retail_price != 903.0
  ), 2) AS category_avg_price
FROM product_revenue
WHERE category_rank <= 3
ORDER BY category, category_rank;
