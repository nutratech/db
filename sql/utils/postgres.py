# -*- coding: utf-8 -*-
"""
Created on Fri Jan 31 16:01:31 2020

@author: shane

This file is part of nutra-server, a server for nutra clients.
    https://github.com/gamesguru/nutra-server

nutra-server is a server for nutra clients.
Copyright (C) 2019-2020  Shane Jaroch

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

import psycopg2
import psycopg2.extras

from . import PSQL_DATABASE, PSQL_HOST, PSQL_PASSWORD, PSQL_SCHEMA, PSQL_USER

# Initialize connection
con = psycopg2.connect(
    database=PSQL_DATABASE,
    user=PSQL_USER,
    password=PSQL_PASSWORD,
    host=PSQL_HOST,
    port="5432",
    options=f"-c search_path={PSQL_SCHEMA}",
)

print(
    f"[Connected to Postgre DB]    postgresql://{PSQL_USER}:{PSQL_PASSWORD}@{PSQL_HOST}:5432/{PSQL_DATABASE}",
)
print(f"[psql] USE SCHEMA {PSQL_SCHEMA};")


def psql(query, params=None, _print=True, ignore_empty_result=False):

    # TODO: revamp this, tighten ship, make more versatile for DB import, and decide on mandatory RETURNING for INSERTs

    cur = con.cursor()
    # Print query
    if params:
        query = cur.mogrify(query, params).decode("utf-8")
    if _print:
        print(f"[psql]   {query};")

    # init result object
    result = PgResult(query)

    #
    # Attempt query
    try:
        cur.execute(query)

    except psycopg2.Error as err:
        #
        # Log error
        # https://kb.objectrocket.com/postgresql/python-error-handling-with-the-psycopg2-postgresql-adapter-645
        print(f"[psql]   {err.pgerror}")

        # Roll back
        con.rollback()
        cur.close()

        # Set err_msg
        result.err_msg = err.pgerror

        return result

    #
    # Extract result
    try:
        headers = [x[0] for x in cur.description] if cur.description else None
        result.set_rows(cur.fetchall(), headers)
        con.commit()
        cur.close()
    except Exception as e:
        if ignore_empty_result is False:
            print(repr(e))
            con.rollback()
        else:
            con.commit()
            cur.close()

    #
    # Set return message
    result.msg = cur.statusmessage
    print(result.msg)

    return result


class PgResult:
    def __init__(self, query, rows=None, headers=None, msg=None, err_msg=None):
        """ Defines a convenient result from `psql()` """

        self.query = query

        self.headers = headers
        self.rows = rows
        self.msg = msg

        self.err_msg = err_msg

    # @property
    # def Response(self):
    #     """ Used ONLY for ERRORS """

    #     return _Response(data={"error": self.err_msg}, code=400)

    def set_rows(self, fetchall, headers):
        """Sets pg_result rows based on fetchall and headers"""

        self.headers = headers
        self.rows = fetchall

        # if len(fetchall):
        #     keys = list(fetchall[0]._index.keys())

        #     # Build dict from named tuple
        #     for entry in fetchall:
        #         row = {}
        #         for i, element in enumerate(entry):
        #             key = keys[i]
        #             row[key] = element
        #         self.rows.append(row)

        #     # Set first row
        #     self.row = self.rows[0]
