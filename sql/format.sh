#!/bin/bash

set -x
set -e

cd "$(dirname "$0")"

# Format tables & functions
pg_format -L -s 2 tables.sql >tables.formatted.sql
mv tables.formatted.sql tables.sql

pg_format -L -s 2 functions.sql >functions.formatted.sql
mv functions.formatted.sql functions.sql
