# Case 13 — Span of Control Violation
### SQL for Business: Applied Query Portfolio

---

## 📌 Business Scenario

A VP of Sales at a mid-sized retail company has a standing policy: no regional sales manager should directly manage more than 4 sales reps. Beyond that, communication breaks down, coaching quality drops, and reps don't get enough face time with their manager.

HR flagged that the policy hasn't been audited in over a year. Headcount grew fast, new reps were assigned to existing managers without a structural review, and nobody checked if the cap was being breached.

The VP needs one thing: a list of every manager currently violating the 4-rep cap — meaning they have 5 or more direct reports right now.

This query runs before the next org review meeting. Anyone on the output list is a candidate for having a Team Lead inserted beneath them.

---

## 🗂️ Table Structure

**Table: `Employee`**
One table containing every employee — both reps and managers. The `managerId` column points back to the `id` of whoever that employee reports to.

| id | name | department | managerId |
|----|------|------------|-----------|
| 101 | Sarah Mitchell | Sales | NULL |
| 102 | James Okafor | Sales | 101 |
| 103 | Priya Nair | Sales | 101 |
| 104 | Dan Reyes | Sales | 101 |
| 105 | Amy Chen | Sales | 101 |
| 106 | Ron Patel | Sales | 101 |

`managerId` is NULL for top-level employees (no manager above them).

---

## ❓ The Business Question

> Which sales managers currently have 5 or more direct reports — violating the span-of-control policy?

Return their names so the VP can review and act before the next org meeting.

---

## 🔍 Query Logic — Before & After

**The problem:** Manager names and employee-manager relationships live in the same table. `managerId` is just another `id` — to get the manager's name, you need to look it up in the same table using a self-join.

**The approach:**
1. Use `e1` as the employee copy — group by `managerId` and count how many employees share the same manager
2. Use `e2` as the manager copy — join on `e1.managerId = e2.id` to pull the manager's name
3. HAVING filters to only managers with 5 or more reports

**Before (no join — broken):**

Grouping and counting works, but you're left with manager IDs, not names. Unusable for an HR report.

**After (self-join — correct):**

| name |
|------|
| Sarah Mitchell |

Sarah has 5 direct reports — she's the only one breaching the policy. Her name surfaces cleanly.

---

## ✅ SQL Solution

```sql
SELECT e2.name
FROM Employee e1
JOIN Employee e2 ON e1.managerId = e2.id
GROUP BY e2.id
HAVING COUNT(*) >= 5;
```

**Why this approach:**
Self-join is the cleanest way to resolve a foreign key that references the same table. One join, one aggregation, one filter — no subquery needed.

**Alternate approach:**
Subquery that first counts reports per managerId, then joins back to get names. Works but adds an extra layer of nesting for no performance benefit at this scale.

**Performance note:**
Self-joins on a single indexed `id` column are efficient. As the Employee table grows to tens of thousands of rows (large enterprises), adding an index on `managerId` significantly speeds up the grouping step.

---

## 💼 Business Impact

This query gives the VP of Sales an actionable list before the org review — not a feeling that "some managers might be overloaded." Every name on the output is a concrete agenda item: discuss, decide, restructure. The difference between a data-driven org review and a gut-feel one starts here.

---

## ⚠️ Common Trap

Joining on `e1.managerId = e2.managerId` instead of `e1.managerId = e2.id`. Both columns exist, the query runs without error, but the output is wrong — you're matching managers to other employees who share the same manager, not to the manager themselves.

---

## 🛠️ MySQL Workbench Setup

```sql
CREATE DATABASE IF NOT EXISTS case13_span_of_control;
USE case13_span_of_control;

CREATE TABLE Employee (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    department VARCHAR(50),
    managerId INT
);

INSERT INTO Employee VALUES
(101, 'Sarah Mitchell', 'Sales', NULL),
(102, 'James Okafor', 'Sales', 101),
(103, 'Priya Nair', 'Sales', 101),
(104, 'Dan Reyes', 'Sales', 101),
(105, 'Amy Chen', 'Sales', 101),
(106, 'Ron Patel', 'Sales', 101);
```

---


## 🔗 Related

- **LeetCode:** [570 — Managers with at Least 5 Direct Reports](https://leetcode.com/problems/managers-with-at-least-5-direct-reports/)
- **Portfolio:** [SQL for Business — Applied Query Portfolio](https://github.com/ParthGaderwar/SQL-for-Business-Applied-Query-Portfolio)

---

*Part of the SQL for Business series — reframing LeetCode problems as real business scenarios.*
