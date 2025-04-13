-- 1. Группировка по payment_status
SELECT
    payment_status,
    COUNT(*) AS orders_count,
    SUM(total_amount) AS total_amount_sum,
    ROUND(AVG(total_amount), 2) AS avg_order_amount
FROM orders
GROUP BY payment_status
ORDER BY orders_count DESC;

-- 2. JOIN с order_items и подсчет сумм
SELECT
    o.order_id,
    o.user_email,
    o.payment_status,
    COUNT(oi.product_code) AS products_count,
    -- Сумма с учетом скидки (итоговая сумма заказа)
    SUM(oi.quantity * oi.price * (1 - oi.discount)) AS order_total_with_discount,
    -- Сумма БЕЗ учета скидки (полная стоимость товаров)
    SUM(oi.quantity * oi.price) AS order_total_without_discount,
    -- Общая сумма скидок
    SUM(oi.quantity * oi.price * oi.discount) AS total_discount_amount,
    -- Средняя цена товара с учетом скидки
    ROUND(AVG(oi.price * (1 - oi.discount)), 2) AS avg_product_price_with_discount,
    -- Средняя цена товара без скидки
    ROUND(AVG(oi.price), 2) AS avg_product_price,
    -- Средний размер скидки в процентах
    ROUND(AVG(oi.discount) * 100, 1) AS avg_discount_percent
FROM
    orders o
JOIN
    order_items oi ON o.order_id = oi.order_id
GROUP BY
    o.order_id, o.user_email, o.payment_status
ORDER BY
    order_total_with_discount DESC
LIMIT 20;

-- 3. Статистика по датам (за каждый день)
SELECT
    toDate(order_date) AS order_day,
    COUNT(*) AS orders_count,
    SUM(total_amount) AS daily_total_amount,
    ROUND(AVG(total_amount), 2) AS daily_avg_amount
FROM orders
GROUP BY order_day
ORDER BY order_day;

-- 4. Самые активные пользователи
-- По сумме заказов
SELECT
    user_email,
    SUM(total_amount) AS total_spent,
    ROUND(AVG(total_amount), 2) AS avg_order_amount
FROM orders
GROUP BY user_email
ORDER BY total_spent DESC
LIMIT 5;

-- По количеству заказов
SELECT
    user_email,
    COUNT(*) AS orders_count,
    ROUND(AVG(total_amount), 2) AS avg_order_amount
FROM orders
GROUP BY user_email
ORDER BY orders_count DESC
LIMIT 5;