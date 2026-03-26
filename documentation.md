# Policy Number Validation System - Complete Guide

---

## Table of Contents
1. [Problem Statement](#problem-statement)
2. [Solution Overview](#solution-overview)
3. [How It Works](#how-it-works)
4. [System Architecture](#system-architecture)
5. [Database Schema](#database-schema)
6. [API Usage Guide](#api-usage-guide)
7. [Implementation Steps](#implementation-steps)
8. [Testing Guide](#testing-guide)
9. [FAQs](#faqs)

---

## Problem Statement

### The Challenge 🎯

Insurance companies need to validate policy numbers in real-time. However, there's a critical requirement: **policy data must be up-to-date before validation**.

**Specific Issues:**
- ❌ Users might submit policy numbers when the system is still loading fresh data
- ❌ Returning "policy not found" when data isn't loaded yet could mislead users
- ❌ The system must gracefully inform users to retry later if data isn't ready

### Why This Matters 💡

Without this protection:
- Users get false "invalid policy" messages during data refresh periods
- Support tickets increase due to confusion
- System reliability appears low
- Business loses customer trust

---

## Solution Overview

### The Answer ✅

We've implemented a **two-stage validation API** that ensures data freshness before policy validation:

1. **Stage 1: Data Readiness Check**
   - Verify that the batch job has completed and marked data as ready
   - If not ready, return a "Service Unavailable" message

2. **Stage 2: Policy Validation**
   - Only if Stage 1 passes, search for the policy number in the database
   - Return whether the policy exists or not

### Key Benefits 🌟

| Benefit | Why It Matters |
|---------|----------------|
| **Data Accuracy** | Policies are validated against fresh, complete data |
| **User Transparency** | Clear messages: "try later" vs "policy not found" |
| **System Reliability** | No false negatives during data refresh |
| **Better UX** | Users understand the difference between system issues and invalid policies |

---

## How It Works

### The Flow Diagram 📊

```
┌─────────────────────────────────────────────────────────┐
│  User submits Policy Number: "POL-2026-001234"          │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
        ┌────────────────────────────┐
        │ API Request Received       │
        │ POST /api/v1/policy-validate
        │ Body: { "policyNo": "..." }│
        └────────┬───────────────────┘
                 │
                 ▼
        ┌─────────────────────────────────────────┐
        │ STAGE 1: Check Data Readiness           │
        │ Query: Is PG_BATCHJOB.DATA_READY = 1?  │
        └─────────────────────────────────────────┘
                 │
         ┌───────┴──────────┐
         │                  │
    YES (Found)         NO (Not Found)
         │                  │
         ▼                  ▼
    ┌────────────────┐  ┌──────────────────────┐
    │ Continue to    │  │ Return Error:        │
    │ Stage 2        │  │ "Service Unavailable"│
    └────────┬───────┘  │ HTTP 503             │
             │          └──────────────────────┘
             │
             ▼
    ┌─────────────────────────────────────────┐
    │ STAGE 2: Validate Policy Number         │
    │ Query: Does policy exist in pda1mob?    │
    └─────────────────────────────────────────┘
             │
      ┌──────┴──────────┐
      │                 │
   FOUND           NOT FOUND
      │                 │
      ▼                 ▼
  ┌──────────────┐  ┌──────────────┐
  │ Return:      │  │ Return:      │
  │ valid: 1     │  │ valid: 0     │
  │ (Success)    │  │ (Success)    │
  └──────────────┘  └──────────────┘
```

### Step-by-Step Process 🔍

#### **Step 1: Data Readiness Check**

**What happens:**
- The API queries the `PG_BATCHJOB` table
- Looks for any record where `DATA_READY = 1`

**What it means:**
- `DATA_READY = 1` → Fresh data is loaded and ready ✅
- No records found → Data is still being processed ⏳

**Database Query:**
```sql
SELECT *
FROM WSO2.PG_BATCHJOB
WHERE DATA_READY = 1;
```

**Outcome:**
- **Found:** Proceed to Step 2
- **Not Found:** Send error response "Service Temporarily Unavailable"

---

#### **Step 2: Policy Validation**

**What happens:**
- The API searches for the submitted policy number in the `pda1mob` table
- Uses the `chdrnum` (policy number) field as the search key

**Database Query:**
```sql
SELECT *
FROM WSO2.pda1mob
WHERE chdrnum = ?;  -- Replace ? with submitted policy number
```

**Outcome:**
- **Record Found:** Policy is valid (return `valid: 1`) ✅
- **No Record:** Policy doesn't exist (return `valid: 0`) ❌

---

## System Architecture

### Overview 🏗️

```
┌───────────────────────────────────────────────────────────────┐
│                        Client Application                      │
│                  (Mobile App / Web Browser)                    │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ HTTP POST Request
                         │
                         ▼
        ┌────────────────────────────────────┐
        │  API Gateway / Load Balancer       │
        └────────────┬───────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────────────────┐
        │  Policy Validation API Service                 │
        │  (WSO2 Micro Integrator)                       │
        │  ┌──────────────────────────────────────────┐  │
        │  │ 1. Parse Request (Policy Number)         │  │
        │  │ 2. Check Data Readiness                  │  │
        │  │ 3. Validate Policy Number                │  │
        │  │ 4. Format & Return Response              │  │
        │  │ 5. Log Request & Timestamp               │  │
        │  └──────────────────────────────────────────┘  │
        └────────────────┬────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────────────────┐
        │  MySQL Database (WSO2 Schema)              │
        │  ┌──────────────────────────────────────┐  │
        │  │ Table: PG_BATCHJOB                   │  │
        │  │ Table: pda1mob                       │  │
        │  └──────────────────────────────────────┘  │
        └────────────────────────────────────────────┘
```

### Components 🔧

| Component | Purpose |
|-----------|---------|
| **API Endpoint** | Receives policy validation requests from clients |
| **Validation Logic** | Implements 2-stage validation process |
| **Database Connection** | Connects to MySQL WSO2 schema |
| **Error Handler** | Catches DB failures, null records, exceptions |
| **Audit Logger** | Logs all requests with timestamps for compliance |
| **Security Layer** | Sanitizes input to prevent SQL injection |

---

## Database Schema

### Table 1: PG_BATCHJOB

**Purpose:** Tracks data batch processing status

**Sample Schema:**
```sql
CREATE TABLE WSO2.PG_BATCHJOB (
    BATCH_ID INT PRIMARY KEY AUTO_INCREMENT,
    DATA_READY INT DEFAULT 0,
    BATCH_START_TIME TIMESTAMP,
    BATCH_END_TIME TIMESTAMP,
    STATUS VARCHAR(50),
    RECORD_COUNT INT,
    LAST_UPDATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Sample Data:**
| BATCH_ID | DATA_READY | BATCH_START_TIME | BATCH_END_TIME | STATUS | RECORD_COUNT | LAST_UPDATED |
|----------|-----------|------------------|----------------|--------|--------------|--------------|
| 1 | 1 | 2026-03-25 22:00:00 | 2026-03-25 22:15:00 | COMPLETED | 45000 | 2026-03-25 22:15:01 |
| 2 | 0 | 2026-03-26 22:00:00 | NULL | IN_PROGRESS | 12000 | 2026-03-26 22:05:00 |

**Key Column:**
- **DATA_READY**: Set to `1` when batch job completes successfully, `0` while processing

---

### Table 2: pda1mob

**Purpose:** Stores insurance policy details

**Sample Schema:**
```sql
CREATE TABLE WSO2.pda1mob (
    POLICY_ID INT PRIMARY KEY AUTO_INCREMENT,
    chdrnum VARCHAR(50) UNIQUE NOT NULL,
    POLICY_HOLDER_NAME VARCHAR(255),
    POLICY_TYPE VARCHAR(100),
    POLICY_STATUS VARCHAR(50),
    PREMIUM_AMOUNT DECIMAL(10, 2),
    START_DATE DATE,
    END_DATE DATE,
    CREATED_AT TIMESTAMP,
    UPDATED_AT TIMESTAMP
);
```

**Sample Data:**
| POLICY_ID | chdrnum | POLICY_HOLDER_NAME | POLICY_TYPE | POLICY_STATUS | PREMIUM_AMOUNT | START_DATE | END_DATE |
|-----------|---------|-------------------|-------------|---------------|----------------|------------|----------|
| 1001 | POL-2026-001234 | John Smith | Motor | ACTIVE | 12500.00 | 2026-01-15 | 2027-01-14 |
| 1002 | POL-2026-005678 | Sarah Johnson | Health | ACTIVE | 8500.00 | 2026-02-01 | 2027-01-31 |
| 1003 | POL-2026-009999 | Mike Davis | Home | EXPIRED | 15000.00 | 2025-03-20 | 2026-03-19 |

**Key Column:**
- **chdrnum**: The policy number to validate (unique identifier)

---

## API Usage Guide

### Making a Request 📤

#### **Endpoint Details**

| Property | Value |
|----------|-------|
| **URL** | `http://your-server/api/v1/policy-validate` |
| **Method** | POST |
| **Content-Type** | application/json |

#### **Request Format**

```json
{
  "policyNo": "POL-2026-001234"
}
```

#### **Example Using cURL**

```bash
curl -X POST http://localhost:8080/api/v1/policy-validate \
  -H "Content-Type: application/json" \
  -d '{"policyNo": "POL-2026-001234"}'
```

#### **Example Using JavaScript**

```javascript
const validatePolicy = async (policyNumber) => {
  try {
    const response = await fetch('http://localhost:8080/api/v1/policy-validate', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ policyNo: policyNumber })
    });
    
    const data = await response.json();
    console.log(data);
  } catch (error) {
    console.error('Error validating policy:', error);
  }
};

// Usage
validatePolicy('POL-2026-001234');
```

---

### Response Formats 📥

#### **Case 1: Service Ready + Policy Valid** ✅

**Status Code:** 200 OK

```json
{
  "status": "success",
  "valid": 1,
  "message": "Policy is valid and active"
}
```

#### **Case 2: Service Ready + Policy Invalid** ❌

**Status Code:** 200 OK

```json
{
  "status": "success",
  "valid": 0,
  "message": "Policy number not found in our system"
}
```

#### **Case 3: Data Not Ready Yet** ⏳

**Status Code:** 503 Service Unavailable

```json
{
  "status": "failed",
  "message": "Service temporarily unavailable. Please try again later."
}
```

#### **Case 4: Server Error** 🔴

**Status Code:** 500 Internal Server Error

```json
{
  "status": "error",
  "message": "An unexpected error occurred. Please contact support."
}
```

---

## Implementation Steps

### Prerequisites ✔️

Before implementation, ensure you have:
- [ ] MySQL database with WSO2 schema
- [ ] WSO2 Micro Integrator setup
- [ ] Access to create API endpoints
- [ ] Database connectivity configured

### Step 1: Create Database Tables 🗂️

Execute these SQL scripts in your WSO2 MySQL database:

```sql
-- Create batch job tracking table
CREATE TABLE IF NOT EXISTS WSO2.PG_BATCHJOB (
    BATCH_ID INT PRIMARY KEY AUTO_INCREMENT,
    DATA_READY INT DEFAULT 0,
    BATCH_START_TIME TIMESTAMP,
    BATCH_END_TIME TIMESTAMP,
    STATUS VARCHAR(50),
    RECORD_COUNT INT,
    LAST_UPDATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create policy master table
CREATE TABLE IF NOT EXISTS WSO2.pda1mob (
    POLICY_ID INT PRIMARY KEY AUTO_INCREMENT,
    chdrnum VARCHAR(50) UNIQUE NOT NULL,
    POLICY_HOLDER_NAME VARCHAR(255),
    POLICY_TYPE VARCHAR(100),
    POLICY_STATUS VARCHAR(50),
    PREMIUM_AMOUNT DECIMAL(10, 2),
    START_DATE DATE,
    END_DATE DATE,
    CREATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_chdrnum (chdrnum)
);

-- Insert sample data
INSERT INTO WSO2.PG_BATCHJOB 
(DATA_READY, BATCH_START_TIME, BATCH_END_TIME, STATUS, RECORD_COUNT) 
VALUES 
(1, NOW(), NOW(), 'COMPLETED', 45000);

INSERT INTO WSO2.pda1mob 
(chdrnum, POLICY_HOLDER_NAME, POLICY_TYPE, POLICY_STATUS, PREMIUM_AMOUNT, START_DATE, END_DATE) 
VALUES 
('POL-2026-001234', 'John Smith', 'Motor', 'ACTIVE', 12500.00, '2026-01-15', '2027-01-14'),
('POL-2026-005678', 'Sarah Johnson', 'Health', 'ACTIVE', 8500.00, '2026-02-01', '2027-01-31'),
('POL-2026-009999', 'Mike Davis', 'Home', 'EXPIRED', 15000.00, '2025-03-20', '2026-03-19');
```

### Step 2: Create API Logic 🔧

In your WSO2 Micro Integrator:

1. Create a new API named `PolicyValidationAPI`
2. Add resource `/policy-validate` with POST method
3. Implement the following logic:

```
SEQUENCE: PolicyValidationSequence
  │
  ├─ Extract payload (policyNo)
  ├─ Validate input (null check, sanitization)
  ├─ Query DB: SELECT * FROM PG_BATCHJOB WHERE DATA_READY = 1
  │
  ├─ IF NO RECORDS FOUND:
  │  └─ Return 503 with "Service Temporarily Unavailable"
  │
  ├─ IF RECORD FOUND:
  │  ├─ Query DB: SELECT * FROM pda1mob WHERE chdrnum = ?
  │  │
  │  ├─ IF POLICY FOUND:
  │  │  └─ Return 200 with { "status": "success", "valid": 1 }
  │  │
  │  └─ IF POLICY NOT FOUND:
  │     └─ Return 200 with { "status": "success", "valid": 0 }
  │
  └─ Log request with timestamp and policy number
```

### Step 3: Add Security & Error Handling 🔒

Implement these checks:

```
✓ Input Validation
  - Check if policyNo is not null or empty
  - Validate format (length, allowed characters)
  
✓ SQL Injection Prevention
  - Use parameterized queries (prepared statements)
  - Never concatenate user input directly into SQL
  
✓ Database Error Handling
  - Catch connection failures
  - Handle timeout errors
  - Log unexpected exceptions
  
✓ Audit Logging
  - Log: policy number, timestamp, request source, response
  - Store logs for compliance/investigation
```

### Step 4: Test the API 🧪

Test all scenarios (see Testing Guide section)

### Step 5: Deploy to Production 🚀

1. Package the API
2. Deploy to production WSO2 instance
3. Configure database connection parameters
4. Monitor and log API usage

---

## Testing Guide

### Test Scenario 1: Data Not Ready ⏳

**Setup:**
```sql
-- Clear the BATCH_JOB table or set DATA_READY = 0
UPDATE WSO2.PG_BATCHJOB SET DATA_READY = 0 WHERE BATCH_ID = 1;
```

**Request:**
```bash
curl -X POST http://localhost:8080/api/v1/policy-validate \
  -H "Content-Type: application/json" \
  -d '{"policyNo": "POL-2026-001234"}'
```

**Expected Response:**
```json
{
  "status": "failed",
  "message": "Service temporarily unavailable. Please try again later."
}
```

**HTTP Status:** 503 Service Unavailable

---

### Test Scenario 2: Valid Policy Number ✅

**Setup:**
```sql
-- Ensure DATA_READY = 1 and policy exists
UPDATE WSO2.PG_BATCHJOB SET DATA_READY = 1 WHERE BATCH_ID = 1;
-- Policy POL-2026-001234 already exists in pda1mob table
```

**Request:**
```bash
curl -X POST http://localhost:8080/api/v1/policy-validate \
  -H "Content-Type: application/json" \
  -d '{"policyNo": "POL-2026-001234"}'
```

**Expected Response:**
```json
{
  "status": "success",
  "valid": 1,
  "message": "Policy is valid"
}
```

**HTTP Status:** 200 OK

---

### Test Scenario 3: Invalid Policy Number ❌

**Setup:**
```sql
-- Ensure DATA_READY = 1
UPDATE WSO2.PG_BATCHJOB SET DATA_READY = 1 WHERE BATCH_ID = 1;
-- Policy INVALID-POLICY-123 does NOT exist in pda1mob table
```

**Request:**
```bash
curl -X POST http://localhost:8080/api/v1/policy-validate \
  -H "Content-Type: application/json" \
  -d '{"policyNo": "INVALID-POLICY-123"}'
```

**Expected Response:**
```json
{
  "status": "success",
  "valid": 0,
  "message": "Policy not found"
}
```

**HTTP Status:** 200 OK

---

### Test Scenario 4: SQL Injection Prevention 🔒

**Attack Attempt:**
```bash
curl -X POST http://localhost:8080/api/v1/policy-validate \
  -H "Content-Type: application/json" \
  -d '{"policyNo": "POL'; DROP TABLE pda1mob; --"}'
```

**Expected Result:**
- Query should NOT execute the DROP command
- Either treated as invalid policy number OR input validation error
- Original tables remain intact

---

### Test Scenario 5: Null/Empty Input ⚠️

**Request:**
```bash
curl -X POST http://localhost:8080/api/v1/policy-validate \
  -H "Content-Type: application/json" \
  -d '{"policyNo": ""}'
```

**Expected Response:**
```json
{
  "status": "error",
  "message": "Policy number cannot be empty"
}
```

**HTTP Status:** 400 Bad Request

---

## FAQs

### Q1: Why do we need to check if data is ready?

**A:** When bulk data is imported from external sources, there's a delay between start and completion. During this time, the database is incomplete. If we validate against incomplete data, we'll incorrectly tell users "policy not found" when it actually exists. By checking first, we can tell users "try again later" instead.

---

### Q2: What does `DATA_READY = 1` mean?

**A:** It's a flag in the `PG_BATCHJOB` table that indicates the batch import process is complete and all policy data has been successfully loaded. When `DATA_READY = 0`, data is still being imported.

---

### Q3: How often should we run the batch job?

**A:** This depends on your business requirements. Common patterns:
- **Daily:** Load new policies added in the last 24 hours
- **Weekly:** Full refresh of all policy data
- **On-Demand:** Triggered when new policies are added

---

### Q4: What happens if the database is down?

**A:** The API should:
1. Catch the database connection error
2. Return a 500 error: "An unexpected error occurred"
3. Log the error with timestamp for investigation
4. Alert the operations team to check database health

---

### Q5: Can I use this API without the batch job check?

**A:** Technically yes, but **NOT recommended**. Without the batch check:
- Users get false negatives during data refresh
- No way to distinguish between "data not ready" and "policy doesn't exist"
- Customer support volume increases
- System appears unreliable

---

### Q6: How do I handle rate limiting?

**A:** Implement rate limiting per IP/user:
- **Example:** 100 requests per minute per IP
- Return 429 (Too Many Requests) when exceeded
- Use API Gateway or middleware for enforcement

---

### Q7: Should I log every request?

**A:** **YES**. Log:
- Policy number (masked if sensitive: POL-****-1234)
- Request timestamp
- Response status (valid/invalid/unavailable)
- Source IP address
- Response time

This helps with:
- Audit trails
- Performance monitoring
- Security investigation
- Compliance requirements

---

### Q8: How do I secure the API?

**A:** Implement:
- **Authentication:** API key or OAuth token required
- **HTTPS:** Use SSL/TLS encryption
- **Input Validation:** Whitelist acceptable formats
- **Parameterized Queries:** Prevent SQL injection
- **Rate Limiting:** Prevent abuse
- **CORS:** Restrict cross-origin requests if needed

---

### Q9: What's the typical response time?

**A:** Expected times:
- Database query: **10-50 ms**
- Network latency: **20-100 ms**
- **Total:** **30-150 ms** under normal conditions

If slower, check:
- Database performance
- Network connectivity
- Server load

---

### Q10: Can I modify the policy number format?

**A:** Yes! The format shown (`POL-2026-001234`) is just an example. You can use:
- `POL-2026-001234` (dash-separated)
- `2026001234` (numeric only)
- `MOT2026ABC123` (mixed format)
- Any format your system uses

Just ensure the `chdrnum` field in the database matches your format.

---

## Troubleshooting

### Issue: API always returns "Service Unavailable"

**Possible Causes:**
1. No record in `PG_BATCHJOB` table
2. `DATA_READY` is 0 for all records

**Solution:**
```sql
-- Check if records exist
SELECT * FROM WSO2.PG_BATCHJOB;

-- Manually set to 1 for testing
UPDATE WSO2.PG_BATCHJOB SET DATA_READY = 1 LIMIT 1;
```

---

### Issue: API can't connect to database

**Possible Causes:**
1. Database server is down
2. Connection credentials incorrect
3. Firewall blocking connection

**Solution:**
```bash
# Test database connectivity
telnet localhost 3306

# Check database service status (if using Docker)
docker ps | grep mysql

# Verify connection string in configuration
```

---

### Issue: SQL Injection vulnerability detected

**Solution:**
Ensure ALL queries use parameterized statements:

```java
// WRONG - DO NOT DO THIS
String query = "SELECT * FROM pda1mob WHERE chdrnum = '" + policyNo + "'";

// CORRECT - USE THIS
String query = "SELECT * FROM pda1mob WHERE chdrnum = ?";
PreparedStatement stmt = connection.prepareStatement(query);
stmt.setString(1, policyNo);
```

---

## Summary

| Aspect | Details |
|--------|---------|
| **Problem** | Validate policies only when fresh data is available |
| **Solution** | Two-stage validation with data readiness check |
| **Stage 1** | Query `PG_BATCHJOB` for `DATA_READY = 1` |
| **Stage 2** | Query `pda1mob` for policy number match |
| **Database** | MySQL (WSO2 schema) |
| **API Method** | POST to `/api/v1/policy-validate` |
| **Response Format** | JSON with status and validity flag |
| **Security** | Input validation, parameterized queries, audit logging |
| **Testing** | 5 main scenarios covered with examples |

---

**Last Updated:** March 26, 2026  
**Version:** 1.0  
**Status:** Ready for Implementation
