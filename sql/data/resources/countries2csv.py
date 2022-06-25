import csv
import json
import os

# change to script's dir
os.chdir(os.path.dirname(os.path.abspath(__file__)))

cos = json.load(open("countries.json"))["data"]

# write out country & state CSV files
c_headers = ["id", "code", "name", "has_zip", "requires_state"]
s_headers = ["id", "country_id", "code", "name"]

with open("countries.csv", "w+") as c_file:
    c_writer = csv.writer(c_file)
    c_writer.writerow(c_headers)

    with open("states.csv", "w+") as s_file:
        s_writer = csv.writer(s_file)
        s_writer.writerow(s_headers)

        # write each country row
        for co in cos:

            # write states
            for st in co["subdivisions"]:
                s_row = list(st.values())
                s_row.insert(1, co["id"])
                s_writer.writerow(s_row)

            # remove and write country
            del co["subdivisions"]
            c_writer.writerow(co.values())
