"""Loads the CSVs in data/ into a local SQLite database (olist_lite.db)
for testing queries.sql. Run `sqlite3 olist_lite.db < schema.sql` first."""
import sqlite3
import pandas as pd

con = sqlite3.connect("olist_lite.db")
tables = ["customers", "sellers", "products", "orders", "order_items", "order_reviews"]
for t in tables:
    df = pd.read_csv(f"data/{t}.csv")
    df.to_sql(t, con, if_exists="append", index=False)
con.commit()
con.close()
print("Loaded:", ", ".join(tables))
