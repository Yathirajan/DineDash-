# Databricks notebook source
# MAGIC %md
# MAGIC # DineDash — 01 Dimension Data Ingestion
# MAGIC
# MAGIC Loads the five dimension CSV files described in the project report into Bronze Delta tables.
# MAGIC Update SOURCE_ROOT if your Unity Catalog Volume path is different.

# COMMAND ----------
from pyspark.sql.types import StructType, StructField, StringType, DoubleType
from pyspark.sql.functions import col, current_timestamp

SOURCE_ROOT = "/Volumes/yathirajana/default/dinedash"

# COMMAND ----------
# Explicit schemas follow the source project report.
schemas = {
    "customers": StructType([
        StructField("customer_id", StringType(), True),
        StructField("name", StringType(), True),
        StructField("email", StringType(), True),
        StructField("dob", StringType(), True),
        StructField("signup_date", StringType(), True),
        StructField("location_id", StringType(), True),
    ]),
    "restaurants": StructType([
        StructField("restaurant_id", StringType(), True),
        StructField("name", StringType(), True),
        StructField("cuisines", StringType(), True),
        StructField("location_id", StringType(), True),
        StructField("rating", DoubleType(), True),
        StructField("delivery_fee", DoubleType(), True),
    ]),
    "locations": StructType([
        StructField("location_id", StringType(), True),
        StructField("area", StringType(), True),
        StructField("city", StringType(), True),
        StructField("state", StringType(), True),
        StructField("latitude", DoubleType(), True),
        StructField("longitude", DoubleType(), True),
    ]),
    "delivery_agents": StructType([
        StructField("agent_id", StringType(), True),
        StructField("name", StringType(), True),
        StructField("phone", StringType(), True),
        StructField("rating", DoubleType(), True),
    ]),
    "menu_items": StructType([
        StructField("item_id", StringType(), True),
        StructField("restaurant_id", StringType(), True),
        StructField("item_name", StringType(), True),
        StructField("price", DoubleType(), True),
        StructField("category", StringType(), True),
    ]),
}

# COMMAND ----------
# Read each source file, attach lineage metadata, and save as a Delta table.
for dataset, schema in schemas.items():
    source_file = f"{SOURCE_ROOT}/dim_{dataset}.csv"
    table_name = f"{dataset}_bronze"

    df = (
        spark.read.format("csv")
        .option("header", "true")
        .schema(schema)
        .load(source_file)
        .withColumn("ingestion_time", current_timestamp())
        .withColumn("source_file", col("_metadata.file_path"))
    )

    (df.write.format("delta")
       .mode("overwrite")
       .option("overwriteSchema", "true")
       .saveAsTable(table_name))

    print(f"Created {table_name}: {spark.table(table_name).count()} rows")

# COMMAND ----------
# Create the filtered dimension tables using the required-field rules in the report.
required_columns = {
    "customers_bronze": ["customer_id", "email", "name", "location_id", "signup_date", "dob"],
    "restaurants_bronze": ["restaurant_id", "name", "cuisines", "location_id", "rating", "delivery_fee"],
    "locations_bronze": ["location_id", "area", "city", "state", "latitude", "longitude"],
    "delivery_agents_bronze": ["agent_id", "name", "phone", "rating"],
    "menu_items_bronze": ["item_id", "restaurant_id", "item_name", "price", "category"],
}

for source_table, required in required_columns.items():
    target_table = source_table.replace("_bronze", "_filtered")
    predicates = " AND ".join(f"`{name}` IS NOT NULL" for name in required)
    spark.sql(f"""
        CREATE OR REPLACE TABLE {target_table}
        USING DELTA
        AS SELECT * FROM {source_table}
        WHERE {predicates}
    """)
    print(f"Created {target_table}: {spark.table(target_table).count()} rows")

# COMMAND ----------
# Quick validation: inspect the resulting table names and schemas.
for table_name in [f"{name}_bronze" for name in schemas]:
    print(f"\n--- {table_name} ---")
    spark.table(table_name).printSchema()
