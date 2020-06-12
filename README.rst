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

1. Inside ``/sql`` folder, run :code:`cp .env.local .env`

2. Set ``.env`` var: ``PSQL_LOCAL_DB_DIR`` to an existing folder

3. Run :code:`cd sql` and :code:`./sql.sh` (this starts the server, after computer reboot)

4. Exit the Postgres terminal with :code:`\q`

5. Rebuild te db with :code:`./rebuild.sh`

Running local database (after init)
===================================

.. code-block:: bash

    cd sql
    ./sql.sh

Tables (Relational Design)
##########################

See :code:`sql/tables.sql` for details.

This is frequently updated, see :code:`docs/` for more info.

.. image:: docs/nutra.svg
