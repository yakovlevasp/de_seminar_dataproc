"""
Скрипт для генерации тестовых данных
"""
from faker import Faker
import csv
import random
from datetime import datetime, timedelta

fake = Faker()

# Генерация согласованных данных
users = [fake.uuid4() for _ in range(50)]
currencies = ['USD', 'EUR', 'RUB', 'GBP', 'JPY']
categories = ['food', 'electronics', 'clothing', 'services', 'home']

# Transactions (CSV)
with open('./data/transactions_v2.csv', 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['transaction_id', 'user_id', 'transaction_date', 'amount', 'currency', 'category', 'is_fraud'])

    for i in range(1000):
        user_id = random.choice(users)
        is_fraud = random.choices([0, 1], weights=[0.95, 0.05])[0]
        writer.writerow([
            f'txn_{i:04d}',
            user_id,
            fake.date_time_between(end_date='now', start_date='-30d').strftime('%Y-%m-%d %H:%M:%S'),
            round(random.uniform(1, 1000), 2),
            random.choice(currencies),
            random.choice(categories),
            is_fraud
        ])

# Logs (TXT) - согласованные с transactions
with open('./data/logs_v2.txt', 'w', newline='') as f:
    for i in range(2000):
        transaction_id = f'txn_{random.randint(0, 999):04d}'
        f.write(f"{fake.uuid4()}\t{transaction_id}\t{random.choice(users)}\t"
                f"{(datetime.now() - timedelta(minutes=random.randint(0, 1440))).strftime('%Y-%m-%d %H:%M:%S')}\t"
                f"{random.choice(['login', 'purchase', 'view', 'logout'])}\t"
                f"{fake.ipv4()}\t{fake.user_agent()}\n")
