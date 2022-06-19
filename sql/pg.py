#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jun 09 17:12:05 2020

@author: shane

This file is part of nutra-server, a server for nutra clients.
    https://github.com/gamesguru/nutra-server

nutra-db is a database for nutra servers.
Copyright (C) 2020  Shane Jaroch

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
"""

import os
import sys

import psycopg2
import psycopg2.extras

from sql.utils import PSQL_SCHEMA
from sql.utils.postgres import build_con, psql

# cd to script's directory
os.chdir(os.path.dirname(os.path.abspath(__file__)))

# NOTE: this is handled by utils.__init__ (for now) [by importing psql()]
# Read in .env file if it exists locally, else look to env vars
# try:
#     load_dotenv(verbose=True)
# except Exception as e:
#     print(repr(e))


# -----------------------
# Important functions
# -----------------------

CSV_DIR = "../data"


def import_() -> None:
    """Imports all tables from CSV"""

    def csv2sql(tablename=None) -> None:
        """Copy a CSV file to corresponding SQL table"""
        con = build_con()
        cur = con.cursor()

        try:
            filepath = f"{CSV_DIR}/{tablename}.csv"
            print(f"\\copy {tablename} FROM {filepath} CSV HEADER")

            # Copy from CSV
            with open(filepath, encoding="utf-8") as csv_file:
                cur.copy_expert(f"COPY {tablename} FROM STDIN CSV HEADER", csv_file)
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

        query = (
            "SELECT pg_catalog.setval("
            f"  pg_get_serial_sequence('{tablename}', 'id'),"
            f"  (SELECT MAX(id) FROM {tablename})  "
            ")"
        )
        psql(query)

    # ------------------------
    # Run the import function
    # ------------------------
    print("[import]\n")

    csv_files = [
        os.path.splitext(f)[0] for f in os.listdir(CSV_DIR) if f.endswith(".csv")
    ]
    ptables = [
        "bf_eqs",
        "bmr_eqs",
        "users",
        "profiles",
        "categories",
        "products",
        "variants",
        "ingredients",
        "nutr_def",
        "meal_names",
        "biometrics",
        "orders",
        "threads",
        "countries",
        "rec_id",
        "recs",
        "rec_nut",
    ]

    # Primary tables
    for table in ptables:
        if table in csv_files:
            csv2sql(table)

    # Secondary tables
    for csv_file in csv_files:
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
        "addresses",
        "emails",
        "customer_activity",
        "reviews",
        "reports",
        "coupons",
        # "shipping_containers",
        # | "order_items",
        "categories",
        "products",
        "variants",
        "ingredients",
        "bf_eqs",
        "bmr_eqs",
        "meal_names",
        "biometrics",
        "orders",
        "cart",
        "users",
        "tokens",
        "profiles",
        "biometric_log",
        # "measurements",
        "recipes",
        "rec_id",
        "recs",
        "rec_nut",
        "rec_dat",
        "version",
    ]
    for table in itables:
        set_serial(table)


def rebuild_() -> None:
    """Drops, rebuilds Tables.  Imports data fresh"""
    print("[rebuild]\n")

    # Rebuild tables
    print("\\i tables.sql")
    with open("tables.sql", encoding="utf-8") as table_file:
        query = table_file.read()
    psql(query, _print=False, ignore_empty_result=True)
    print()

    # Rebuild functions
    print("\\i functions.sql")
    with open("functions.sql", encoding="utf-8") as func_file:
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
            filepath = f"{CSV_DIR}/{tablename}.csv"
            print(f"\\copy {tablename} TO {filepath} CSV HEADER")

            # Write to CSV
            with open(filepath, "w+", encoding="utf-8") as output:
                cur.copy_expert(f"COPY {tablename} TO STDOUT CSV HEADER", output)
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


if __name__ == "__main__":
    if len(sys.argv) < 2:
        # NOTE: currently done this way, for debugging purposes
        ARG1 = "r"
        # exit(
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
