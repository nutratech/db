#
# Install deps (Linux)

sudo apt install postgresql-client-common postgresql-12 postgresql-client-12 postgresql-server-dev-12

# optional
sudo apt install postgresql-autodoc

#
# Setting up DB
See the top-level README.rst for details on how to run postgres as a service,
and how to create the template database & import data.

#
# Importing, exporting, rebuilding (locally)
# Run python setup script [args = i, e, r .. import, export, rebuild]
./pg.py r

# Export data to CSV
./pg.py e

# To rebuild run
./pg.py r
