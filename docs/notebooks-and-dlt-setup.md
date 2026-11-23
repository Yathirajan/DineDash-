# Importing the DineDash notebooks and configuring the DLT pipeline

## Files in this repository

- `notebooks/01_dimension_data_ingestion.py` — explicit PySpark schemas, Bronze Delta tables, and filtered dimension tables.
- `notebooks/02_incremental_orders_ingestion.py` — initializes `orders_bronze` and loads the monthly JSON files using `COPY INTO`.
- `notebooks/03_business_analytics.py` — Databricks SQL analysis from the project report.
- `pipelines/dinedash_dlt_pipeline.sql` — Bronze, Silver and Gold declarative pipeline definitions.

These are Databricks source-format notebook files (`.py`) with `# COMMAND` and `# MAGIC` cell markers. They can be imported into a Databricks workspace.

## Before running

1. Upload the source datasets to a Unity Catalog Volume. The report uses:
   `/Volumes/yathirajana/default/dinedash/`
2. Confirm that the following files exist:
   - `dim_customers.csv`
   - `dim_restaurants.csv`
   - `dim_locations.csv`
   - `dim_delivery_agents.csv`
   - `dim_menu_items.csv`
   - `orders/orders_2024_01.json` through the months you intend to load.
3. If your catalog, schema, or Volume differs, update the `SOURCE_ROOT` / `ORDERS_ROOT` variables in the notebooks and the source paths in the DLT SQL file.
4. Import the three notebook files into Databricks and run them in order when using the notebook-based workflow.

## Configure the DLT / Lakeflow pipeline

1. In Databricks, create a SQL pipeline (Lakeflow Declarative Pipelines; previously Delta Live Tables).
2. Add `pipelines/dinedash_dlt_pipeline.sql` as the pipeline source.
3. Ensure the pipeline has access to the source Volume and the required catalog/schema permissions.
4. Select a target catalog and schema for the pipeline's output tables.
5. Start the pipeline and review the event log, expectations, and output tables.

## Important distinctions

- The project report describes both a notebook-based ingestion/analysis workflow and a DLT pipeline. The notebook-based workflow creates `*_filtered` tables; the DLT pipeline independently creates its own Bronze/Silver/Gold datasets.
- Do not run the notebook ingestion and DLT pipeline into the same target schema without considering table-name collisions. Use separate schemas or choose one ingestion route.
- The report's DLT example was adjusted in the repository to explode order-item structs once and to aggregate revenue/customer spend at order grain. In the Silver table, an order appears once per item, so summing `total_amount` directly from that table would overstate revenue.
- The item-level DLT logic assumes each element in `items_ordered` is a struct containing `item_id`, `price`, and `quantity`, as shown by the report's pipeline SQL. Check the actual JSON schema before running.
- The report's dashboard screenshot is documented in the README; dashboard assets and original source data have not been uploaded.
- These files are based on the project report and have not been executed against your Databricks workspace in this session. Validate schemas, paths, and pipeline compatibility in your workspace before using them for a live run.
