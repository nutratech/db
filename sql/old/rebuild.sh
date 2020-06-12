#!/bin/bash -e

cd "$(dirname "$0")"
source .env


# Create tables
psql -c "\i tables.sql" postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/$PSQL_DB_NAME

# Stored Procedures
psql -c "\i functions.sql" postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/$PSQL_DB_NAME

# Import data
bash import.sh
