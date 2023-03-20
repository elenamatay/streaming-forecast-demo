import time
import gzip
import logging
import argparse
import datetime
import json

print("Started Reading JSON file")

#data = []
#with open('./data/sensors.json') as f:
#    for line in f:
#        data.append(json.loads(line))

#print(data[0])


INPUT = './data/sensors.json'

with open('./data/sensors.json') as f:
    for line in f:
        print(json.loads(line)[2])

#print(data[0])
    