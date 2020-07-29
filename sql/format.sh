#!/bin/bash

cd "$(dirname "$0")"

pg_format -s 2 tables.sql -o tables.sql
pg_format -s 2 functions.sql -o functions.sql
