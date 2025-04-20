CREATE DATABASE IF NOT EXISTS user_transactions;

-- transactions_v2
CREATE EXTERNAL TABLE IF NOT EXISTS user_transactions.transactions_v2 (
    transaction_id STRING,
    user_id STRING,
    amount DOUBLE,
    currency STRING,
    transaction_date TIMESTAMP,
    is_fraud INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 's3a://task1-transactions-bucket-b1gbmhga2f59uao8jrf0/transactions'
TBLPROPERTIES (
    'skip.header.line.count'='1',
    'serialization.null.format'=''
);

-- logs_v2
CREATE EXTERNAL TABLE IF NOT EXISTS user_transactions.logs_v2 (
    log_id STRING,
    transaction_id STRING,
    category STRING,
    comment STRING,
    log_timestamp TIMESTAMP
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ';'
STORED AS TEXTFILE
LOCATION 's3a://task1-transactions-bucket-b1gbmhga2f59uao8jrf0/logs/'
TBLPROPERTIES (
    'skip.header.line.count'='1',
    'serialization.null.format'=''
);