# Case 10 — Avg Cycle Time Per Machine
### SQL for Business: Applied Query Portfolio

---

## 📌 Business Scenario

A mid-sized electronics manufacturer runs three assembly machines on the factory floor — M1, M2, and M3. Each machine processes multiple production jobs per shift.

The operations team logs every job twice in the same activity table:
- A **"start"** event when the machine begins processing
- An **"end"** event when the job finishes

The floor manager needs a single report: **what is the average time each machine takes to complete one job?**

This report feeds into shift planning, bottleneck detection, and equipment maintenance scheduling. A machine averaging 4 minutes per job vs 9 minutes is a red flag — it either has a mechanical issue or is being overloaded.

Without this query, the team was manually calculating cycle times in spreadsheets at end of shift. Too slow. Too error-prone.

---

## 🗂️ Table Structure

**Table: `Activity`**
One table, but each job creates two rows — one for start, one for end.

| machine_id | process_id | activity_type | timestamp |
|------------|------------|---------------|-----------|
| 0 | 0 | start | 0.712 |
| 0 | 0 | end | 1.520 |
| 0 | 1 | start | 3.140 |
| 0 | 1 | end | 4.120 |
| 1 | 0 | start | 0.550 |
| 1 | 0 | end | 1.550 |
| 1 | 1 | start | 0.430 |
| 1 | 1 | end | 1.420 |
| 2 | 0 | start | 4.100 |
| 2 | 0 | end | 4.512 |
| 2 | 1 | start | 2.500 |
| 2 | 1 | end | 5.000 |

---

## ❓ The Business Question

> Which machines are slowest on average, and by how much?

Specifically: for each machine, calculate the average time (in seconds) between the start and end of every job it processed.

---

## 🔍 Query Logic — Before & After

**The problem:** start and end times are in separate rows, not columns. You can't just subtract two columns — you have to extract and subtract across rows within the same group.

**The approach:** Use conditional aggregation — `CASE WHEN` inside `SUM()` — to assign positive values to `end` timestamps and negative values to `start` timestamps. When summed per machine per process, the result is the duration of each job. Divide by `COUNT(DISTINCT process_id)` to get the average.

---

## ✅ SQL Solution

```sql
SELECT 
    machine_id,
    ROUND(
        SUM(CASE WHEN activity_type = 'end' THEN timestamp ELSE -timestamp END) 
        / COUNT(DISTINCT process_id),
        3
    ) AS processing_time
FROM Activity
GROUP BY machine_id;
```

**Why this approach:**
No JOIN needed. One pass through the table — end timestamps add, start timestamps subtract, net divided by job count gives average cycle time per machine.

**Alternate approach:**
Self-join the table on `machine_id` and `process_id` where one row is 'start' and the other is 'end', then subtract. Works, but doubles the data scanned and is harder to read.

**Performance note:**
Conditional aggregation is efficient on a single scan. The self-join alternate scales poorly — O(n²) in the worst case without proper indexing on `machine_id` + `process_id`.

---

## 📊 Output

| machine_id | processing_time |
|------------|----------------|
| 0 | 0.894 |
| 1 | 0.995 |
| 2 | 1.456 |

Machine 2 is averaging nearly 64% longer per job than Machine 0 — a flag worth investigating.

---

## 💼 Business Impact

This query gives the floor manager a machine performance dashboard they can run at any point during the shift. Instead of waiting for end-of-day spreadsheet reconciliation, they can identify a slow machine mid-shift and intervene before it delays downstream production.

---

## ⚠️ Common Trap

Wrapping only the `SUM()` in `ROUND()` instead of the entire division expression:

```sql
-- WRONG
ROUND(SUM(...)) / COUNT(DISTINCT process_id)

-- CORRECT
ROUND(SUM(...) / COUNT(DISTINCT process_id), 3)
```

The first rounds before dividing — you lose precision in the final answer.

---

## 🛠️ MySQL Workbench Setup

```sql
CREATE DATABASE IF NOT EXISTS case10_avg_cycle_time;
USE case10_avg_cycle_time;

CREATE TABLE Activity (
    machine_id INT,
    process_id INT,
    activity_type ENUM('start', 'end'),
    timestamp FLOAT
);

INSERT INTO Activity VALUES
(0, 0, 'start', 0.712),
(0, 0, 'end', 1.520),
(0, 1, 'start', 3.140),
(0, 1, 'end', 4.120),
(1, 0, 'start', 0.550),
(1, 0, 'end', 1.550),
(1, 1, 'start', 0.430),
(1, 1, 'end', 1.420),
(2, 0, 'start', 4.100),
(2, 0, 'end', 4.512),
(2, 1, 'start', 2.500),
(2, 1, 'end', 5.000);
```

---



*Part of the SQL for Business series — reframing LeetCode problems as real business scenarios.*
