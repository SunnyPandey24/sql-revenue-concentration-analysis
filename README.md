# Revenue Concentration & Delivery-Risk Analysis (SQL)

**A SQL-only analytics case study on a synthetic e-commerce dataset (4,000 customers, 8,835 orders, $4.38M in revenue, Jan 2023–Dec 2024).**

> Note on the data: this dataset is **synthetically generated** (via `generate.py`, seeded for reproducibility) rather than downloaded from Kaggle. It's modeled on the structure of the popular Olist Brazilian E-Commerce dataset, but generating it myself meant I could control realistic patterns — seasonality, a Pareto-style revenue split, late-delivery effects, and a seller anomaly — and then *prove* I could find them with SQL. All numbers below come directly from running `queries.sql` against this data.

---

## Schema

```mermaid
erDiagram
    CUSTOMERS ||--o{ ORDERS : places
    SELLERS ||--o{ PRODUCTS : lists
    SELLERS ||--o{ ORDER_ITEMS : fulfills
    PRODUCTS ||--o{ ORDER_ITEMS : "ordered as"
    ORDERS ||--o{ ORDER_ITEMS : contains
    ORDERS ||--o| ORDER_REVIEWS : receives

    CUSTOMERS {
        int customer_id PK
        string customer_name
        string region
        date signup_date
    }
    SELLERS {
        int seller_id PK
        string seller_name
        string region
    }
    PRODUCTS {
        int product_id PK
        string product_name
        string category
        int seller_id FK
        numeric price
    }
    ORDERS {
        int order_id PK
        int customer_id FK
        date order_date
        date estimated_delivery_date
        date delivered_date
        string order_status
        boolean is_late
    }
    ORDER_ITEMS {
        int order_item_id PK
        int order_id FK
        int product_id FK
        int seller_id FK
        int quantity
        numeric unit_price
    }
    ORDER_REVIEWS {
        int order_id PK_FK
        int review_score
    }
```

## Tech stack
SQL (ANSI-standard CTEs + window functions — runs on PostgreSQL, MySQL 8+, and SQLite 3.25+), Python/pandas (data generation only, not part of the analysis layer).

## How to run it
```bash
# Option A — SQLite (zero setup)
sqlite3 olist_lite.db < schema.sql
python3 load_data.py          # loads the CSVs in data/ into the db
sqlite3 olist_lite.db < queries.sql

# Option B — PostgreSQL
psql -d your_db -f schema.sql
# load data/*.csv with \copy or your tool of choice, then:
psql -d your_db -f queries.sql
```
Note: a few queries use SQLite's `strftime`/`julianday`. On Postgres, swap these for `DATE_TRUNC('month', col)` and `EXTRACT`/date-subtraction equivalents — the CTE logic and window functions are unchanged.

---

## Key findings

**1. Late deliveries are a measurable satisfaction problem, not a vague complaint.**
Orders delivered late average a **2.18/5** review score, versus **4.20/5** for on-time orders — a ~48% drop. Late delivery isn't a minor annoyance in this data; it's the single biggest driver of bad reviews. *(Query 5)*
→ *If I were on this team:* I'd push for a delivery-time SLA dashboard, not just a post-mortem review report — by the time the review comes in, the customer relationship is already damaged.

**2. Revenue is heavily concentrated in a small slice of customers.**
The top 20% of customers (by lifetime spend) generate **60.7%** of total revenue. The bottom 20% generate under **1%**. *(Query 3)*
→ *So what:* retention spend should be weighted toward this top quintile — a 5% churn reduction there is worth far more than the same effort spread evenly across all customers.

**3. A small group of sellers shows a sudden, sustained volume collapse.**
Six sellers had order volume drop 50%+ month-over-month and never recover, starting around mid-2024 — the kind of pattern that's invisible in a single "total revenue" dashboard but obvious once you check seller-level trends month by month. *(Query 7)*
→ *So what:* this is the kind of automatable check (flag any seller whose volume drops 50%+ vs. their trailing 3-month average) that should run weekly, not get discovered months later in a deep-dive.

**4. Revenue is seasonal and growing — November/December run ~60-70% above the February low.**
Monthly revenue grew from ~$2K (Jan 2023) to ~$415K (Dec 2024) with a clear holiday peak each year. *(Query 1)*
→ *So what:* inventory and seller-capacity planning should anchor to this seasonal curve, not a flat monthly average.

---

## What's in `queries.sql`
| # | Query | Technique |
|---|---|---|
| 1 | Monthly revenue + MoM growth | `LAG()` window function |
| 2 | Top categories by revenue vs. by volume | `RANK()`, dual ranking |
| 3 | Customer revenue concentration (Pareto) | `NTILE(5)` |
| 4 | Running total of daily revenue | Cumulative `SUM() OVER()` |
| 5 | Late delivery → review score impact | Aggregate + join |
| 6 | Late delivery rate by region | `CASE WHEN` aggregation |
| 7 | Seller anomaly detection (MoM volume drop) | `LAG()` + threshold flag |
| 8 | Cohort retention (month 0–3 by signup cohort) | Multi-CTE, date-math join |
| 9 | Category × quarter revenue pivot | Manual `CASE WHEN` pivot |
| 10 | Customer LTV ranking | `DENSE_RANK()`, `PERCENT_RANK()` |
| 11 | Win-back list (inactive 90+ days, previously active) | Date-diff filter |

## Repo structure
```
.
├── README.md
├── schema.sql          # table definitions + indexes
├── generate.py         # synthetic data generator (reproducible, seeded)
├── load_data.py         # loads CSVs into SQLite for local testing
├── queries.sql          # all 11 analytical queries, commented
└── data/
    ├── customers.csv
    ├── sellers.csv
    ├── products.csv
    ├── orders.csv
    ├── order_items.csv
    └── order_reviews.csv
```
