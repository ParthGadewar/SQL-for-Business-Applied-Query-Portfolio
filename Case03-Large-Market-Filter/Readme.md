# Case 03 — Large market filter

**Platform:** LeetCode #595
**Difficulty:** Easy
**Core Concept:** Multi-condition filtering with OR, threshold operators

---

## Business Scenario

A policy research firm maintains a database of country-level data — land area,
population, and GDP. Before running any regional analysis, the team needs to 
flag which countries qualify as "large markets."

The definition: a country is a large market if it has an area of at least 
3,000,000 km² OR a population of at least 25,000,000. Either condition alone 
is enough to qualify.

---

## Table Structure

| Column     | Type         | Notes                  |
|------------|--------------|------------------------|
| name       | VARCHAR(100) | Primary Key            |
| continent  | VARCHAR(50)  |                        |
| area       | INT          | In km²                 |
| population | INT          |                        |
| gdp        | BIGINT       |                        |

---

## Sample Data

| name        | continent | area     | population  | gdp           |
|-------------|-----------|----------|-------------|---------------|
| Afghanistan | Asia      | 652230   | 25500100    | 20343000000   |
| Albania     | Europe    | 28748    | 2831741     | 12960000000   |
| Algeria     | Africa    | 2381741  | 37100000    | 188681000000  |
| Andorra     | Europe    | 468      | 78115       | 3712000000    |
| Angola      | Africa    | 1246700  | 20609294    | 100990000000  |
| Russia      | Europe    | 17098242 | 144500000   | 1699877000000 |
| Canada      | Americas  | 9984670  | 38000000    | 1736425000000 |
| China       | Asia      | 9596960  | 1400050000  | 14722730000000|
| Vatican     | Europe    | 0        | 800         | 0             |
| Australia   | Oceania   | 7692024  | 25600000    | 1392680000000 |

---

## Expected Output

| name        | population  | area     |
|-------------|-------------|----------|
| Afghanistan | 25500100    | 652230   |
| Algeria     | 37100000    | 2381741  |
| Russia      | 144500000   | 17098242 |
| Canada      | 38000000    | 9984670  |
| China       | 1400050000  | 9596960  |
| Australia   | 25600000    | 7692024  |

---

## The Wrong Query (and why it's wrong)

```sql
-- WRONG — only checks population
SELECT name, population, area
FROM World
WHERE population >= 25000000;
```

This silently misses countries like Russia and Canada, which qualify purely
on area (17M km² and 9.9M km² respectively) but may not always meet the 
population threshold depending on your dataset.

The sample data on LeetCode is small enough that this might still produce
a passing output — which is exactly what makes it dangerous. Always write
the query against the full problem definition, not just what the sample
data happens to show.

---

## Solution

```sql
SELECT name, population, area
FROM World
WHERE area >= 3000000        -- qualifies on land size
   OR population >= 25000000; -- qualifies on population
```

---

## Why This Approach

`OR` is correct here because the business rule is inclusive — meeting either
threshold alone is enough to qualify a country. `AND` would return only
countries that satisfy both conditions simultaneously, which is a completely
different and far stricter filter.

---

## Three Things That Can Trip You Up

**1. Writing only one condition because the sample data lets you get away with it**
LeetCode's sample table is tiny. A query with only the population condition
might return the right rows for that sample — and you'd never know you were
missing area-only qualifiers like Russia or Canada on the real dataset.

**2. `>` vs `>=`**
The problem says "at least" — which means the boundary value itself qualifies.
`>` would silently exclude a country sitting exactly at 3,000,000 km² or
exactly 25,000,000 people. Always read threshold language carefully.

**3. `OR` vs `AND`**
The word "or" appears in the problem statement in plain English. The instinct
to second-guess whether it should be AND in SQL is worth resisting. When
either condition alone qualifies a row, OR is always the right operator.

---

## Alternate Approach

```sql
-- UNION approach — functionally identical, more verbose
SELECT name, population, area
FROM World
WHERE area >= 3000000

UNION

SELECT name, population, area
FROM World
WHERE population >= 25000000;
```

Works correctly but queries the table twice. No advantage over a single OR
at this scale.

---

## Performance Note

`OR` on unindexed columns triggers a full table scan. Fine at country-level
data volume. At scale, consider separate indexes on `area` and `population`,
though the query planner may still prefer a full scan depending on 
selectivity.

