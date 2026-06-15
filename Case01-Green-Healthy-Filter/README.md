

# Case 01 — Recyclable and Low Fat Products

**Difficulty:** Easy
**Topic:** Basic Filtering, ENUM Data Type
**Tool:** MySQL Workbench

---

## Business Scenario

A retail chain is launching a **"Green & Healthy"** shelf campaign. The marketing team needs a list of products that meet **both** sustainability criteria before the weekend — low fat formulation AND recyclable packaging.

The product catalog stores these as ENUM flags — each column only accepts `'Y'` or `'N'`. No in-between values, no nulls expected. The task is to filter only the products where both flags are `'Y'`.

---

## Table Structure

| Column | Type | Values |
|--------|------|--------|
| product_id | INT | Primary Key |
| product_name | VARCHAR(100) | Product name |
| low_fats | ENUM | 'Y' or 'N' |
| recyclable | ENUM | 'Y' or 'N' |

---

## Sample Data

| product_id | product_name | low_fats | recyclable |
|------------|--------------|----------|------------|
| 0 | Whole Grain Crackers | Y | N |
| 1 | Organic Almond Milk | Y | Y |
| 2 | Greek Yogurt Cup | N | Y |
| 3 | Oat Granola Bar | Y | Y |
| 4 | Cheddar Cheese Block | N | N |

---

## Expected Output

| product_id | product_name |
|------------|--------------|
| 1 | Organic Almond Milk |
| 3 | Oat Granola Bar |

---

## Solution

```sql
SELECT product_id, product_name
FROM Products
WHERE low_fats = 'Y'
  AND recyclable = 'Y';
```

---

## Approach

Both conditions live in a single table with no relationships to other tables — no joins needed. The filter is a strict AND — a product must satisfy both flags simultaneously to qualify. Simple, direct, and exactly what the business needs.

**What I almost did:** Started writing a CTE before realizing nothing here required one. The lesson — check if the simple solution is already correct before reaching for complexity.

---

## Alternate Approach

```sql
SELECT product_id, product_name
FROM Products
WHERE 
  CASE WHEN low_fats = 'Y' THEN 1 ELSE 0 END +
  CASE WHEN recyclable = 'Y' THEN 1 ELSE 0 END = 2;
```

Scores each flag and filters where both score. Technically works but adds unnecessary steps for what is fundamentally a two-condition filter. Avoided for readability and simplicity.

---

## Performance Note

Runs efficiently at scale with indexes on `low_fats` and `recyclable`. ENUM columns in MySQL are stored as integers internally, making equality checks fast. On a table with millions of products, this query remains performant without any structural changes.

---

## What This Unlocks

Any business filtering a product catalog by multiple binary attributes — sustainability flags, availability status, pricing tiers, compliance markers — can apply this exact logic. The pattern scales across industries.

---

## LinkedIn Post

https://www.linkedin.com/in/parth-r-gadewar/
