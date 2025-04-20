-- Создание таблицы orders
CREATE TABLE orders
(
    order_id UInt32,
    user_id UInt32,
    order_date DateTime,
    total_amount Float32,
    payment_status String
)
ENGINE = S3(
    'https://storage.yandexcloud.net/task-2-orders-bucket/orders.csv',
    'CSVWithNames'
)


-- Создание таблицы order_items
CREATE TABLE order_items
(
    item_id UInt32,
    order_id UInt32,
    product_name String,
    product_price Float32,
    quantity UInt32
)
ENGINE = S3(
    'https://storage.yandexcloud.net/task-2-orders-bucket/order_items.txt',
    'CSVWithNames'
)
SETTINGS
    format_csv_delimiter = ';'