# Case 04 — The View count cheat

**Platform:** LeetCode #1148

**Difficulty:** Easy

**SQL Concept:** Self-referencing filter, DISTINCT deduplication, column aliasing

**Business Framing:** Content platform editorial analytics

---

## Business Scenario

A digital media company runs an article publishing platform where writers publish content and readers consume it. The editorial team wants to identify **authors who have read their own published articles** — a behavior that signals active self-review, quality checking, or potentially inflated view counts on their own content.

This list feeds directly into a content integrity report: authors who consistently self-read may be skewing engagement metrics, or alternately, may be the most quality-conscious writers on the platform.

The data team is asked: *"Give us a clean, deduplicated list of author IDs who have viewed at least one of their own articles."*

---

| article_id | author_id | viewer_id | view_date  | Notes                              |
|------------|-----------|-----------|------------|------------------------------------|
| 1          | 3         | 5         | 2019-08-01 |                                    |
| 1          | 3         | 6         | 2019-08-02 |                                    |
| 2          | 7         | 7         | 2019-08-01 | author 7 viewed their own article  |
| 2          | 7         | 7         | 2019-08-02 | same author, different date        |
| 4          | 7         | 1         | 2019-07-22 |                                    |
| 3          | 4         | 4         | 2019-07-21 | author 4 viewed their own article  |
| 3          | 4         | 4         | 2019-07-21 | exact duplicate row                |

> **Test design note:** Author 7 appears twice as a self-viewer across different dates. Author 4 has an exact duplicate row. Both cases confirm that `DISTINCT` is doing real work here — not just theoretical cleanup.

---

## The Query

```sql
SELECT DISTINCT author_id AS id
FROM Views
WHERE author_id = viewer_id  -- same person on both sides of the row
ORDER BY id ASC;
```

---

## Approach

The logic lives entirely within a single row. No joins, no subqueries needed — each row already contains both the author and the viewer. The filter `author_id = viewer_id` catches every self-view instance.

`DISTINCT` then collapses multiple self-view events (different dates, duplicate rows) into one entry per author. Without it, Author 7 would appear twice and Author 4 would appear twice — technically correct rows, wrong answer.

`AS id` is required because the output spec asks for a column named `id`, not `author_id`.

---

## What I Almost Did

Reached for a subquery — something like selecting `author_id` from a grouped result. Unnecessary. The self-reference check is row-level, not aggregate-level. Simple filter + DISTINCT is the complete solution.

---

## Alternate Approach

```sql
SELECT author_id AS id
FROM Views
WHERE author_id = viewer_id
GROUP BY author_id
ORDER BY author_id ASC;
```

`GROUP BY` achieves the same deduplication as `DISTINCT` here. Chose `DISTINCT` because the intent is purely deduplication — no aggregation is happening, and `DISTINCT` communicates that more clearly than a `GROUP BY` with no aggregate function.

---

## Performance Note

On a large Views table (millions of rows), an index on `author_id` and `viewer_id` would allow the filter to run without a full table scan. `DISTINCT` adds a sort/dedup step, but since the filtered result set (only self-views) is typically small relative to total views, this remains efficient in practice.

---

## What This Unlocks

This query is the first step in a content integrity audit. The resulting author list can be cross-referenced against engagement dashboards to determine whether self-views are meaningfully inflating article performance metrics — a real concern for platforms that use view counts to rank or compensate writers.

