# install linux deps
sudo apt install postgresql-client-common postgresql-12 postgresql-client-12 postgresql-server-dev-12

# optional
sudo apt install postgresql-autodoc

# export path in ~/.bashrc or ~/.profile
export PATH=$PATH:/usr/lib/postgresql/12/bin/

# Run in the following order
bash init-db.sh
bash start-pg.sh
bash config-db.sh
