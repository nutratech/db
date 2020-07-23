#!/bin/bash

cd "$(dirname "$0")"


HEADERS="commit,username,author_date,commit_date,message"
(echo $HEADERS && git log --date=local --pretty=format:%h,%an,%ai,%ci,\"%s\") > ../data/csv/version.csv
