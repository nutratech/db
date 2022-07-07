#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jun 09 17:12:05 2020

@author: shane
"""

import os
import sys

import psycopg2
import psycopg2.extras

from .utils import PSQL_SCHEMA
from .utils.postgres import build_con, psql

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))

# NOTE: this is handled by utils.__init__ (for now) [by importing psql()]
# Read in .env file if it exists locally, else look to env vars
# try:
#     load_dotenv(verbose=True)
# except Exception as e:
#     print(repr(e))


# -----------------------
# Important functions
# -----------------------

CSV_DIR = os.path.join(SCRIPT_DIR, "data")


def import_() -> None:
    """Imports all tables from CSV"""

    def csv2sql(tablename=None) -> None:
        """Copy a CSV file to corresponding SQL table"""
        con = build_con()
        cur = con.cursor()

        try:
            filepath = os.path.join(CSV_DIR, f"{tablename}.csv")
            print(f"\\copy {tablename} FROM {filepath} CSV HEADER")

            # Copy from CSV
            with open(filepath, encoding="utf-8") as csv_file:
                cur.copy_expert(f'COPY "{tablename}" FROM STDIN CSV HEADER', csv_file)
            print(f"COPY {cur.rowcount}")
            con.commit()
            cur.close()
        except psycopg2.Error as err:
            print("\n" + err.pgerror)

            # Roll back
            con.rollback()
            cur.close()
            raise err

    def set_serial(tablename=None) -> None:
        """Sets the serial sequence value (col_name='id')
        to the max value for the column"""

        query = f"""
SELECT
  pg_catalog.setval( pg_get_serial_sequence('{tablename}', 'id'), (
      SELECT
        MAX(id)
      FROM "{tablename}" ) )
        """

        # Beautify it a bit
        query = " ".join(query.split())

        psql(query)

    # ------------------------
    # Run the import function
    # ------------------------
    print("[copy]\n")

    csv_files = [
        os.path.splitext(f)[0] for f in os.listdir(CSV_DIR) if f.endswith(".csv")
    ]
    ptables = [
        "bf_eq",
        "bmr_eq",
        "user",
        "profile",
        "nutr_def",
        "country",
        "rec_id",
        "rec",
        "rec_nut",
    ]

    # Primary tables
    for table in ptables:
        if table in csv_files:
            csv2sql(table)

    # Secondary tables
    for csv_file in csv_files:
        # skip hidden / dev files, prefixed with period
        if csv_file.startswith("."):
            continue
        if csv_file not in ptables:
            csv2sql(csv_file)

    # Set sequence value for serial numbers on all iterable tables
    itables = [
        # | "tokens",
        # | "emails",
        # "countries",
        # "states",
        "email",
        "bf_eq",
        "bmr_eq",
        "user",
        "token",
        "profile",
        # "measurements",
        "recipe",
        "rec_id",
        "rec",
        "rec_nut",
        "rec_dat",
        "version",
    ]
    print("\n[set_serial]\n")
    for table in itables:
        set_serial(table)


def rebuild_() -> None:
    """Drops, rebuilds Tables.  Imports data fresh"""
    print("[REBUILD]\n")
    print("\n[create]\n")

    # Rebuild tables
    print("\\i tables.sql")
    with open(os.path.join(SCRIPT_DIR, "tables.sql"), encoding="utf-8") as table_file:
        query = table_file.read()
    psql(query, _print=False, ignore_empty_result=True)
    print()

    # Rebuild functions
    print("\\i functions.sql")
    with open(os.path.join(SCRIPT_DIR, "functions.sql"), encoding="utf-8") as func_file:
        query = func_file.read()
    psql(query, _print=False, ignore_empty_result=True)

    # ----------------------------
    # Call `import_()` separately
    # ----------------------------
    print()
    import_()


def export_() -> None:
    """Exports all tables to CSV"""

    def sql2csv(tablename) -> None:
        """Copy a SQL table to corresponding CSV file"""
        con = build_con()
        cur = con.cursor()

        try:
            filepath = os.path.join(CSV_DIR, f"{tablename}.csv")
            print(f"\\copy {tablename} TO {filepath} CSV HEADER")

            # Write to CSV
            with open(filepath, "w+", encoding="utf-8") as output:
                cur.copy_expert(f'COPY "{tablename}" TO STDOUT CSV HEADER', output)
            print(f"COPY {cur.rowcount}")
            con.commit()
            cur.close()
        except psycopg2.Error as err:
            print("\n" + err.pgerror)

            # Roll back
            con.rollback()
            cur.close()
            raise err

    # ------------------------
    # Run the export function
    # ------------------------
    print("[export]\n")

    query = f"SELECT tablename FROM pg_tables WHERE schemaname='{PSQL_SCHEMA}';"
    pg_result = psql(query)

    tables = [x[0] for x in pg_result.rows]
    for table in tables:
        sql2csv(table)


def truncate_() -> None:
    """Truncates tables, not very often used"""
    # TODO: warning on this and rebuild!!
    print("[truncate]\n")

    query = f"SELECT tablename FROM pg_tables WHERE schemaname='{PSQL_SCHEMA}';"
    pg_result = psql(query)

    tables = [x[0] for x in pg_result.rows]
    queries = [f"TRUNCATE {x} CASCADE;" for x in tables]
    query = " ".join(queries)
    psql(query, ignore_empty_result=True)


def main() -> int:
    """Handles the arg parsing bit and passes off"""
    if len(sys.argv) < 2:
        # NOTE: currently done this way, for debugging purposes
        ARG1 = "r"
        # sys.exit(
        #     "error: no args specified! ""
        #     "use either i, t, r, e .. [import, truncate, rebuild, export]"
        # )
    else:
        ARG1 = sys.argv[1]

    if ARG1 in {"i", "import"}:
        import_()
    if ARG1 in {"t", "truncate"}:
        truncate_()
    elif ARG1 in {"r", "rebuild"}:
        rebuild_()
    elif ARG1 in {"e", "export"}:
        export_()

    return 0
