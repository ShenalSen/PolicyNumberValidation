DROP DATABASE IF EXISTS insurance;
CREATE DATABASE insurance;
USE insurance;

CREATE TABLE products (
    product_id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(255),
    description TEXT,
    coverage_type VARCHAR(100),
    coverage_amount DECIMAL(15,2),
    deductible DECIMAL(15,2),
    premium VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //
CREATE TRIGGER auto_increment_product_id 
BEFORE INSERT ON products
FOR EACH ROW
BEGIN
    DECLARE next_id INT;
    SELECT COALESCE(MAX(CAST(SUBSTRING(product_id, 3) AS UNSIGNED)), 0) + 1 
    INTO next_id FROM products WHERE product_id REGEXP '^P_[0-9]+';
    SET NEW.product_id = CONCAT('P_', LPAD(next_id, 3, '0'));
END;
//
DELIMITER ;

CREATE TABLE customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    dob DATE,
    gender ENUM('Male', 'Female', 'Other'),
    email VARCHAR(150),
    phone VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('active','inactive')
);

DELIMITER //
CREATE TRIGGER auto_increment_customer_id 
BEFORE INSERT ON customers
FOR EACH ROW
BEGIN
    DECLARE next_id INT;
    SELECT COALESCE(MAX(CAST(SUBSTRING(customer_id, 3) AS UNSIGNED)), 0) + 1 
    INTO next_id FROM customers WHERE customer_id REGEXP '^C_[0-9]+';
    SET NEW.customer_id = CONCAT('C_', LPAD(next_id, 3, '0'));
END;
//
DELIMITER ;

CREATE TABLE employees (
    employee_id VARCHAR(10) PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role VARCHAR(50),
    email VARCHAR(150),
    phone VARCHAR(20),
    address VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //
CREATE TRIGGER auto_increment_employee_id 
BEFORE INSERT ON employees
FOR EACH ROW
BEGIN
    DECLARE next_id INT;
    SELECT COALESCE(MAX(CAST(SUBSTRING(employee_id, 3) AS UNSIGNED)), 0) + 1 
    INTO next_id FROM employees WHERE employee_id REGEXP '^E_[0-9]+';
    SET NEW.employee_id = CONCAT('E_', LPAD(next_id, 3, '0'));
END;
//
DELIMITER ;

CREATE TABLE policies (
    policy_id      VARCHAR(10) PRIMARY KEY,
    customer_id    VARCHAR(10),
    product_id     VARCHAR(10),
    employee_id    VARCHAR(10),
    start_date     DATE,
    end_date       DATE,
    next_due_date  DATE,
    premium_amount DECIMAL(12,2),
    status         ENUM('Active','Expired','Cancelled','Inactive'),
    policy_details TEXT,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id)  REFERENCES products(product_id),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

DELIMITER //
CREATE TRIGGER auto_increment_policy_id 
BEFORE INSERT ON policies
FOR EACH ROW
BEGIN
    DECLARE next_id INT;
    SELECT COALESCE(MAX(CAST(SUBSTRING(policy_id, 5) AS UNSIGNED)), 0) + 1 
    INTO next_id FROM policies WHERE policy_id REGEXP '^POL_[0-9]+';
    SET NEW.policy_id = CONCAT('POL_', LPAD(next_id, 3, '0'));
END;
//
DELIMITER ;

CREATE TABLE claims (
    claim_id VARCHAR(20) PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(150),
    mobile_number VARCHAR(20),
    address TEXT,
    policy_id VARCHAR(20),
    type_of_policy VARCHAR(100),
    policy_value DECIMAL(12,2),
    submitted_date DATE,
    incident_date DATE,
    employee_name VARCHAR(100),
    current_status ENUM('Submitted','Under Review','Approved','Declined','Payment Processing','Closed'),
    incident_details TEXT,
    loss_damage_details TEXT,
    note TEXT,
    FOREIGN KEY (policy_id) REFERENCES policies(policy_id)
);

DELIMITER //
CREATE TRIGGER auto_increment_claim_id 
BEFORE INSERT ON claims
FOR EACH ROW
BEGIN
    DECLARE next_id INT;
    SELECT COALESCE(MAX(CAST(SUBSTRING(claim_id, 5) AS UNSIGNED)), 0) + 1 
    INTO next_id FROM claims WHERE claim_id REGEXP '^CLM_[0-9]+';
    SET NEW.claim_id = CONCAT('CLM_', LPAD(next_id, 3, '0'));
END;
//
DELIMITER ;


INSERT INTO employees VALUES
('E_001', 'Alice', 'Fernando', 'Claims Officer', 'alice@insure.com', '0771234567', '123 Colombo Rd', NOW()),
('E_002', 'Bob', 'Silva', 'Underwriter', 'bob@insure.com', '0772345678', '456 Galle Rd', NOW()),
('E_003', 'Carol', 'Perera', 'Agent', 'carol@insure.com', '0773456789', '789 Kandy Rd', NOW()),
('E_004', 'Dan', 'Rajan', 'Claims Officer', 'dan@insure.com', '0774567890', 'Trinco Rd', NOW()),
('E_005', 'Eve', 'Kumaran', 'Auditor', 'eve@insure.com', '0775678901', 'Anuradhapura', NOW());


INSERT INTO customers VALUES
('C_001', 'David', 'Johnson', '1990-01-15', 'Male', 'david@example.com', '0774567890', 'Jaffna', NOW(), 'active'),
('C_002', 'Emily', 'Brown', '1985-06-25', 'Female', 'divi8330@gmail.com', '0775678901', 'Kandy', NOW(), 'active'),
('C_003', 'Frank', 'Lee', '1978-09-12', 'Other', 'frank@example.com', '0776789012', 'Galle', NOW(), 'inactive'),
('C_004', 'Grace', 'Dinesh', '1993-03-03', 'Female', 'grace@example.com', '0777890123', 'Colombo', NOW(), 'active'),
('C_005', 'Harry', 'Kumar', '1980-07-20', 'Male', 'harry@example.com', '0778901234', 'Batticaloa', NOW(), 'inactive');


INSERT INTO products VALUES
('P_001', 'Comprehensive Health Insurance', 'Full medical coverage', 'health', 1000000.00, 5000.00, 'Annual', NOW()),
('P_002', 'Standard Auto Insurance', 'Basic car insurance coverage', 'auto', 500000.00, 10000.00, 'Monthly', NOW()),
('P_003', 'Premium Home Insurance', 'Coverage for home and assets', 'property', 1500000.00, 20000.00, 'Quarterly', NOW()),
('P_004', 'International Travel Insurance', 'Covers emergencies while abroad', 'travel', 300000.00, 1000.00, 'Weekly', NOW()),
('P_005', 'Term Life Insurance', 'Life protection with fixed term', 'life', 2000000.00, 15000.00, 'Annual', NOW()),
('P_006', 'Basic Health Insurance', 'Covers minor medical expenses', 'health', 300000.00, 2000.00, 'Annual', NOW()),
('P_007', 'Collision Auto Insurance', 'Covers vehicle collision damage', 'auto', 750000.00, 12000.00, 'Monthly', NOW());


-- policy_id, customer_id, product_id, employee_id, start_date, end_date, next_due_date, premium_amount, status, policy_details, created_at
INSERT INTO policies VALUES
('POL_001', 'C_001', 'P_001', 'E_001', '2023-01-01', '2027-01-01', '2026-04-01', 15000.00, 'Active',    'Health plan - Full',        NOW()),
('POL_002', 'C_002', 'P_002', 'E_001', '2023-06-01', '2024-06-01', NULL,         8500.00,  'Cancelled', 'Auto basic coverage',       NOW()),
('POL_003', 'C_002', 'P_003', 'E_002', '2022-01-01', '2023-01-01', NULL,         22000.00, 'Expired',   'Home cover elite',          NOW()),
('POL_004', 'C_003', 'P_006', 'E_003', '2024-01-01', '2027-01-01', '2026-04-01', 4000.00,  'Inactive',  'Basic health',              NOW()),
('POL_005', 'C_004', 'P_005', 'E_004', '2024-02-01', '2027-02-01', '2026-05-01', 12000.00, 'Active',    'Life shield plan',          NOW()),
('POL_006', 'C_002', 'P_007', 'E_001', '2024-03-01', '2027-03-01', '2026-04-01', 9000.00,  'Active',    'Collision coverage',        NOW()),
('POL_007', 'C_002', 'P_004', 'E_001', '2024-04-01', '2027-04-01', '2026-05-01', 3500.00,  'Active',    'Travel emergency cover',    NOW()),
('POL_008', 'C_002', 'P_001', 'E_001', '2024-05-01', '2027-05-01', '2026-06-01', 18000.00, 'Active',    'Extra health plan',         NOW()),
('POL_009', 'C_002', 'P_005', 'E_001', '2023-08-01', '2024-08-01', NULL,         11000.00, 'Expired',   'Life plan trial',           NOW());


INSERT INTO claims VALUES
('CLM_001', 'David', 'Johnson', 'david@example.com', '0774567890', 'Jaffna', 'POL_001', 'Comprehensive Health Insurance', 750000.00,
 '2024-05-15', '2024-05-10', 'Alice Fernando', 'Submitted', 'Surgery after accident', 'Requested 750K medical coverage', 'N/A'),

('CLM_002', 'Emily', 'Brown', 'divi8330@gmail.com', '0775678901', 'Kandy', 'POL_002', 'Standard Auto Insurance', 200000.00,
 '2024-04-20', '2024-04-15', 'Alice Fernando', 'Under Review', 'Rear-end collision', 'Damage estimate 200K', 'Review ongoing'),

('CLM_003', 'Emily', 'Brown', 'divi8330@gmail.com', '0775678901', 'Kandy', 'POL_003', 'Premium Home Insurance', 1000000.00,
 '2023-12-01', '2023-11-28', 'Bob Silva', 'Approved', 'Roof damage in storm', 'Full approval', 'Issued approval letter'),

('CLM_004', 'Frank', 'Lee', 'frank@example.com', '0776789012', 'Galle', 'POL_004', 'Basic Health Insurance', 50000.00,
 '2024-06-10', '2024-06-05', 'Carol Perera', 'Declined', 'Dental surgery', 'Policy inactive - not covered', 'Marked declined'),

('CLM_005', 'David', 'Johnson', 'david@example.com', '0774567890', 'Jaffna', 'POL_001', 'Comprehensive Health Insurance', 100000.00,
 '2024-06-20', '2024-06-18', 'Alice Fernando', 'Payment Processing', 'Follow-up consultation', 'Approved - pending transfer', 'Payment within 5 days'),

('CLM_006', 'Emily', 'Brown', 'divi8330@gmail.com', '0775678901', 'Kandy', 'POL_002', 'Standard Auto Insurance', 150000.00,
 '2024-03-10', '2024-03-08', 'Alice Fernando', 'Closed', 'Windshield replacement', 'Paid & closed', 'Customer confirmed'),

('CLM_007', 'Emily', 'Brown', 'divi8330@gmail.com', '0775678901', 'Kandy', 'POL_006', 'Collision Auto Insurance', 300000.00,
 '2024-06-15', '2024-06-14', 'Alice Fernando', 'Approved', 'Side impact damage', 'Approved with 300K', 'Send cheque'),

('CLM_008', 'Emily', 'Brown', 'divi8330@gmail.com', '0775678901', 'Kandy', 'POL_007', 'International Travel Insurance', 50000.00,
 '2024-06-10', '2024-06-09', 'Alice Fernando', 'Under Review', 'Lost baggage claim', 'Reviewing documents', 'Pending supervisor check'),

('CLM_009', 'Emily', 'Brown', 'divi8330@gmail.com', '0775678901', 'Kandy', 'POL_008', 'Comprehensive Health Insurance', 250000.00,
 '2024-06-22', '2024-06-20', 'Alice Fernando', 'Submitted', 'Appendicitis operation', 'Initial claim submission', 'Awaiting feedback'),

('CLM_010', 'Emily', 'Brown', 'divi8330@gmail.com', '0775678901', 'Kandy', 'POL_009', 'Term Life Insurance', 2000000.00,
 '2024-06-01', '2024-05-30', 'Alice Fernando', 'Declined', 'Death of insured - past expiry', 'Policy expired before event', 'Rejected');

CREATE TABLE policy_payments (
    payment_id     VARCHAR(15)   PRIMARY KEY,
    policy_id      VARCHAR(10)   NOT NULL,
    customer_id    VARCHAR(10)   NOT NULL,
    amount         DECIMAL(12,2) NOT NULL,
    tran_date      DATE          NOT NULL,
    payment_method ENUM('Cash','Card','Bank Transfer','Online') DEFAULT 'Online',
    reference_no   VARCHAR(50)   NULL,
    status         ENUM('Success','Failed','Pending')          DEFAULT 'Success',
    created_at     TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (policy_id)   REFERENCES policies(policy_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    INDEX idx_policy_tran (policy_id, tran_date)
);

DELIMITER //
CREATE TRIGGER auto_increment_payment_id
BEFORE INSERT ON policy_payments
FOR EACH ROW
BEGIN
    DECLARE next_id INT;
    SELECT COALESCE(MAX(CAST(SUBSTRING(payment_id, 4) AS UNSIGNED)), 0) + 1
    INTO next_id FROM policy_payments WHERE payment_id REGEXP '^PAY[0-9]+';
    SET NEW.payment_id = CONCAT('PAY', LPAD(next_id, 6, '0'));
END;
//
DELIMITER ;

-- Seed: payment history
-- payment_id, policy_id, customer_id, amount, tran_date, payment_method, reference_no, status
INSERT INTO policy_payments VALUES
('PAY000001', 'POL_001', 'C_001', 15000.00, '2026-03-01', 'Online',        'REF2026030101', 'Success', NOW()),
('PAY000002', 'POL_001', 'C_001', 15000.00, '2026-02-01', 'Bank Transfer', 'REF2026020101', 'Success', NOW()),
('PAY000003', 'POL_001', 'C_001', 15000.00, '2026-01-01', 'Online',        'REF2026010101', 'Success', NOW()),
('PAY000004', 'POL_005', 'C_004', 12000.00, '2026-03-01', 'Card',          'REF2026030205', 'Success', NOW()),
('PAY000005', 'POL_005', 'C_004', 12000.00, '2026-02-01', 'Online',        'REF2026020205', 'Success', NOW()),
('PAY000006', 'POL_006', 'C_002', 9000.00,  '2026-03-01', 'Online',        'REF2026030106', 'Success', NOW()),
('PAY000007', 'POL_006', 'C_002', 9000.00,  '2026-02-01', 'Card',          'REF2026020106', 'Success', NOW()),
('PAY000008', 'POL_007', 'C_002', 3500.00,  '2026-03-01', 'Cash',          'REF2026030107', 'Success', NOW()),
('PAY000009', 'POL_008', 'C_002', 18000.00, '2026-03-01', 'Online',        'REF2026030108', 'Success', NOW()),
('PAY000010', 'POL_008', 'C_002', 18000.00, '2026-02-01', 'Online',        'REF2026020108', 'Success', NOW());



-- USE CASE 2: BATCH SYNCHRONIZATION TABLES

CREATE TABLE IF NOT EXISTS batch_control (
    job_id       VARCHAR(10) PRIMARY KEY,
    job_name     VARCHAR(100) NOT NULL,
    data_ready   TINYINT(1) DEFAULT 0, -- 1 = Ready, 0 = Busy/Syncing
    updated_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO batch_control (job_id, job_name, data_ready) 
VALUES ('J_001', 'Daily_Active_Policy_Sync', 1)
ON DUPLICATE KEY UPDATE data_ready = 1;

CREATE TABLE IF NOT EXISTS valid_policies (
    policy_id    VARCHAR(10) PRIMARY KEY,
    sync_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (policy_id) REFERENCES policies(policy_id)
);

INSERT INTO valid_policies (policy_id)
SELECT policy_id FROM policies WHERE status = 'Active';