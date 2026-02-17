-- ================================================
-- TELECOM SUBSCRIBER & CDR MANAGEMENT SYSTEM
-- Database Schema Design
-- Target: 250K-500K records
-- ================================================

-- Drop existing database if exists
DROP DATABASE IF EXISTS telecom_db;
CREATE DATABASE telecom_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE telecom_db;

-- ================================================
-- 1. PLANS TABLE
-- Different subscription plans offered
-- ================================================
CREATE TABLE plans (
    plan_id INT PRIMARY KEY AUTO_INCREMENT,
    plan_name VARCHAR(100) NOT NULL,
    plan_type ENUM('prepaid', 'postpaid') NOT NULL,
    monthly_fee DECIMAL(10,2) NOT NULL,
    included_minutes INT DEFAULT 0,
    included_data_gb INT DEFAULT 0,
    included_sms INT DEFAULT 0,
    overage_rate_per_minute DECIMAL(5,2) DEFAULT 0.50,
    overage_rate_per_mb DECIMAL(5,4) DEFAULT 0.01,
    overage_rate_per_sms DECIMAL(5,2) DEFAULT 0.10,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_plan_type (plan_type)
) ENGINE=InnoDB;

-- ================================================
-- 2. NETWORK TOWERS TABLE
-- Cell towers for location tracking
-- ================================================
CREATE TABLE network_towers (
    tower_id INT PRIMARY KEY AUTO_INCREMENT,
    tower_name VARCHAR(100) NOT NULL,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    city VARCHAR(100) NOT NULL,
    province VARCHAR(100) NOT NULL,
    capacity INT NOT NULL COMMENT 'Maximum concurrent connections',
    technology ENUM('2G', '3G', '4G', '5G') NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    installation_date DATE,
    INDEX idx_location (city, province),
    INDEX idx_technology (technology)
) ENGINE=InnoDB;

-- ================================================
-- 3. SUBSCRIBERS TABLE
-- Customer information and active subscriptions
-- ================================================
CREATE TABLE subscribers (
    subscriber_id INT PRIMARY KEY AUTO_INCREMENT,
    phone_number VARCHAR(15) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150),
    national_id VARCHAR(20) UNIQUE NOT NULL,
    date_of_birth DATE NOT NULL,
    address TEXT,
    city VARCHAR(100),
    province VARCHAR(100),
    plan_id INT NOT NULL,
    sim_card_number VARCHAR(20) UNIQUE NOT NULL,
    activation_date DATE NOT NULL,
    status ENUM('active', 'suspended', 'terminated') DEFAULT 'active',
    account_balance DECIMAL(10,2) DEFAULT 0.00 COMMENT 'For prepaid users',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (plan_id) REFERENCES plans(plan_id),
    INDEX idx_phone (phone_number),
    INDEX idx_status (status),
    INDEX idx_plan (plan_id),
    INDEX idx_activation (activation_date)
) ENGINE=InnoDB;

-- ================================================
-- 4. CALL DETAIL RECORDS (CDR) TABLE
-- Core table - stores all call records
-- Partitioned by month for performance
-- ================================================
CREATE TABLE call_records (
    cdr_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    caller_id INT NOT NULL,
    receiver_phone VARCHAR(15) NOT NULL,
    call_type ENUM('voice', 'video') DEFAULT 'voice',
    call_direction ENUM('outgoing', 'incoming') NOT NULL,
    call_start_time DATETIME NOT NULL,
    call_duration_seconds INT NOT NULL,
    tower_id INT NOT NULL,
    call_status ENUM('completed', 'failed', 'busy', 'no_answer') NOT NULL,
    is_roaming BOOLEAN DEFAULT FALSE,
    cost DECIMAL(8,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (caller_id) REFERENCES subscribers(subscriber_id),
    FOREIGN KEY (tower_id) REFERENCES network_towers(tower_id),
    INDEX idx_caller_time (caller_id, call_start_time),
    INDEX idx_call_time (call_start_time),
    INDEX idx_tower (tower_id),
    INDEX idx_status (call_status)
) ENGINE=InnoDB;

-- ================================================
-- 5. DATA USAGE TABLE
-- Internet/data consumption tracking
-- ================================================
CREATE TABLE data_usage (
    usage_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    subscriber_id INT NOT NULL,
    session_start DATETIME NOT NULL,
    session_end DATETIME NOT NULL,
    data_consumed_mb DECIMAL(12,2) NOT NULL,
    tower_id INT NOT NULL,
    service_type ENUM('web', 'video', 'social', 'gaming', 'other') DEFAULT 'web',
    cost DECIMAL(8,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subscriber_id) REFERENCES subscribers(subscriber_id),
    FOREIGN KEY (tower_id) REFERENCES network_towers(tower_id),
    INDEX idx_subscriber_time (subscriber_id, session_start),
    INDEX idx_session_start (session_start),
    INDEX idx_tower (tower_id)
) ENGINE=InnoDB;

-- ================================================
-- 6. SMS RECORDS TABLE
-- Text message logs
-- ================================================
CREATE TABLE sms_records (
    sms_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    sender_id INT NOT NULL,
    receiver_phone VARCHAR(15) NOT NULL,
    message_type ENUM('standard', 'promotional', 'transactional') DEFAULT 'standard',
    sent_time DATETIME NOT NULL,
    delivery_status ENUM('sent', 'delivered', 'failed') NOT NULL,
    tower_id INT NOT NULL,
    cost DECIMAL(5,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES subscribers(subscriber_id),
    FOREIGN KEY (tower_id) REFERENCES network_towers(tower_id),
    INDEX idx_sender_time (sender_id, sent_time),
    INDEX idx_sent_time (sent_time),
    INDEX idx_delivery (delivery_status)
) ENGINE=InnoDB;

-- ================================================
-- 7. BILLING TABLE
-- Monthly bills and payment tracking
-- ================================================
CREATE TABLE billing (
    bill_id INT PRIMARY KEY AUTO_INCREMENT,
    subscriber_id INT NOT NULL,
    billing_month DATE NOT NULL COMMENT 'First day of billing month',
    plan_fee DECIMAL(10,2) NOT NULL,
    call_charges DECIMAL(10,2) DEFAULT 0.00,
    data_charges DECIMAL(10,2) DEFAULT 0.00,
    sms_charges DECIMAL(10,2) DEFAULT 0.00,
    total_amount DECIMAL(10,2) NOT NULL,
    tax_amount DECIMAL(10,2) DEFAULT 0.00,
    final_amount DECIMAL(10,2) NOT NULL,
    due_date DATE NOT NULL,
    payment_status ENUM('pending', 'paid', 'overdue', 'partial') DEFAULT 'pending',
    payment_date DATE,
    payment_method ENUM('cash', 'card', 'bank_transfer', 'mobile_wallet'),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subscriber_id) REFERENCES subscribers(subscriber_id),
    INDEX idx_subscriber_month (subscriber_id, billing_month),
    INDEX idx_payment_status (payment_status),
    INDEX idx_due_date (due_date),
    UNIQUE KEY unique_subscriber_month (subscriber_id, billing_month)
) ENGINE=InnoDB;

-- ================================================
-- 8. RECHARGE HISTORY TABLE
-- Prepaid balance top-ups
-- ================================================
CREATE TABLE recharge_history (
    recharge_id INT PRIMARY KEY AUTO_INCREMENT,
    subscriber_id INT NOT NULL,
    recharge_amount DECIMAL(10,2) NOT NULL,
    recharge_method ENUM('card', 'mobile_wallet', 'bank', 'retailer') NOT NULL,
    recharge_time DATETIME NOT NULL,
    previous_balance DECIMAL(10,2) NOT NULL,
    new_balance DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subscriber_id) REFERENCES subscribers(subscriber_id),
    INDEX idx_subscriber_time (subscriber_id, recharge_time),
    INDEX idx_recharge_time (recharge_time)
) ENGINE=InnoDB;

-- ================================================
-- 9. SIM SWAP HISTORY TABLE
-- Track SIM card changes (important for fraud detection)
-- ================================================
CREATE TABLE sim_swap_history (
    swap_id INT PRIMARY KEY AUTO_INCREMENT,
    subscriber_id INT NOT NULL,
    old_sim_card VARCHAR(20) NOT NULL,
    new_sim_card VARCHAR(20) NOT NULL,
    swap_reason ENUM('lost', 'damaged', 'upgrade', 'stolen', 'other') NOT NULL,
    swap_date DATETIME NOT NULL,
    verified_by VARCHAR(100) COMMENT 'Staff member who verified',
    verification_document VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subscriber_id) REFERENCES subscribers(subscriber_id),
    INDEX idx_subscriber (subscriber_id),
    INDEX idx_swap_date (swap_date)
) ENGINE=InnoDB;

-- ================================================
-- VIEWS FOR COMMON QUERIES
-- ================================================

-- Active subscribers summary
CREATE VIEW active_subscribers_summary AS
SELECT 
    s.subscriber_id,
    s.phone_number,
    CONCAT(s.first_name, ' ', s.last_name) AS full_name,
    p.plan_name,
    p.plan_type,
    s.account_balance,
    s.activation_date,
    DATEDIFF(CURDATE(), s.activation_date) AS days_active
FROM subscribers s
JOIN plans p ON s.plan_id = p.plan_id
WHERE s.status = 'active';

-- Monthly revenue summary
CREATE VIEW monthly_revenue_summary AS
SELECT 
    DATE_FORMAT(billing_month, '%Y-%m') AS month,
    COUNT(*) AS total_bills,
    SUM(plan_fee) AS plan_revenue,
    SUM(call_charges) AS call_revenue,
    SUM(data_charges) AS data_revenue,
    SUM(sms_charges) AS sms_revenue,
    SUM(final_amount) AS total_revenue,
    SUM(CASE WHEN payment_status = 'paid' THEN final_amount ELSE 0 END) AS collected_revenue
FROM billing
GROUP BY DATE_FORMAT(billing_month, '%Y-%m');

-- ================================================
-- END OF SCHEMA
-- ================================================
