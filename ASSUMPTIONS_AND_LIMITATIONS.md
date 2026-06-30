# Assumptions and Limitations

## Assumptions
1. Synthetic data is representative enough to demonstrate analysis patterns.
2. Revenue is approximated as `price + freight_value` at item level.
3. Delivery risk is proxied by delivery delay and review score.
4. Customer risk tiers can be defined with threshold-based rules.

## Limitations
1. Synthetic data may not reflect real-world seasonality or behavioral variance.
2. No causal inference — analysis is descriptive/diagnostic.
3. Delivery performance can be influenced by external factors not modeled here.
4. Missing/late reviews may bias service-quality interpretation.

## Scope boundaries
- Focus is on concentration and fulfillment-risk analytics.
- Does not include forecasting, churn modeling, or experimentation.

## How to extend
- Add monthly cohort trends.
- Add category-level concentration analysis.
- Add seller-level reliability impact on customer risk.
