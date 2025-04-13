CREATE DATABASE IF NOT EXISTS user_transactions;

-- Для CSV (transactions_v2)
CREATE EXTERNAL TABLE IF NOT EXISTS user_transactions.transactions_v2 (
    transaction_id STRING,
    user_id STRING,
    transaction_date TIMESTAMP,
    amount DOUBLE,
    currency STRING,
    category STRING,
    is_fraud INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 's3a://task1-transactions-bucket/transactions'
TBLPROPERTIES (
    'skip.header.line.count'='1',
    'serialization.null.format'=''
);

-- Для TXT (logs_v2)
CREATE EXTERNAL TABLE IF NOT EXISTS user_transactions.logs_v2 (
    log_id STRING,
    transaction_id STRING,
    user_id STRING,
    event_time TIMESTAMP,
    event_type STRING,
    ip_address STRING,
    device STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION 's3a://task1-transactions-bucket/logs'
TBLPROPERTIES ('serialization.null.format'='');