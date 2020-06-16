#
# Install deps (Linux)

sudo apt install postgresql-client-common postgresql-12 postgresql-client-12 postgresql-server-dev-12

# optional
sudo apt install postgresql-autodoc

# Add line to ~/.bashrc or ~/.profile
export PATH=$PATH:/usr/lib/postgresql/12/bin/



#
# Set up the database for the first time

bash init-db.sh
bash dbup.sh
bash config-db.sh

# NOTE: must run `dbup.sh` every computer reboot!

# Run python setup script [args = i, e, r .. import, export, rebuild]
./pg.py r

# Export data to CSV
./pg.py e

# To rebuild run
./pg.py r
