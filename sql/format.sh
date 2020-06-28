#!/bin/bash

pg_format -s 2 tables.sql -o tables.sql
pg_format -s 2 functions.sql -o functions.sql
