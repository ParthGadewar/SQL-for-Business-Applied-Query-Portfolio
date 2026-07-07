

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

## SQL workbench setup

```sql
CREATE TABLE ModelPrices (
    model_id INT,
    model_name VARCHAR(50),
    start_date DATE,
    end_date DATE,
    price INT
);

CREATE TABLE VehicleSales (
    model_id INT,
    sale_date DATE,
    units_sold INT
);

INSERT INTO ModelPrices (model_id, model_name, start_date, end_date, price) VALUES
(1, 'Toyota RAV4', '2024-01-01', '2024-01-31', 32000),
(1, 'Toyota RAV4', '2024-02-01', '2024-02-29', 30500),
(2, 'Honda CR-V',  '2024-01-01', '2024-02-29', 34000),
(3, 'Honda Civic', '2024-01-01', '2024-02-29', 24000);

INSERT INTO VehicleSales (model_id, sale_date, units_sold) VALUES
(1, '2024-01-10', 15),
(1, '2024-01-25', 10),
(1, '2024-02-05', 20),
(1, '2024-02-20', 5),
(2, '2024-01-15', 8),
(2, '2024-02-10', 12);
-- model_id 3 (Civic) intentionally has zero sales rows
```

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

## Query walkthrough — how it executes step by step:


**`LEFT JOIN VehicleSales vs ON mp.model_id = vs.model_id`** — `ModelPrices` is the left table, so every model survives the join even with zero matching sales. Honda Civic gets a row of all-NULL columns from `VehicleSales`, but it still appears in the result. An `INNER JOIN` here would silently drop it — exactly the kind of report that goes uncaught until someone asks "why isn't this model showing up anywhere?"

**`AND vs.sale_date BETWEEN mp.start_date AND mp.end_date`** — this second join condition is what pins each sale to the correct price period. Without it, RAV4's January and February price rows would each match every RAV4 sale, duplicating rows and corrupting the weighted average.

**`SUM(vs.units_sold * mp.price)`** — multiplies each matched sale's unit count by the price active during that period, then sums into a total revenue-equivalent per model. A plain `AVG(price)` can't do this — it would treat a price with 20 units sold the same as a price with 2.

**`SUM(vs.units_sold)`** — total units sold per model. For a model with real sales, this is a straightforward count. For Civic, every `vs.units_sold` value from the join is `NULL`, and `SUM()` ignores NULLs — so its total comes out to `NULL` (not `0`), since summing zero non-NULL rows returns `NULL`.

**`... / SUM(vs.units_sold)`** — dividing anything by `NULL` returns `NULL` (not an error, not a crash) — so Civic's average becomes `NULL` instead of triggering a divide-by-zero failure.

**`IFNULL(..., 0)`** — catches that `NULL` and converts it to `0`, which is what the business actually wants displayed for a model with no sales — not a blank, not an error, just `0.00`.

**`GROUP BY mp.model_id, mp.model_name`** — grouping on the left table's key is deliberate. Grouping on a column from `VehicleSales` would risk inconsistent behavior for unmatched models. Grouping on `mp.model_id` guarantees one clean row per listed model.


## Why This Approach

`LEFT JOIN` from `ModelPrices` ensures models with zero sales (like the Honda Civic in the sample data) still appear in the output — a plain `INNER JOIN` would silently drop them. The `BETWEEN` condition pins each sale to the exact price window active on that date, so a single model's multiple price periods don't get conflated. The weighted average (`SUM(units*price)/SUM(units)`) reflects what customers actually paid, not a naive average of listed prices.

## Alternate Approach

A correlated subquery could look up the matching price for each sale row individually instead of joining. Rejected here because the join scales better and keeps the logic in a single readable pass rather than a per-row lookup.

## Performance Note

This pattern performs well as long as `model_id` and date columns are indexed — the `BETWEEN` join condition benefits significantly from a composite index on `(model_id, start_date, end_date)`. Without indexing, the range comparison forces a scan across all price periods per sale, which degrades at scale (thousands of models × frequent price changes).

## So What

This tells dealership partners the price customers *actually* paid, not just what was listed — directly usable to judge whether a price drop increased volume enough to justify the margin loss, model by model.

---

