# DineDash project workflow

## Processing sequence

1. **Ingest source data**
   - Dimension data: customers, restaurants, locations, delivery agents, and menu items (CSV).
   - Transaction data: monthly order files (JSON).

2. **Bronze**
   - Read dimension files with explicit PySpark schemas.
   - Add ingestion timestamp and source-file metadata.
   - Store raw dimension datasets as Delta tables.
   - Initialize `orders_bronze` and incrementally ingest monthly order files with `COPY INTO`.

3. **Silver**
   - Filter rows with missing required dimension attributes.
   - Apply order-level data-quality expectations in the DLT pipeline.
   - Explode the nested ordered-items array.
   - Enrich orders with customer, restaurant, agent, menu-item, and location attributes.

4. **Gold**
   - Aggregate restaurant order counts, item quantities, city-level metrics, delivery-agent performance, daily revenue, and customer lifetime spend.

5. **Orchestration and reporting**
   - The project report describes a Databricks Workflow with a pipeline task followed by a dashboard/query task.
   - The dashboard shown in the report contains total revenue, orders per restaurant, top-selling items, and daily revenue trend visualizations.

## Data model at a glance

| Dataset | Key fields described in the report |
|---|---|
| Customers | customer_id, name, email, dob, signup_date, location_id |
| Restaurants | restaurant_id, name, cuisines, location_id, rating, delivery_fee |
| Locations | location_id, area, city, state, latitude, longitude |
| Delivery agents | agent_id, name, phone, rating |
| Menu items | item_id, restaurant_id, item_name, price, category |
| Orders | order_id, timestamp, customer_id, restaurant_id, agent_id, delivery_location_id, items_ordered, total_amount, tip, payment_method, order_status |

## Important implementation notes

- The original report uses a workspace-specific Unity Catalog Volume path. Update it for your workspace before running the code.
- The report states that its case-study analysis used four months of order data, while the incremental ingestion exercise demonstrates January, February, and March loads.
- The report is documentation of the work and includes screenshots of a successful workflow run and dashboard. Exported notebooks and original datasets still need to be added for a complete, reproducible repository.
