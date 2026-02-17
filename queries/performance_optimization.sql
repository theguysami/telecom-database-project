-- ================================================
-- PERFORMANCE OPTIMIZATION EXAMPLES
-- Demonstrating query optimization skills
-- ================================================

USE telecom_db;

-- ================================================
-- SECTION 1: QUERY PERFORMANCE ANALYSIS
-- ================================================

-- 1.1 Check Current Index Usage
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    SEQ_IN_INDEX,
    COLUMN_NAME,
    CARDINALITY
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'telecom_db'
ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;

-- 1.2 Analyze Table Sizes
SELECT 
    TABLE_NAME,
    TABLE_ROWS,
    ROUND(DATA_LENGTH / 1024 / 1024, 2) AS data_size_mb,
    ROUND(INDEX_LENGTH / 1024 / 1024, 2) AS index_size_mb,
    ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2) AS total_size_mb
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'telecom_db'
ORDER BY (DATA_LENGTH + INDEX_LENGTH) DESC;

-- ================================================
-- SECTION 2: BEFORE vs AFTER OPTIMIZATION
-- ================================================

-- Example 1: Slow Query - Find calls by phone number
-- BEFORE: Full table scan on 350K records

-- Run EXPLAIN to see execution plan
EXPLAIN 
SELECT * FROM call_records 
WHERE caller_id = (SELECT subscriber_id FROM subscribers WHERE phone_number = '09123456789')
LIMIT 10;

-- OPTIMIZATION: The phone_number already has an index (idx_phone), 
-- but we can optimize with a JOIN instead of subquery

EXPLAIN
SELECT c.* 
FROM call_records c
JOIN subscribers s ON c.caller_id = s.subscriber_id
WHERE s.phone_number = '09123456789'
LIMIT 10;

-- ================================================
-- Example 2: Optimize Date Range Queries
-- ================================================

-- BEFORE: Slow date range query
EXPLAIN
SELECT COUNT(*) 
FROM call_records 
WHERE DATE(call_start_time) = '2024-12-01';

-- Problem: Using DATE() function prevents index usage

-- AFTER: Optimized version (uses index)
EXPLAIN
SELECT COUNT(*) 
FROM call_records 
WHERE call_start_time >= '2024-12-01 00:00:00' 
  AND call_start_time < '2024-12-02 00:00:00';

-- ================================================
-- Example 3: Composite Index Benefits
-- ================================================

-- Query that benefits from composite index (subscriber_id, call_start_time)
EXPLAIN
SELECT 
    caller_id,
    COUNT(*) as call_count,
    SUM(call_duration_seconds) as total_duration
FROM call_records
WHERE caller_id = 1000
  AND call_start_time >= '2024-12-01'
GROUP BY caller_id;

-- The composite index idx_caller_time (caller_id, call_start_time) 
-- makes this query very efficient

-- ================================================
-- SECTION 3: ADDITIONAL OPTIMIZATION INDEXES
-- ================================================

-- 3.1 Add covering index for common revenue queries
-- (Already exists, but here's how you'd add it)
-- CREATE INDEX idx_billing_subscriber_month ON billing(subscriber_id, billing_month, final_amount);

-- 3.2 Add index for fraud detection queries
CREATE INDEX idx_call_records_fraud ON call_records(caller_id, call_start_time, tower_id);

-- 3.3 Index for geographic analysis
CREATE INDEX idx_subscribers_location ON subscribers(province, city, status);

-- ================================================
-- SECTION 4: QUERY OPTIMIZATION TECHNIQUES
-- ================================================

-- 4.1 Use LIMIT to prevent full table scans during testing
-- BAD:
-- SELECT * FROM call_records; -- Returns 350K rows!

-- GOOD:
SELECT * FROM call_records LIMIT 100;

-- 4.2 Avoid SELECT * - Specify only needed columns
-- BAD:
SELECT * FROM subscribers s
JOIN billing b ON s.subscriber_id = b.subscriber_id;

-- GOOD:
SELECT 
    s.subscriber_id, 
    s.phone_number, 
    b.final_amount
FROM subscribers s
JOIN billing b ON s.subscriber_id = b.subscriber_id;

-- 4.3 Use EXISTS instead of IN for large datasets
-- BAD (slower):
SELECT * FROM subscribers
WHERE subscriber_id IN (SELECT subscriber_id FROM billing WHERE final_amount > 100000);

-- GOOD (faster):
SELECT s.* FROM subscribers s
WHERE EXISTS (
    SELECT 1 FROM billing b 
    WHERE b.subscriber_id = s.subscriber_id 
    AND b.final_amount > 100000
);

-- ================================================
-- SECTION 5: PARTITION STRATEGY (Advanced)
-- ================================================

-- For production systems, partition large tables by date
-- This is an EXAMPLE - would require recreating the table

/*
-- Partition call_records by month
CREATE TABLE call_records_partitioned (
    cdr_id BIGINT AUTO_INCREMENT,
    caller_id INT NOT NULL,
    receiver_phone VARCHAR(15) NOT NULL,
    call_start_time DATETIME NOT NULL,
    call_duration_seconds INT NOT NULL,
    tower_id INT NOT NULL,
    call_status ENUM('completed', 'failed', 'busy', 'no_answer') NOT NULL,
    cost DECIMAL(8,2) DEFAULT 0.00,
    PRIMARY KEY (cdr_id, call_start_time),
    INDEX idx_caller_time (caller_id, call_start_time),
    INDEX idx_call_time (call_start_time)
) ENGINE=InnoDB
PARTITION BY RANGE (YEAR(call_start_time) * 100 + MONTH(call_start_time)) (
    PARTITION p202410 VALUES LESS THAN (202411),
    PARTITION p202411 VALUES LESS THAN (202412),
    PARTITION p202412 VALUES LESS THAN (202501),
    PARTITION p202501 VALUES LESS THAN (202502),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);
*/

-- Benefits:
-- 1. Queries filtered by date only scan relevant partitions
-- 2. Easier to archive old data
-- 3. Better maintenance (optimize individual partitions)

-- ================================================
-- SECTION 6: PERFORMANCE TESTING
-- ================================================

-- 6.1 Benchmark: Query execution time
SET @start_time = NOW(6);

SELECT COUNT(*) 
FROM call_records 
WHERE call_start_time >= '2024-12-01' 
  AND call_start_time < '2025-01-01';

SET @end_time = NOW(6);
SELECT TIMESTAMPDIFF(MICROSECOND, @start_time, @end_time) / 1000 AS execution_time_ms;

-- 6.2 Compare JOIN performance
-- Test 1: Using JOIN
SET @start_time = NOW(6);

SELECT COUNT(*)
FROM call_records c
JOIN subscribers s ON c.caller_id = s.subscriber_id
WHERE s.status = 'active';

SET @end_time = NOW(6);
SELECT TIMESTAMPDIFF(MICROSECOND, @start_time, @end_time) / 1000 AS join_time_ms;

-- Test 2: Using subquery
SET @start_time = NOW(6);

SELECT COUNT(*)
FROM call_records
WHERE caller_id IN (SELECT subscriber_id FROM subscribers WHERE status = 'active');

SET @end_time = NOW(6);
SELECT TIMESTAMPDIFF(MICROSECOND, @start_time, @end_time) / 1000 AS subquery_time_ms;

-- ================================================
-- SECTION 7: CACHING STRATEGY
-- ================================================

-- 7.1 Create materialized summary table for dashboards
CREATE TABLE IF NOT EXISTS daily_metrics_cache (
    metric_date DATE PRIMARY KEY,
    total_calls INT,
    total_data_gb DECIMAL(12,2),
    total_sms INT,
    active_users INT,
    total_revenue DECIMAL(15,2),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_date (metric_date)
) ENGINE=InnoDB;

-- 7.2 Populate cache table (run daily)
INSERT INTO daily_metrics_cache (metric_date, total_calls, total_data_gb, total_sms, active_users, total_revenue)
SELECT 
    DATE(c.call_start_time) AS metric_date,
    COUNT(DISTINCT c.cdr_id) AS total_calls,
    ROUND(SUM(d.data_consumed_mb) / 1024, 2) AS total_data_gb,
    COUNT(DISTINCT sms.sms_id) AS total_sms,
    COUNT(DISTINCT c.caller_id) AS active_users,
    SUM(c.cost) AS total_revenue
FROM call_records c
LEFT JOIN data_usage d ON DATE(c.call_start_time) = DATE(d.session_start)
LEFT JOIN sms_records sms ON DATE(c.call_start_time) = DATE(sms.sent_time)
WHERE DATE(c.call_start_time) = CURDATE() - INTERVAL 1 DAY
GROUP BY DATE(c.call_start_time)
ON DUPLICATE KEY UPDATE
    total_calls = VALUES(total_calls),
    total_data_gb = VALUES(total_data_gb),
    total_sms = VALUES(total_sms),
    active_users = VALUES(active_users),
    total_revenue = VALUES(total_revenue);

-- ================================================
-- SECTION 8: STORED PROCEDURES (Optimization)
-- ================================================

-- 8.1 Stored Procedure: Calculate monthly bill efficiently
DELIMITER //

CREATE PROCEDURE IF NOT EXISTS calculate_monthly_bill(
    IN p_subscriber_id INT,
    IN p_billing_month DATE
)
BEGIN
    DECLARE v_plan_fee DECIMAL(10,2);
    DECLARE v_call_charges DECIMAL(10,2);
    DECLARE v_data_charges DECIMAL(10,2);
    DECLARE v_sms_charges DECIMAL(10,2);
    DECLARE v_total DECIMAL(10,2);
    DECLARE v_tax DECIMAL(10,2);
    
    -- Get plan fee
    SELECT monthly_fee INTO v_plan_fee
    FROM plans p
    JOIN subscribers s ON p.plan_id = s.plan_id
    WHERE s.subscriber_id = p_subscriber_id;
    
    -- Calculate call charges
    SELECT COALESCE(SUM(cost), 0) INTO v_call_charges
    FROM call_records
    WHERE caller_id = p_subscriber_id
      AND DATE_FORMAT(call_start_time, '%Y-%m-01') = p_billing_month;
    
    -- Calculate data charges
    SELECT COALESCE(SUM(cost), 0) INTO v_data_charges
    FROM data_usage
    WHERE subscriber_id = p_subscriber_id
      AND DATE_FORMAT(session_start, '%Y-%m-01') = p_billing_month;
    
    -- Calculate SMS charges
    SELECT COALESCE(SUM(cost), 0) INTO v_sms_charges
    FROM sms_records
    WHERE sender_id = p_subscriber_id
      AND DATE_FORMAT(sent_time, '%Y-%m-01') = p_billing_month;
    
    -- Calculate total
    SET v_total = v_plan_fee + v_call_charges + v_data_charges + v_sms_charges;
    SET v_tax = v_total * 0.09;
    
    -- Return results
    SELECT 
        p_subscriber_id AS subscriber_id,
        p_billing_month AS billing_month,
        v_plan_fee AS plan_fee,
        v_call_charges AS call_charges,
        v_data_charges AS data_charges,
        v_sms_charges AS sms_charges,
        v_total AS total_amount,
        v_tax AS tax_amount,
        v_total + v_tax AS final_amount;
END //

DELIMITER ;

-- Usage:
-- CALL calculate_monthly_bill(1, '2024-12-01');

-- ================================================
-- SECTION 9: QUERY HINTS & OPTIMIZATION TIPS
-- ================================================

-- 9.1 Force index usage (when optimizer chooses wrong index)
SELECT /*+ INDEX(call_records idx_caller_time) */
    caller_id, COUNT(*)
FROM call_records
WHERE caller_id BETWEEN 1000 AND 2000
GROUP BY caller_id;

-- 9.2 Use STRAIGHT_JOIN when you know the optimal join order
SELECT STRAIGHT_JOIN
    s.phone_number,
    COUNT(c.cdr_id) as call_count
FROM subscribers s
JOIN call_records c ON s.subscriber_id = c.caller_id
WHERE s.status = 'active'
GROUP BY s.phone_number;

-- ================================================
-- SECTION 10: MONITORING & MAINTENANCE
-- ================================================

-- 10.1 Find slow queries (requires slow query log enabled)
-- Check current settings:
SHOW VARIABLES LIKE 'slow_query%';
SHOW VARIABLES LIKE 'long_query_time';

-- 10.2 Optimize all tables (run monthly)
-- OPTIMIZE TABLE call_records;
-- OPTIMIZE TABLE data_usage;
-- OPTIMIZE TABLE billing;

-- 10.3 Analyze table statistics (helps optimizer)
ANALYZE TABLE call_records;
ANALYZE TABLE subscribers;
ANALYZE TABLE billing;

-- ================================================
-- KEY PERFORMANCE METRICS TO TRACK
-- ================================================

-- Average query response time by table
-- Index hit rate
-- Cache hit rate  
-- Disk I/O operations
-- Connection pool usage
-- Slow query count per hour

-- ================================================
-- END OF PERFORMANCE OPTIMIZATION GUIDE
-- ================================================
