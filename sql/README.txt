#
# Install deps (Linux)
sudo apt install postgresql-client-common postgresql-12 postgresql-client-12 postgresql-server-dev-12

# optional
sudo apt install postgresql-autodoc

# Add line to ~/.bashrc or ~/.profile
export PATH=$PATH:/usr/lib/postgresql/12/bin/


#
# Run in the following order

bash init-db.sh
bash start-pg.sh
bash config-db.sh

# Run python setup scripts
python3

>>> import pg
[Connected to Postgre DB]    postgresql://shane:@localhost:5432/nutra
[psql] USE SCHEMA nt;

>>>
