-- ================================================
-- TELECOM DATABASE - BUSINESS QUERIES
-- Demonstrating real-world telecom analytics
-- ================================================

USE telecom_db;

-- ================================================
-- SECTION 1: SUBSCRIBER ANALYTICS
-- ================================================

-- 1.1 Active Subscribers by Plan Type
SELECT 
    p.plan_name,
    p.plan_type,
    COUNT(s.subscriber_id) AS total_subscribers,
    ROUND(AVG(s.account_balance), 2) AS avg_balance,
    ROUND(AVG(DATEDIFF(CURDATE(), s.activation_date)), 0) AS avg_days_active
FROM subscribers s
JOIN plans p ON s.plan_id = p.plan_id
WHERE s.status = 'active'
GROUP BY p.plan_id, p.plan_name, p.plan_type
ORDER BY total_subscribers DESC;

-- 1.2 Top 10 Most Active Callers (by call volume)
SELECT 
    s.subscriber_id,
    s.phone_number,
    CONCAT(s.first_name, ' ', s.last_name) AS full_name,
    p.plan_name,
    COUNT(c.cdr_id) AS total_calls,
    ROUND(SUM(c.call_duration_seconds) / 60, 2) AS total_minutes,
    ROUND(SUM(c.cost), 2) AS total_call_cost
FROM subscribers s
JOIN call_records c ON s.subscriber_id = c.caller_id
JOIN plans p ON s.plan_id = p.plan_id
WHERE c.call_status = 'completed'
GROUP BY s.subscriber_id, s.phone_number, s.first_name, s.last_name, p.plan_name
ORDER BY total_calls DESC
LIMIT 10;

-- 1.3 Churn Risk Analysis (Low Activity Users)
-- Subscribers with less than 5 calls in the last 30 days
SELECT 
    s.subscriber_id,
    s.phone_number,
    CONCAT(s.first_name, ' ', s.last_name) AS full_name,
    COUNT(c.cdr_id) AS calls_last_30_days,
    DATEDIFF(CURDATE(), MAX(c.call_start_time)) AS days_since_last_call,
    s.account_balance
FROM subscribers s
LEFT JOIN call_records c ON s.subscriber_id = c.caller_id 
    AND c.call_start_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
WHERE s.status = 'active'
GROUP BY s.subscriber_id, s.phone_number, s.first_name, s.last_name, s.account_balance
HAVING calls_last_30_days < 5
ORDER BY calls_last_30_days ASC, days_since_last_call DESC
LIMIT 20;

-- ================================================
-- SECTION 2: REVENUE ANALYTICS
-- ================================================

-- 2.1 Monthly Revenue Summary
SELECT 
    DATE_FORMAT(billing_month, '%Y-%m') AS month,
    COUNT(DISTINCT subscriber_id) AS total_subscribers,
    ROUND(SUM(plan_fee), 2) AS plan_revenue,
    ROUND(SUM(call_charges), 2) AS call_revenue,
    ROUND(SUM(data_charges), 2) AS data_revenue,
    ROUND(SUM(sms_charges), 2) AS sms_revenue,
    ROUND(SUM(final_amount), 2) AS total_revenue,
    ROUND(SUM(CASE WHEN payment_status = 'paid' THEN final_amount ELSE 0 END), 2) AS collected_revenue,
    ROUND(SUM(CASE WHEN payment_status IN ('pending', 'overdue') THEN final_amount ELSE 0 END), 2) AS outstanding_revenue
FROM billing
GROUP BY DATE_FORMAT(billing_month, '%Y-%m')
ORDER BY month DESC;

-- 2.2 Revenue by Plan Type
SELECT 
    p.plan_type,
    p.plan_name,
    COUNT(DISTINCT b.subscriber_id) AS subscribers,
    ROUND(AVG(b.final_amount), 2) AS avg_monthly_revenue_per_user,
    ROUND(SUM(b.final_amount), 2) AS total_revenue
FROM billing b
JOIN subscribers s ON b.subscriber_id = s.subscriber_id
JOIN plans p ON s.plan_id = p.plan_id
WHERE b.payment_status = 'paid'
GROUP BY p.plan_type, p.plan_name
ORDER BY total_revenue DESC;

-- 2.3 Payment Collection Rate
SELECT 
    DATE_FORMAT(billing_month, '%Y-%m') AS month,
    COUNT(*) AS total_bills,
    SUM(CASE WHEN payment_status = 'paid' THEN 1 ELSE 0 END) AS paid_bills,
    ROUND(SUM(CASE WHEN payment_status = 'paid' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS collection_rate_pct,
    ROUND(SUM(final_amount), 2) AS billed_amount,
    ROUND(SUM(CASE WHEN payment_status = 'paid' THEN final_amount ELSE 0 END), 2) AS collected_amount
FROM billing
GROUP BY DATE_FORMAT(billing_month, '%Y-%m')
ORDER BY month DESC;

-- ================================================
-- SECTION 3: NETWORK PERFORMANCE
-- ================================================

-- 3.1 Tower Utilization Analysis
SELECT 
    t.tower_id,
    t.tower_name,
    t.city,
    t.technology,
    t.capacity,
    COUNT(DISTINCT c.cdr_id) AS total_calls,
    ROUND(COUNT(DISTINCT c.cdr_id) * 100.0 / t.capacity, 2) AS utilization_rate_pct,
    COUNT(CASE WHEN c.call_status = 'failed' THEN 1 END) AS failed_calls,
    ROUND(COUNT(CASE WHEN c.call_status = 'failed' THEN 1 END) * 100.0 / COUNT(*), 2) AS failure_rate_pct
FROM network_towers t
LEFT JOIN call_records c ON t.tower_id = c.tower_id
WHERE t.is_active = TRUE
GROUP BY t.tower_id, t.tower_name, t.city, t.technology, t.capacity
ORDER BY total_calls DESC
LIMIT 20;

-- 3.2 Network Technology Distribution
SELECT 
    t.technology,
    COUNT(t.tower_id) AS tower_count,
    COUNT(DISTINCT c.caller_id) AS unique_users,
    COUNT(c.cdr_id) AS total_calls,
    ROUND(AVG(c.call_duration_seconds) / 60, 2) AS avg_call_minutes
FROM network_towers t
LEFT JOIN call_records c ON t.tower_id = c.tower_id
GROUP BY t.technology
ORDER BY tower_count DESC;

-- 3.3 Peak Usage Hours
SELECT 
    HOUR(call_start_time) AS hour_of_day,
    COUNT(*) AS total_calls,
    ROUND(AVG(call_duration_seconds) / 60, 2) AS avg_duration_minutes,
    COUNT(CASE WHEN call_status = 'completed' THEN 1 END) AS completed_calls,
    COUNT(CASE WHEN call_status = 'failed' THEN 1 END) AS failed_calls
FROM call_records
GROUP BY HOUR(call_start_time)
ORDER BY hour_of_day;

-- ================================================
-- SECTION 4: DATA USAGE ANALYTICS
-- ================================================

-- 4.1 Top Data Consumers
SELECT 
    s.subscriber_id,
    s.phone_number,
    CONCAT(s.first_name, ' ', s.last_name) AS full_name,
    p.plan_name,
    p.included_data_gb,
    ROUND(SUM(d.data_consumed_mb) / 1024, 2) AS total_data_gb,
    COUNT(d.usage_id) AS total_sessions,
    ROUND(AVG(d.data_consumed_mb), 2) AS avg_session_mb
FROM subscribers s
JOIN data_usage d ON s.subscriber_id = d.subscriber_id
JOIN plans p ON s.plan_id = p.plan_id
GROUP BY s.subscriber_id, s.phone_number, s.first_name, s.last_name, p.plan_name, p.included_data_gb
ORDER BY total_data_gb DESC
LIMIT 10;

-- 4.2 Data Usage by Service Type
SELECT 
    service_type,
    COUNT(usage_id) AS total_sessions,
    ROUND(SUM(data_consumed_mb) / 1024, 2) AS total_data_gb,
    ROUND(AVG(data_consumed_mb), 2) AS avg_session_mb,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, session_start, session_end)), 2) AS avg_duration_minutes
FROM data_usage
GROUP BY service_type
ORDER BY total_data_gb DESC;

-- 4.3 Daily Data Consumption Trend
SELECT 
    DATE(session_start) AS date,
    ROUND(SUM(data_consumed_mb) / 1024, 2) AS total_data_gb,
    COUNT(DISTINCT subscriber_id) AS unique_users,
    COUNT(usage_id) AS total_sessions
FROM data_usage
GROUP BY DATE(session_start)
ORDER BY date DESC
LIMIT 30;

-- ================================================
-- SECTION 5: FRAUD DETECTION
-- ================================================

-- 5.1 Suspicious SIM Swap Activity
-- Users with multiple SIM swaps in short period
SELECT 
    s.subscriber_id,
    s.phone_number,
    CONCAT(s.first_name, ' ', s.last_name) AS full_name,
    COUNT(ss.swap_id) AS total_swaps,
    MIN(ss.swap_date) AS first_swap,
    MAX(ss.swap_date) AS last_swap,
    DATEDIFF(MAX(ss.swap_date), MIN(ss.swap_date)) AS days_between_swaps
FROM subscribers s
JOIN sim_swap_history ss ON s.subscriber_id = ss.subscriber_id
GROUP BY s.subscriber_id, s.phone_number, s.first_name, s.last_name
HAVING total_swaps >= 2
ORDER BY total_swaps DESC, days_between_swaps ASC;

-- 5.2 Unusual Call Patterns (Potential Fraud)
-- Users making calls from multiple distant towers simultaneously
SELECT 
    c1.caller_id,
    s.phone_number,
    CONCAT(s.first_name, ' ', s.last_name) AS full_name,
    c1.call_start_time,
    t1.city AS tower1_city,
    t2.city AS tower2_city,
    t1.tower_name AS tower1,
    t2.tower_name AS tower2
FROM call_records c1
JOIN call_records c2 ON c1.caller_id = c2.caller_id 
    AND c1.cdr_id != c2.cdr_id
    AND ABS(TIMESTAMPDIFF(MINUTE, c1.call_start_time, c2.call_start_time)) <= 5
JOIN network_towers t1 ON c1.tower_id = t1.tower_id
JOIN network_towers t2 ON c2.tower_id = t2.tower_id
JOIN subscribers s ON c1.caller_id = s.subscriber_id
WHERE t1.city != t2.city
LIMIT 20;

-- 5.3 Abnormal Spending Pattern
-- Users whose monthly bill is >300% higher than previous month
SELECT 
    b1.subscriber_id,
    s.phone_number,
    CONCAT(s.first_name, ' ', s.last_name) AS full_name,
    DATE_FORMAT(b1.billing_month, '%Y-%m') AS current_month,
    b1.final_amount AS current_bill,
    DATE_FORMAT(b2.billing_month, '%Y-%m') AS previous_month,
    b2.final_amount AS previous_bill,
    ROUND((b1.final_amount - b2.final_amount) * 100.0 / b2.final_amount, 2) AS increase_pct
FROM billing b1
JOIN billing b2 ON b1.subscriber_id = b2.subscriber_id 
    AND b2.billing_month = DATE_SUB(b1.billing_month, INTERVAL 1 MONTH)
JOIN subscribers s ON b1.subscriber_id = s.subscriber_id
WHERE b1.final_amount > b2.final_amount * 3
    AND b2.final_amount > 0
ORDER BY increase_pct DESC
LIMIT 20;

-- ================================================
-- SECTION 6: CUSTOMER SEGMENTATION
-- ================================================

-- 6.1 Customer Value Segmentation
WITH customer_metrics AS (
    SELECT 
        s.subscriber_id,
        s.phone_number,
        CONCAT(s.first_name, ' ', s.last_name) AS full_name,
        AVG(b.final_amount) AS avg_monthly_revenue,
        DATEDIFF(CURDATE(), s.activation_date) AS customer_lifetime_days,
        COUNT(DISTINCT b.bill_id) AS billing_cycles
    FROM subscribers s
    LEFT JOIN billing b ON s.subscriber_id = b.subscriber_id
    WHERE s.status = 'active'
    GROUP BY s.subscriber_id, s.phone_number, s.first_name, s.last_name, s.activation_date
)
SELECT 
    CASE 
        WHEN avg_monthly_revenue >= 300000 THEN 'Premium'
        WHEN avg_monthly_revenue >= 150000 THEN 'High Value'
        WHEN avg_monthly_revenue >= 75000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(avg_monthly_revenue), 2) AS avg_revenue,
    ROUND(AVG(customer_lifetime_days), 0) AS avg_lifetime_days
FROM customer_metrics
GROUP BY customer_segment
ORDER BY avg_revenue DESC;

-- ================================================
-- SECTION 7: OPERATIONAL INSIGHTS
-- ================================================

-- 7.1 Call Success Rate by Hour
SELECT 
    HOUR(call_start_time) AS hour,
    COUNT(*) AS total_calls,
    SUM(CASE WHEN call_status = 'completed' THEN 1 ELSE 0 END) AS completed_calls,
    ROUND(SUM(CASE WHEN call_status = 'completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS success_rate_pct
FROM call_records
GROUP BY HOUR(call_start_time)
ORDER BY hour;

-- 7.2 Geographic Distribution
SELECT 
    s.province,
    COUNT(DISTINCT s.subscriber_id) AS total_subscribers,
    COUNT(DISTINCT t.tower_id) AS towers_in_province,
    COUNT(c.cdr_id) AS total_calls,
    ROUND(AVG(b.final_amount), 2) AS avg_monthly_bill
FROM subscribers s
LEFT JOIN call_records c ON s.subscriber_id = c.caller_id
LEFT JOIN billing b ON s.subscriber_id = b.subscriber_id
LEFT JOIN network_towers t ON s.province = t.province
WHERE s.status = 'active'
GROUP BY s.province
ORDER BY total_subscribers DESC;

-- 7.3 Prepaid vs Postpaid Performance
SELECT 
    p.plan_type,
    COUNT(DISTINCT s.subscriber_id) AS total_subscribers,
    ROUND(AVG(CASE WHEN p.plan_type = 'prepaid' THEN s.account_balance ELSE 0 END), 2) AS avg_prepaid_balance,
    ROUND(AVG(b.final_amount), 2) AS avg_monthly_bill,
    ROUND(SUM(b.final_amount), 2) AS total_revenue
FROM subscribers s
JOIN plans p ON s.plan_id = p.plan_id
LEFT JOIN billing b ON s.subscriber_id = b.subscriber_id
WHERE s.status = 'active'
GROUP BY p.plan_type;

-- ================================================
-- SECTION 8: ADVANCED ANALYTICS
-- ================================================

-- 8.1 Customer Lifetime Value (CLV) Estimation
SELECT 
    s.subscriber_id,
    s.phone_number,
    CONCAT(s.first_name, ' ', s.last_name) AS full_name,
    DATEDIFF(CURDATE(), s.activation_date) AS days_active,
    COUNT(DISTINCT b.bill_id) AS total_bills,
    ROUND(SUM(b.final_amount), 2) AS total_revenue,
    ROUND(AVG(b.final_amount), 2) AS avg_monthly_revenue,
    ROUND(SUM(b.final_amount) * (365.0 / DATEDIFF(CURDATE(), s.activation_date)), 2) AS estimated_annual_value
FROM subscribers s
JOIN billing b ON s.subscriber_id = b.subscriber_id
WHERE s.status = 'active' 
    AND b.payment_status = 'paid'
    AND DATEDIFF(CURDATE(), s.activation_date) > 30
GROUP BY s.subscriber_id, s.phone_number, s.first_name, s.last_name, s.activation_date
ORDER BY estimated_annual_value DESC
LIMIT 10;

-- 8.2 Roaming Revenue Analysis
SELECT 
    DATE_FORMAT(c.call_start_time, '%Y-%m') AS month,
    COUNT(CASE WHEN c.is_roaming = TRUE THEN 1 END) AS roaming_calls,
    COUNT(CASE WHEN c.is_roaming = FALSE THEN 1 END) AS domestic_calls,
    ROUND(SUM(CASE WHEN c.is_roaming = TRUE THEN c.cost ELSE 0 END), 2) AS roaming_revenue,
    ROUND(SUM(CASE WHEN c.is_roaming = FALSE THEN c.cost ELSE 0 END), 2) AS domestic_revenue,
    ROUND(SUM(CASE WHEN c.is_roaming = TRUE THEN c.cost ELSE 0 END) * 100.0 / SUM(c.cost), 2) AS roaming_revenue_pct
FROM call_records c
WHERE c.call_status = 'completed'
GROUP BY DATE_FORMAT(c.call_start_time, '%Y-%m')
ORDER BY month DESC;

-- ================================================
-- END OF QUERIES
-- ================================================
