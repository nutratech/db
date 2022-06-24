#!/bin/bash
set -x


# Install requirements
sudo apt install \
	postgresql-client-common postgresql postgresql-client libpq-dev

# optional installs
sudo apt install direnv python3-dev python3-venv

# Register as startup service and start now (before reboot)
sudo systemctl enable postgresql
sudo update-rc.d postgresql enable
sudo systemctl start postgresql

# Set up the default user
sudo -u postgres psql -c "CREATE USER shane"
sudo -u postgres psql -c "ALTER USER shane PASSWORD 'password'"
sudo -u postgres psql -c "ALTER USER shane WITH SUPERUSER CREATEROLE CREATEDB REPLICATION BYPASSRLS"


DB=nt
SCHEMA=nt
# Set up the default database & schema
psql -d postgres -c "CREATE DATABASE $DB"
psql -d $DB -c "CREATE SCHEMA $SCHEMA"
psql -d $DB -c "DROP SCHEMA public"
psql -d $DB -c "ALTER DATABASE $DB SET search_path TO $SCHEMA"
