# Case 12 — Training Completion Tracker
### SQL for Business: Applied Query Portfolio

---

## 📌 Business Scenario

A corporate L&D (Learning & Development) team runs mandatory training modules for all employees every quarter. There are 3 modules: Compliance, Data Privacy, and Leadership Essentials.

Every employee is expected to complete every module. But the completion data only records the sessions that actually happened — if an employee skipped a module, there's simply no row for that combination.

At the end of the quarter, the L&D manager needs a full completion report — every employee against every module, with a count of how many times they attended (repetitions are allowed and tracked). Missing combinations must show 0, not be absent from the report.

This matters for compliance — regulators require proof that every employee was trained on every mandatory module. A missing row isn't the same as a 0, and reporting software that can't distinguish the two creates audit risk.

---

## 🗂️ Table Structure

**Table: `employees`**
All employees in the company.

| employee_id | employee_name |
|-------------|---------------|
| 1 | Alice Fernandez |
| 2 | Bob Mendes |
| 3 | Clara Osei |

**Table: `training_modules`**
All mandatory training modules.

| module_name |
|-------------|
| Compliance |
| Data Privacy |
| Leadership Essentials |

**Table: `training_completions`**
A log of every training session attended. One row per attendance event.

| employee_id | module_name |
|-------------|-------------|
| 1 | Compliance |
| 1 | Compliance |
| 1 | Data Privacy |
| 2 | Leadership Essentials |

---

## ❓ The Business Question

> For every employee-module combination, how many times did the employee attend that module this quarter?

All combinations must appear — including zeros for modules never attended.

---

## 🔍 Query Logic — Before & After

**The problem:** `training_completions` only has rows for sessions that happened. Bob never attended Compliance or Data Privacy — those rows don't exist anywhere. You can't get a 0 count for something that isn't in the table.

**The approach:** 
1. CROSS JOIN `employees` × `training_modules` to generate every possible combination (3 employees × 3 modules = 9 rows)
2. LEFT JOIN that result with `training_completions` to bring in attendance counts where they exist
3. COUNT the matches — unmatched combinations naturally return 0 via COALESCE or COUNT behavior with NULLs

**Before (simple GROUP BY on completions — broken):**

Only attended combinations appear. Bob and Clara's zero rows are missing entirely. Compliance audit fails.

**After (CROSS JOIN + LEFT JOIN — correct):**

| employee_id | employee_name | module_name | attended_count |
|-------------|---------------|-------------|----------------|
| 1 | Alice Fernandez | Compliance | 2 |
| 1 | Alice Fernandez | Data Privacy | 1 |
| 1 | Alice Fernandez | Leadership Essentials | 0 |
| 2 | Bob Mendes | Compliance | 0 |
| 2 | Bob Mendes | Data Privacy | 0 |
| 2 | Bob Mendes | Leadership Essentials | 1 |
| 3 | Clara Osei | Compliance | 0 |
| 3 | Clara Osei | Data Privacy | 0 |
| 3 | Clara Osei | Leadership Essentials | 0 |

Every combination present. Zeros explicitly shown. Audit-ready.

---

## ✅ SQL Solution

```sql
SELECT 
    e.employee_id,
    e.employee_name,
    m.module_name,
    COUNT(tc.module_name) AS attended_count
FROM employees e
CROSS JOIN training_modules m
LEFT JOIN training_completions tc 
    ON e.employee_id = tc.employee_id 
    AND m.module_name = tc.module_name
GROUP BY e.employee_id, e.employee_name, m.module_name
ORDER BY e.employee_id, m.module_name;
```

**Why this approach:**
CROSS JOIN is the only way to generate combinations that don't exist in any single table. LEFT JOIN then preserves all of them, and COUNT naturally returns 0 for unmatched rows.

**Alternate approach:**
Subquery that generates combinations, then a correlated COUNT for each. Functionally identical but significantly slower — one subquery execution per row vs. one pass with JOIN.

**Performance note:**
CROSS JOIN is only safe when both input tables are small (employees and module lists typically are). If either table grows to thousands of rows, the cartesian product explodes — rethink the approach at that scale.

---

## 💼 Business Impact

This query turns an incomplete attendance log into a compliance-ready report. The L&D team can export this directly into their regulatory filing. Zero rows are as important as non-zero ones — they identify exactly who needs follow-up training before the quarter closes.

---

## ⚠️ Common Trap

Joining `training_completions` directly to `employees` without the CROSS JOIN step first. This only surfaces combinations that exist in the completions table — missing combinations never appear, zeros are never generated, and the report looks complete when it isn't.

---

## 🛠️ MySQL Workbench Setup

```sql
CREATE DATABASE IF NOT EXISTS case12_training_completion_tracker;
USE case12_training_completion_tracker;

CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(100)
);

CREATE TABLE training_modules (
    module_name VARCHAR(100) PRIMARY KEY
);

CREATE TABLE training_completions (
    employee_id INT,
    module_name VARCHAR(100)
);

INSERT INTO employees VALUES
(1, 'Alice Fernandez'),
(2, 'Bob Mendes'),
(3, 'Clara Osei');

INSERT INTO training_modules VALUES
('Compliance'),
('Data Privacy'),
('Leadership Essentials');

INSERT INTO training_completions VALUES
(1, 'Compliance'),
(1, 'Compliance'),
(1, 'Data Privacy'),
(2, 'Leadership Essentials');
```

---


## 🔗 Related

- **LeetCode:** [1280 — Students and Examinations](https://leetcode.com/problems/students-and-examinations/)
- **Portfolio:** [SQL for Business — Applied Query Portfolio](https://github.com/ParthGaderwar/SQL-for-Business-Applied-Query-Portfolio)

---

*Part of the SQL for Business series — reframing LeetCode problems as real business scenarios.*
