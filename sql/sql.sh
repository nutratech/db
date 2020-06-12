#!/bin/bash

cd "$(dirname "$0")"
source .env


# Init db (not required every time)
sudo chown -R $LOGNAME:$LOGNAME /var/run/postgresql
pg_ctl initdb -D $PSQL_LOCAL_DB_DIR -l $PSQL_LOCAL_DB_DIR/postgreslogfile || true
pg_ctl -D $PSQL_LOCAL_DB_DIR -l $PSQL_LOCAL_DB_DIR/postgreslogfile start || true

# Create db, set our search_path, other things
psql -c "CREATE DATABASE $PSQL_DB_NAME;" postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/postgres || true
psql -c "\encoding UTF8" postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/$PSQL_DB_NAME || true
psql -c "UPDATE pg_database SET encoding=pg_char_to_encoding('UTF8') WHERE datname='$PSQL_DB_NAME';" postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/postgres || true
psql -c "ALTER ROLE $PSQL_USER SET search_path TO $PSQL_SCHEMA_NAME;" postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/$PSQL_DB_NAME || true

# Start the server
psql postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/$PSQL_DB_NAME
