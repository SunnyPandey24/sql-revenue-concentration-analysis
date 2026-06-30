# Data Dictionary

This document describes the key datasets used in this case study.

## customers.csv
| Column | Description |
|---|---|
| customer_id | Unique customer identifier |
| customer_city | Customer city |
| customer_state | Customer state |

## sellers.csv
| Column | Description |
|---|---|
| seller_id | Unique seller identifier |
| seller_city | Seller city |
| seller_state | Seller state |

## products.csv
| Column | Description |
|---|---|
| product_id | Unique product identifier |
| product_category | Product category |

## orders.csv
| Column | Description |
|---|---|
| order_id | Unique order identifier |
| customer_id | Customer placing the order |
| order_status | Order status |
| order_purchase_timestamp | Order purchase datetime |
| order_delivered_customer_date | Actual delivery datetime |
| order_estimated_delivery_date | Estimated delivery datetime |

## order_items.csv
| Column | Description |
|---|---|
| order_id | Order identifier |
| order_item_id | Item line number within order |
| product_id | Product identifier |
| seller_id | Seller identifier |
| price | Item price |
| freight_value | Shipping/freight amount |

## order_reviews.csv
| Column | Description |
|---|---|
| review_id | Unique review identifier |
| order_id | Related order |
| review_score | Customer rating score |
| review_creation_date | Review creation date |

## Notes
- Exact column names may vary slightly based on generator version.
- Align `schema.sql` definitions with CSV headers before loading.
