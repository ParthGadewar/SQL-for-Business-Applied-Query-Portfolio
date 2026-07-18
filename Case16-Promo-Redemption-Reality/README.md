---

## Business Scenario

A retail chain runs a loyalty program and periodically launches promotional campaigns — holiday discounts, flash sales, birthday rewards. Every campaign gets pushed to the entire member base, but not everyone redeems every promo.

## Business Question

**Out of all enrolled loyalty members, what percentage actually redeemed each individual promo?**

Low redemption on a promo is a direct signal — bad targeting, poor timing, or an offer that isn't compelling. Marketing uses this ranked number to decide which promo formats to repeat, retire, or redesign.


## Schema

**LoyaltyMembers**

| Column Name | Type |
|---|---|
| member_id | int |
| member_name | varchar |

`member_id` is the primary key. Each row represents one enrolled loyalty member.

**PromoRedemptions**

| Column Name | Type |
|---|---|
| promo_id | int |
| member_id | int |

`(promo_id, member_id)` is the composite primary key — each row represents one member redeeming one promo.

## MySQL Workbench Setup Script

```sql
DROP TABLE IF EXISTS PromoRedemptions;
DROP TABLE IF EXISTS LoyaltyMembers;

CREATE TABLE LoyaltyMembers (
    member_id   INT PRIMARY KEY,
    member_name VARCHAR(50)
);

CREATE TABLE PromoRedemptions (
    promo_id  INT,
    member_id INT,
    PRIMARY KEY (promo_id, member_id)
);

INSERT INTO LoyaltyMembers (member_id, member_name) VALUES
(6, 'Alice'),
(2, 'Bob'),
(7, 'Alex');

INSERT INTO PromoRedemptions (promo_id, member_id) VALUES
(215, 6),
(209, 2),
(208, 2),
(210, 6),
(208, 6),
(209, 7),
(209, 6),
(215, 7),
(208, 7),
(210, 2),
(207, 2),
(210, 7);
```

## Solution Query

```sql
SELECT 
    pr.promo_id,
    ROUND(
        COUNT(pr.member_id) * 100.0 / (SELECT COUNT(*) FROM LoyaltyMembers),
        2
    ) AS redemption_rate
FROM PromoRedemptions pr
GROUP BY pr.promo_id
ORDER BY redemption_rate DESC, pr.promo_id ASC;
```

## Expected Output

| promo_id | redemption_rate |
|---|---|
| 208 | 100.0 |
| 209 | 100.0 |
| 210 | 100.0 |
| 215 | 66.67 |
| 207 | 33.33 |

## Why This Approach

The total loyalty member count is a single fixed value that every `promo_id` group needs to divide against — a scalar subquery `(SELECT COUNT(*) FROM LoyaltyMembers)` handles that cleanly without a separate join or CTE. Because `(promo_id, member_id)` is a composite primary key, duplicate redemptions per member per promo are structurally impossible, so `COUNT(pr.member_id)` alone is sufficient — no `DISTINCT` needed. Multiplying by `100.0` instead of `100` forces floating-point division, avoiding the integer-division-to-zero trap.

## Alternate Approach

The scalar subquery could be replaced with a `CROSS JOIN` against a pre-aggregated `(SELECT COUNT(*) AS total FROM LoyaltyMembers) t`, joining `total` into every row before grouping. Functionally equivalent, but the scalar subquery is simpler to read for a single fixed value and avoids introducing a join for something that isn't relational — it's just a constant.

## Performance Note

The scalar subquery runs once and MySQL treats it as a constant for the query plan, so this scales well even as `PromoRedemptions` grows into the millions of rows — the grouping and division cost dominates, not the subquery. Where it could break down: if `LoyaltyMembers` itself becomes highly volatile (mass enrollments/churn happening concurrently with the report running), the "total members" snapshot could shift mid-calculation on very large, high-write systems — worth pinning to a reporting timestamp in that case.

## Business Impact

This query gives marketing a ranked, promo-by-promo redemption leaderboard in one pass — no manual cross-referencing of member lists against redemption logs. Promos consistently below a threshold (say, 40%) become candidates for retirement or redesign; promos near 100% become templates worth repeating.

---

Want me to update the memory to reflect this new README structure (Business Scenario + Business Question split, setup script before solution query) for future cases, or is this a one-off for Case 17?
