#!/bin/bash

source .env

pg_ctl -D $PSQL_DB_DIR stop

