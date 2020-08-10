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

import getpass
import os
import random
import string
import sys
from datetime import datetime

import bcrypt
import psycopg2
import psycopg2.extras
import usaddress
from dotenv import load_dotenv

from utils.postgres import psql

# cd to script's directory
os.chdir(os.path.dirname(os.path.abspath(__file__)))

# Read in .env file if it exists locally, else look to env vars
try:
    load_dotenv(verbose=True)
except Exception as e:
    print(repr(e))

# PostgreSQL
PSQL_DATABASE = os.getenv("PSQL_DB_NAME", "nutra")
PSQL_SCHEMA = os.getenv("PSQL_SCHEMA_NAME", "nt")

PSQL_USER = os.getenv("PSQL_USER", getpass.getuser())
PSQL_PASSWORD = os.getenv("PSQL_PASSWORD", "password")

PSQL_HOST = os.getenv("PSQL_HOST", "localhost")

if PSQL_USER == "$LOGNAME":
    PSQL_USER = getpass.getuser()

# Initialize connection
con = psycopg2.connect(
    database=PSQL_DATABASE,
    user=PSQL_USER,
    password=PSQL_PASSWORD,
    host=PSQL_HOST,
    port="5432",
    options=f"-c search_path={PSQL_SCHEMA}",
)

print(f"psql postgresql://{PSQL_USER}:{PSQL_PASSWORD}@{PSQL_HOST}:5432/{PSQL_DATABASE}")
print(".. Connected to PostgreSQL DB!")
print(f"USE SCHEMA {PSQL_SCHEMA};\n")


# -----------------------
# Important functions
# -----------------------

csv_dir = "../data"


def import_():
    """ Imports all tables from CSV """

    def csv2sql(tablename=None):
        """ Copy a CSV file to corresponding SQL table """
        cur = con.cursor()

        try:
            filepath = f"{csv_dir}/{tablename}.csv"
            print(f"\\copy {tablename} FROM {filepath} CSV HEADER")

            # Copy from CSV
            with open(filepath) as input:
                cur.copy_expert(f"COPY {tablename} FROM STDIN CSV HEADER", input)
            print(f"COPY {cur.rowcount}")
            con.commit()
            cur.close()
        except psycopg2.Error as err:
            print("\n" + err.pgerror)

            # Roll back
            con.rollback()
            cur.close()
            raise err

    def set_serial(tablename=None):
        """ Sets the serial sequence value (col_name='id') to the max value for the column """
        cur = con.cursor()

        query = f"SELECT pg_catalog.setval(pg_get_serial_sequence('{tablename}', 'id'), (SELECT MAX(id) FROM {tablename}))"
        print(query)
        cur.execute(cur.mogrify(query))
        print(cur.statusmessage)

        con.commit()
        cur.close()

    # ------------------------
    # Run the import function
    # ------------------------
    print("[import]\n")

    csv_files = [
        os.path.splitext(f)[0] for f in os.listdir(csv_dir) if f.endswith(".csv")
    ]
    ptables = [
        "users",
        "categories",
        "products",
        "variants",
        "ingredients",
        "nutr_def",
        "orders",
        "threads",
        "countries",
        "rec_id",
        "recs",
        "rec_nut",
    ]

    # Primary tables
    for t in ptables:
        if t in csv_files:
            csv2sql(t)

    # Secondary tables
    for f in csv_files:
        if f.startswith("."):
            continue
        if f not in ptables:
            csv2sql(f)

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
        "threads",
        "messages",
        "orders",
        "cart",
        "users",
        "rec_id",
        "recs",
        "rec_nut",
        "rec_dat",
        "version"
    ]
    for t in itables:
        set_serial(t)


def rebuild_():
    """ Drops, rebuilds Tables.  Imports data fresh """

    print("[rebuild]\n")

    cur = con.cursor()

    # Rebuild tables
    print("\\i tables.sql")
    query = cur.mogrify(open("tables.sql").read())
    cur.execute(query)
    print(cur.statusmessage + "\n")

    # Rebuild functions
    print("\\i functions.sql")
    query = cur.mogrify(open("functions.sql").read())
    cur.execute(query)
    print(cur.statusmessage)

    # Commit
    con.commit()
    cur.close()

    # ----------------------------
    # Call `import_()` separately
    # ----------------------------
    print()
    import_()


def export_():
    """ Exports all tables to CSV """

    def sql2csv(tablename):
        """ Copy a SQL table to corresponding CSV file """
        cur = con.cursor()

        try:
            filepath = f"{csv_dir}/{tablename}.csv"
            print(f"\\copy {tablename} TO {filepath} CSV HEADER")

            # Write to CSV
            with open(filepath, "w+") as output:
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

    cur = con.cursor()

    query = f"SELECT tablename FROM pg_tables WHERE schemaname='{PSQL_SCHEMA}';"
    print(query)
    cur.execute(query)
    print(cur.statusmessage)

    tables = [t[0] for t in cur.fetchall()]
    for t in tables:
        sql2csv(t)

    # Clean up
    cur.close()


def truncate_():
    print("[truncate]\n")
    # TODO: warning on this and rebuild!!

    cur = con.cursor()

    query = f"SELECT tablename FROM pg_tables WHERE schemaname='{PSQL_SCHEMA}';"
    print(query)
    cur.execute(query)
    print(cur.statusmessage)

    tables = [t[0] for t in cur.fetchall()]
    queries = [f"TRUNCATE {t} CASCADE;" for t in tables]
    query = " ".join(queries)
    print(query)
    cur.execute(cur.mogrify(query))
    print(cur.statusmessage)

    # Commit
    con.commit()
    cur.close()


def analyze_():
    # NOTE: Scratchpad for analyzing the data
    print("[analyze]\n")

    # 1a. count(nut_data) FOR nutr_id IN nutr_ids
    # DONE: faster in SQL (see: functions.sql)
    # cur = con.cursor()
    # query = "SELECT id FROM nutr_def;"
    # print(query)
    # cur.execute(query)
    # print(cur.statusmessage)

    # nutr_ids = [x[0] for x in cur.fetchall()]
    # incidences = {}
    # for nutr_id in nutr_ids:
    #     # Find number of nut_data entries foreach nutrient
    #     cur = con.cursor()
    #     query = f"SELECT count(*) FROM nut_data WHERE nutr_id={nutr_id};"
    #     print(query)
    #     cur.execute(query)
    #     print(cur.statusmessage)
    #     incidence = cur.fetchone()[0]
    #     # nutr_ids = [x[0] for x in cur.fetchall()]
    #     incidences[nutr_id] = incidence
    # print(json.dumps(incidences, indent=2))


def faker_():
    print("[faker]\n")

    import faker
    import ujson as json

    f = faker.Faker()

    for i in range(6734):
        # for i in range(6734):
        profile = f.profile()
        # print(json.dumps(profile, indent=2))

        # passwd
        N = random.randint(6, 18)
        password = "".join(
            random.SystemRandom().choice(string.ascii_uppercase + string.digits)
            for _ in range(N)
        )
        passwd = bcrypt.hashpw(password.encode(), bcrypt.gensalt(6)).decode()

        created = random.randint(1546300800, 1595270561)
        terms_agreement = datetime.fromtimestamp(created)

        height = random.randint(120, 220)
        weight = random.randint(35, 110)
        activity_level = random.randint(1, 5)
        weight_goal = random.randint(1, 5)
        bmr_equation = random.randint(0, 2)
        bodyfat_method = random.randint(0, 2)

        # INSERT fake user
        pg_result = psql(
            """
INSERT INTO users (username, passwd, terms_agreement, gender, name, job, dob, height, weight, blood_group, activity_level, weight_goal, bmr_equation, bodyfat_method, created)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
RETURNING
    id""",
            [
                profile["username"],
                passwd,
                terms_agreement,
                profile["sex"],
                profile["name"],
                profile["job"],
                profile["birthdate"],
                height,
                weight,
                profile["blood_group"],
                activity_level,
                weight_goal,
                bmr_equation,
                bodyfat_method,
                created,
            ],
        )
        try:
            user_id = pg_result.row["id"]
        except Exception as e:
            print(repr(e))
            continue

        # INSERT fake emails
        activated = bool(random.getrandbits(1))
        created = random.randint(created, 1595270561)
        pg_result = psql(
            "INSERT INTO emails (user_id, email, main, activated, created) VALUES (%s, %s, %s, %s, %s) RETURNING id",
            [user_id, profile["mail"], "t", activated, created],
        )

        # addresses
        address = profile["residence"]
        pg_result = psql(
            "INSERT INTO addresses (user_id, address) VALUES (%s, %s) RETURNING id",
            [user_id, address],
        )

        # TODO: orders, reviews


# -----------------------

if __name__ == "__main__":
    """ Make script executable """

    if len(sys.argv) < 2:
        # for debugging purposes
        arg1 = "a"
        # exit(
        #     "error: no args specified! use either i, t, r, e .. [import, truncate, rebuild, export]"
        # )
    else:
        arg1 = sys.argv[1]

    if arg1 == "i" or arg1 == "import":
        import_()
    if arg1 == "t" or arg1 == "truncate":
        truncate_()
    elif arg1 == "r" or arg1 == "rebuild":
        rebuild_()
    elif arg1 == "e" or arg1 == "export":
        export_()
    elif arg1 == "a" or arg1 == "analyze":
        analyze_()
    elif arg1 == "f" or arg1 == "faker":
        faker_()
