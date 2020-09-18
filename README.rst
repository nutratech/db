**********
 nutra-db
**********

.. image:: https://api.travis-ci.com/gamesguru/ntdb.svg?branch=master
    :target: https://travis-ci.com/gamesguru/ntdb

Python, SQL and CSV files for setting up nutra-server database.

See CLI:    https://github.com/nutratech/cli

Pypi page:  https://pypi.org/project/nutra

See server: https://github.com/gamesguru/nutra-server

Setting up local database
#########################

1. Inside ``/sql`` folder, run

.. code-block:: bash

    cp .env.local .env

2. Set ``.env`` var ``PSQL_LOCAL_DB_DIR`` to an existing folder (e.g. ``~/.pgsql/nutra``)

3. Run :code:`cd sql` and start PostgreSQL server,

.. code-block:: bash

    sudo killall postgres
    ./dbup.sh

4. Rebuild te db with,

NOTE: Must do this after DB update or to build fresh

.. code-block:: bash

    python pg.py r

Running local database (after init)
===================================

This is mostly used for running manual commands.

.. code-block:: bash

    cd sql
    ./sql.sh

Then for example,

.. code-block:: sql

    SELECT * FROM functions();
    SELECT * FROM version;

NOTE: after computer reboot, may need to start server

.. code-block:: bash

    sudo killall postgres
    ./dbup.sh

NOTE: To disable automatic starting of postgres server on reboot:

.. code-block:: bash

    sudo systemctl disable postgresql

It will output a confirmation message:

.. code-block:: bash

    Synchronizing state of postgresql.service with SysV service script with /lib/systemd/systemd-sysv-install.
    Executing: /lib/systemd/systemd-sysv-install disable postgresql
    Removed /etc/systemd/system/multi-user.target.wants/postgresql.service.


Tables (Relational Design)
##########################

See :code:`sql/tables.sql` for details.

This is frequently updated, see :code:`docs/` for more info.

.. image:: docs/nutra.svg
