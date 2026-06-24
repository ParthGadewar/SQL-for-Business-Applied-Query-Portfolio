
# Case 08 — Browse-No-Purchase

---

## 📌 Business Scenario

An e-commerce company's marketing team is preparing a **re-engagement campaign**.

Before they can target anyone, they need a clean answer to one question:

> *Which customers have visited the site but never made a purchase — and how many times has it happened?*

The team has two data sources:
- **`Visits`** — logs every site visit, whether or not a purchase followed
- **`Transactions`** — logs every completed purchase, linked back to the visit it came from

Not every visit results in a transaction. Customers who browse repeatedly without buying are warm leads — they're aware of the brand, they keep coming back, but they haven't converted. These are the highest-priority targets for a personalized nudge (discount code, abandoned-browse email, retargeting ad).

The output needed: a list of customer IDs with a count of how many visit sessions had zero transactions.

---

## 🗂️ Table Schema

**`Visits`**

| Column Name | Type |
|-------------|------|
| visit_id | int |
| customer_id | int |

**`Transactions`**

| Column Name | Type |
|----------------|------|
| transaction_id | int |
| visit_id | int |
| amount | int |

---

## 🧪 Sample Data

**Visits**

| visit_id | customer_id |
|----------|-------------|
| 1 | 23 |
| 2 | 9 |
| 4 | 30 |
| 5 | 54 |
| 6 | 96 |
| 7 | 54 |
| 8 | 54 |

**Transactions**

| transaction_id | visit_id | amount |
|----------------|----------|--------|
| 2 | 5 | 310 |
| 3 | 5 | 300 |
| 9 | 5 | 200 |
| 12 | 1 | 910 |
| 13 | 2 | 970 |

---

## ✅ Expected Output

| customer_id | count_no_trans |
|-------------|----------------|
| 54 | 2 |
| 30 | 1 |
| 96 | 1 |

> **Reading this:** Customer 54 visited 3 times total; 1 visit (visit_id 5) had transactions, so 2 visits qualify. Customers 30 and 96 each visited once with no purchase.

---

## 💡 Solution Query

```sql
SELECT
    a.customer_id,
    COUNT(a.visit_id) AS count_no_trans
FROM Visits a
LEFT JOIN Transactions b
    ON a.visit_id = b.visit_id
WHERE b.transaction_id IS NULL
GROUP BY a.customer_id;
```

---

## 🔍 Approach Rationale

The key challenge: **preserve visits that have no matching transaction** — which rules out `INNER JOIN` immediately.

**Why `INNER JOIN` fails:** It only returns rows where a match exists on both sides. Any visit with no transaction record gets silently dropped — the exact opposite of what we need.

**Why `LEFT JOIN + IS NULL` works:** `LEFT JOIN` keeps every row from `Visits` regardless of whether a match exists in `Transactions`. For unmatched visits, all columns from the right table come back as `NULL`. The `WHERE b.transaction_id IS NULL` filter then isolates exactly those rows — browse-only sessions.

**MySQL-specific note:** Writing `COUNT(visit_id)` without a table alias throws an ambiguous column error because both tables share that column name. `COUNT(a.visit_id)` resolves it cleanly.

---

## 🔄 Alternate Approach

```sql
SELECT customer_id, COUNT(visit_id) AS count_no_trans
FROM Visits
WHERE visit_id NOT IN (
    SELECT visit_id FROM Transactions
)
GROUP BY customer_id;
```

**Why the main approach wins:** `NOT IN` has two risks at scale — if the subquery returns any `NULL` values, the entire result set goes empty (silent failure). It also re-executes the subquery per row in some engines. `LEFT JOIN + IS NULL` handles NULLs predictably and runs in a single pass.

---

## ⚡ Performance Note

Efficient when `visit_id` is indexed on both tables. At high volume, unindexed columns force a full scan. In production, partitioning `Visits` by date helps when the campaign targets a specific time window.

---

## 📊 Business Impact

The `count_no_trans` field doubles as a priority signal for campaign targeting:

- **Count ≥ 3:** Repeat browsers — highest intent, most aggressive re-engagement (personalized discount, direct outreach)
- **Count = 2:** Moderate priority — retargeting ads, browse-reminder emails
- **Count = 1:** Lower priority — standard re-engagement flow

Without this query, the team either targets all non-purchasers (wasteful) or manually filters session logs (slow and error-prone). This gives them a clean, ranked list ready to pipe into any CRM or campaign tool.

---

## 🛠️ MySQL Workbench Setup

```sql
CREATE DATABASE IF NOT EXISTS case08_browse_no_purchase;
USE case08_browse_no_purchase;

CREATE TABLE Visits (
    visit_id    INT PRIMARY KEY,
    customer_id INT
);

CREATE TABLE Transactions (
    transaction_id INT PRIMARY KEY,
    visit_id       INT,
    amount         INT
);

INSERT INTO Visits VALUES
(1, 23), (2, 9), (4, 30),
(5, 54), (6, 96), (7, 54), (8, 54);

INSERT INTO Transactions VALUES
(2,  5, 310), (3, 5, 300),
(9,  5, 200), (12, 1, 910), (13, 2, 970);
```

---



*Part of the SQL for Business series — reframing LeetCode problems as real business scenarios.*

---

Two things to update before pushing: drop in your Workbench screenshots and paste the LinkedIn post URL. Ready for Case 09 when you are.
