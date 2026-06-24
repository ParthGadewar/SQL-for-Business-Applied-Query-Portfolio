
# Case 09 — Footfall Spike Analysis

---

## 📌 Business Scenario

Last year, a fast food chain had a problem they couldn't explain until it was too late.

On certain days, customer footfall spiked significantly compared to the day before. The kitchen ran out of stock mid-shift. Wait times doubled. Staff were stretched thin. Complaints went up. By the time the outlet manager realized what was happening, the damage was already done.

The operations team pulled the data afterward and the pattern was clear — these spikes weren't random. They were predictable. The problem wasn't the spike itself. **The problem was that nobody saw it coming.**

Now, heading into the new year, the data team is asked to go back through last year's daily footfall records and answer one question:

> *Which days saw a higher customer count than the day before — so we never get caught off guard again?*

This query builds the foundation of that early warning system.

---

## 🗂️ Table Schema

**`DailyFootfall`**

| Column Name | Type |
|-------------|------|
| id | int |
| recordDate | date |
| customerCount | int |

---

## 🧪 Sample Data

| id | recordDate | customerCount |
|----|------------|---------------|
| 1 | 2024-01-01 | 320 |
| 2 | 2024-01-02 | 475 |
| 3 | 2024-01-03 | 390 |
| 4 | 2024-01-04 | 610 |

---

## ✅ Expected Output

| id |
|----|
| 2 |
| 4 |

> **Reading this:** On 2024-01-02, footfall jumped from 320 to 475 — a spike nobody was prepared for. On 2024-01-04, it jumped again from 390 to 610. These are exactly the kinds of days that caused last year's operational failures. Identifying them is the first step to making sure it doesn't happen again.

---

## 💡 Solution Query

```sql
SELECT a.id
FROM DailyFootfall a
JOIN DailyFootfall b
    ON DATEDIFF(a.recordDate, b.recordDate) = 1
WHERE a.customerCount > b.customerCount;
```

---

## 🔍 Approach Rationale

The core challenge: **you only have one table, but you need to compare each row with the row from the previous day.**

The solution is a **Self Join** — joining the table to itself using two aliases:
- `a` = today's record
- `b` = yesterday's record

The `ON DATEDIFF(a.recordDate, b.recordDate) = 1` condition pairs each row with exactly the row that is one day before it. Once paired side by side, the `WHERE a.customerCount > b.customerCount` filter keeps only the days where footfall went up.

`a.id` is selected because we want the id of *today's* row — the day that spiked. `b.id` would return yesterday's id, which is incorrect.

**Why `DATEDIFF` instead of subtracting dates directly:**
Raw date subtraction in MySQL returns unreliable results depending on format. `DATEDIFF()` is explicit, readable, and guaranteed to return the difference in whole days.

---

## 🔄 Alternate Approach

```sql
SELECT a.id
FROM DailyFootfall a
JOIN DailyFootfall b
    ON b.recordDate = DATE_SUB(a.recordDate, INTERVAL 1 DAY)
WHERE a.customerCount > b.customerCount;
```

**Why the main approach wins:** `DATE_SUB` is slightly more verbose and less immediately readable for someone scanning the query quickly. `DATEDIFF = 1` states the intent more clearly — the dates are exactly one day apart.

---

## ⚡ Performance Note

Self joins on date columns are efficient when `recordDate` is indexed. Without an index, MySQL performs a full scan of both copies of the table for every row comparison — which degrades quickly on a full year of daily records across hundreds of outlets.

---

## 📊 Business Impact

This query turns last year's footfall logs into a **spike calendar**. With this in hand, the operations team can:

- Identify which dates consistently see day-over-day jumps
- Pre-schedule additional staff for those periods next year
- Set inventory reorder triggers before known spike windows
- Build an early warning threshold — if today's count crosses X% of yesterday's, escalate automatically

Last year the chain reacted. Next year they plan. That shift starts with this query.

---

## 🛠️ MySQL Workbench Setup

```sql
CREATE DATABASE IF NOT EXISTS case09_footfall_spike_analysis;
USE case09_footfall_spike_analysis;

CREATE TABLE DailyFootfall (
    id            INT PRIMARY KEY,
    recordDate    DATE,
    customerCount INT
);

INSERT INTO DailyFootfall VALUES
(1, '2024-01-01', 320),
(2, '2024-01-02', 475),
(3, '2024-01-03', 390),
(4, '2024-01-04', 610);
```


