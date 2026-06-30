# Case 14 — OTP Confirmation Rate
### `Case14-OTP-Confirmation-Rate/README.md`

---

## Business Scenario

A fintech app uses one-time passwords (OTPs) as a second authentication factor — every login, every high-value transaction, every sensitive account change triggers an SMS or push-based OTP. The user has a short window to enter the code. If they confirm it in time, the action proceeds. If they don't, the attempt times out.

Over time, this generates a pattern per user: some users confirm almost every OTP without issue, some have a string of timeouts, and some — new signups especially — may never have triggered a single OTP yet.

The fraud and risk team wants a per-user confirmation rate report. A user who consistently fails to confirm OTPs is a signal worth investigating — it could mean a wrong or outdated phone number on file, a UX problem with how the code is delivered, or in rarer cases, account takeover attempts where the real owner isn't the one receiving the codes. This report becomes a standing input into that risk model, not a one-off check.

---

## Table Structure

**`Users`**

| Column | Type | Notes |
|---|---|---|
| user_id | INT | Primary key |
| signup_date | DATETIME | When the account was created |

**`OTPVerifications`**

| Column | Type | Notes |
|---|---|---|
| user_id | INT | Foreign key to `Users` |
| attempt_timestamp | DATETIME | When the OTP was triggered |
| status | ENUM('confirmed', 'timeout') | Outcome of that specific attempt |

`Users` is the anchor table — every registered account belongs here regardless of OTP activity. `OTPVerifications` logs one row per attempt, so a single user can appear many times, once per code sent to them.

---

## Sample Data

| user_id | name (for reference) | OTP attempts |
|---|---|---|
| 201 | Alex | 2 timeouts |
| 202 | Priya | 3 confirmed |
| 203 | Marcus | 1 confirmed, 1 timeout |
| 204 | Diane | none — never triggered |

---


## Mysql workbench setup

-- Case 14: OTP Confirmation Rate (Fintech 2FA) — Workbench Setup

CREATE TABLE Users (
    user_id INT PRIMARY KEY,
    signup_date DATETIME
);

CREATE TABLE OTPVerifications (
    user_id INT,
    attempt_timestamp DATETIME,
    status ENUM('confirmed', 'timeout'),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

INSERT INTO Users (user_id, signup_date) VALUES
(201, '2024-01-05 09:12:00'),  -- Alex
(202, '2024-02-11 14:30:00'),  -- Priya
(203, '2024-03-02 18:45:00'),  -- Marcus
(204, '2024-04-19 08:00:00');  -- Diane (never triggers an OTP)

INSERT INTO OTPVerifications (user_id, attempt_timestamp, status) VALUES
(201, '2024-05-01 09:00:00', 'timeout'),
(201, '2024-05-03 10:15:00', 'timeout'),
(202, '2024-05-02 11:00:00', 'confirmed'),
(202, '2024-05-04 12:30:00', 'confirmed'),
(202, '2024-05-06 09:45:00', 'confirmed'),
(203, '2024-05-05 16:00:00', 'confirmed'),
(203, '2024-05-07 17:20:00', 'timeout');

## Solution Query

```sql
SELECT 
    u.user_id,
    ROUND(
        IFNULL(
            SUM(CASE WHEN o.status = 'confirmed' THEN 1 ELSE 0 END) / NULLIF(COUNT(o.status), 0),
            0
        ),
    2) AS confirmation_rate
FROM Users u
LEFT JOIN OTPVerifications o ON u.user_id = o.user_id
GROUP BY u.user_id;
```

**Expected Output**

| user_id | confirmation_rate |
|---|---|
| 201 | 0.00 |
| 202 | 1.00 |
| 203 | 0.50 |
| 204 | 0.00 |

---

## Query Walkthrough

**`LEFT JOIN OTPVerifications o ON u.user_id = o.user_id`** — `Users` is the left table, so every registered user survives the join even with zero matching OTP rows. Diane (204) gets a row of all-NULL columns from `OTPVerifications`, but she still appears in the result. An `INNER JOIN` here would silently drop her — exactly the kind of report that goes uncaught until someone asks "why isn't this new signup showing up anywhere?"

**`SUM(CASE WHEN o.status = 'confirmed' THEN 1 ELSE 0 END)`** — `SUM()` can't add up text values directly. The `CASE WHEN` converts each row into a 1 (confirmed) or 0 (anything else, including timeout), and `SUM()` adds those flags up to get a confirmed-count per user.

**`COUNT(o.status)`** — counts non-NULL `status` values per user. For a user with real attempts, this is their total OTP count. For Diane, every `o.status` value from the join is `NULL`, and `COUNT()` ignores NULLs — so her count comes out to exactly `0`, without needing a separate `CASE` for it.

**`NULLIF(COUNT(o.status), 0)`** — this is the divide-by-zero guard. If the count is `0`, `NULLIF` swaps it for `NULL` before the division happens. Dividing anything by `NULL` returns `NULL` (not an error, not a crash) — so Diane's intermediate rate becomes `NULL` instead of triggering a divide-by-zero failure.

**`IFNULL(..., 0)`** — catches that `NULL` and converts it to `0`, which is what the business actually wants displayed for a user with no OTP history — not a blank, not an error, just `0.00`.

**`GROUP BY u.user_id`** — grouping on the left table's key is deliberate. `o.user_id` would be `NULL` for unmatched users like Diane, which risks inconsistent grouping behavior. Grouping on `u.user_id` guarantees one clean row per registered user, full stop.

---

## Why This Approach

`LEFT JOIN` + conditional aggregation is the standard pattern any time you need a metric "per entity" that must include entities with zero qualifying activity. It keeps the entire user base in the report by construction, rather than relying on a second query or `UNION` to patch in the missing users afterward.

---

## Alternate Approach

A subquery-per-user using correlated `SELECT` statements (one for confirmed count, one for total count) would produce the same numbers, but it executes once per user instead of once per joined row — far slower at scale and harder to read. The `LEFT JOIN` + `GROUP BY` version does it in a single pass.

---

## Performance Note

This scales fine as long as `OTPVerifications.user_id` is indexed (it should be, as a foreign key) — the join and grouping both lean on that index. Where it would start to strain: if OTP volume grows into the tens of millions of rows and this report needs to run live on every dashboard refresh, you'd want to pre-aggregate confirmation counts into a rollup table updated on a schedule, rather than recomputing the full join every time someone loads the risk dashboard.

---

## Business Impact

This single query gives the risk team a ranked list of users by OTP reliability without manual cross-referencing. A user sitting at `0.00` or `0.20` over a meaningful number of attempts becomes a flagged case — worth a support outreach to check their phone number, or in higher-risk scenarios, a closer look at the account itself. It also catches Diane-type users: signed up but never engaged with 2FA at all, which is its own kind of risk signal (dormant or possibly fake accounts).

---

## Common Trap

The instinct is to write `o.status` inside a plain `COUNT()` and assume it's safe — it is, but only because `COUNT()` specifically ignores NULLs. If you'd used `COUNT(*)` instead, it would count the single all-NULL row produced by the LEFT JOIN for unmatched users, incorrectly returning `1` instead of `0` for Diane's denominator. Always use `COUNT(column)`, not `COUNT(*)`, when you're depending on NULL-skipping behavior from a LEFT JOIN.

---

Ready for the LinkedIn post whenever you want it — separately, as usual.
