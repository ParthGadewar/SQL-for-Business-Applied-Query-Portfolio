# Case 05 — Notification Length Audit

**Platform:** LeetCode #1683  
**Difficulty:** Easy  
**SQL Concept:** String length filtering with CHAR_LENGTH()  
**Business Framing:** Pre-send push notification quality control  

---

## Business Scenario

A marketing team is preparing a bulk push notification campaign — messages sent simultaneously to thousands of app users. Before the campaign goes live, the data team runs a QC (quality control) check on all queued notifications.

The rule is simple: any notification with content exceeding 15 characters risks being truncated or dropped by certain mobile operating systems before it even reaches the user. Truncated notifications kill click rates and make the campaign look broken.

The ask: *"Flag every notification ID where the content is too long so the content team can shorten it before send."*

---

## Table Structure

| Column | Type | Notes |
|--------|------|-------|
| tweet_id | INT | Primary key — unique per notification |
| content | VARCHAR | The notification message text |

---

## Sample Data

| tweet_id | content |
|----------|---------|
| 1 | Sale starts now! |
| 2 | Hi |
| 3 | Don't miss our biggest flash sale of the year! |
| 4 | 50% off today |
| 5 | Click here to claim your exclusive limited-time discount offer now |

---

## Query

```sql
SELECT tweet_id
FROM Tweets
WHERE CHAR_LENGTH(content) > 15;
```

---

## Why This Approach

`CHAR_LENGTH()` counts actual characters — not bytes. `LENGTH()` would work here since the content is alphanumeric, but `CHAR_LENGTH()` is the safer professional default. If content ever includes multibyte characters (accented letters, symbols, emojis), `LENGTH()` would return incorrect counts. `CHAR_LENGTH()` handles all of them correctly.

---

## Alternate Approach

`LENGTH(content) > 15` works on this dataset since content is restricted to alphanumeric characters and spaces. Chosen `CHAR_LENGTH()` over it because it's more robust in real-world scenarios where character encoding varies.

---

## Performance Note

`CHAR_LENGTH()` runs a full table scan with no index support — fine for a pre-send audit on a bounded campaign table. Would need optimization (indexed computed column or application-level validation) if running continuously against a high-volume notifications stream.

---

## 💡 Business Impact

This query gives the content team an exact list of notifications to fix before the campaign sends — preventing truncated messages, protecting click-through rates, and avoiding a broken experience for users.
