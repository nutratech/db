#!/bin/bash

source .env

sudo chown -R $LOGNAME:$LOGNAME /var/run/postgresql
pg_ctl -D $PSQL_DB_DIR -l $PSQL_DB_DIR/pg.log start

