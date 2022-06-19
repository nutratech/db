#!/bin/bash

# Install requirements
sudo apt install \
	postgresql-client-common postgresql-12 postgresql-client-12 \
	postgresql-server-dev-12

# Register as startup service and start now (before reboot)
sudo systemctl enable postgresql
sudo update-rc.d postgresql enable
sudo systemctl start postgresql

# Set up the default user
sudo -u postgres psql -c "CREATE USER shane"
sudo -u postgres psql -c "ALTER USER shane PASSWORD 'password'"
sudo -u postgres psql -c "ALTER USER shane WITH SUPERUSER CREATEROLE CREATEDB REPLICATION BYPASSRLS"

# Set up the default database & schema
psql -d postgres -c "CREATE DATABASE nt"
psql -d postgres -c "CREATE schema nt"
psql -d postgres -c "ALTER DATABASE nt SET search_path TO nt"

# TODO: create tables & load data
