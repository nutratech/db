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

