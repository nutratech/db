#!/bin/bash

set -x

cd "$(dirname "$0")"
source .env

set -e

# Define constants
DB=nt
SCHEMA=nt

# Clean up previous run
rm -rf $DB
mkdir -p $DB

# cd into specified directory
cd $DB

# Generate docs
postgresql_autodoc \
	-h localhost \
	-u $LOGNAME \
	--password=password \
	-d $DB \
	-f $SCHEMA \
	-t dot

# Generate PDF, HTML, etc
#  convert DOT --> EPS
#  convert EPS --> SVG
dot -Tps $DB.dot -o $DB.eps
epstopdf $DB.eps
pdf2svg $DB.pdf $DB.svg

# Move up
mv $DB.svg ..

# Clean up (unless otherwise specified in .env file)
if [ "0" != "$NTDB_AUTODOC_CLEANUP" ]; then
	cd ..
	rm -rf $DB
fi
