**********
 nutra-db
**********

.. image:: https://api.travis-ci.com/nutratech/ntdb.svg?branch=master
    :target: https://app.travis-ci.com/github/nutratech/ntdb

Python, SQL, CSV files & RST documentation for setting up the server database.

We also have a server, CLI, and two sqlite3 databases repositories.

Locally running PostgreSQL
##########################

**NOTE:** Many of these commands must be run out of the ``sql/`` folder.

Ubuntu
======

**NOTE:** This is available as a script too: ``sql/init-ubuntu.sh``.

I followed the instructions here to register it as a startup service.

https://askubuntu.com/questions/539187/how-to-make-postgres-start-automatically-on-boot

You can also start it immediately, without needing a reboot.

.. code-block:: bash

    sudo systemctl enable postgresql
    sudo update-rc.d postgresql enable

    # Start immediately
    sudo service postgresql start

Now you can create the ``nt`` database, and grant yourself access.

Log in as the ``postgres`` user to initialize your role and databases.

.. code-block:: bash

    # Step 1: Set up your role
    sudo -u postgres psql -c "CREATE USER $LOGNAME"
    sudo -u postgres psql -c "ALTER USER $LOGNAME PASSWORD 'password'"
    sudo -u postgres psql -c "ALTER USER $LOGNAME WITH LOGIN SUPERUSER CREATEROLE CREATEDB REPLICATION BYPASSRLS"
    sudo -u postgres psql -c "ALTER USER $LOGNAME VALID UNTIL 'infinity'"

    DB=nt
    SCHEMA=nt

    # Step 2: Set up your new database
    psql -d postgres -c "CREATE DATABASE $DB"

    # Step 3: Configure it
    psql -d $DB -c "CREATE SCHEMA $SCHEMA"
    psql -d $DB -c "DROP SCHEMA public"
    psql -d $DB -c "ALTER DATABASE $DB SET search_path TO $SCHEMA"

**NOTE:** This sets you a password. You may need a password to connect
with ``DataGrip``, or outside the local Unix socket context.

macOS
=====

I followed the instructions here.

https://stackoverflow.com/questions/7975556/how-can-i-start-postgresql-server-on-mac-os-x

PostgreSQL installed with ``brew`` will already create a user under your name
with appropriate permissions.
So you can skip **Step 1** from above (for Ubuntu). Just do steps 2 and 3.

The brew install script will output more useful information,
I recommend reading it and deciding if any of it is important or relevant to
your use case.

.. code-block:: bash

    # At the time of writing this, brew defaults to version 14.4
    #  e.g. on Monterey: postgresql--14.4.monterey.bottle.tar.gz
    brew install postgres

    # Start postgres, and register it as a startup service
    brew services start postgresql

Windows
=======

**NOTE:** This is not tested. I'm including a few resources for now, though.

You can search for "start postgres server as service in windows" for ideas.

https://www.delftstack.com/howto/postgres/start-postgres-server-windows/#use-services-msc-to-start-stop-a-postgresql-session-in-windows

https://stackoverflow.com/questions/36629963/how-can-i-start-postgresql-on-windows

https://stackoverflow.com/questions/70792159/start-postgres-as-service-on-windows

**NOTE:** I haven't included instructions for starting the PostgreSQL service
automatically on Windows.

Inserting Data & Configuring ``.env`` file
##########################################

Inside ``/sql`` folder, run this.
And update the variables as you see fit.

.. code-block:: bash

    cp .env.local .env

Rebuild the ``nt`` database with this.

**NOTE:** Must do this after DB update. Or if you want to build fresh

.. code-block:: bash

    python -m sql r

Verify your tables.

.. code-block:: psql

    \dt

.. code-block:: sql

    SELECT * FROM functions();
    SELECT * FROM version;

Now you can configure your ``.env`` file accordingly, or add the connection
in ``DataGrip`` or similar GUI tools.

**NOTE:** You may wish to create a separate ``nt_test`` schema which is
consumed by the server tests.
This will avoid having to repeatedly drop and rebuild local data.
Which is guaranteed to happen anyways, with frequent updates to the tables
and a lack of upgrade scripts in these early stages.

Tables (Relational Design)
##########################

See :code:`sql/tables.sql` for details.

This is frequently updated, see :code:`docs/` for more info.

.. image:: docs/nt.svg
