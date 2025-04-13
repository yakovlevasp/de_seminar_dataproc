"""
Скрипт для генерации тестовых данных
"""
import csv
import random
import logging

from faker import Faker


fake = Faker()

def generate_data(num_orders=1000, num_products=200, num_users=100):
    """
    Генерирует тестовые данные для заказов и их элементов
    :param num_orders: количество заказов
    :param num_products: количество продуктов
    :param num_users: количество пользователей
    :return: данные заказов и их элементов
    """
    # Создаем списки возможных значений
    payment_statuses = ['paid', 'pending', 'failed', 'refunded']
    payment_methods = ['credit_card', 'paypal', 'bank_transfer', 'cash']
    products = [(f'PROD-{i:03d}', fake.catch_phrase()) for i in range(1, num_products+1)]

    # Генерируем пользователей
    users = [fake.unique.email() for _ in range(num_users)]

    # Генерируем данные
    orders = []
    order_items = []

    for order_id in range(1, num_orders+1):
        user = random.choice(users)
        order_date = fake.date_time_between(start_date='-30d', end_date='now')

        # Сначала генерируем items для заказа
        num_items = random.randint(1, 5)
        selected_products = random.sample(products, num_items)

        items_for_order = []
        total_amount = 0

        for product_code, product_name in selected_products:
            quantity = random.randint(1, 3)
            price = round(random.uniform(5, 150), 2)
            discount = round(random.uniform(0, 0.3), 2) if random.random() > 0.7 else 0

            item_total = quantity * price * (1 - discount)
            total_amount += item_total

            items_for_order.append({
                'order_id': order_id,
                'product_code': product_code,
                'product_name': product_name,
                'quantity': quantity,
                'price': price,
                'discount': discount
            })

        # Округляем итоговую сумму
        total_amount = round(total_amount, 2)

        # Создаем заказ
        orders.append({
            'order_id': order_id,
            'user_email': user,
            'payment_status': random.choice(payment_statuses),
            'payment_method': random.choice(payment_methods),
            'order_date': order_date.strftime('%Y-%m-%d %H:%M:%S'),
            'total_amount': total_amount,
            'shipping_address': fake.address().replace('\n', ', ')
        })

        # Добавляем items в общий список
        order_items.extend(items_for_order)

    return orders, order_items

def save_to_csv(filename, data, fieldnames):
    """
    Сохраняет данные в CSV-файл
    :param filename: имя файла для сохранения
    :param data: данные для записи
    :param fieldnames: поля для записи
    """
    with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(data)

def main():
    # Генерируем данные
    orders, order_items = generate_data()

    # Определяем заголовки для CSV
    orders_fields = [
        'order_id', 'user_email', 'payment_status', 'payment_method',
        'order_date', 'total_amount', 'shipping_address', 'phone_number'
    ]

    order_items_fields = [
        'order_id', 'product_code', 'product_name',
        'quantity', 'price', 'discount'
    ]

    # Сохраняем в CSV
    save_to_csv('./data/orders.csv', orders, orders_fields)
    save_to_csv('./data/order_items.csv', order_items, order_items_fields)

    logging.info(
        f"""Данные успешно сгенерированы:
        - orders.csv ({len(orders)} записей)
        - order_items.csv ({len(order_items)} записей)"""
    )

if __name__ == "__main__":
    main()