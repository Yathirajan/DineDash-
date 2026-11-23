# DineDash — Food Delivery Data Engineering Project

DineDash is an end-to-end food-delivery analytics project built with **Databricks**, **Apache Spark (PySpark)**, **Databricks SQL**, **Delta Lake**, and **Delta Live Tables (DLT)**. It ingests order and reference data, applies data-quality rules, combines datasets for analysis, and produces business metrics for a Databricks dashboard.

## Project objectives

- Ingest monthly food-delivery order data and reference/dimension datasets.
- Persist raw data in Delta tables with ingestion metadata.
- Clean records by filtering rows with missing required fields.
- Build an ETL pipeline that organizes data into Bronze, Silver, and Gold layers.
- Analyze customer, restaurant, menu-item, payment, delivery-agent, and location performance.
- Publish aggregated metrics for dashboard reporting.

## Technology stack

| Technology | How it is used |
|---|---|
| Databricks | Data engineering and analytics workspace |
| Apache Spark / PySpark | Reading CSV data, defining schemas, transforming data |
| Databricks SQL | Data exploration, joins, aggregations, and business analysis |
| Delta Lake | Reliable table storage for the data layers |
| Delta Live Tables (DLT) | Declarative pipeline transformations and data-quality expectations |
| Databricks Workflows | Orchestrating pipeline execution and dashboard preparation |

## Architecture

```text
CSV dimension files + monthly JSON order files
                    |
                    v
          Data ingestion (Bronze)
     Raw Delta tables + ingestion metadata
                    |
                    v
           Data quality (Silver)
    Required-field checks, explode and joins
                    |
                    v
             Business (Gold)
   Aggregated metrics and analytical views
                    |
                    v
       Databricks SQL Dashboard
```

### Bronze layer

- Reads customer, restaurant, location, delivery-agent, and menu-item CSV datasets.
- Uses explicit PySpark schemas for the dimension datasets.
- Adds `ingestion_time` and `source_file` metadata to raw dimension records.
- Creates Delta tables for raw data.
- Loads monthly order JSON files incrementally into `orders_bronze` with `COPY INTO`.

### Silver layer

- Filters records with missing required identifiers and attributes.
- Uses DLT streaming tables and materialized views to transform and combine order data with customer, restaurant, agent, menu-item, and location details.
- Applies data-quality expectations to important order fields.
- Explodes the ordered-items array to support item-level analysis.

### Gold layer

Creates business-facing aggregates, including:

- Total orders by restaurant
- Top-selling menu items
- Average restaurant ratings and tips by city
- Delivery-agent order counts and ratings
- Daily revenue trends
- Customer lifetime spend

## Analytics covered

The SQL analysis includes:

- Order volume, payment-method distribution, and order-status distribution
- Orders by restaurant, customer, and delivery agent
- Highest-value orders and average tips by payment method
- Tip percentage and successful/cancelled/failed order percentages
- Top customers and restaurants
- Most frequently ordered items and average items per order
- Preferred restaurants by customer
- Monthly top-ordering areas
- Average order value by cuisine
- High-value deliveries by agent
- Revenue by area for selected cuisines
- Customer lifetime value and repeat-customer behavior
- Cancellation patterns by delivery area

Representative queries are in [`sql/analytics_queries.sql`](sql/analytics_queries.sql).

## Workflow and dashboard

The documented workflow runs the ETL pipeline, queries Gold-layer outputs, and prepares a Databricks SQL dashboard. The project report includes a successful workflow run and a dashboard with total revenue, orders per restaurant, top-selling items, and daily revenue trend visualizations.

## Repository structure

```text
DineDash-/
├── README.md
├── docs/
│   └── project-workflow.md
└── sql/
    └── analytics_queries.sql
```

## Running the project

1. Create or select a Databricks workspace with Spark and Delta support.
2. Upload the source CSV and monthly JSON datasets to a Unity Catalog Volume (or update the file paths to match your workspace).
3. Run the PySpark ingestion steps to create the raw dimension Delta tables.
4. Create and incrementally populate `orders_bronze` using the monthly JSON files and `COPY INTO`.
5. Execute the cleaning and transformation steps, or configure the DLT pipeline based on the workflow documented here.
6. Run the analytical SQL queries against the resulting tables.
7. Create a Databricks SQL dashboard using the Gold-layer metrics.

> **Environment note:** The original project report uses paths under `/Volumes/yathirajana/default/dinedash/`. These are workspace-specific. Replace the catalog, schema, and Volume path with the locations available in your Databricks environment.

## Data and reproducibility

The project report describes five dimension datasets (customers, restaurants, locations, delivery agents, and menu items) and monthly JSON order data for 2024. The report's analysis scope states that four months of order data were used for the case-study analysis. The raw datasets and exported Databricks notebooks are not included in this repository yet; add them before treating this repository as a fully reproducible code release.

## Future improvements

- Add the original source datasets or a small, privacy-safe sample dataset.
- Export and version the executed Databricks notebooks and DLT pipeline source.
- Add automated data-quality tests and pipeline monitoring.
- Add a documented data dictionary and ER diagram.
- Add dashboard screenshots and reproducible deployment instructions.

---

**Project:** DineDash  
**Focus:** Data Engineering | ETL | Food Delivery Analytics
