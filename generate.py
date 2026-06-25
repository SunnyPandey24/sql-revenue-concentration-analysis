import random, datetime as dt
import pandas as pd
import numpy as np
from faker import Faker

fake = Faker()
random.seed(42)
np.random.seed(42)

N_CUSTOMERS = 4000
N_SELLERS = 180
N_PRODUCTS = 450
N_ORDERS = 9000

CATEGORIES = ["electronics","home_decor","fashion","beauty","sports","toys","books",
              "garden","auto_parts","groceries","furniture","pet_supplies"]
REGIONS = ["North","South","East","West","Central"]

# ---- customers ----
start_date = dt.date(2023,1,1)
end_date = dt.date(2024,12,31)
days_range = (end_date - start_date).days

customers = []
for i in range(1, N_CUSTOMERS+1):
    signup = start_date + dt.timedelta(days=random.randint(0, days_range-30))
    customers.append({
        "customer_id": i,
        "customer_name": fake.name(),
        "region": random.choice(REGIONS),
        "signup_date": signup
    })
customers_df = pd.DataFrame(customers)

# ---- sellers ----
sellers = [{"seller_id": i, "seller_name": fake.company(), "region": random.choice(REGIONS)}
           for i in range(1, N_SELLERS+1)]
sellers_df = pd.DataFrame(sellers)

# ---- products ----
products = []
for i in range(1, N_PRODUCTS+1):
    cat = random.choice(CATEGORIES)
    base_price = {
        "electronics": (80,1200),"home_decor": (10,150),"fashion": (15,200),
        "beauty": (5,90),"sports": (10,300),"toys": (5,120),"books": (5,60),
        "garden": (10,200),"auto_parts": (15,400),"groceries": (3,40),
        "furniture": (50,1500),"pet_supplies": (5,150)
    }[cat]
    products.append({
        "product_id": i,
        "product_name": fake.word().title()+" "+cat.replace("_"," ").title(),
        "category": cat,
        "seller_id": random.randint(1, N_SELLERS),
        "price": round(random.uniform(*base_price), 2)
    })
products_df = pd.DataFrame(products)

# Pareto: 20% of customers (whales) generate ~70% of orders
n_whales = int(N_CUSTOMERS * 0.2)
whale_ids = random.sample(range(1, N_CUSTOMERS+1), n_whales)
regular_ids = [c for c in range(1, N_CUSTOMERS+1) if c not in whale_ids]

order_customer_pool = whale_ids * 8 + regular_ids * 1  # whales ordered far more often

orders = []
order_items = []
reviews = []
order_id = 1
item_id = 1

# seasonality: more orders Nov/Dec, dip in Feb
def season_weight(month):
    weights = {1:0.9,2:0.7,3:0.9,4:0.95,5:1.0,6:1.0,7:0.95,8:0.95,9:1.0,10:1.1,11:1.6,12:1.7}
    return weights[month]

# build a weighted day pool based on seasonality
day_pool = []
d = start_date
while d <= end_date:
    w = season_weight(d.month)
    day_pool.extend([d]*int(w*10))
    d += dt.timedelta(days=1)

# a few "struggling sellers" who will show a sudden volume drop after a certain month (anomaly to detect)
struggling_sellers = random.sample(range(1, N_SELLERS+1), 6)
struggle_start = dt.date(2024,7,1)

for _ in range(N_ORDERS):
    cust_id = random.choice(order_customer_pool)
    cust_signup = customers_df.loc[customers_df.customer_id==cust_id, "signup_date"].iloc[0]
    order_date = random.choice(day_pool)
    if order_date < cust_signup:
        order_date = cust_signup + dt.timedelta(days=random.randint(0,60))
        if order_date > end_date:
            continue

    n_items = random.choices([1,2,3,4],[0.55,0.25,0.13,0.07])[0]
    chosen_products = []
    for _ in range(n_items):
        p = products_df.sample(1).iloc[0]
        # avoid struggling sellers heavily after struggle_start to create the anomaly signal
        if p.seller_id in struggling_sellers and order_date >= struggle_start:
            if random.random() < 0.85:
                continue
        chosen_products.append(p)
    if not chosen_products:
        continue

    order_total = 0
    estimated_days = random.randint(5,12)
    estimated_delivery = order_date + dt.timedelta(days=estimated_days)

    # late delivery probability higher for furniture/auto_parts (bulky) and randomly ~15% overall
    is_late = random.random() < 0.16
    if is_late:
        delivered_date = estimated_delivery + dt.timedelta(days=random.randint(1,10))
    else:
        delivered_date = estimated_delivery - dt.timedelta(days=random.randint(0,3))
        if delivered_date < order_date:
            delivered_date = order_date + dt.timedelta(days=random.randint(2,6))

    if delivered_date > dt.date(2025,1,15):
        delivered_status = "shipped"
    else:
        delivered_status = "delivered"

    for p in chosen_products:
        qty = random.choices([1,2,3],[0.8,0.15,0.05])[0]
        order_items.append({
            "order_item_id": item_id,
            "order_id": order_id,
            "product_id": int(p.product_id),
            "seller_id": int(p.seller_id),
            "quantity": qty,
            "unit_price": p.price
        })
        order_total += p.price*qty
        item_id += 1

    orders.append({
        "order_id": order_id,
        "customer_id": cust_id,
        "order_date": order_date,
        "estimated_delivery_date": estimated_delivery,
        "delivered_date": delivered_date,
        "order_status": delivered_status,
        "is_late": is_late
    })

    # review score: lower if late
    if delivered_status == "delivered":
        if is_late:
            score = random.choices([1,2,3,4,5],[0.35,0.30,0.20,0.10,0.05])[0]
        else:
            score = random.choices([1,2,3,4,5],[0.02,0.05,0.13,0.35,0.45])[0]
        reviews.append({"order_id": order_id, "review_score": score})

    order_id += 1

orders_df = pd.DataFrame(orders)
order_items_df = pd.DataFrame(order_items)
reviews_df = pd.DataFrame(reviews)

customers_df.to_csv("data/customers.csv", index=False)
sellers_df.to_csv("data/sellers.csv", index=False)
products_df.to_csv("data/products.csv", index=False)
orders_df.to_csv("data/orders.csv", index=False)
order_items_df.to_csv("data/order_items.csv", index=False)
reviews_df.to_csv("data/order_reviews.csv", index=False)

print("customers", len(customers_df))
print("sellers", len(sellers_df))
print("products", len(products_df))
print("orders", len(orders_df))
print("order_items", len(order_items_df))
print("reviews", len(reviews_df))
print("struggling_sellers", struggling_sellers)
