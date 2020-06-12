#!/bin/bash -e

cd "$(dirname "$0")"
source .env
cd ../data/csv/nt

# Export each table
psql -Atc "select tablename from pg_tables where schemaname='$PSQL_SCHEMA_NAME'" postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/$PSQL_DB_NAME |\
  while read TBL; do
    echo $TBL
    psql -c "COPY $PSQL_SCHEMA_NAME.$TBL TO stdout WITH csv HEADER" postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/$PSQL_DB_NAME > $TBL.csv
  done
