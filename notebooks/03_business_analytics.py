# Databricks notebook source
# MAGIC %md
# MAGIC # DineDash — 03 Business Analytics
# MAGIC
# MAGIC Databricks SQL analytics based on the questions and table names in the project report.
# MAGIC Run after the dimension and orders ingestion notebooks. Monetary amounts are in USD in the case study.

# COMMAND ----------
# MAGIC %sql
# MAGIC SELECT COUNT(*) AS total_orders FROM orders_bronze;

# COMMAND ----------
# MAGIC %sql
# MAGIC SELECT payment_method, COUNT(*) AS orders_count
# MAGIC FROM orders_bronze
# MAGIC GROUP BY payment_method
# MAGIC ORDER BY orders_count DESC;

# COMMAND ----------
# MAGIC %sql
# MAGIC SELECT order_status, COUNT(*) AS orders_count
# MAGIC FROM orders_bronze
# MAGIC GROUP BY order_status
# MAGIC ORDER BY orders_count DESC;

# COMMAND ----------
# MAGIC %sql
# MAGIC SELECT restaurant_id, COUNT(*) AS total_orders
# MAGIC FROM orders_bronze
# MAGIC GROUP BY restaurant_id
# MAGIC ORDER BY total_orders DESC;

# COMMAND ----------
# MAGIC %sql
# MAGIC SELECT customer_id, COUNT(*) AS total_orders
# MAGIC FROM orders_bronze
# MAGIC GROUP BY customer_id
# MAGIC ORDER BY total_orders DESC;

# COMMAND ----------
# MAGIC %sql
# MAGIC SELECT agent_id, COUNT(*) AS total_orders
# MAGIC FROM orders_bronze
# MAGIC GROUP BY agent_id
# MAGIC ORDER BY total_orders DESC;

# COMMAND ----------
# MAGIC %sql
# MAGIC SELECT order_id, total_amount
# MAGIC FROM orders_bronze
# MAGIC ORDER BY total_amount DESC
# MAGIC LIMIT 10;

# COMMAND ----------
# MAGIC %sql
# MAGIC SELECT payment_method, ROUND(AVG(tip), 2) AS average_tip
# MAGIC FROM orders_bronze
# MAGIC GROUP BY payment_method
# MAGIC ORDER BY average_tip DESC;

# COMMAND ----------
# MAGIC %sql
# MAGIC SELECT
# MAGIC   ROUND(
# MAGIC     100.0 * SUM(CASE WHEN tip > total_amount * 0.10 THEN 1 ELSE 0 END)
# MAGIC     / NULLIF(COUNT(*), 0), 2
# MAGIC   ) AS percentage_tip_gt_10
# MAGIC FROM orders_bronze;

# COMMAND ----------
# MAGIC %sql
# MAGIC SELECT
# MAGIC   order_status,
# MAGIC   COUNT(*) AS order_count,
# MAGIC   ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
# MAGIC FROM orders_bronze
# MAGIC GROUP BY order_status;

# COMMAND ----------
# MAGIC %sql
# MAGIC SELECT item, COUNT(*) AS item_count
# MAGIC FROM orders_bronze
# MAGIC LATERAL VIEW EXPLODE(items_ordered) exploded_items AS item
# MAGIC GROUP BY item
# MAGIC ORDER BY item_count DESC
# MAGIC LIMIT 10;

# COMMAND ----------
# MAGIC %sql
# MAGIC SELECT ROUND(AVG(SIZE(items_ordered)), 2) AS avg_items_per_order
# MAGIC FROM orders_bronze;

# COMMAND ----------
# MAGIC %sql
# MAGIC WITH customer_restaurant_counts AS (
# MAGIC   SELECT customer_id, restaurant_id, COUNT(*) AS order_count
# MAGIC   FROM orders_bronze
# MAGIC   GROUP BY customer_id, restaurant_id
# MAGIC ),
# MAGIC ranked AS (
# MAGIC   SELECT *,
# MAGIC     RANK() OVER (PARTITION BY customer_id ORDER BY order_count DESC) AS rnk
# MAGIC   FROM customer_restaurant_counts
# MAGIC )
# MAGIC SELECT ranked.customer_id, restaurants.name AS preferred_restaurant, ranked.order_count
# MAGIC FROM ranked
# MAGIC JOIN restaurants_filtered restaurants
# MAGIC   ON ranked.restaurant_id = restaurants.restaurant_id
# MAGIC WHERE ranked.rnk = 1;

# COMMAND ----------
# MAGIC %sql
# MAGIC SELECT
# MAGIC   DATE_FORMAT(o.`timestamp`, 'yyyy-MM') AS order_month,
# MAGIC   l.area,
# MAGIC   COUNT(*) AS total_orders
# MAGIC FROM orders_bronze o
# MAGIC JOIN locations_filtered l
# MAGIC   ON o.delivery_location_id = l.location_id
# MAGIC GROUP BY DATE_FORMAT(o.`timestamp`, 'yyyy-MM'), l.area
# MAGIC QUALIFY RANK() OVER (
# MAGIC   PARTITION BY DATE_FORMAT(o.`timestamp`, 'yyyy-MM')
# MAGIC   ORDER BY COUNT(*) DESC
# MAGIC ) <= 10
# MAGIC ORDER BY order_month, total_orders DESC;

# COMMAND ----------
# MAGIC %sql
# MAGIC SELECT r.cuisines, ROUND(AVG(o.total_amount), 2) AS avg_order_value
# MAGIC FROM orders_bronze o
# MAGIC JOIN restaurants_filtered r ON o.restaurant_id = r.restaurant_id
# MAGIC GROUP BY r.cuisines
# MAGIC ORDER BY avg_order_value DESC;

# COMMAND ----------
# MAGIC %sql
# MAGIC SELECT a.agent_id, a.name, COUNT(o.order_id) AS high_value_order_count
# MAGIC FROM orders_bronze o
# MAGIC JOIN delivery_agents_filtered a ON o.agent_id = a.agent_id
# MAGIC WHERE o.total_amount > 50
# MAGIC GROUP BY a.agent_id, a.name
# MAGIC ORDER BY high_value_order_count DESC;

# COMMAND ----------
# MAGIC %sql
# MAGIC SELECT l.area, ROUND(SUM(o.total_amount), 2) AS total_revenue
# MAGIC FROM orders_bronze o
# MAGIC JOIN restaurants_filtered r ON o.restaurant_id = r.restaurant_id
# MAGIC JOIN locations_filtered l ON r.location_id = l.location_id
# MAGIC WHERE r.cuisines LIKE '%Italian%'
# MAGIC GROUP BY l.area
# MAGIC ORDER BY total_revenue DESC;

# COMMAND ----------
# MAGIC %sql
# MAGIC SELECT r.cuisines, AVG(TRY_DIVIDE(o.tip, o.total_amount)) AS avg_tip_to_total_ratio
# MAGIC FROM orders_bronze o
# MAGIC JOIN restaurants_filtered r ON o.restaurant_id = r.restaurant_id
# MAGIC GROUP BY r.cuisines
# MAGIC ORDER BY avg_tip_to_total_ratio DESC;

# COMMAND ----------
# MAGIC %sql
# MAGIC SELECT
# MAGIC   mi.item_name,
# MAGIC   o.restaurant_id,
# MAGIC   COUNT(*) AS order_count
# MAGIC FROM orders_bronze o
# MAGIC LATERAL VIEW EXPLODE(o.items_ordered) exploded_items AS item
# MAGIC JOIN menu_items_filtered mi ON item.item_id = mi.item_id
# MAGIC GROUP BY mi.item_name, o.restaurant_id
# MAGIC ORDER BY order_count DESC;

# COMMAND ----------
# MAGIC %sql
# MAGIC SELECT
# MAGIC   c.customer_id,
# MAGIC   c.name,
# MAGIC   SUM(o.total_amount) AS customer_lifetime_value
# MAGIC FROM orders_bronze o
# MAGIC JOIN customers_filtered c ON o.customer_id = c.customer_id
# MAGIC GROUP BY c.customer_id, c.name
# MAGIC ORDER BY customer_lifetime_value DESC;
