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
bash start-pg.sh
bash config-db.sh

# Run python setup script
python3 import.py

# Export data to CSV
python3 export.py

# To rebuild run these two
bash config-db.sh
python3 import.py
