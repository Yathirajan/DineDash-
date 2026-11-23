# Databricks notebook source
# MAGIC %md
# MAGIC # DineDash — 02 Incremental Orders Ingestion
# MAGIC
# MAGIC Creates the Delta target and loads monthly JSON order files with COPY INTO.
# MAGIC COPY INTO tracks previously loaded files so rerunning the same command does not normally reload them.
# MAGIC The report demonstrates January, February and March 2024; April is included as the next monthly step.
# MAGIC Update ORDERS_ROOT to your Volume path.

# COMMAND ----------
ORDERS_ROOT = "/Volumes/yathirajana/default/dinedash/orders"

# COMMAND ----------
# Initialize an empty Delta table with the JSON source schema.
spark.sql(f"""
CREATE TABLE IF NOT EXISTS orders_bronze
USING DELTA
AS
SELECT *
FROM json.`{ORDERS_ROOT}/orders_2024_01.json`
WHERE 1 = 0
""")

# COMMAND ----------
# Load the monthly files sequentially, following the project report.
for month in ["01", "02", "03", "04"]:
    file_path = f"{ORDERS_ROOT}/orders_2024_{month}.json"
    spark.sql(f"""
        COPY INTO orders_bronze
        FROM '{file_path}'
        FILEFORMAT = JSON
    """)
    print(f"After month {month}, orders_bronze count = {spark.table('orders_bronze').count()}")

# COMMAND ----------
# Validate the loaded data.
display(spark.sql("""
SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT order_id) AS distinct_order_ids,
    MIN(`timestamp`) AS first_order_timestamp,
    MAX(`timestamp`) AS last_order_timestamp
FROM orders_bronze
"""))

# COMMAND ----------
# Inspect a small sample and schema before running downstream analytics.
display(spark.table("orders_bronze").limit(10))
spark.table("orders_bronze").printSchema()
