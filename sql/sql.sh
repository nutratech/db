#!/bin/bash

cd "$(dirname "$0")"
source .env

# Connect to DB
psql postgresql://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST:5432/$PSQL_DB_NAME
