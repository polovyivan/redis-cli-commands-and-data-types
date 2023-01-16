#!/bin/bash

echo "########### Creating env variables ###########"
PAYMENT_TYPES=("VISA" "MASTERCARD" "DISCOVER" "AMEX" "CASH")
ROWS=100000
NUMBER_OF_CUSTOMERS=$((${ROWS} / 3))
echo "########### Numbers of customers is ${NUMBER_OF_CUSTOMERS} ###########"

SQL_SCRIPT_PATH=/tmp/sql/01-init-sql-script.sql

function getUUID() {
  UUID=($(cat /proc/sys/kernel/random/uuid))
}

function getDate() {
  DATE=$(date -d "$((${RANDOM_NUMBER} % 22 + 2000))-
                  $((${RANDOM_NUMBER} % 12 + 1))-
                  $((${RANDOM_NUMBER} % 28 + 1))
                  $((${RANDOM_NUMBER} % 23 + 1)):00:00" '+%Y-%m-%d %H:%M:%S')
}

function getPaymentType() {
  PAYMENT_TYPE=${PAYMENT_TYPES[${RANDOM_NUMBER} % ${#PAYMENT_TYPES[@]}]}
}

function getAmount() {
  AMOUNT=$((1 + ${RANDOM_NUMBER} % (200 - 1))).$((${RANDOM_NUMBER} % 99))
}

echo "########### Creating sql script file ###########"
echo "
DROP TABLE IF EXISTS purchase_transaction;

CREATE TABLE purchase_transaction (
id VARCHAR(36) PRIMARY KEY,
payment_type VARCHAR(20) NOT NULL,
amount DECIMAL(19,4),
customer_id VARCHAR(36),
created_at DATETIME NOT NULL
);
" >${SQL_SCRIPT_PATH}

if [ "${ROWS}" -gt 0 ]; then
  echo "########### Generating insert statement for ${ROWS} rows ###########"
  echo "INSERT INTO purchase_transaction VALUES" >>${SQL_SCRIPT_PATH}
fi

for ((i = ${NUMBER_OF_CUSTOMERS}; i >= 0; i--)); do
  RANDOM_NUMBER=$((RANDOM))

  if [ ${i} == 0 ]; then
    NUMBER_OF_TRANSACTIONS_FOR_CUSTOMER=${ROWS}
  else
    MAX_NUMBER_OF_TRANSACTION_PER_CUSTOMER=$((${ROWS} / ${i}))
    NUMBER_OF_TRANSACTIONS_FOR_CUSTOMER=$((${RANDOM_NUMBER} % ${MAX_NUMBER_OF_TRANSACTION_PER_CUSTOMER} + 2))
    ROWS=$((ROWS - NUMBER_OF_TRANSACTIONS_FOR_CUSTOMER))
  fi
  getUUID
  for ((j = 1; j <= ${NUMBER_OF_TRANSACTIONS_FOR_CUSTOMER}; j++)); do
    RANDOM_NUMBER=$((RANDOM))
    getPaymentType
    getAmount
    getDate
    if [ ${i} == 0 ] && [ ${j} == ${NUMBER_OF_TRANSACTIONS_FOR_CUSTOMER} ]; then
      LAST_CHAR=";"
    else
      LAST_CHAR=","
    fi
    echo "(uuid(),\"${PAYMENT_TYPE}\", \"${AMOUNT}\", \"${UUID}\", \"${DATE}\")${LAST_CHAR}" >>${SQL_SCRIPT_PATH}
  done
done

echo "########### Running SQL script against DB ###########"
mysql --user="customer_user" --password="customer_password" --database="customer" <${SQL_SCRIPT_PATH}

echo "########### Script execution finished! ###########"
