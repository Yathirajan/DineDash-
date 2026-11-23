-- DineDash Lakeflow Declarative Pipelines / Delta Live Tables SQL
-- Adapted from the DLT implementation in the project report (pages 28–32).
-- Configure the source path in the pipeline settings as a pipeline configuration
-- key named dinedash.source_path, or replace the default Volume path below.
-- Expected source files:
--   orders/*.json
--   dim_customers.csv, dim_restaurants.csv, dim_locations.csv,
--   dim_delivery_agents.csv, dim_menu_items.csv

-- BRONZE: order events are ingested as a streaming table.
CREATE OR REFRESH STREAMING TABLE orders_bronze
AS
SELECT *
FROM STREAM READ_FILES(
  '/Volumes/yathirajana/default/dinedash/orders/',
  format => 'json'
);

-- BRONZE: dimension/reference data.
CREATE OR REFRESH MATERIALIZED VIEW customers_bronze
AS
SELECT *
FROM READ_FILES(
  '/Volumes/yathirajana/default/dinedash/dim_customers.csv',
  format => 'csv',
  header => true,
  inferSchema => true
);

CREATE OR REFRESH MATERIALIZED VIEW restaurants_bronze
AS
SELECT *
FROM READ_FILES(
  '/Volumes/yathirajana/default/dinedash/dim_restaurants.csv',
  format => 'csv',
  header => true,
  inferSchema => true
);

CREATE OR REFRESH MATERIALIZED VIEW locations_bronze
AS
SELECT *
FROM READ_FILES(
  '/Volumes/yathirajana/default/dinedash/dim_locations.csv',
  format => 'csv',
  header => true,
  inferSchema => true
);

CREATE OR REFRESH MATERIALIZED VIEW agents_bronze
AS
SELECT *
FROM READ_FILES(
  '/Volumes/yathirajana/default/dinedash/dim_delivery_agents.csv',
  format => 'csv',
  header => true,
  inferSchema => true
);

CREATE OR REFRESH MATERIALIZED VIEW items_bronze
AS
SELECT *
FROM READ_FILES(
  '/Volumes/yathirajana/default/dinedash/dim_menu_items.csv',
  format => 'csv',
  header => true,
  inferSchema => true
);

-- SILVER: reject orders that do not have the required order/customer/items fields.
-- Keep items_ordered as an array of structs at this stage.
CREATE OR REFRESH STREAMING TABLE cleaned_orders (
  CONSTRAINT valid_order_id EXPECT (order_id IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT valid_customer EXPECT (customer_id IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT valid_items EXPECT (items_ordered IS NOT NULL AND SIZE(items_ordered) > 0)
    ON VIOLATION DROP ROW
)
AS
SELECT
  order_id,
  CAST(`timestamp` AS TIMESTAMP) AS order_ts,
  customer_id,
  restaurant_id,
  agent_id,
  delivery_location_id,
  items_ordered,
  total_amount,
  tip,
  payment_method,
  order_status
FROM STREAM(orders_bronze);

-- SILVER: explode the nested order items once, then enrich with dimensions.
-- The report's item struct uses item_id, price and quantity.
CREATE OR REFRESH STREAMING TABLE orders_silver (
  CONSTRAINT valid_restaurant_name EXPECT (restaurant_name IS NOT NULL)
    ON VIOLATION DROP ROW,
  CONSTRAINT valid_agent_name EXPECT (agent_name IS NOT NULL)
    ON VIOLATION DROP ROW,
  CONSTRAINT valid_item_id EXPECT (item_id IS NOT NULL)
    ON VIOLATION DROP ROW
)
AS
SELECT
  o.order_id,
  o.order_ts,
  o.customer_id,
  c.name AS customer_name,
  c.email AS customer_email,
  o.restaurant_id,
  r.name AS restaurant_name,
  r.cuisines,
  r.rating AS restaurant_rating,
  o.agent_id,
  a.name AS agent_name,
  a.rating AS agent_rating,
  o.delivery_location_id,
  l.area,
  l.city,
  l.state,
  item.item_id AS item_id,
  i.item_name,
  i.category AS item_category,
  item.price AS item_price,
  item.quantity AS item_quantity,
  o.total_amount,
  o.tip,
  o.payment_method,
  o.order_status
FROM (
  SELECT
    order_id, order_ts, customer_id, restaurant_id, agent_id,
    delivery_location_id, total_amount, tip, payment_method, order_status,
    EXPLODE(items_ordered) AS item
  FROM STREAM(cleaned_orders)
) o
LEFT JOIN customers_bronze c
  ON o.customer_id = c.customer_id
LEFT JOIN restaurants_bronze r
  ON o.restaurant_id = r.restaurant_id
LEFT JOIN agents_bronze a
  ON o.agent_id = a.agent_id
LEFT JOIN locations_bronze l
  ON o.delivery_location_id = l.location_id
LEFT JOIN items_bronze i
  ON o.item.item_id = i.item_id;

-- GOLD: restaurant order volume.
CREATE OR REFRESH MATERIALIZED VIEW total_orders_per_restaurant
AS
SELECT restaurant_name, COUNT(DISTINCT order_id) AS total_orders
FROM orders_silver
GROUP BY restaurant_name;

-- GOLD: top-selling items by quantity.
CREATE OR REFRESH MATERIALIZED VIEW top_selling_items
AS
SELECT item_name, SUM(item_quantity) AS total_qty_sold
FROM orders_silver
GROUP BY item_name
ORDER BY total_qty_sold DESC
LIMIT 10;

-- GOLD: city-level restaurant rating and average tip.
CREATE OR REFRESH MATERIALIZED VIEW avg_fees_by_city
AS
SELECT
  city,
  AVG(restaurant_rating) AS avg_restaurant_rating,
  AVG(tip) AS avg_tip
FROM orders_silver
GROUP BY city;

-- GOLD: delivery agent performance.
CREATE OR REFRESH MATERIALIZED VIEW agent_order_counts
AS
SELECT
  agent_name,
  COUNT(DISTINCT order_id) AS orders_handled,
  AVG(agent_rating) AS avg_rating
FROM orders_silver
GROUP BY agent_name
ORDER BY orders_handled DESC;

-- GOLD: daily revenue trend.
-- The order-level total is repeated for each exploded item in orders_silver,
-- so aggregate from a distinct order-grain view to avoid multiplying revenue.
CREATE OR REFRESH MATERIALIZED VIEW daily_revenue_trend
AS
WITH order_grain AS (
  SELECT DISTINCT order_id, order_ts, total_amount
  FROM orders_silver
)
SELECT
  DATE(order_ts) AS order_date,
  SUM(total_amount) AS total_revenue
FROM order_grain
GROUP BY DATE(order_ts)
ORDER BY order_date;

-- GOLD: customer lifetime spend, also at order grain to avoid item duplication.
CREATE OR REFRESH MATERIALIZED VIEW customer_ltv
AS
WITH order_grain AS (
  SELECT DISTINCT order_id, customer_id, customer_name, total_amount
  FROM orders_silver
)
SELECT
  customer_id,
  customer_name,
  SUM(total_amount) AS lifetime_spend
FROM order_grain
GROUP BY customer_id, customer_name;

-- GOLD: customer order counts.
CREATE OR REFRESH MATERIALIZED VIEW customer_order_counts
AS
WITH order_grain AS (
  SELECT DISTINCT order_id, customer_id, customer_name
  FROM orders_silver
)
SELECT customer_name, COUNT(*) AS total_orders
FROM order_grain
GROUP BY customer_name;
