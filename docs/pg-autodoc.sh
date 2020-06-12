#!/bin/bash -e

cd "$(dirname "$0")"

DB=nutra

mkdir -p $DB
cd $DB

# Generate docs, convert DOT --> EPS
postgresql_autodoc -d $DB

# svg
dot -Tps $DB.dot -o $DB.eps
convert -flatten $DB.eps $DB.svg
# png
convert -flatten $DB.dot $DB.png

# Move up
mv $DB.svg ..
