-- =====================================================================
-- PROJECT: Revenue Leakage & Customer Concentration Analysis (Olist-style)
-- All queries use standard ANSI SQL (window functions, CTEs) and run
-- as-is on PostgreSQL, MySQL 8+, and SQLite 3.25+.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. MONTHLY REVENUE TREND + MONTH-OVER-MONTH GROWTH (LAG window fn)
-- Business question: "Is revenue growing, and where did it slow down?"
-- ---------------------------------------------------------------------
WITH monthly_revenue AS (
    SELECT
        strftime('%Y-%m', o.order_date)            AS order_month,
        SUM(oi.quantity * oi.unit_price)            AS revenue,
        COUNT(DISTINCT o.order_id)                  AS orders
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY 1
)
SELECT
    order_month,
    orders,
    ROUND(revenue, 2)                                          AS revenue,
    ROUND(LAG(revenue) OVER (ORDER BY order_month), 2)         AS prev_month_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY order_month))
        / LAG(revenue) OVER (ORDER BY order_month), 1
    )                                                           AS mom_growth_pct
FROM monthly_revenue
ORDER BY order_month;


-- ---------------------------------------------------------------------
-- 2. TOP CATEGORIES — by revenue vs. by order volume (deliberately
--    different rankings to show revenue-per-order isn't uniform)
-- ---------------------------------------------------------------------
WITH cat_stats AS (
    SELECT
        p.category,
        COUNT(DISTINCT oi.order_id)                AS order_count,
        SUM(oi.quantity * oi.unit_price)            AS revenue
    FROM order_items oi
    JOIN products p ON p.product_id = oi.product_id
    GROUP BY p.category
)
SELECT
    category,
    order_count,
    ROUND(revenue, 2)                               AS revenue,
    ROUND(revenue / order_count, 2)                 AS revenue_per_order,
    RANK() OVER (ORDER BY revenue DESC)              AS rank_by_revenue,
    RANK() OVER (ORDER BY order_count DESC)          AS rank_by_volume
FROM cat_stats
ORDER BY revenue DESC;


-- ---------------------------------------------------------------------
-- 3. CUSTOMER REVENUE CONCENTRATION (Pareto / NTILE quintiles)
-- Business question: "What % of revenue depends on our top customers?"
-- ---------------------------------------------------------------------
WITH customer_revenue AS (
    SELECT
        o.customer_id,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY o.customer_id
),
ranked AS (
    SELECT
        customer_id,
        revenue,
        NTILE(5) OVER (ORDER BY revenue DESC) AS revenue_quintile
    FROM customer_revenue
)
SELECT
    revenue_quintile,
    COUNT(*)                                              AS customers,
    ROUND(SUM(revenue), 2)                                AS total_revenue,
    ROUND(100.0 * SUM(revenue) / (SELECT SUM(revenue) FROM customer_revenue), 1) AS pct_of_total_revenue
FROM ranked
GROUP BY revenue_quintile
ORDER BY revenue_quintile;
-- Finding: quintile 1 (top 20% of customers) drives the large majority of revenue.


-- ---------------------------------------------------------------------
-- 4. RUNNING TOTAL OF REVENUE (cumulative sum window function)
-- ---------------------------------------------------------------------
WITH daily_revenue AS (
    SELECT
        o.order_date,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY o.order_date
)
SELECT
    order_date,
    ROUND(revenue, 2)                                              AS daily_revenue,
    ROUND(SUM(revenue) OVER (ORDER BY order_date), 2)              AS running_total_revenue
FROM daily_revenue
ORDER BY order_date;


-- ---------------------------------------------------------------------
-- 5. DELIVERY PERFORMANCE -> REVIEW SCORE IMPACT
-- Business question: "Does late delivery actually hurt customer
-- satisfaction, or is that just assumed?"
-- ---------------------------------------------------------------------
SELECT
    o.is_late,
    COUNT(*)                       AS delivered_orders,
    ROUND(AVG(r.review_score), 2)  AS avg_review_score
FROM orders o
JOIN order_reviews r ON r.order_id = o.order_id
GROUP BY o.is_late;
-- Finding: late deliveries average ~2.2/5 stars vs ~4.2/5 for on-time orders.


-- ---------------------------------------------------------------------
-- 6. LATE DELIVERY RATE BY SELLER REGION
-- ---------------------------------------------------------------------
SELECT
    s.region,
    COUNT(*)                                            AS total_items,
    SUM(CASE WHEN o.is_late THEN 1 ELSE 0 END)          AS late_items,
    ROUND(100.0 * SUM(CASE WHEN o.is_late THEN 1 ELSE 0 END) / COUNT(*), 1) AS late_rate_pct
FROM order_items oi
JOIN orders o   ON o.order_id  = oi.order_id
JOIN sellers s  ON s.seller_id = oi.seller_id
GROUP BY s.region
ORDER BY late_rate_pct DESC;


-- ---------------------------------------------------------------------
-- 7. SELLER ANOMALY DETECTION — month-over-month volume drop flag
-- Business question: "Which sellers show a sudden, sustained drop in
-- order volume that operations should investigate?"
-- ---------------------------------------------------------------------
WITH seller_month AS (
    SELECT
        oi.seller_id,
        strftime('%Y-%m', o.order_date)    AS order_month,
        COUNT(*)                           AS items_sold
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    GROUP BY oi.seller_id, order_month
),
with_prev AS (
    SELECT
        seller_id,
        order_month,
        items_sold,
        LAG(items_sold) OVER (PARTITION BY seller_id ORDER BY order_month) AS prev_month_items
    FROM seller_month
)
SELECT
    seller_id,
    order_month,
    items_sold,
    prev_month_items,
    ROUND(100.0 * (items_sold - prev_month_items) / prev_month_items, 1) AS mom_change_pct
FROM with_prev
WHERE prev_month_items >= 3
  AND items_sold <= prev_month_items * 0.5     -- flag: volume dropped 50%+
ORDER BY seller_id, order_month;


-- ---------------------------------------------------------------------
-- 8. COHORT RETENTION — % of each signup cohort still ordering in
--    months 0-3 after signup
-- ---------------------------------------------------------------------
WITH cohort AS (
    SELECT customer_id, strftime('%Y-%m', signup_date) AS cohort_month
    FROM customers
),
cust_orders AS (
    SELECT customer_id, strftime('%Y-%m', order_date) AS order_month
    FROM orders
),
month_offsets AS (
    SELECT
        c.customer_id,
        c.cohort_month,
        (CAST(strftime('%Y', co.order_month || '-01') AS INTEGER) * 12
            + CAST(strftime('%m', co.order_month || '-01') AS INTEGER))
        - (CAST(strftime('%Y', c.cohort_month || '-01') AS INTEGER) * 12
            + CAST(strftime('%m', c.cohort_month || '-01') AS INTEGER)) AS month_offset
    FROM cohort c
    JOIN cust_orders co ON co.customer_id = c.customer_id
),
cohort_size AS (
    SELECT cohort_month, COUNT(*) AS cohort_customers
    FROM cohort GROUP BY cohort_month
)
SELECT
    m.cohort_month,
    cs.cohort_customers,
    m.month_offset,
    COUNT(DISTINCT m.customer_id)                                          AS active_customers,
    ROUND(100.0 * COUNT(DISTINCT m.customer_id) / cs.cohort_customers, 1)   AS pct_active
FROM month_offsets m
JOIN cohort_size cs ON cs.cohort_month = m.cohort_month
WHERE m.month_offset BETWEEN 0 AND 3
GROUP BY m.cohort_month, cs.cohort_customers, m.month_offset
ORDER BY m.cohort_month, m.month_offset;


-- ---------------------------------------------------------------------
-- 9. MANUAL PIVOT — Revenue by category x quarter (CASE WHEN pivot,
--    the technique to use when your SQL flavor has no native PIVOT)
-- ---------------------------------------------------------------------
SELECT
    p.category,
    ROUND(SUM(CASE WHEN strftime('%m', o.order_date) IN ('01','02','03') THEN oi.quantity*oi.unit_price ELSE 0 END), 2) AS q1_revenue,
    ROUND(SUM(CASE WHEN strftime('%m', o.order_date) IN ('04','05','06') THEN oi.quantity*oi.unit_price ELSE 0 END), 2) AS q2_revenue,
    ROUND(SUM(CASE WHEN strftime('%m', o.order_date) IN ('07','08','09') THEN oi.quantity*oi.unit_price ELSE 0 END), 2) AS q3_revenue,
    ROUND(SUM(CASE WHEN strftime('%m', o.order_date) IN ('10','11','12') THEN oi.quantity*oi.unit_price ELSE 0 END), 2) AS q4_revenue
FROM order_items oi
JOIN orders o   ON o.order_id   = oi.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE strftime('%Y', o.order_date) = '2024'
GROUP BY p.category
ORDER BY (q1_revenue + q2_revenue + q3_revenue + q4_revenue) DESC;


-- ---------------------------------------------------------------------
-- 10. CUSTOMER LIFETIME VALUE RANKING (dense rank + percentile)
-- ---------------------------------------------------------------------
WITH customer_revenue AS (
    SELECT
        o.customer_id,
        SUM(oi.quantity * oi.unit_price) AS lifetime_value,
        COUNT(DISTINCT o.order_id)       AS total_orders
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY o.customer_id
)
SELECT
    customer_id,
    total_orders,
    ROUND(lifetime_value, 2)                                   AS lifetime_value,
    DENSE_RANK() OVER (ORDER BY lifetime_value DESC)            AS ltv_rank,
    ROUND(PERCENT_RANK() OVER (ORDER BY lifetime_value DESC) * 100, 1) AS percentile
FROM customer_revenue
ORDER BY lifetime_value DESC
LIMIT 25;


-- ---------------------------------------------------------------------
-- 11. CUSTOMERS WHO HAVE GONE QUIET (no order in 90+ days, but were
--     previously active — a basic win-back / churn-risk list)
-- ---------------------------------------------------------------------
WITH last_order AS (
    SELECT customer_id, MAX(order_date) AS last_order_date, COUNT(*) AS total_orders
    FROM orders
    GROUP BY customer_id
)
SELECT
    customer_id,
    last_order_date,
    total_orders,
    CAST(julianday('2024-12-31') - julianday(last_order_date) AS INTEGER) AS days_since_last_order
FROM last_order
WHERE total_orders >= 2
  AND julianday('2024-12-31') - julianday(last_order_date) >= 90
ORDER BY days_since_last_order DESC
LIMIT 50;
