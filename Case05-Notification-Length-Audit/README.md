

# Case 05 — Characters exceeding the limit

**Platform:** LeetCode #1683  
**Difficulty:** Easy  
**SQL Concept:** String length filtering with CHAR_LENGTH()  
**Business Framing:** Pre-send push notification quality control  

---

## Business Scenario

### How push notification campaigns work

When a company wants to reach thousands (or millions) of app users at once, they run a **push notification campaign**. The marketing team writes the message, defines the target audience, and schedules the send time. Before the campaign goes live, that content gets stored in a database — one row per notification, waiting to be sent.

Here's a simplified version of what that pipeline looks like:

```
Marketing team writes notifications
        ↓
Content stored in database (Tweets/Notifications table)
        ↓
QC query runs — flags anything that violates rules
        ↓
Flagged notifications sent back to content team for editing
        ↓
Clean notifications sent to users
```

The QC step is where this query lives.

---

### Why character length matters

Mobile operating systems — Android and iOS — have display limits for push notifications. If a notification exceeds that limit, one of two things happens:

- The message gets **truncated** — the user sees "Don't miss our biggest flash sa..." and the rest is cut off
- The notification gets **silently dropped** — it never reaches the user at all

Both outcomes hurt the campaign. A truncated message loses its call to action. A dropped message means zero chance of the user clicking through.

**Example — what the user actually sees:**

| What was written | What the user sees on their phone |
|-----------------|----------------------------------|
| `Sale starts now!` | `Sale starts now!` ✅ Fully visible |
| `Don't miss our biggest flash sale of the year!` | `Don't miss our bigge...` ❌ Truncated |
| `Click here to claim your exclusive limited-time discount offer now` | *(notification dropped)* ❌ Never shown |

The first one fits. The other two don't — and a user who sees a cut-off message or nothing at all is a missed opportunity.

---

### The real cost

Imagine a campaign with 50,000 notifications queued. If 30% of them are too long:

- 15,000 notifications either get truncated or dropped
- Click-through rate drops significantly
- The marketing team doesn't know why the campaign underperformed
- The same mistake happens next campaign

One QC query before the send catches all of this.

---

## Table Structure

| Column | Type | Notes |
|--------|------|-------|
| tweet_id | INT | Primary key — unique per notification |
| content | VARCHAR | The notification message text |

---

## Sample Data

| tweet_id | content | CHAR_LENGTH | Status |
|----------|---------|-------------|--------|
| 1 | Sale starts now! | 16 | ❌ Too long |
| 2 | Hi | 2 | ✅ Valid |
| 3 | Don't miss our biggest flash sale of the year! | 47 | ❌ Too long |
| 4 | 50% off today | 14 | ✅ Valid |
| 5 | Click here to claim your exclusive limited-time discount offer now | 65 | ❌ Too long |

> The Status and CHAR_LENGTH columns are shown here for clarity — they are not in the actual table. The query calculates length on the fly.

---

## Query

```sql
SELECT tweet_id
FROM Tweets
WHERE CHAR_LENGTH(content) > 15;
```

**Output for the sample data above:**

| tweet_id |
|----------|
| 1 |
| 3 |
| 5 |

These three get flagged and sent back to the content team for editing before the campaign goes out.

---

## LENGTH() vs CHAR_LENGTH() — Why It Matters

Both functions measure string length, but they count differently:

| Function | What it counts | Safe for emojis/accents? |
|----------|---------------|--------------------------|
| `LENGTH()` | Bytes | ❌ No |
| `CHAR_LENGTH()` | Characters | ✅ Yes |

**Example:**

The emoji 🔥 is a single character but takes up 4 bytes in UTF-8 encoding.

```sql
SELECT LENGTH('🔥');        -- returns 4 (bytes)
SELECT CHAR_LENGTH('🔥');   -- returns 1 (character)
```

If a notification content were `"Sale🔥"` (5 characters), `LENGTH()` would return 8 — incorrectly flagging it as longer than it is. `CHAR_LENGTH()` returns 5 — correct.

In this specific LeetCode problem, content is restricted to alphanumeric characters and spaces, so both functions produce the same result. But in a real push notification system where marketers routinely use emojis, `CHAR_LENGTH()` is the only safe choice.

---

## Alternate Approach

```sql
SELECT tweet_id
FROM Tweets
WHERE LENGTH(content) > 15;
```

Works on this dataset but is not recommended for production. If content ever includes multibyte characters, `LENGTH()` returns byte count instead of character count — producing wrong results without any error or warning.

---

## Performance Note

`CHAR_LENGTH()` requires a full table scan — there is no index that can pre-filter on a computed string length. For a pre-send audit on a bounded campaign table (hundreds or thousands of rows), this is completely fine. If this check needed to run continuously against a high-volume stream of incoming notifications, the better approach would be to enforce the length limit at the application layer before data is ever written to the database.

---

## 💡 Business Impact

This query gives the content team an exact list of notification IDs to fix — before a single message reaches a user. It prevents truncated messages, protects click-through rates, and removes a silent failure point from the campaign pipeline.
```
