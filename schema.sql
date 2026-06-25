DROP TABLE IF EXISTS order_reviews;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS sellers;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id     INTEGER PRIMARY KEY,
    customer_name   TEXT NOT NULL,
    region          TEXT NOT NULL,
    signup_date     DATE NOT NULL
);

CREATE TABLE sellers (
    seller_id       INTEGER PRIMARY KEY,
    seller_name     TEXT NOT NULL,
    region          TEXT NOT NULL
);

CREATE TABLE products (
    product_id      INTEGER PRIMARY KEY,
    product_name    TEXT NOT NULL,
    category        TEXT NOT NULL,
    seller_id       INTEGER NOT NULL REFERENCES sellers(seller_id),
    price           NUMERIC(10,2) NOT NULL
);

CREATE TABLE orders (
    order_id                INTEGER PRIMARY KEY,
    customer_id             INTEGER NOT NULL REFERENCES customers(customer_id),
    order_date              DATE NOT NULL,
    estimated_delivery_date DATE NOT NULL,
    delivered_date          DATE NOT NULL,
    order_status            TEXT NOT NULL,
    is_late                 BOOLEAN NOT NULL
);

CREATE TABLE order_items (
    order_item_id   INTEGER PRIMARY KEY,
    order_id        INTEGER NOT NULL REFERENCES orders(order_id),
    product_id      INTEGER NOT NULL REFERENCES products(product_id),
    seller_id       INTEGER NOT NULL REFERENCES sellers(seller_id),
    quantity        INTEGER NOT NULL,
    unit_price      NUMERIC(10,2) NOT NULL
);

CREATE TABLE order_reviews (
    order_id        INTEGER PRIMARY KEY REFERENCES orders(order_id),
    review_score    INTEGER NOT NULL CHECK (review_score BETWEEN 1 AND 5)
);

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_items_order ON order_items(order_id);
CREATE INDEX idx_items_product ON order_items(product_id);
CREATE INDEX idx_items_seller ON order_items(seller_id);
