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
    o.user_id,
    o.payment_status,
    COUNT(oi.order_id) AS products_count,
    SUM(oi.quantity * oi.product_price) AS order_total,
    ROUND(AVG(oi.product_price), 2) AS avg_product_price
FROM
    orders o
JOIN
    order_items oi ON o.order_id = oi.order_id
GROUP BY
    o.order_id, o.user_id, o.payment_status
ORDER BY
    order_total DESC

-- 3. Статистика по датам (за день)
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
    user_id,
    SUM(total_amount) AS total_spent,
    ROUND(AVG(total_amount), 2) AS avg_order_amount
FROM orders
GROUP BY user_id
ORDER BY total_spent DESC

-- По количеству заказов
SELECT
    user_id,
    COUNT(*) AS orders_count,
    ROUND(AVG(total_amount), 2) AS avg_order_amount
FROM orders
GROUP BY user_id
ORDER BY orders_count DESC