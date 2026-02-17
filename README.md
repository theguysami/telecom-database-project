# 📡 Telecom Subscriber & CDR Management System

A comprehensive MySQL database project simulating real-world telecommunications operations — managing **800K+ records** across subscribers, call detail records (CDR), billing, network infrastructure, and analytics.

![MySQL](https://img.shields.io/badge/MySQL-8.0+-4479A1?style=flat&logo=mysql&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.8+-3776AB?style=flat&logo=python&logoColor=white)
![Records](https://img.shields.io/badge/Records-800K+-success)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen)

---

## 🎯 Project Overview

This project demonstrates database design and optimization skills for a telecom domain. It simulates operations of a mobile network operator similar to **Hamrah Aval (MCI)** — Iran's largest telecommunications company with 100M+ subscribers.

### What This System Handles:
- 📋 **Subscriber Management** — Customer profiles, plans, account status
- 📞 **Call Detail Records (CDR)** — Voice and video call tracking
- 🌐 **Data Usage** — Internet consumption monitoring
- 💳 **Billing** — Automated revenue calculation and payment tracking
- 📡 **Network Infrastructure** — Cell tower management and utilization
- 🔍 **Fraud Detection** — Suspicious activity identification
- 📊 **Analytics** — Revenue, churn, and operational insights

---

## 🗄️ Database Schema

### Tables Overview

| Table | Records | Description |
|-------|---------|-------------|
| `plans` | 15 | Subscription packages (prepaid/postpaid) |
| `network_towers` | 800 | Cell tower infrastructure (2G-5G) |
| `subscribers` | 50,000 | Customer master data |
| `call_records` | 350,000 | CDR — all voice/video calls ⭐ |
| `data_usage` | 125,000 | Internet consumption sessions |
| `sms_records` | 75,000 | Text message logs |
| `billing` | 150,000 | Monthly bills (3 months) |
| `recharge_history` | 40,000 | Prepaid top-ups |
| `sim_swap_history` | 7,000 | SIM replacement audit trail |
| **TOTAL** | **~797,000** | |

### Entity Relationships

```
plans ──────────────────> subscribers <──── network_towers
                               │
            ┌──────────────────┼──────────────────┐
            │                  │                  │
            ▼                  ▼                  ▼
      call_records          billing          data_usage
      sms_records      recharge_history   sim_swap_history
```

---

## ✨ Key Features

### 🏗️ Database Design
- Normalized schema (3NF) with proper foreign keys
- ACID compliance using InnoDB engine
- Audit trails with timestamps on all tables
- Referential integrity enforcement

### ⚡ Performance Optimization
- Composite indexes for time-series queries
- Query optimization (EXPLAIN analysis)
- 70% query performance improvement demonstrated
- Partition strategy for large tables

### 📊 Business Intelligence
- Revenue analytics by plan, service type, and time period
- Customer segmentation (Premium / High / Medium / Low value)
- Churn risk identification
- Network performance monitoring
- Fraud detection patterns

### 🔍 Fraud Detection
- Suspicious SIM swap activity monitoring
- Simultaneous calls from distant towers (SIM cloning)
- Abnormal spending pattern detection

---

## 🛠️ Tech Stack

- **Database**: MySQL 8.0+
- **Data Generation**: Python 3.8+
  - `mysql-connector-python` — Database connectivity
- **Tools**: MySQL Workbench

---

## 🚀 Getting Started

### Prerequisites
- MySQL 8.0 or higher installed
- Python 3.8 or higher installed
- 500MB+ free disk space

### Step 1: Clone the Repository
```bash
git clone https://github.com/theguysami/telecom-database-project.git
cd telecom-database-project
```

### Step 2: Create the Database Schema
In MySQL Workbench:
- File → Open SQL Script → `schema/telecom_schema.sql`
- Execute (⚡ lightning bolt)

Or via command line:
```bash
mysql -u root -p < schema/telecom_schema.sql
```

### Step 3: Install Python Dependencies
```bash
pip install -r scripts/requirements.txt
```

### Step 4: Generate Sample Data
```bash
python scripts/generate_telecom_data.py
```
Enter your MySQL credentials when prompted.
⏱️ Data generation takes approximately **15-20 minutes**.

### Step 5: Verify Installation
```sql
USE telecom_db;
SHOW TABLES;
SELECT COUNT(*) FROM call_records; -- Should return ~350,000
```

---

## 💡 Sample Queries

### Top 10 Revenue-Generating Subscribers
```sql
SELECT 
    s.phone_number,
    CONCAT(s.first_name, ' ', s.last_name) AS full_name,
    ROUND(SUM(b.final_amount), 2) AS total_revenue
FROM subscribers s
JOIN billing b ON s.subscriber_id = b.subscriber_id
WHERE b.payment_status = 'paid'
GROUP BY s.subscriber_id
ORDER BY total_revenue DESC
LIMIT 10;
```

### Network Peak Hours
```sql
SELECT 
    HOUR(call_start_time) AS hour_of_day,
    COUNT(*) AS total_calls,
    ROUND(AVG(call_duration_seconds) / 60, 2) AS avg_minutes
FROM call_records
WHERE call_status = 'completed'
GROUP BY HOUR(call_start_time)
ORDER BY total_calls DESC;
```

### Fraud Detection — Suspicious SIM Swaps
```sql
SELECT 
    s.phone_number,
    CONCAT(s.first_name, ' ', s.last_name) AS full_name,
    COUNT(ss.swap_id) AS total_swaps,
    MAX(ss.swap_date) AS last_swap
FROM subscribers s
JOIN sim_swap_history ss ON s.subscriber_id = ss.subscriber_id
GROUP BY s.subscriber_id
HAVING total_swaps >= 2
ORDER BY total_swaps DESC;
```

> 📂 40+ business queries available in `queries/business_queries.sql`

---

## ⚡ Performance Optimization Example

### Before (Full Table Scan — Slow ❌)
```sql
-- Using DATE() function prevents index usage
SELECT COUNT(*) FROM call_records 
WHERE DATE(call_start_time) = '2024-12-01';
-- Execution time: ~850ms
```

### After (Index Used — Fast ✅)
```sql
-- Range condition uses the index directly
SELECT COUNT(*) FROM call_records 
WHERE call_start_time >= '2024-12-01 00:00:00' 
  AND call_start_time < '2024-12-02 00:00:00';
-- Execution time: ~120ms (7x faster!)
```

> 📂 Full optimization guide in `queries/performance_optimization.sql`

---

## 📁 Project Structure

```
telecom-database-project/
│
├── README.md
│
├── schema/
│   └── telecom_schema.sql          # Database DDL (9 tables, indexes, views)
│
├── scripts/
│   ├── generate_telecom_data.py    # Data generator (~800K records)
│   └── requirements.txt            # Python dependencies
│
├── queries/
│   ├── business_queries.sql        # 40+ analytics queries
│   └── performance_optimization.sql # Optimization techniques
│
└── docs/
    ├── DATABASE_OVERVIEW.md        # Schema documentation
    └── SETUP_INSTRUCTIONS.md       # Detailed setup guide
```

---

## 📊 Key Insights from the Data

- **Revenue**: Postpaid customers generate 65% of total revenue
- **Network**: 4G towers handle 80% of all traffic
- **Peak Hours**: 18:00–22:00 sees highest call volume
- **Data Usage**: Video streaming accounts for 40% of data consumption
- **Fraud**: ~0.8% of SIM swaps flagged as suspicious

---

## 🔮 Future Enhancements

- [ ] Table partitioning by month for `call_records`
- [ ] REST API layer for external data access
- [ ] Churn prediction using machine learning
- [ ] Real-time dashboard with Grafana
- [ ] Automated monthly billing stored procedure
- [ ] Docker containerization

---

## 👤 Author

**Sami**
- GitHub: [@theguysami](https://github.com/theguysami)

---

## 🎓 Skills Demonstrated

✅ Complex relational database schema design  
✅ Query optimization and indexing strategies  
✅ Business intelligence and analytics  
✅ Telecom domain knowledge  
✅ ETL / data generation with Python  
✅ Performance tuning and benchmarking  
✅ Fraud detection logic  
✅ Professional documentation  

---

⭐ **If you found this project helpful, consider giving it a star!**
