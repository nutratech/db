#!/bin/bash

cd "$(dirname "$0")"
source .env

# Connect to DB
if [ $PSQL_HOST == 'localhost' ]
then
    psql postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/$PSQL_DB_NAME?options="--search_path%3d$PSQL_SCHEMA_NAME --jit%3doff"
else
    psql postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/$PSQL_DB_NAME?options=--search_path%3d$PSQL_SCHEMA_NAME
fi
