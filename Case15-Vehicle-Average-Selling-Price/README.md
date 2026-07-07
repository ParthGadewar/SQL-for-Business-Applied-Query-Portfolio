

# Case 15 — True Average Selling Price of Vehicles

**Company:** AutoTrader.ca

## Business Scenario

Thousands of vehicle listings are managed by dealerships across Canada. Dealers frequently adjust prices based on market demand, inventory levels, competitor pricing, and seasonal promotions. As a result, the same vehicle model can carry multiple prices over its listing period.

Meanwhile, customers continue purchasing vehicles every day — each sale happens at whatever price was active on that specific date.

Leadership wants to understand the **true average selling price** of each vehicle model over a reporting period, to evaluate pricing strategy and market performance. Simply averaging the listed prices would be misleading, since some prices led to far more sales than others.

## Business Challenge

For every vehicle model:
- Match each completed sale to the price that was active on the date of that sale.
- Calculate the Average Selling Price (ASP) as a **weighted average** — weighted by the number of units sold at each price.
- If a model had zero recorded sales in the period, report its ASP as `0`.

## Schema

**ModelPrices**
| Column | Type |
|---|---|
| model_id | INT |
| model_name | VARCHAR(50) |
| start_date | DATE |
| end_date | DATE |
| price | INT |

**VehicleSales**
| Column | Type |
|---|---|
| model_id | INT |
| sale_date | DATE |
| units_sold | INT |

## SQL Solution

```sql
SELECT 
    mp.model_id,
    mp.model_name,
    ROUND(
        IFNULL(SUM(vs.units_sold * mp.price) / SUM(vs.units_sold), 0), 
        2
    ) AS avg_selling_price
FROM ModelPrices mp
LEFT JOIN VehicleSales vs
    ON mp.model_id = vs.model_id
    AND vs.sale_date BETWEEN mp.start_date AND mp.end_date
GROUP BY mp.model_id, mp.model_name;
```

## Why This Approach

`LEFT JOIN` from `ModelPrices` ensures models with zero sales (like the Honda Civic in the sample data) still appear in the output — a plain `INNER JOIN` would silently drop them. The `BETWEEN` condition pins each sale to the exact price window active on that date, so a single model's multiple price periods don't get conflated. The weighted average (`SUM(units*price)/SUM(units)`) reflects what customers actually paid, not a naive average of listed prices.

## Alternate Approach

A correlated subquery could look up the matching price for each sale row individually instead of joining. Rejected here because the join scales better and keeps the logic in a single readable pass rather than a per-row lookup.

## Performance Note

This pattern performs well as long as `model_id` and date columns are indexed — the `BETWEEN` join condition benefits significantly from a composite index on `(model_id, start_date, end_date)`. Without indexing, the range comparison forces a scan across all price periods per sale, which degrades at scale (thousands of models × frequent price changes).

## So What

This tells dealership partners the price customers *actually* paid, not just what was listed — directly usable to judge whether a price drop increased volume enough to justify the margin loss, model by model.

---

