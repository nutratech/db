**********
 nutra-db
**********

.. image:: https://api.travis-ci.com/gamesguru/ntdb.svg?branch=master
    :target: https://travis-ci.com/gamesguru/ntdb

Python, SQL, CSV files & RST documentation for setting up the server database.

We also have a server, CLI, and two sqlite3 databases repositories.

Locally running PostgreSQL
##########################

Ubuntu
======

I followed the instructions here to register it as a startup service.

https://askubuntu.com/questions/539187/how-to-make-postgres-start-automatically-on-boot

You can also start it immediately, without needing a reboot.

.. code-block:: bash

    sudo systemctl enable postgresql
    sudo update-rc.d postgresql enable

    # Start immediately
    sudo service postgresql start

Now you can create the ``nt`` database, and grant yourself access.

Log in as the ``postgres`` user to manage your databases.

.. code-block:: bash

    # Enter a psql shell (as postgres user)
    sudo -u postgres psql

You should be running a shell such as ``postgres=#``.

Enter the following commands now.

.. code-block:: sql

    -- As the postgres user, run this.

    -- Grant yourself access; use your $LOGNAME in these steps
    CREATE USER shane;
    ALTER USER shane PASSWORD 'password';
    ALTER USER shane WITH SUPERUSER CREATEROLE CREATEDB REPLICATION BYPASSRLS;

    -- Password never expires
    ALTER USER shane VALID UNTIL 'infinity';

Now exit out of the SQL shell. Go back to your regular user login.

**NOTE:** This sets you a password. You will need the password to connect
with ``DataGrip``, or outside the local Unix socket context.

macOS
=====

I followed the instructions here.

https://stackoverflow.com/questions/7975556/how-can-i-start-postgresql-server-on-mac-os-x

PostgreSQL installed with ``brew`` will already create a user under your name
with appropriate permissions. So you can skip many of the steps above.

The install script will output more useful information, I recommend reading it
and deciding if any of it is important or relevant to your use case.

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

Setting up local database
#########################

Try to connect as yourself to the default database.

.. code-block:: bash

    psql -d postgres

    # or, if that fails:
    psql -d template1

From the SQL shell (now running as yourself, NOT the ``postgres`` user).

**NOTE:** you may have to run these blocks individually.

.. code-block:: sql

    -- Create database
    CREATE DATABASE nt;

.. code-block:: psql

    -- Verify it's in the list of DBs
    \l

    -- Use database nt
    \c nt

.. code-block:: sql

    -- Drop default public schema (optional); set nt to default schema
    DROP SCHEMA public;
    CREATE schema nt;
    ALTER DATABASE nt SET search_path TO nt;

You can connect easily via the Unix socket (and bypass the password prompt).

::

    psql -d nt

Test that you have create permissions and things are working superficially.

.. code-block:: sql

    CREATE TABLE test (name text);

.. code-block:: psql

    -- List tables
    \dt

    -- List columns in table
    \d test

.. code-block:: sql

    -- Insert some test values
    INSERT INTO test (name) VALUES ('testName001');
    SELECT name FROM test;
    DROP TABLE test;

Now you can configure your ``.env`` file accordingly, or add the connection
in ``DataGrip`` or similar GUI tools.

**NOTE:** I haven't included instructions for starting the PostgreSQL service
automatically on Windows.

**NOTE:** You may wish to create a separate ``nt_test`` schema which is
consumed by the server tests.
This will avoid having to repeatedly drop and rebuild local data.
Which is guaranteed to happen anyways, with frequent updates to the tables
and a lack of upgrade scripts in these early stages.

Creating the Tables & Functions
###############################

You will need to create the tables and functions before you can connect with
the server or populate with test data.

First change directories with ``cd ntdb/sql``.

Log into the database with ``psql -d nt``, and then run this.

.. code-block:: psql

    \i tables

Inserting Data & Configuring ``.env`` file
==========================================

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

NOTE: To enable automatic startup of postgres server on system reboot.

.. code-block:: bash

    sudo systemctl enable postgresql

Tables (Relational Design)
##########################

See :code:`sql/tables.sql` for details.

This is frequently updated, see :code:`docs/` for more info.

.. image:: docs/nt.svg
