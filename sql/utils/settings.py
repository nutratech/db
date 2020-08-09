import getpass
import os
from datetime import timedelta

from dotenv import load_dotenv

# Read in .env file if it exists locally, else look to env vars
try:
    load_dotenv(verbose=True)
except Exception as e:
    print(repr(e))

# USPS API key
USPS_API_KEY = os.getenv("USPS_API_KEY")

# Email creds
PROD_EMAIL = os.getenv("PROD_EMAIL")
PROD_EMAIL_PASS = os.getenv("PROD_EMAIL_PASS")

# Server host
SERVER_PORT = os.getenv("PORT", 20000)
ON_REMOTE = os.getenv("ON_REMOTE", False)
SERVER_HOST = (
    "https://nutra-server.herokuapp.com"
    if ON_REMOTE
    else f"http://localhost:{SERVER_PORT}"
)
WEB_HOST = (
    "https://nutra-web.herokuapp.com"
    if ON_REMOTE
    else f"http://localhost:{SERVER_PORT}"
)

# PostgreSQL
PSQL_DATABASE = os.getenv("PSQL_DB_NAME", "nutra")
PSQL_SCHEMA = "nt"

PSQL_USER = os.getenv("PSQL_USER", getpass.getuser())
PSQL_PASSWORD = os.getenv("PSQL_PASSWORD", "password")

PSQL_HOST = os.getenv("PSQL_HOST", "localhost")

# Other
JWT_SECRET = os.getenv("JWT_SECRET", "secret123")
TOKEN_EXPIRY = timedelta(weeks=520)
SLACK_TOKEN = os.getenv("SLACK_TOKEN", None)
SEARCH_LIMIT = 100
CUSTOM_FOOD_DATA_SRC_ID = 6

NUTR_ID_KCAL = 208

NUTR_IDS_FLAVONES = [
    710,
    711,
    712,
    713,
    714,
    715,
    716,
    734,
    735,
    736,
    737,
    738,
    731,
    740,
    741,
    742,
    743,
    745,
    749,
    750,
    751,
    752,
    753,
    755,
    756,
    758,
    759,
    762,
    770,
    773,
    785,
    786,
    788,
    789,
    791,
    792,
    793,
    794,
]

NUTR_IDS_AMINOS = [
    501,
    502,
    503,
    504,
    505,
    506,
    507,
    508,
    509,
    510,
    511,
    512,
    513,
    514,
    515,
    516,
    517,
    518,
    521,
]
