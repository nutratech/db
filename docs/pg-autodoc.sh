#!/bin/bash -ex

cd "$(dirname "$0")"

source ../sql/.env

DB=nt

rm -rf $DB
mkdir -p $DB
cd $DB

# Generate docs
if [ $PSQL_USER ]; then
	postgresql_autodoc \
		-d $PSQL_DB_NAME \
		-h $PSQL_HOST \
		-u $PSQL_USER \
		--password=$PSQL_PASSWORD \
		-f $DB \
		-t dot
else
	postgresql_autodoc \
		-d $PSQL_DB_NAME \
		-f $DB \
		-t dot
fi

# convert DOT --> EPS
# convert EPS --> SVG
dot -Tps $DB.dot -o $DB.eps
epstopdf $DB.eps
pdf2svg $DB.pdf $DB.svg

# Move up
mv $DB.svg ..
