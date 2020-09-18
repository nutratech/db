#!/bin/bash

cd "$(dirname "$0")"
source .env

sudo chown -R $LOGNAME:$LOGNAME /var/run/postgresql
pg_ctl -D $PSQL_DB_DIR stop
