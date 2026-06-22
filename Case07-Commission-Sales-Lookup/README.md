# Case 07 — Commission Sales Lookup

**Platform:** LeetCode #1068

**Difficulty:** Easy

**SQL Concept:** INNER JOIN across two tables

**Business Framing:** Electronics distributor commission payout report

---

## Business Scenario

### What happened

A regional electronics distributor sells products from multiple brands — Nokia, Apple, Samsung, and others. Every time a sale is recorded, it goes into the `Sales` table with a `product_id`, the year it sold, quantity, and price per unit.

But the `Sales` table doesn't store the product name — only the ID. The actual product names live in a separate `Product` catalog table.

At the end of each quarter, the finance team needs to generate a **commission payout report** for the sales reps. The report must show: which product was sold, in which year, and at what price. Sales reps earn commission only on products they actually moved — unsold catalog items don't count.

The ask: *"Give me every sales transaction with the product name and price attached — only for products that have actual sales records."*

---

### Why this is an INNER JOIN problem

Two tables are involved:

- `Sales` — records every transaction: product_id, year, quantity, price
- `Product` — the master catalog: product_id, product_name

The key detail: Samsung (product_id 300) exists in the `Product` table but has **zero sales records** in the `Sales` table. It should not appear in the commission report — nobody sold it, so nobody earns commission on it.

This is exactly what INNER JOIN is built for. It returns only rows where a match exists in **both** tables. No sales record = no match = not in the output.

If you used LEFT JOIN here, Samsung would appear in the result with `NULL` values for year and price — a ghost row that would confuse the finance team and potentially corrupt the commission calculation.

---

### The consequence of getting the join wrong

| Join Type | What happens to Samsung (no sales) |
|-----------|-------------------------------------|
| `INNER JOIN` | ✅ Excluded — correctly not in commission report |
| `LEFT JOIN` | ❌ Appears with NULL year and price — pollutes the report |

The rule of thumb: if you only want rows with a confirmed match in both tables, use INNER JOIN. If you need to preserve unmatched rows from one side, use LEFT JOIN.

---

## Table Structure

**Sales**

| Column | Type | Notes |
|--------|------|-------|
| sale_id | INT | Part of composite primary key |
| product_id | INT | Foreign key → Product table |
| year | INT | Year the sale occurred |
| quantity | INT | Units sold |
| price | INT | Price per unit |

**Product**

| Column | Type | Notes |
|--------|------|-------|
| product_id | INT | Primary key |
| product_name | VARCHAR | Brand/product name |

---

## Sample Data

**Product table:**

| product_id | product_name |
|------------|--------------|
| 100 | Nokia |
| 200 | Apple |
| 300 | Samsung |

**Sales table:**

| sale_id | product_id | year | quantity | price |
|---------|------------|------|----------|-------|
| 1 | 100 | 2008 | 10 | 5000 |
| 2 | 100 | 2009 | 12 | 5000 |
| 7 | 200 | 2011 | 15 | 9000 |

Note: Samsung (product_id 300) has no sales record — intentional.

---

## Query

```sql
SELECT b.product_name, a.year, a.price
FROM Sales a
JOIN Product b
    ON a.product_id = b.product_id;
```

---

## Expected Output

| product_name | year | price |
|--------------|------|-------|
| Nokia | 2008 | 5000 |
| Nokia | 2009 | 5000 |
| Apple | 2011 | 9000 |

Samsung does not appear — correctly excluded because it has no matching sales record.

---

## Why This Approach

`JOIN` (INNER JOIN) returns only rows with a confirmed match in both tables. Since commission is calculated only on actual sales, unsold products must be excluded — INNER JOIN enforces this automatically through the join condition.

---

## Alternate Approach

`LEFT JOIN` would work if you needed to see all products regardless of sales — for example, an inventory report showing which catalog items haven't moved. For a commission report, LEFT JOIN is the wrong choice because it introduces NULL rows for unsold products, which have no place in a payout calculation.

---

## Performance Note

INNER JOIN on an indexed foreign key (`product_id`) is highly efficient. At scale, ensuring `product_id` is indexed in both tables keeps this query fast even with millions of sales rows.

---

## Business Impact

Finance gets a clean, accurate commission report — every row represents a real sale with a real product name and price attached. No ghost rows, no NULLs, no manual cleanup. The join does the filtering automatically.
