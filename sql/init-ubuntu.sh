#!/bin/bash
set -x

# Constants
DB=nt
SCHEMA=nt

# STEP 1
# Install requirements
sudo apt install \
	postgresql \
	postgresql-client-common \
	libpq-dev

# optional installs
sudo apt install \
	python3-dev \
	python3-venv \
	direnv \
	postgresql-autodoc

# STEP 2
# Register Postgres as a startup service & start now (before reboot)
sudo systemctl enable postgresql
sudo update-rc.d postgresql enable
sudo systemctl start postgresql

# STEP 3
# Set up your default user
sudo -u postgres psql -c "CREATE USER $LOGNAME"
sudo -u postgres psql -c "ALTER USER $LOGNAME WITH LOGIN SUPERUSER CREATEROLE CREATEDB REPLICATION BYPASSRLS"
psql -d template1 -c "ALTER USER $LOGNAME PASSWORD 'password'"
psql -d template1 -c "ALTER USER $LOGNAME VALID UNTIL 'infinity'"

# STEP 4
# Set up default database & schema
psql -d template1 -c "CREATE DATABASE $DB"
psql -d $DB -c "CREATE SCHEMA $SCHEMA"
psql -d $DB -c "DROP SCHEMA public"
psql -d $DB -c "ALTER DATABASE $DB SET search_path TO $SCHEMA"
