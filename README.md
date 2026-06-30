# SQL Revenue Concentration & Delivery-Risk Analysis

A portfolio-ready SQL case study on synthetic e-commerce data that answers a common business question:

> Are we over-dependent on a small set of customers, and are those same customers exposed to delivery risk?

This project combines **revenue concentration analysis** (Pareto-style) with **operational risk signals** (delivery delays and review quality) to identify at-risk revenue pockets and suggest action priorities.

---

## Why this project matters

Revenue can look healthy overall while still being fragile:

- A few customers may drive a large share of sales (concentration risk).
- Delivery delays can erode retention and future revenue (execution risk).
- If high-value customers are also high-risk on operations, revenue quality is weaker than topline numbers suggest.

This case study demonstrates how to detect these patterns using SQL and lightweight Python data generation/loading scripts.

---

## Repository structure

```text
.
├── README.md
├── EXECUTIVE_SUMMARY.md
├── DATA_DICTIONARY.md
├── ASSUMPTIONS_AND_LIMITATIONS.md
├── requirements.txt
├── .gitignore
├── LICENSE
├── generate.py
├── load_data.py
├── schema.sql
├── queries.sql
├── customers.csv
├── sellers.csv
├── products.csv
├── orders.csv
├── order_items.csv
└── order_reviews.csv
```

---

## Analysis goals

1. Measure revenue concentration (e.g., top customer share, cumulative share).
2. Quantify delivery-risk exposure (late deliveries, delay days).
3. Combine concentration + risk into a practical customer prioritization view.
4. Produce actionable recommendations for operations and account management.

---

## Core KPIs to report

Use/extend the queries to produce these metrics:

- **Top 10 customer revenue share (%)**
- **Top 20% customer revenue share (%)**
- **Late delivery rate (%)**
- **Average delay days (for late deliveries)**
- **Revenue at risk** (revenue linked to delayed/low-rated orders)
- **Customer risk tiers** (High / Medium / Low)

> Tip: Put final KPI outputs in a markdown table or CSV under `outputs/` for presentation.

---

## Quick start

### 1) Clone

```bash
git clone https://github.com/SunnyPandey24/sql-revenue-concentration-analysis.git
cd sql-revenue-concentration-analysis
```

### 2) Install dependencies

```bash
pip install -r requirements.txt
```

### 3) Generate synthetic data (optional)

```bash
python generate.py
```

### 4) Create/load schema and run SQL analysis

Use your preferred SQL engine (SQLite/PostgreSQL compatible adjustments may be needed) and execute:

1. `schema.sql` (table creation)
2. data loading flow via `load_data.py` (or manual imports)
3. `queries.sql` (analysis logic)

---

## Business recommendations (template)

Based on concentration + delivery-risk findings, typical recommendations include:

- Create a **VIP delivery SLA lane** for top-revenue customers.
- Trigger proactive outreach when delay thresholds are breached.
- Diversify revenue by improving retention among mid-tier customers.
- Track concentration and risk monthly on a management dashboard.

---

## Validation checks (recommended)

Before trusting outputs, run checks such as:

- Null checks on IDs and critical dates
- Duplicate key checks (`order_id`, `customer_id`)
- Referential checks between orders, items, and customers
- Revenue sanity checks (non-negative prices/quantities)

---

## Files added for portfolio value

- `EXECUTIVE_SUMMARY.md` — concise stakeholder-facing summary
- `DATA_DICTIONARY.md` — table/field documentation
- `ASSUMPTIONS_AND_LIMITATIONS.md` — transparency and scope boundaries
- `requirements.txt` — reproducible environment

---

## License

This project is licensed under the MIT License. See `LICENSE`.
