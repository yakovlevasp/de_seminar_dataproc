-- Создание таблицы orders
CREATE TABLE orders
(
    order_id UInt32,
    user_email String,
    payment_status String,
    payment_method String,
    order_date DateTime,
    total_amount Float32,
    shipping_address String
)
ENGINE = S3(
    'https://storage.yandexcloud.net/task2-orders-bucket/orders.csv',
    'CSV'
)


-- Создание таблицы order_items
CREATE TABLE order_items
(
    order_id UInt32,
    product_code String,
    product_name String,
    quantity UInt8,
    price Float32,
    discount Float32
)
ENGINE = S3(
    'https://storage.yandexcloud.net/task2-orders-bucket/order_items.csv',
    'CSV'
)