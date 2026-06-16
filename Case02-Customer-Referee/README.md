# Case 02 — Find Customer Referee

**Difficulty:** Easy
**Topic:** NULL Handling, Filtering, WHERE Clause
**Tool:** MySQL Workbench

---

## Business Scenario

A retail bank wants to measure true organic customer acquisition — specifically, how many customers were **not** referred by a particular relationship manager (ID: 2). This means the query must return customers who were either referred by someone else, or walked in on their own with no referrer at all.

The challenge: customers with no referrer have a NULL value in the `referee_id` column — not a zero, not an empty string, but NULL. A simple `!=` filter silently drops these customers, making the manager's network appear larger than it actually is and making organic acquisition look smaller than it really is.

---

## Table Structure

| Column | Type | Description |
|--------|------|-------------|
| id | INT | Primary Key |
| name | VARCHAR(25) | Customer name |
| referee_id | INT | ID of referring customer, NULL if no referrer |

---

## Sample Data

| id | name | referee_id |
|----|------|------------|
| 1 | Alice | NULL |
| 2 | Bob | 1 |
| 3 | Carol | 2 |
| 4 | David | 2 |
| 5 | Emma | NULL |
| 6 | Frank | 3 |

---

## Expected Output

Customers NOT referred by relationship manager ID 2:

| name |
|------|
| Alice |
| Bob |
| Emma |
| Frank |

---

## The Wrong Query — And Why It Looks Right

```sql
-- This looks correct but silently drops NULL rows
SELECT name
FROM Customer
WHERE referee_id != 2;
```

This returns only Bob and Frank — Alice and Emma disappear completely because NULL != 2 does not evaluate to TRUE in SQL. It evaluates to UNKNOWN, and SQL excludes UNKNOWN rows from results. No error. No warning. Just missing data.

---

## Solution

```sql
SELECT name
FROM Customer
WHERE referee_id != 2
   OR referee_id IS NULL;
```

---

## Approach

NULL in SQL does not mean zero or false — it means unknown. Any comparison with NULL using `=`, `!=`, `>`, or `<` returns UNKNOWN, not TRUE or FALSE. The only way to explicitly check for NULL is with `IS NULL` or `IS NOT NULL`.

Adding `OR referee_id IS NULL` brings back all customers with no referrer — which in any real CRM dataset is a significant and business-critical segment. Without this, the query runs cleanly, returns results, and is silently wrong.

**What I almost did:** Wrote `WHERE NOT (referee_id = 2)` thinking it was logically equivalent. It hits the exact same NULL trap — NOT UNKNOWN is still UNKNOWN.

---

## Alternate Approach

```sql
-- Sounds logical, same NULL trap
SELECT name
FROM Customer
WHERE NOT (referee_id = 2);
```

```sql
-- Also valid using COALESCE
SELECT name
FROM Customer
WHERE COALESCE(referee_id, 0) != 2;
```

COALESCE replaces NULL with 0 before comparison, which sidesteps the NULL trap. Works correctly but adds a function call on every row — less readable and slightly less performant than the explicit OR IS NULL approach on large tables.

---

## Performance Note

With an index on `referee_id`, the OR condition remains efficient for most CRM-scale datasets. On very large tables, OR conditions can sometimes prevent index usage depending on the query planner — in that case COALESCE or a UNION approach may perform better. For standard business use cases this query is fast and reliable.

---

## What This Unlocks

The business gets accurate organic acquisition numbers. Without the NULL fix, walk-in customers are invisible in the report — making one manager's referral network look disproportionately large and skewing any downstream decisions about hiring, incentives, or channel investment based on that data.

---

## Key Takeaway

NULL does not behave like any other value in SQL. It is not zero, not false, not empty. Once you get burned by a silently wrong NULL filter in a real dataset, you never forget to check for it again.



