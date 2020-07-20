import json

import faker
import usaddress


f = faker.Faker()
lens = set()

# for i in range(10000):
while len(lens) < 8:
    a = f.address()
    a = a.replace('\n', ' ')
    p = usaddress.parse(a)

    addy = {'address': a}
    for e in p:
        addy[e[1]] = e[0]
    if len(addy) not in lens:
        print(json.dumps(addy, indent=2))
    lens.add(len(addy))

print(lens)
