# Case 06 — Acquisition ID Mapping

**Platform:** LeetCode #1378
**Difficulty:** Easy
**SQL Concept:** LEFT JOIN across two tables
**Business Framing:** Post-acquisition employee identity system migration

---

## Business Scenario

### What happened

A mid-sized tech company acquired a smaller firm and absorbed all their employees into the main HR system. As part of the integration, the acquiring company began rolling out **Unique IDs** — identifiers used across their internal tools, access control systems, and payroll platform.

But the rollout is not instant. Migrating identities takes time — accounts need to be verified, old records need to be mapped, and some employees may be on leave or have incomplete records. On any given day during the migration, only a portion of employees will have a Unique ID assigned.

HR needs a report that shows **every employee** — with their Unique ID if it exists, and `NULL` if the migration is still pending for them.

---

### Why this is a LEFT JOIN problem

There are two tables involved:

- `Employees` — the source of truth. Contains every employee, old and new.
- `EmployeeUNI` — partial. Only contains employees who have already been assigned a Unique ID.

If you use `INNER JOIN`, you only get rows that exist in **both** tables. Alice and Bob — who haven't been migrated yet — would disappear from the result entirely. HR would have no idea they exist, let alone that their migration is pending.

That's a data gap that could cause real problems: missed payroll setup, missing access permissions, or employees being left out of system communications.

`LEFT JOIN` fixes this. It keeps every row from the left table (`Employees`) and matches what it can from the right table (`EmployeeUNI`). Where there's no match, it fills `NULL` — which is exactly what the business needs to see.

---

### The consequence of getting this wrong

| Join Type | What happens to Alice & Bob |
|-----------|----------------------------|
| `INNER JOIN` | ❌ Dropped from results — HR doesn't know they exist |
| `LEFT JOIN` | ✅ Appear with `NULL` unique_id — flagged for follow-up |

The NULL rows are not errors. They are an **action list** — every NULL is an employee whose migration is incomplete and needs attention.

---

## Table Structure

**Employees**

| Column | Type | Notes |
|--------|------|-------|
| id | INT | Primary key |
| name | VARCHAR | Employee full name |

**EmployeeUNI**

| Column | Type | Notes |
|--------|------|-------|
| id | INT | References Employees.id |
| unique_id | INT | New system identifier |

---

## Sample Data

**Employees**

| id | name     |
|----|----------|
| 1  | Alice    |
| 7  | Bob      |
| 11 | Meir     |
| 90 | Winston  |
| 3  | Jonathan |

**EmployeeUNI**

| id | unique_id |
|----|-----------|
| 3  | 1         |
| 11 | 2         |
| 90 | 3         |

Alice (id: 1) and Bob (id: 7) have no entry in `EmployeeUNI` — their migration is pending.

---

## Query

```sql
SELECT b.unique_id, a.name
FROM Employees a
LEFT JOIN EmployeeUNI b ON a.id = b.id;
```

---

## Expected Output

| unique_id | name     |
|-----------|----------|
| NULL      | Alice    |
| NULL      | Bob      |
| 2         | Meir     |
| 3         | Winston  |
| 1         | Jonathan |

---

## Why LEFT JOIN and Not INNER JOIN

`INNER JOIN` only returns rows with a match in both tables. Any employee without a Unique ID gets silently dropped — which defeats the entire purpose of the report. `LEFT JOIN` guarantees every employee appears, with `NULL` signaling that their migration is incomplete.

**Key rule:** The table you cannot afford to lose rows from always goes on the left.

---

## Alternate Approach

`RIGHT JOIN` with the tables swapped (`FROM EmployeeUNI RIGHT JOIN Employees`) produces identical results but is harder to read and less intuitive. The convention is to lead with the source-of-truth table on the left.

---

## Performance Note

This join runs on `id`, which is the primary key in both tables — so it's indexed by default. The query will stay fast even as both tables grow. Performance would only degrade if joining on a non-indexed column in a large table.

---

## 💡 Business Impact

This pattern applies to any situation where two systems need to be reconciled — SSO migrations, badge rollouts, CRM integrations, or any onboarding process where coverage is partial. The NULL rows don't just answer the question "who has a Unique ID?" — they answer the more important question: **"who still needs one?"**
