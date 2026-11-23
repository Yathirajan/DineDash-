-- DineDash: representative Databricks SQL analytics
-- Assumes orders_bronze and the *_filtered dimension tables have been created.
-- Monetary values are expressed in USD as specified in the project case study.

-- 1. Total number of orders
SELECT COUNT(*) AS total_orders
FROM orders_bronze;

-- 2. Orders by payment method
SELECT payment_method, COUNT(*) AS orders_count
FROM orders_bronze
GROUP BY payment_method
ORDER BY orders_count DESC;

-- 3. Orders by status
SELECT order_status, COUNT(*) AS orders_count
FROM orders_bronze
GROUP BY order_status
ORDER BY orders_count DESC;

-- 4. Order volume by restaurant
SELECT restaurant_id, COUNT(*) AS total_orders
FROM orders_bronze
GROUP BY restaurant_id
ORDER BY total_orders DESC;

-- 5. Order volume by customer
SELECT customer_id, COUNT(*) AS total_orders
FROM orders_bronze
GROUP BY customer_id
ORDER BY total_orders DESC;

-- 6. Orders handled by delivery agent
SELECT agent_id, COUNT(*) AS total_orders
FROM orders_bronze
GROUP BY agent_id
ORDER BY total_orders DESC;

-- 7. Ten highest-value orders
SELECT order_id, total_amount
FROM orders_bronze
ORDER BY total_amount DESC
LIMIT 10;

-- 8. Average tip by payment method
SELECT payment_method, ROUND(AVG(tip), 2) AS average_tip
FROM orders_bronze
GROUP BY payment_method
ORDER BY average_tip DESC;

-- 9. Percentage of orders where the tip exceeds 10% of the order amount
SELECT ROUND(
    100.0 * SUM(CASE WHEN tip > total_amount * 0.10 THEN 1 ELSE 0 END)
    / NULLIF(COUNT(*), 0), 2
) AS percentage_tip_gt_10
FROM orders_bronze;

-- 10. Order-status percentage distribution
SELECT
    order_status,
    COUNT(*) AS order_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM orders_bronze
GROUP BY order_status;

-- 11. Most frequently ordered items
SELECT item, COUNT(*) AS item_count
FROM orders_bronze
LATERAL VIEW EXPLODE(items_ordered) exploded_items AS item
GROUP BY item
ORDER BY item_count DESC
LIMIT 10;

-- 12. Average number of items per order
SELECT ROUND(AVG(SIZE(items_ordered)), 2) AS avg_items_per_order
FROM orders_bronze;

-- 13. Preferred restaurant(s) for each customer.
-- RANK preserves ties when a customer has multiple equally preferred restaurants.
WITH customer_restaurant_counts AS (
    SELECT customer_id, restaurant_id, COUNT(*) AS order_count
    FROM orders_bronze
    GROUP BY customer_id, restaurant_id
),
ranked_restaurants AS (
    SELECT
        customer_id,
        restaurant_id,
        order_count,
        RANK() OVER (PARTITION BY customer_id ORDER BY order_count DESC) AS restaurant_rank
    FROM customer_restaurant_counts
)
SELECT
    ranked.customer_id,
    restaurants.name AS preferred_restaurant,
    ranked.order_count
FROM ranked_restaurants ranked
JOIN restaurants_filtered restaurants
    ON ranked.restaurant_id = restaurants.restaurant_id
WHERE ranked.restaurant_rank = 1;

-- 14. Top ten areas by order volume for each month
WITH monthly_area_orders AS (
    SELECT
        DATE_FORMAT(orders.`timestamp`, 'yyyy-MM') AS order_month,
        locations.area,
        COUNT(*) AS total_orders
    FROM orders_bronze orders
    JOIN locations_filtered locations
        ON orders.delivery_location_id = locations.location_id
    GROUP BY DATE_FORMAT(orders.`timestamp`, 'yyyy-MM'), locations.area
),
ranked_areas AS (
    SELECT
        order_month,
        area,
        total_orders,
        RANK() OVER (PARTITION BY order_month ORDER BY total_orders DESC) AS area_rank
    FROM monthly_area_orders
)
SELECT order_month, area, total_orders
FROM ranked_areas
WHERE area_rank <= 10
ORDER BY order_month, total_orders DESC;

-- 15. Average order value by cuisine
SELECT
    restaurants.cuisines,
    ROUND(AVG(orders.total_amount), 2) AS avg_order_value
FROM orders_bronze orders
JOIN restaurants_filtered restaurants
    ON orders.restaurant_id = restaurants.restaurant_id
GROUP BY restaurants.cuisines
ORDER BY avg_order_value DESC;

-- 16. High-value orders handled by each delivery agent (over $50)
SELECT
    agents.agent_id,
    agents.name,
    COUNT(orders.order_id) AS high_value_order_count
FROM orders_bronze orders
JOIN delivery_agents_filtered agents
    ON orders.agent_id = agents.agent_id
WHERE orders.total_amount > 50
GROUP BY agents.agent_id, agents.name
ORDER BY high_value_order_count DESC;

-- 17. Revenue by area for Italian restaurants
SELECT
    locations.area,
    ROUND(SUM(orders.total_amount), 2) AS total_revenue
FROM orders_bronze orders
JOIN restaurants_filtered restaurants
    ON orders.restaurant_id = restaurants.restaurant_id
JOIN locations_filtered locations
    ON restaurants.location_id = locations.location_id
WHERE restaurants.cuisines LIKE '%Italian%'
GROUP BY locations.area
ORDER BY total_revenue DESC;

-- 18. Customer lifetime spend by signup year
WITH customer_spend AS (
    SELECT
        customers.customer_id,
        customers.signup_date,
        SUM(orders.total_amount) AS lifetime_spend
    FROM orders_bronze orders
    JOIN customers_filtered customers
        ON orders.customer_id = customers.customer_id
    GROUP BY customers.customer_id, customers.signup_date
)
SELECT
    YEAR(TO_DATE(signup_date)) AS signup_year,
    ROUND(AVG(lifetime_spend), 2) AS avg_customer_lifetime_value
FROM customer_spend
GROUP BY YEAR(TO_DATE(signup_date))
ORDER BY avg_customer_lifetime_value DESC;

-- 19. Locations with the most cancelled orders
SELECT
    locations.area,
    COUNT(orders.order_id) AS cancellation_count
FROM orders_bronze orders
JOIN locations_filtered locations
    ON orders.delivery_location_id = locations.location_id
WHERE orders.order_status = 'cancelled'
GROUP BY locations.area
ORDER BY cancellation_count DESC;
