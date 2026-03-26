# Policy Number Validation API – Technical Details Document

## 1. Overview

This API is designed to validate insurance policy numbers. Before checking policy validity, it verifies whether the background data batch process has completed successfully. If the data is not ready, the API returns a service unavailable response.

## 2. API Request

| Property | Value |
|----------|-------|
| **Method** | POST |
| **Endpoint** | `/api/v1/policy-validate` |

### Request Body

```json
{
  "policy_id": "POL_005"
}
```

## 3. Processing Logic & SQL

### Step 1: Check if Data is Ready for Processing

```sql
SELECT *
FROM batch_control
WHERE data_ready = 1;
```

**If record count = 0:**

```json
{
  "status": "failed",
  "message": "Service temporarily unavailable. Please try again later."
}
```

### Step 2: Validate Policy Number

```sql
SELECT *
FROM valid_policies
WHERE policy_id = 'POL_005';
```

**If record is found:**

```json
{
  "status": "success",
  "valid": 1
}
```

**If record is not found:**

```json
{
  "status": "success",
  "valid": 0
}
```
## 4. API Response Examples

### Success – Valid Policy

```json
{
  "status": "success",
  "valid": 1
}
```

### Success – Invalid Policy

```json
{
  "status": "success",
  "valid": 0
}
```

### Failure – Data Not Ready

```json
{
  "status": "failed",
  "message": "Service temporarily unavailable. Please try again later."
}
```

## 5. Key Notes

| Aspect | Details |
|--------|---------|
| **Database** | MySQL (WSO2 schema) |
| **Error Handling** | Handle DB connectivity failures, null records, and unexpected exceptions |
| **Batch Job Check** | Must precede policy number validation |
| **Audit Logging** | Log policy number received and timestamp of the request |
| **Security** | Validate and sanitize input to prevent SQL injection |

## 6. Test Cases

### Test Case 1 – Batch Not Ready

**Setup:**

```sql
SELECT *
FROM batch_control
WHERE data_ready = 1;
-- Expecting 0 rows
```

**Expected API Response:**

```json
{
  "status": "failed",
  "message": "Service temporarily unavailable. Please try again later."
}
```

### Test Case 2 – Valid Policy Number

**Setup:**

```sql
SELECT *
FROM batch_control
WHERE data_ready = 1;

SELECT *
FROM valid_policies
WHERE policy_id = 'POL_005';
```

**Expected API Response:**

```json
{
  "status": "success",
  "valid": 1
}
```

### Test Case 3 – Invalid Policy Number

**Setup:**

```sql
SELECT *
FROM batch_control
WHERE data_ready = 1;

SELECT *
FROM valid_policies
WHERE policy_id = 'POL_005';
```

**Expected API Response:**

```json
{
  "status": "success",
  "valid": 0
}
```


# Technical Specification: Policy Validation & Sync Management

This document defines the dual-API architecture designed to handle large-scale policy validation while maintaining data integrity through a synchronized "Gatekeeper" mechanism.

---

## 1. Database Schema Definition

To ensure high performance, we use a **Core Schema** for business logic and a **Mirror Schema** for API lookups.

### 1.1 Table: `batch_control`
Acts as the global status indicator for the synchronization process.

| Field | Type | Description |
| :--- | :--- | :--- |
| `job_id` | VARCHAR(10) (PK) | Unique ID for the batch task. |
| `job_name` | VARCHAR | Descriptive name (e.g., "Nightly_Policy_Sync"). |
| `data_ready` | TINYINT | **1**: Ready for API traffic; **0**: System Locked/Syncing. |

**Sample Data:**
| job_id | job_name | data_ready | updated_at |
| :--- | :--- | :--- | :--- |
| 1 | Daily_Sync | 1 | 2026-03-26 12:00:00 |

### 1.2 Table: `valid_policies`
An optimized table containing only data of policies with an **'Active'** status.

| Field | Type | Description |
| :--- | :--- | :--- |
| `policy_id` | VARCHAR (PK)| The unique Policy Number (mapped from Core `policy_id`). |
| `sync_at` | TIMESTAMP | Record insertion timestamp. |

---

## 2. API 1: Sync Controller (Internal Trigger)

This API manages the lifecycle of the data refresh.

* **Endpoint:** `POST /admin/v1/sync-trigger`
* **Method:** POST
* **Description:** Initiates the "Lock-Sync-Unlock" sequence to update the mirror table.

### Processing Logic:
1.  **Phase 1 (Lock):** Execute `UPDATE batch_control SET data_ready = 0 WHERE job_id = J_001`.
2.  **Phase 2 (Clear):** `TRUNCATE TABLE valid_policies`.
3.  **Phase 3 (Filter & Sync):**
    ```sql
    INSERT INTO valid_policies (policy_id)
    SELECT policy_id FROM policies WHERE status = 'Active';
    ```
4.  **Phase 4 (Safety Delay):** The API holds the `data_ready = 0` status for **5 minutes** to ensure database consistency.
5.  **Phase 5 (Unlock):** Execute `UPDATE batch_control SET data_ready = 1 WHERE job_id = 1`.

---

## 3. API 2: Policy Validator (Client Facing)

Provides the final validation result to the user.

* **Endpoint:** `/api/v1/policy-validate`
* **Method:** POST
* **Payload:** `{"policy_id": "POL_001"}`

### Processing Logic:
1.  **Gatekeeper Check:** The API queries `SELECT * FROM batch_control WHERE data_ready = 1`.
2.  **State A (Busy):** If 0 rows return, stop and return "Service unavailable".
3.  **State B (Ready):** If 1 row returns, query `valid_policies` for the provided `policyNo`.

---

## 4. Response Examples

### Scenario 1: Sync in Progress (The 5-Minute Window)
Occurs when `data_ready = 0`.
```json
{
  "status": "failed",
  "message": "Service temporarily unavailable. Please try again later."
}
```

### Scenario 2: Valid Active Policy
Occurs when `data_ready = 1` and ID is found in the mirror table.
```json
{
  "status": "success",
  "valid": 1
}
```

### Scenario 3: Invalid/Inactive Policy
Occurs when `data_ready = 1` but ID is **not** in the mirror table (because it was filtered out as 'Expired' or 'Cancelled').
```json
{
  "status": "success",
  "valid": 0
}
```

---

## 5. Sequence Flow

1.  **Admin** calls **Sync Controller API**.
2.  **Sync Controller** flips the switch to **Busy (0)**.
3.  **Policy Validator** starts rejecting all traffic with a **503-style message**.
4.  **Sync Controller** updates the mirror table with only **Active** policies.
5.  **Sync Controller** waits for **5 minutes**.
6.  **Sync Controller** flips the switch back to **Ready (1)**.
7.  **Policy Validator** resumes normal service and confirms policy validity.

