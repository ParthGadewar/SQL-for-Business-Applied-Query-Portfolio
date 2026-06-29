# Case 11 — Payroll Blind Spot
### SQL for Business: Applied Query Portfolio

---

## 📌 Business Scenario

It's year-end at a mid-sized tech company. The HR team is running their annual bonus audit before payroll closes.

They have two tables: one listing all active employees, and one recording bonus amounts paid out this cycle. The problem — not every employee has a bonus record. Some are new hires not yet enrolled in the bonus program. Others simply weren't added to the payout table due to a data entry gap.

The payroll team needs to flag two groups before the books close:
1. Employees whose bonus was recorded but falls **below ₹5,000** — potentially an error or underpayment
2. Employees with **no bonus record at all** — possibly missed entirely

This query is run before final payroll approval so the HR lead can review exceptions and either confirm or correct them.

---

## 🗂️ Table Structure

**Table: `employees`**
Every active employee in the company.

| emp_id | emp_name |
|--------|----------|
| 1 | Rohan Sharma |
| 2 | Priya Mehta |
| 3 | Arjun Singh |
| 4 | Neha Kapoor |
| 5 | Vikram Nair |

**Table: `bonus_payroll`**
Bonus amounts recorded for this cycle. Not every employee has a row here.

| emp_id | bonus |
|--------|-------|
| 2 | 500 |
| 3 | 2000 |
| 4 | 7000 |

---

## ❓ The Business Question

> Which employees either received a bonus under ₹5,000 or have no bonus record at all?

These are the exceptions the HR lead needs to manually review before payroll is finalized.

---

## 🔍 Query Logic — Before & After

**The problem:** Some employees don't exist in `bonus_payroll` at all. An INNER JOIN would silently drop them — Rohan and Vikram would never appear in the output, and the audit would be incomplete.

**The approach:** LEFT JOIN keeps all employees from the base table, bringing in bonus amounts where they exist and returning NULL where they don't. The WHERE clause then catches both cases: bonus below threshold OR no record (NULL).

**Before (INNER JOIN — broken):**

| emp_id | emp_name | bonus |
|--------|----------|-------|
| 2 | Priya Mehta | 500 |
| 3 | Arjun Singh | 2000 |
| 4 | Neha Kapoor | 7000 |

Rohan and Vikram are silently dropped. Audit is incomplete.

**After (LEFT JOIN — correct):**

| emp_id | emp_name | bonus |
|--------|----------|-------|
| 2 | Priya Mehta | 500 |
| 3 | Arjun Singh | 2000 |
| 1 | Rohan Sharma | NULL |
| 5 | Vikram Nair | NULL |

All exceptions surfaced. Neha's ₹7,000 correctly excluded.

---

## ✅ SQL Solution

```sql
SELECT 
    e.emp_id,
    e.emp_name,
    b.bonus
FROM employees e
LEFT JOIN bonus_payroll b ON e.emp_id = b.emp_id
WHERE b.bonus < 5000 OR b.bonus IS NULL;
```

**Why this approach:**
LEFT JOIN is the only join type that preserves all employees regardless of whether a bonus record exists. The OR condition catches both underpayments and missing records in a single pass.

**Alternate approach:**
Subquery using `NOT IN` to find employees absent from `bonus_payroll`, unioned with a filtered join for low bonuses. Works, but requires two scans and is significantly harder to read and maintain.

**Performance note:**
LEFT JOIN with an indexed `emp_id` on both tables is efficient. The `NOT IN` alternate degrades on large datasets and can behave unexpectedly if NULLs exist in the subquery result.

---

## 💼 Business Impact

This query is the last checkpoint before payroll closes. Running it catches two failure modes — underpayments and missing records — before money moves. The cost of catching this in a query is zero. The cost of correcting it after payroll runs is significant, both financially and in employee trust.

---

## ⚠️ Common Trap

Using AND instead of OR in the WHERE clause:

```sql
-- WRONG: logically impossible
WHERE b.bonus < 5000 AND b.bonus IS NULL

-- CORRECT: catches both cases
WHERE b.bonus < 5000 OR b.bonus IS NULL
```

A value cannot simultaneously be less than 5000 AND NULL. The AND version returns zero rows every time.

---

## 🛠️ MySQL Workbench Setup

```sql
CREATE DATABASE IF NOT EXISTS case11_payroll_blind_spot;
USE case11_payroll_blind_spot;

CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(100)
);

CREATE TABLE bonus_payroll (
    emp_id INT,
    bonus INT
);

INSERT INTO employees VALUES
(1, 'Rohan Sharma'),
(2, 'Priya Mehta'),
(3, 'Arjun Singh'),
(4, 'Neha Kapoor'),
(5, 'Vikram Nair');

INSERT INTO bonus_payroll VALUES
(2, 500),
(3, 2000),
(4, 7000);
```

---


## 🔗 Related

- **LeetCode:** [577 — Employee Bonus](https://leetcode.com/problems/employee-bonus/)
- **Portfolio:** [SQL for Business — Applied Query Portfolio](https://github.com/ParthGaderwar/SQL-for-Business-Applied-Query-Portfolio)

---

*Part of the SQL for Business series — reframing LeetCode problems as real business scenarios.*
