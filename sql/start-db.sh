#!/bin/bash

source .env

pg_ctl -D $PSQL_DB_DIR -l $PSQL_DB_DIR/pg.log start

