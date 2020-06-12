#!/bin/bash

cd "$(dirname "$0")"
source .env

# Remove old instance
pg_ctl -D $PSQL_DB_DIR -l $PSQL_DB_DIR/pg.log stop
rm -rf ~/.pgsql/nutra

# Init db (not required every time)
mkdir -p ~/.pgsql/nutra
sudo chown -R $LOGNAME:$LOGNAME /var/run/postgresql
pg_ctl initdb -D $PSQL_DB_DIR -l $PSQL_DB_DIR/postgreslogfile

# Start db (needed for remainder of onboarding)
pg_ctl -D $PSQL_DB_DIR -l $PSQL_DB_DIR/pg.log start



# Create db, configure encoding
psql -c "DROP DATABASE IF EXISTS $PSQL_DB_NAME;" postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/postgres || true
psql -c "CREATE DATABASE $PSQL_DB_NAME;" postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/postgres || true
psql -c "\encoding UTF8" postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/$PSQL_DB_NAME || true
psql -c "UPDATE pg_database SET encoding=pg_char_to_encoding('UTF8') WHERE datname='$PSQL_DB_NAME';" postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/postgres || true

# Create schema and tables, set search_path
psql -c "\i tables.sql" postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/$PSQL_DB_NAME || true
psql -c "ALTER ROLE $PSQL_USER SET search_path TO $PSQL_SCHEMA_NAME;" postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/$PSQL_DB_NAME || true
