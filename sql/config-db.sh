#!/bin/bash

cd "$(dirname "$0")"
source .env

# Create db, configure encoding
psql -c "DROP DATABASE IF EXISTS $PSQL_DB_NAME;" postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/postgres
psql -c "CREATE DATABASE $PSQL_DB_NAME;" postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/postgres
psql -c "\encoding UTF8" postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/$PSQL_DB_NAME
psql -c "UPDATE pg_database SET encoding=pg_char_to_encoding('UTF8') WHERE datname='$PSQL_DB_NAME';" postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/postgres

# Create schema and tables, set search_path
# todo, create this (schema) in python script, and tables/functions and import rows?
psql -c "\i tables.sql" postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/$PSQL_DB_NAME
psql -c "\i functions.sql" postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/$PSQL_DB_NAME
psql -c "ALTER ROLE $PSQL_USER SET search_path TO $PSQL_SCHEMA_NAME;" postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/$PSQL_DB_NAME
