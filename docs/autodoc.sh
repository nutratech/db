#!/bin/bash

set -x
source .env

set -e

cd "$(dirname "$0")"

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

# Clean up unless otherwise specified in .env file
if [ "0" != "$NTDB_AUTODOC_CLEANUP" ]; then
	cd ..
	rm -rf $DB
fi
