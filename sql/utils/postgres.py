# -*- coding: utf-8 -*-
"""
Created on Fri Jan 31 16:01:31 2020

@author: shane

This file is part of nutra-server, a server for nutra clients.
    https://github.com/gamesguru/nutra-server

nutra-server is a server for nutra clients.
Copyright (C) 2019-2022 Shane Jaroch

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

from sql.utils import PSQL_DATABASE, PSQL_HOST, PSQL_PASSWORD, PSQL_SCHEMA, PSQL_USER


# pylint: disable=c-extension-no-member
def build_con() -> psycopg2._psycopg.connection:
    """Build and return a psql connection"""

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
        "psql "
        f"postgresql://{PSQL_USER}:{PSQL_PASSWORD}@{PSQL_HOST}:5432/{PSQL_DATABASE}",
    )

    return con


class PgResult:
    """Result object"""

    def __init__(self, query, rows=None, headers=None, msg=None, err_msg=None) -> None:
        """Defines a convenient result from `psql()`"""

        self.query = query

        self.headers = headers
        self.rows = rows
        self.msg = msg

        self.err_msg = err_msg

    def set_rows(self, rows: list, headers: list):
        """Sets pg_result rows based on fetchall and headers"""

        self.headers = headers
        self.rows = rows


def psql(
    query: str, params: tuple = None, _print=True, ignore_empty_result=False
) -> PgResult:
    """Execute a query (optionally parameterized), and return a PgResult"""

    # TODO: revamp this, tighten ship, make more versatile for DB import,
    #  and decide on mandatory RETURNING for INSERT(s)

    con = build_con()
    cur = con.cursor()
    # Print query
    if params:
        query = cur.mogrify(query, params).decode("utf-8")
    if _print:
        print(f"  psql {query};")

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
        print(f"  [psql]   {err.pgerror}")

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
    # TODO: find out which class(es) of Exception are possibly thrown
    # pylint: disable=broad-except
    except Exception as err:
        if ignore_empty_result is False:
            print(f"  {repr(err)}")
            con.rollback()
        else:
            con.commit()
            cur.close()

    #
    # Set return message
    result.msg = cur.statusmessage
    print(f"  {result.msg}")

    return result
