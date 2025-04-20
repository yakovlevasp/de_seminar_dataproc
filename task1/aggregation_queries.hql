-- 1. Фильтрация валют и агрегация
SELECT
    currency,
    COUNT(*) as transaction_count,
    SUM(amount) as total_amount,
    AVG(amount) as avg_amount
FROM user_transactions.transactions_v2
WHERE currency IN ('USD', 'EUR', 'RUB')
GROUP BY currency;

-- 2. Анализ мошеннических транзакций
SELECT
    CASE is_fraud WHEN 1 THEN 'fraud' ELSE 'normal' END as fraud_status,
    COUNT(*) as transaction_count,
    SUM(amount) as total_amount,
    AVG(amount) as avg_amount
FROM user_transactions.transactions_v2
GROUP BY is_fraud;

-- 3. Ежедневная статистика
SELECT
    DATE(transaction_date) as day,
    COUNT(*) as daily_count,
    SUM(amount) as daily_amount,
    AVG(amount) as avg_daily_amount
FROM user_transactions.transactions_v2
GROUP BY DATE(transaction_date)
ORDER BY day DESC;

-- 4. Анализ по временным интервалам
SELECT
    HOUR(transaction_date) as hour_of_day,
    COUNT(*) as transaction_count,
    SUM(CASE WHEN is_fraud = 1 THEN 1 ELSE 0 END) as fraud_count
FROM user_transactions.transactions_v2
GROUP BY HOUR(transaction_date)
ORDER BY hour_of_day;

-- 5. JOIN с логами и анализ категорий
SELECT
    l.category as category,
    COUNT(DISTINCT t.transaction_id) as transaction_count,
    COUNT(l.log_id) as log_entries,
    AVG(t.amount) as avg_amount,
    SUM(CASE WHEN t.is_fraud = 1 THEN 1 ELSE 0 END) as fraud_count
FROM user_transactions.transactions_v2 t
JOIN user_transactions.logs_v2 l ON t.transaction_id = l.transaction_id
GROUP BY l.category
ORDER BY transaction_count DESC;