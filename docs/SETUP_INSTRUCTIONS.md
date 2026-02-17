# How to Run the Data Generator

## Step 1: Install Python Dependencies

Open Command Prompt (or PowerShell) and navigate to where you saved the files, then run:

```bash
pip install -r requirements.txt
```

Or install manually:
```bash
pip install mysql-connector-python Faker
```

## Step 2: Run the Generator

```bash
python generate_telecom_data.py
```

## Step 3: Enter Your MySQL Credentials

The script will ask for:
- **MySQL Host**: Just press Enter (defaults to localhost)
- **MySQL User**: Just press Enter (defaults to root)  
- **MySQL Password**: Enter your MySQL root password

## What Happens Next?

The script will:
1. Connect to your `telecom_db` database
2. Generate realistic data for all 9 tables
3. Show progress for each table
4. Display a summary when done

### Expected Runtime:
- **Plans**: < 1 second
- **Towers**: ~2-3 seconds
- **Subscribers**: ~2-3 minutes (50,000 records)
- **Call Records**: ~5-7 minutes (350,000 records) ⏰
- **Data Usage**: ~2-3 minutes (125,000 records)
- **SMS**: ~1-2 minutes (75,000 records)
- **Billing**: ~2-3 minutes (150,000 records)
- **Recharges**: ~1 minute (40,000 records)
- **SIM Swaps**: < 1 minute (7,000 records)

**Total Time**: ~15-20 minutes

## Troubleshooting

### Error: "No module named 'mysql'"
**Solution**: Run `pip install mysql-connector-python`

### Error: "Access denied for user"
**Solution**: Check your MySQL password is correct

### Error: "Unknown database 'telecom_db'"
**Solution**: Make sure you ran the `telecom_schema.sql` file first

### Script is slow
**This is normal!** Generating 800K records takes time. Grab a coffee ☕

## After It Completes

You'll see a summary like:
```
DATABASE POPULATION SUMMARY
============================================================
  plans........................         15 records
  network_towers...............        800 records
  subscribers..................     50,000 records
  call_records.................    350,000 records
  data_usage...................    125,000 records
  sms_records..................     75,000 records
  billing......................    150,000 records
  recharge_history.............     40,000 records
  sim_swap_history.............      7,000 records
------------------------------------------------------------
  TOTAL........................    797,815 records
============================================================

  Database Size: 156.42 MB
```

## What's Next?

Once data is loaded, I'll provide you with:
1. Sample business queries
2. Performance optimization examples
3. Analysis queries for your resume
4. Documentation for GitHub

Your database is now ready for querying! 🎉
