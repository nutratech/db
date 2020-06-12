#!/bin/bash

cd "$(dirname "$0")"
source .env
cd ../data/csv/nt

# ------------------------------
# Import primary tables
# ------------------------------
declare -a ptables=("users" "nutr_def" "fdgrp" "data_src" "food_des" "serving_id" "products" "variants" "orders" "threads")
for table in "${ptables[@]}"
do
  echo $table
  psql -c "\copy $PSQL_SCHEMA_NAME.$table FROM '${table}.csv' WITH csv HEADER" postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/$PSQL_DB_NAME
done


# ------------------------------
# Import remaining tables
# ------------------------------
for filename in *.csv; do
  # https://stackoverflow.com/questions/12590490/splitting-filename-delimited-by-period
  table="${filename%%.*}"

  # Skip covered tables
  # https://stackoverflow.com/questions/3685970/check-if-a-bash-array-contains-a-value
  if [[ ! " ${ptables[@]} " =~ " ${table} " ]]; then
    echo $table
    cat "$filename" | psql -c "\copy $PSQL_SCHEMA_NAME.$table FROM $table.csv WITH csv HEADER" postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/$PSQL_DB_NAME
  fi
done


# ------------------------------
# Set serial maxes
# ------------------------------
declare -a itables=("users" "food_des" "serving_id" "recipe_des" "portion_id" "tag_id" "food_logs" "exercises" "exercise_logs" "orders" "reviews" "cart" "biometrics" "biometric_logs")
for table in "${itables[@]}"
do
  echo $table
  psql -c "SELECT pg_catalog.setval(pg_get_serial_sequence('$table', 'id'), (SELECT MAX(id) FROM $table))" postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/$PSQL_DB_NAME
done


# ------------------------------
# Set public floors
# ------------------------------
# food_des --> 10,000,000
psql -c "SELECT pg_catalog.setval(pg_get_serial_sequence('food_des', 'id'), 10000000)" postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/$PSQL_DB_NAME
