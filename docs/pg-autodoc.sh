#!/bin/bash

set -x
set -e

cd "$(dirname "$0")"

#source ../sql/.env

DB=nt
SCHEMA=nt

rm -rf $DB
mkdir -p $DB
cd $DB

# Generate docs
postgresql_autodoc \
	-h localhost \
	-u $LOGNAME \
	--password=password \
	-d $DB \
	-f $SCHEMA \
	-t dot

# convert DOT --> EPS
# convert EPS --> SVG
dot -Tps $DB.dot -o $DB.eps
epstopdf $DB.eps
pdf2svg $DB.pdf $DB.svg

# Move up
mv $DB.svg ..
