#!/usr/bin/env python3
"""
Telecom Database Data Generator
Generates realistic sample data for telecom_db
Target: ~500K records across all tables
"""

import mysql.connector
from mysql.connector import Error
import random
from datetime import datetime, timedelta
import sys

# ================================================
# PERSIAN NAMES (English Transliteration)
# Clean, consistent, professional - no mixed scripts!
# ================================================

PERSIAN_MALE_FIRST_NAMES = [
    'Ali', 'Mohammad', 'Hossein', 'Reza', 'Amir', 'Hassan', 'Mehdi',
    'Ahmad', 'Javad', 'Saeed', 'Hamid', 'Majid', 'Masoud', 'Alireza',
    'Mohammadreza', 'Hamed', 'Vahid', 'Karim', 'Shahram', 'Behnam',
    'Omid', 'Siavash', 'Babak', 'Farhad', 'Dariush', 'Kamran', 'Arash',
    'Navid', 'Pedram', 'Soroush', 'Milad', 'Pouya', 'Iman', 'Ehsan',
    'Morteza', 'Mostafa', 'Nima', 'Soheil', 'Shahin', 'Farshid'
]

PERSIAN_FEMALE_FIRST_NAMES = [
    'Sara', 'Maryam', 'Fateme', 'Zahra', 'Leila', 'Narges', 'Azadeh',
    'Shadi', 'Parisa', 'Nasrin', 'Mahnaz', 'Fatemeh', 'Zeinab', 'Sahar',
    'Negar', 'Sepideh', 'Bahar', 'Elnaz', 'Golnaz', 'Shirin',
    'Niloofar', 'Yasmin', 'Masoumeh', 'Sogand', 'Pantea', 'Roxana',
    'Sanaz', 'Mahsa', 'Arezoo', 'Nazanin', 'Kimia', 'Tara', 'Roya',
    'Sarina', 'Hana', 'Ghazaleh', 'Darya', 'Setareh', 'Melika', 'Baran'
]

PERSIAN_LAST_NAMES = [
    'Ahmadi', 'Hosseini', 'Mohammadi', 'Rezaei', 'Karimi', 'Moradi',
    'Mousavi', 'Rahimi', 'Jafari', 'Abbasi', 'Sadeghi', 'Tehrani',
    'Shirazi', 'Esfahani', 'Tabrizi', 'Mashhadi', 'Rashidi', 'Nazari',
    'Salimi', 'Hashemi', 'Bagheri', 'Rostami', 'Hajizadeh', 'Sultani',
    'Ghorbani', 'Safari', 'Kazemi', 'Nikpour', 'Amiri', 'Maleki',
    'Ebrahimi', 'Pourali', 'Zareei', 'Soleimani', 'Asadi', 'Nouri',
    'Kiani', 'Rajabi', 'Tavakoli', 'Mansouri', 'Mirzaei', 'Farahani',
    'Lotfi', 'Naseri', 'Shafiei', 'Azizi', 'Ghasemi', 'Yousefi',
    'Zamani', 'Shirali'
]

def get_random_persian_name():
    """Generate a random Persian full name (transliterated)"""
    gender = random.choice(['male', 'female'])
    if gender == 'male':
        first_name = random.choice(PERSIAN_MALE_FIRST_NAMES)
    else:
        first_name = random.choice(PERSIAN_FEMALE_FIRST_NAMES)
    last_name = random.choice(PERSIAN_LAST_NAMES)
    return first_name, last_name

# Configuration
CONFIG = {
    'num_plans': 15,
    'num_towers': 800,
    'num_subscribers': 50000,
    'num_calls': 350000,
    'num_data_sessions': 125000,
    'num_sms': 75000,
    'num_recharges': 40000,
    'num_sim_swaps': 7000,
}

# Iranian provinces and major cities
PROVINCES_CITIES = {
    'Tehran': ['Tehran', 'Rey', 'Shemiranat', 'Varamin'],
    'Isfahan': ['Isfahan', 'Kashan', 'Najafabad', 'Khomeini Shahr'],
    'Fars': ['Shiraz', 'Marvdasht', 'Kazerun', 'Jahrom'],
    'Khorasan Razavi': ['Mashhad', 'Neyshabur', 'Sabzevar', 'Torbat-e Heydarieh'],
    'Khuzestan': ['Ahvaz', 'Abadan', 'Khorramshahr', 'Dezful'],
    'East Azerbaijan': ['Tabriz', 'Maragheh', 'Marand', 'Bonab'],
    'Gilan': ['Rasht', 'Bandar Anzali', 'Lahijan', 'Langarud'],
    'Mazandaran': ['Sari', 'Babol', 'Amol', 'Qaem Shahr'],
    'Kerman': ['Kerman', 'Rafsanjan', 'Sirjan', 'Bam'],
    'West Azerbaijan': ['Urmia', 'Khoy', 'Mahabad', 'Miandoab'],
}

# Iranian mobile network prefixes (sample)
MOBILE_PREFIXES = ['0912', '0913', '0914', '0915', '0916', '0917', '0918', '0919',
                   '0910', '0911', '0921', '0922', '0932', '0933', '0934', '0935']

# Plan names
PLAN_NAMES = [
    'Basic Starter', 'Silver Package', 'Gold Premium', 'Platinum Elite',
    'Student Special', 'Family Bundle', 'Business Pro', 'Unlimited Plus',
    'Data Max', 'Talk & Text', 'Youth Package', 'Senior Saver',
    'Weekend Warrior', 'International Roam', 'Corporate Enterprise'
]

def create_connection(host, user, password, database):
    """Create MySQL database connection"""
    try:
        connection = mysql.connector.connect(
            host=host,
            user=user,
            password=password,
            database=database
        )
        if connection.is_connected():
            print(f"✓ Successfully connected to MySQL database: {database}")
            return connection
    except Error as e:
        print(f"✗ Error connecting to MySQL: {e}")
        sys.exit(1)

def generate_iranian_phone():
    """Generate realistic Iranian mobile phone number"""
    prefix = random.choice(MOBILE_PREFIXES)
    suffix = ''.join([str(random.randint(0, 9)) for _ in range(7)])
    return prefix + suffix

def generate_sim_card():
    """Generate SIM card number (ICCID format)"""
    return '89982' + ''.join([str(random.randint(0, 9)) for _ in range(15)])

def generate_national_id():
    """Generate Iranian national ID (10 digits)"""
    return ''.join([str(random.randint(0, 9)) for _ in range(10)])

def random_date(start_date, end_date):
    """Generate random date between start and end"""
    time_between = end_date - start_date
    days_between = time_between.days
    random_days = random.randrange(days_between)
    return start_date + timedelta(days=random_days)

def random_datetime(start_date, end_date):
    """Generate random datetime between start and end"""
    time_between = end_date - start_date
    seconds_between = time_between.total_seconds()
    random_seconds = random.randrange(int(seconds_between))
    return start_date + timedelta(seconds=random_seconds)

def insert_plans(cursor):
    """Insert subscription plans"""
    print("\n[1/9] Generating Plans...")
    plans_data = []
    
    for i, name in enumerate(PLAN_NAMES):
        plan_type = random.choice(['prepaid', 'postpaid'])
        monthly_fee = round(random.uniform(50000, 500000), 2)  # Iranian Rial
        included_minutes = random.choice([0, 100, 300, 500, 1000, 2000, 9999])
        included_data_gb = random.choice([0, 5, 10, 20, 50, 100, 999])
        included_sms = random.choice([0, 50, 100, 200, 500, 9999])
        
        plans_data.append((
            name, plan_type, monthly_fee, included_minutes, included_data_gb,
            included_sms, 0.50, 0.01, 0.10, True
        ))
    
    cursor.executemany("""
        INSERT INTO plans (plan_name, plan_type, monthly_fee, included_minutes,
                          included_data_gb, included_sms, overage_rate_per_minute,
                          overage_rate_per_mb, overage_rate_per_sms, is_active)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """, plans_data)
    
    print(f"  ✓ Inserted {len(plans_data)} plans")

def insert_towers(cursor, num_towers):
    """Insert network towers"""
    print(f"\n[2/9] Generating {num_towers} Network Towers...")
    towers_data = []
    
    for i in range(num_towers):
        province = random.choice(list(PROVINCES_CITIES.keys()))
        city = random.choice(PROVINCES_CITIES[province])
        
        # Realistic Iranian coordinates (approximate ranges)
        latitude = round(random.uniform(25.0, 40.0), 8)
        longitude = round(random.uniform(44.0, 63.0), 8)
        
        tower_name = f"{city}-Tower-{i+1:04d}"
        technology = random.choices(
            ['2G', '3G', '4G', '5G'],
            weights=[5, 15, 50, 30]  # More modern towers
        )[0]
        capacity = random.choice([500, 1000, 1500, 2000, 3000])
        installation_date = random_date(datetime(2015, 1, 1), datetime(2024, 12, 31))
        
        towers_data.append((
            tower_name, latitude, longitude, city, province,
            capacity, technology, True, installation_date
        ))
    
    cursor.executemany("""
        INSERT INTO network_towers (tower_name, latitude, longitude, city, province,
                                   capacity, technology, is_active, installation_date)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
    """, towers_data)
    
    print(f"  ✓ Inserted {len(towers_data)} towers")

def insert_subscribers(cursor, num_subscribers):
    """Insert subscribers"""
    print(f"\n[3/9] Generating {num_subscribers} Subscribers...")
    subscribers_data = []
    used_phones = set()
    used_national_ids = set()
    used_sim_cards = set()
    
    for i in range(num_subscribers):
        # Generate unique identifiers
        while True:
            phone = generate_iranian_phone()
            if phone not in used_phones:
                used_phones.add(phone)
                break
        
        while True:
            national_id = generate_national_id()
            if national_id not in used_national_ids:
                used_national_ids.add(national_id)
                break
        
        while True:
            sim_card = generate_sim_card()
            if sim_card not in used_sim_cards:
                used_sim_cards.add(sim_card)
                break
        
        # Use clean Persian names (English transliteration)
        first_name, last_name = get_random_persian_name()
        email = f"{first_name.lower()}.{last_name.lower()}{random.randint(1,999)}@{random.choice(['gmail', 'yahoo', 'outlook'])}.com"
        
        province = random.choice(list(PROVINCES_CITIES.keys()))
        city = random.choice(PROVINCES_CITIES[province])
        address = f"No.{random.randint(1,200)}, {random.choice(['Valiasr', 'Azadi', 'Enghelab', 'Imam', 'Shahid Beheshti', 'Hafez'])} St, {city}"
        
        # Age between 18-80
        dob = random_date(datetime(1944, 1, 1), datetime(2006, 12, 31))
        
        plan_id = random.randint(1, CONFIG['num_plans'])
        activation_date = random_date(datetime(2020, 1, 1), datetime(2024, 12, 31))
        
        status = random.choices(
            ['active', 'suspended', 'terminated'],
            weights=[90, 7, 3]
        )[0]
        
        # Prepaid users have balance
        account_balance = round(random.uniform(0, 500000), 2) if random.random() > 0.5 else 0
        
        subscribers_data.append((
            phone, first_name, last_name, email, national_id, dob,
            address, city, province, plan_id, sim_card, activation_date,
            status, account_balance
        ))
        
        # Progress indicator
        if (i + 1) % 10000 == 0:
            print(f"  ... {i + 1}/{num_subscribers} subscribers generated")
    
    # Batch insert
    batch_size = 1000
    for i in range(0, len(subscribers_data), batch_size):
        batch = subscribers_data[i:i+batch_size]
        cursor.executemany("""
            INSERT INTO subscribers (phone_number, first_name, last_name, email, national_id,
                                    date_of_birth, address, city, province, plan_id,
                                    sim_card_number, activation_date, status, account_balance)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, batch)
        print(f"  ... Inserted batch {i//batch_size + 1}/{(len(subscribers_data) + batch_size - 1)//batch_size}")
    
    print(f"  ✓ Inserted {len(subscribers_data)} subscribers")

def insert_call_records(cursor, num_calls):
    """Insert call detail records"""
    print(f"\n[4/9] Generating {num_calls} Call Records (this may take a while)...")
    
    # Get subscriber and tower IDs
    cursor.execute("SELECT subscriber_id FROM subscribers WHERE status = 'active'")
    subscriber_ids = [row[0] for row in cursor.fetchall()]
    
    cursor.execute("SELECT tower_id FROM network_towers WHERE is_active = TRUE")
    tower_ids = [row[0] for row in cursor.fetchall()]
    
    cursor.execute("SELECT phone_number FROM subscribers")
    all_phones = [row[0] for row in cursor.fetchall()]
    
    calls_data = []
    start_date = datetime(2024, 10, 1)
    end_date = datetime(2025, 1, 31)
    
    for i in range(num_calls):
        caller_id = random.choice(subscriber_ids)
        receiver_phone = random.choice(all_phones)
        call_type = random.choices(['voice', 'video'], weights=[85, 15])[0]
        call_direction = random.choice(['outgoing', 'incoming'])
        call_start_time = random_datetime(start_date, end_date)
        
        # Duration distribution (most calls short, some long)
        duration = int(random.expovariate(1/180))  # Average 3 minutes
        duration = min(duration, 7200)  # Cap at 2 hours
        
        tower_id = random.choice(tower_ids)
        call_status = random.choices(
            ['completed', 'failed', 'busy', 'no_answer'],
            weights=[80, 5, 8, 7]
        )[0]
        is_roaming = random.random() < 0.05  # 5% roaming
        
        # Calculate cost (simplified)
        cost = round(duration * 0.1, 2) if call_status == 'completed' else 0
        
        calls_data.append((
            caller_id, receiver_phone, call_type, call_direction, call_start_time,
            duration, tower_id, call_status, is_roaming, cost
        ))
        
        # Progress indicator
        if (i + 1) % 50000 == 0:
            print(f"  ... {i + 1}/{num_calls} calls generated")
    
    # Batch insert
    batch_size = 1000
    for i in range(0, len(calls_data), batch_size):
        batch = calls_data[i:i+batch_size]
        cursor.executemany("""
            INSERT INTO call_records (caller_id, receiver_phone, call_type, call_direction,
                                     call_start_time, call_duration_seconds, tower_id,
                                     call_status, is_roaming, cost)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, batch)
        print(f"  ... Inserted batch {i//batch_size + 1}/{(len(calls_data) + batch_size - 1)//batch_size}")
    
    print(f"  ✓ Inserted {len(calls_data)} call records")

def insert_data_usage(cursor, num_sessions):
    """Insert data usage sessions"""
    print(f"\n[5/9] Generating {num_sessions} Data Usage Sessions...")
    
    cursor.execute("SELECT subscriber_id FROM subscribers WHERE status = 'active'")
    subscriber_ids = [row[0] for row in cursor.fetchall()]
    
    cursor.execute("SELECT tower_id FROM network_towers WHERE is_active = TRUE")
    tower_ids = [row[0] for row in cursor.fetchall()]
    
    data_usage = []
    start_date = datetime(2024, 10, 1)
    end_date = datetime(2025, 1, 31)
    
    for i in range(num_sessions):
        subscriber_id = random.choice(subscriber_ids)
        session_start = random_datetime(start_date, end_date)
        
        # Session duration (minutes)
        duration_minutes = int(random.expovariate(1/30))  # Average 30 min
        duration_minutes = min(duration_minutes, 480)  # Cap at 8 hours
        session_end = session_start + timedelta(minutes=duration_minutes)
        
        # Data consumed (MB) - correlated with duration
        data_consumed = round(random.uniform(10, 500) * (duration_minutes / 30), 2)
        
        tower_id = random.choice(tower_ids)
        service_type = random.choices(
            ['web', 'video', 'social', 'gaming', 'other'],
            weights=[30, 40, 20, 5, 5]
        )[0]
        
        cost = round(data_consumed * 0.01, 2)
        
        data_usage.append((
            subscriber_id, session_start, session_end, data_consumed,
            tower_id, service_type, cost
        ))
        
        if (i + 1) % 25000 == 0:
            print(f"  ... {i + 1}/{num_sessions} sessions generated")
    
    # Batch insert
    batch_size = 1000
    for i in range(0, len(data_usage), batch_size):
        batch = data_usage[i:i+batch_size]
        cursor.executemany("""
            INSERT INTO data_usage (subscriber_id, session_start, session_end,
                                   data_consumed_mb, tower_id, service_type, cost)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, batch)
    
    print(f"  ✓ Inserted {len(data_usage)} data sessions")

def insert_sms_records(cursor, num_sms):
    """Insert SMS records"""
    print(f"\n[6/9] Generating {num_sms} SMS Records...")
    
    cursor.execute("SELECT subscriber_id FROM subscribers WHERE status = 'active'")
    subscriber_ids = [row[0] for row in cursor.fetchall()]
    
    cursor.execute("SELECT tower_id FROM network_towers WHERE is_active = TRUE")
    tower_ids = [row[0] for row in cursor.fetchall()]
    
    cursor.execute("SELECT phone_number FROM subscribers")
    all_phones = [row[0] for row in cursor.fetchall()]
    
    sms_data = []
    start_date = datetime(2024, 10, 1)
    end_date = datetime(2025, 1, 31)
    
    for i in range(num_sms):
        sender_id = random.choice(subscriber_ids)
        receiver_phone = random.choice(all_phones)
        message_type = random.choices(
            ['standard', 'promotional', 'transactional'],
            weights=[85, 10, 5]
        )[0]
        sent_time = random_datetime(start_date, end_date)
        delivery_status = random.choices(
            ['sent', 'delivered', 'failed'],
            weights=[5, 92, 3]
        )[0]
        tower_id = random.choice(tower_ids)
        cost = 0.10
        
        sms_data.append((
            sender_id, receiver_phone, message_type, sent_time,
            delivery_status, tower_id, cost
        ))
    
    # Batch insert
    batch_size = 1000
    for i in range(0, len(sms_data), batch_size):
        batch = sms_data[i:i+batch_size]
        cursor.executemany("""
            INSERT INTO sms_records (sender_id, receiver_phone, message_type, sent_time,
                                    delivery_status, tower_id, cost)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, batch)
    
    print(f"  ✓ Inserted {len(sms_data)} SMS records")

def insert_billing(cursor):
    """Insert billing records for last 3 months"""
    print(f"\n[7/9] Generating Billing Records...")
    
    cursor.execute("""
        SELECT subscriber_id, plan_id FROM subscribers WHERE status = 'active'
    """)
    active_subscribers = cursor.fetchall()
    
    cursor.execute("SELECT plan_id, monthly_fee FROM plans")
    plan_fees = {row[0]: row[1] for row in cursor.fetchall()}
    
    billing_data = []
    
    # Generate bills for last 3 months (Oct, Nov, Dec 2024)
    billing_months = [
        datetime(2024, 10, 1),
        datetime(2024, 11, 1),
        datetime(2024, 12, 1)
    ]
    
    for billing_month in billing_months:
        due_date = billing_month + timedelta(days=15)
        
        for subscriber_id, plan_id in active_subscribers:
            plan_fee = float(plan_fees[plan_id])
            
            # Random usage charges
            call_charges = round(random.uniform(0, 100000), 2)
            data_charges = round(random.uniform(0, 50000), 2)
            sms_charges = round(random.uniform(0, 10000), 2)
            
            total_amount = plan_fee + call_charges + data_charges + sms_charges
            tax_amount = round(total_amount * 0.09, 2)  # 9% tax
            final_amount = total_amount + tax_amount
            
            payment_status = random.choices(
                ['pending', 'paid', 'overdue', 'partial'],
                weights=[10, 75, 10, 5]
            )[0]
            
            payment_date = None
            payment_method = None
            if payment_status in ['paid', 'partial']:
                payment_date = billing_month + timedelta(days=random.randint(1, 20))
                payment_method = random.choice(['cash', 'card', 'bank_transfer', 'mobile_wallet'])
            
            billing_data.append((
                subscriber_id, billing_month, plan_fee, call_charges, data_charges,
                sms_charges, total_amount, tax_amount, final_amount, due_date,
                payment_status, payment_date, payment_method
            ))
    
    # Batch insert
    batch_size = 1000
    for i in range(0, len(billing_data), batch_size):
        batch = billing_data[i:i+batch_size]
        cursor.executemany("""
            INSERT INTO billing (subscriber_id, billing_month, plan_fee, call_charges,
                               data_charges, sms_charges, total_amount, tax_amount,
                               final_amount, due_date, payment_status, payment_date,
                               payment_method)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, batch)
        print(f"  ... Inserted batch {i//batch_size + 1}/{(len(billing_data) + batch_size - 1)//batch_size}")
    
    print(f"  ✓ Inserted {len(billing_data)} billing records")

def insert_recharge_history(cursor, num_recharges):
    """Insert recharge history for prepaid users"""
    print(f"\n[8/9] Generating {num_recharges} Recharge Records...")
    
    cursor.execute("""
        SELECT subscriber_id, account_balance 
        FROM subscribers 
        WHERE status = 'active' AND account_balance > 0
    """)
    prepaid_subscribers = cursor.fetchall()
    
    recharge_data = []
    start_date = datetime(2024, 10, 1)
    end_date = datetime(2025, 1, 31)
    
    for i in range(num_recharges):
        subscriber_id, current_balance = random.choice(prepaid_subscribers)
        current_balance = float(current_balance)  # Convert Decimal to float
        
        recharge_amount = random.choice([10000, 20000, 50000, 100000, 200000, 500000])
        recharge_method = random.choice(['card', 'mobile_wallet', 'bank', 'retailer'])
        recharge_time = random_datetime(start_date, end_date)
        
        previous_balance = round(random.uniform(0, current_balance), 2)
        new_balance = previous_balance + recharge_amount
        
        recharge_data.append((
            subscriber_id, recharge_amount, recharge_method, recharge_time,
            previous_balance, new_balance
        ))
    
    # Batch insert
    batch_size = 1000
    for i in range(0, len(recharge_data), batch_size):
        batch = recharge_data[i:i+batch_size]
        cursor.executemany("""
            INSERT INTO recharge_history (subscriber_id, recharge_amount, recharge_method,
                                         recharge_time, previous_balance, new_balance)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, batch)
    
    print(f"  ✓ Inserted {len(recharge_data)} recharge records")

def insert_sim_swaps(cursor, num_swaps):
    """Insert SIM swap history"""
    print(f"\n[9/9] Generating {num_swaps} SIM Swap Records...")
    
    cursor.execute("SELECT subscriber_id, sim_card_number FROM subscribers")
    subscribers = cursor.fetchall()
    
    swap_data = []
    start_date = datetime(2024, 1, 1)
    end_date = datetime(2025, 1, 31)
    
    used_sim_cards = set()
    
    for i in range(num_swaps):
        subscriber_id, old_sim = random.choice(subscribers)
        
        # Generate new unique SIM
        while True:
            new_sim = generate_sim_card()
            if new_sim not in used_sim_cards:
                used_sim_cards.add(new_sim)
                break
        
        swap_reason = random.choices(
            ['lost', 'damaged', 'upgrade', 'stolen', 'other'],
            weights=[30, 40, 15, 10, 5]
        )[0]
        
        swap_date = random_datetime(start_date, end_date)
        fn, ln = get_random_persian_name()
        verified_by = f"{fn} {ln}"
        verification_doc = f"DOC-{random.randint(10000, 99999)}"
        
        swap_data.append((
            subscriber_id, old_sim, new_sim, swap_reason, swap_date,
            verified_by, verification_doc
        ))
    
    cursor.executemany("""
        INSERT INTO sim_swap_history (subscriber_id, old_sim_card, new_sim_card,
                                     swap_reason, swap_date, verified_by,
                                     verification_document)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
    """, swap_data)
    
    print(f"  ✓ Inserted {len(swap_data)} SIM swap records")

def print_summary(cursor):
    """Print database statistics"""
    print("\n" + "="*60)
    print("DATABASE POPULATION SUMMARY")
    print("="*60)
    
    tables = [
        'plans', 'network_towers', 'subscribers', 'call_records',
        'data_usage', 'sms_records', 'billing', 'recharge_history',
        'sim_swap_history'
    ]
    
    total_records = 0
    for table in tables:
        cursor.execute(f"SELECT COUNT(*) FROM {table}")
        count = cursor.fetchone()[0]
        total_records += count
        print(f"  {table:.<30} {count:>10,} records")
    
    print("-"*60)
    print(f"  {'TOTAL':.<30} {total_records:>10,} records")
    print("="*60)
    
    # Database size
    cursor.execute("""
        SELECT 
            ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS size_mb
        FROM information_schema.TABLES
        WHERE table_schema = 'telecom_db'
    """)
    size = cursor.fetchone()[0]
    print(f"\n  Database Size: {size} MB")
    print("="*60)

def main():
    """Main execution function"""
    print("="*60)
    print("TELECOM DATABASE DATA GENERATOR")
    print("="*60)
    print("\nTarget Configuration:")
    for key, value in CONFIG.items():
        print(f"  {key}: {value:,}")
    print("="*60)
    
    # Get database credentials
    print("\n📋 MySQL Connection Setup")
    host = input("MySQL Host [localhost]: ").strip() or "localhost"
    user = input("MySQL User [root]: ").strip() or "root"
    password = input("MySQL Password: ").strip()
    database = "telecom_db"
    
    # Connect to database
    connection = create_connection(host, user, password, database)
    cursor = connection.cursor()
    
    try:
        # Disable foreign key checks for faster inserts
        cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
        
        # Generate data
        start_time = datetime.now()
        
        insert_plans(cursor)
        connection.commit()
        
        insert_towers(cursor, CONFIG['num_towers'])
        connection.commit()
        
        insert_subscribers(cursor, CONFIG['num_subscribers'])
        connection.commit()
        
        insert_call_records(cursor, CONFIG['num_calls'])
        connection.commit()
        
        insert_data_usage(cursor, CONFIG['num_data_sessions'])
        connection.commit()
        
        insert_sms_records(cursor, CONFIG['num_sms'])
        connection.commit()
        
        insert_billing(cursor)
        connection.commit()
        
        insert_recharge_history(cursor, CONFIG['num_recharges'])
        connection.commit()
        
        insert_sim_swaps(cursor, CONFIG['num_sim_swaps'])
        connection.commit()
        
        # Re-enable foreign key checks
        cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
        
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        
        # Print summary
        print_summary(cursor)
        
        print(f"\n⏱️  Total Execution Time: {duration:.2f} seconds ({duration/60:.2f} minutes)")
        print("\n✅ Data generation completed successfully!")
        print("\n💡 Next Steps:")
        print("   1. Open MySQL and run: USE telecom_db;")
        print("   2. Try sample queries (I'll provide these next)")
        print("   3. Check the data: SELECT * FROM subscribers LIMIT 10;")
        
    except Exception as e:
        print(f"\n✗ Error during data generation: {e}")
        connection.rollback()
        raise
    
    finally:
        cursor.close()
        connection.close()
        print("\n🔌 Database connection closed")

if __name__ == "__main__":
    main()
