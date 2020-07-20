import psycopg2
import psycopg2.extras

from .settings import PSQL_DATABASE, PSQL_HOST, PSQL_PASSWORD, PSQL_SCHEMA, PSQL_USER

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


def psql(query, params=None):

    # TODO: revamp this, tighten ship, make more versatile for DB import, and decide on mandatory RETURNING for INSERTs

    cur = con.cursor(cursor_factory=psycopg2.extras.DictCursor)
    print(query)
    # Print query
    if params:
        query = cur.mogrify(query, params).decode("utf-8")
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
        result.set_rows(cur.fetchall())
        con.commit()
        cur.close()
    except Exception as e:
        print(e)
        con.rollback()
        cur.close()

    #
    # Set return message
    result.msg = cur.statusmessage
    print(f"[psql]   {result.msg}")

    return result


class PgResult:
    def __init__(self, query, rows=None, msg=None, err_msg=None):
        """ Defines a convenient result from `psql()` """

        self.query = query

        self.rows = rows
        self.msg = msg

        self.err_msg = err_msg

    # @property
    # def Response(self):
    #     """ Used ONLY for ERRORS """

    #     return _Response(data={"error": self.err_msg}, code=400)

    def set_rows(self, fetchall):
        """ Sets the DictCursor rows based on cur.fetchall() """

        self.rows = []

        if len(fetchall):
            keys = list(fetchall[0]._index.keys())

            # Build dict from named tuple
            for entry in fetchall:
                row = {}
                for i, element in enumerate(entry):
                    key = keys[i]
                    row[key] = element
                self.rows.append(row)

            # Set first row
            self.row = self.rows[0]
