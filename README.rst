**********
 nutra-db
**********

.. image:: https://api.travis-ci.com/nutratech/db.svg?branch=master
    :target: https://app.travis-ci.com/github/nutratech/db

Python, SQL, CSV files & RST documentation for setting up the server database.

We also have a server, CLI, and two sqlite3 databases repositories.

Locally running Postgres
########################

Ubuntu
======

**NOTE:** This is available as a shell script: ``sql/init-ubuntu.sh``.

You can start the Postgres service immediately, without needing a reboot.

I followed the instructions here to register it as a startup service.

https://askubuntu.com/questions/539187/how-to-make-postgres-start-automatically-on-boot

Now you can create the ``nt`` database, and grant yourself access.

Log in as the ``postgres`` user to initialize your role and databases.

Set a password, so you can connect with other tools, or outside the local
Unix socket context.

macOS
=====

I followed the instructions here.

https://stackoverflow.com/questions/7975556/how-can-i-start-postgresql-server-on-mac-os-x

Postgres installed with ``brew`` will already create a user under your name
with appropriate permissions.

You can skip to **Step 4** of the shell Ubuntu init script.

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

**NOTE:** This is not tested. I'm including a few resources for now.

You can search for "start postgres server as service in windows" for ideas.

https://www.delftstack.com/howto/postgres/start-postgres-server-windows/#use-services-msc-to-start-stop-a-postgresql-session-in-windows

https://stackoverflow.com/questions/36629963/how-can-i-start-postgresql-on-windows

https://stackoverflow.com/questions/70792159/start-postgres-as-service-on-windows

**NOTE:** I haven't included instructions for starting the Postgres service
automatically on Windows.

Inserting Data & Configuring ``.env`` file
##########################################

Inside ``/sql`` folder, run this.
And update the variables as you see fit.

.. code-block:: bash

    cp .env.local .env

Rebuild the ``nt`` database with this.

**NOTE:** Do this to apply experimental DB updates. Or to rebuild fresh.

.. code-block:: bash

    python -m sql r

Verify your tables.

.. code-block:: psql

    \dt

.. code-block:: sql

    SELECT * FROM function();
    SELECT * FROM version;

Now you can configure your ``.env`` file accordingly, or add the connection
in ``DataGrip`` or ``dbeaver``.

**NOTE:** You may wish to create a separate ``nt_test`` schema which is
consumed by the server tests.
This will avoid having to repeatedly drop and rebuild local data.
Which is guaranteed to happen anyways, with frequent updates to the tables
and a lack of upgrade scripts in these early stages of development.

Locally manipulating data
=========================

Importing, exporting, rebuilding (locally).

Run python sql module ``[args = i, e, r ... import, export, rebuild]``.

.. code-block:: bash

    # Rebuild (drop, create, insert)
    python -m sql r

    # Export data to CSV
    # TODO: investigate pg_dump, even for development / testing environments
    python -m sql e

    # Only import (no drop or create)
    python -m sql i

Tables (Relational Design)
##########################

See :code:`sql/tables.sql` for details.

This is frequently updated, see :code:`docs/` for more info.

.. image:: docs/nt.svg
