#!/usr/bin/env python3

# Copyright 2018 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import time
import gzip
import logging
import argparse
import datetime
import json
from google.cloud import pubsub_v1
from google.api_core.exceptions import AlreadyExists, InvalidArgument

TIME_FORMAT = "%Y-%m-%d %H:%M:%S"
TOPIC = 'streaming_data_inbound'
INPUT = './data/sensor_data.csv.gz'

def publish(publisher, topic, original_ts, events):
   numobs = len(events)
   if numobs > 0:
       logging.info('Publishing {0} events from {1}'.format(numobs, original_ts))
       for event_data in events:
         publisher.publish(topic,event_data)

def get_timestamp(line):
   # look at first field of row
   timestamp = line.split(',')[2]
   return datetime.datetime.strptime(timestamp.strip(), TIME_FORMAT)

def get_json_object(line):
   # look at first field of row
   values = line.split(',')
   
   obj_dict = {}
   obj_dict["sensor_id"] = values[0]
   obj_dict["value"] = values[1]
   obj_dict["ts"] = values[2]
   obj_dict["published"] = datetime.datetime.utcnow()
   
   return json.dumps(obj_dict, default=str)

def simulate(topic, ifp, firstObsTime, programStart, speedFactor):
   # sleep computation
   def compute_sleep_secs(obs_time):
        time_elapsed = (datetime.datetime.utcnow() - programStart).seconds
        sim_time_elapsed = ((obs_time - firstObsTime).days * 86400.0 + (obs_time - firstObsTime).seconds) / speedFactor
        to_sleep_secs = sim_time_elapsed - time_elapsed
        return to_sleep_secs

   topublish = list() 

   obs_time = datetime.datetime.utcnow()
   for line in ifp:
       line = line.decode('utf-8')
       event_data = get_json_object(line)   # entire line of input CSV is the message
       obs_time = get_timestamp(line) # from first column
       # how much time should we sleep?
       if compute_sleep_secs(obs_time) > 1:
          # notify the accumulated topublish
          publish(publisher, topic, obs_time, topublish) # notify accumulated messages
          topublish = list() # empty out list

          # recompute sleep, since notification takes a while
          to_sleep_secs = compute_sleep_secs(obs_time)
          if to_sleep_secs > 0:
             logging.info('Sleeping {} seconds'.format(to_sleep_secs))
             time.sleep(to_sleep_secs)
       topublish.append(event_data.encode('utf-8'))

   # left-over records; notify again
   publish(publisher, topic, obs_time, topublish)

def peek_timestamp(ifp):
   # peek ahead to next line, get timestamp and go back
   pos = ifp.tell()
   line = ifp.readline()
   ifp.seek(pos)
   line = line.decode('utf-8')
   return get_timestamp(line)


if __name__ == '__main__':
   parser = argparse.ArgumentParser(description='Send sensor data to Cloud Pub/Sub in small groups, simulating real-time behavior')
   parser.add_argument('--speedFactor', help='Example: 60 implies 1 hour of data sent to Cloud Pub/Sub in 1 minute', required=True, type=float)
   parser.add_argument('--project', help='Example: --project $DEVSHELL_PROJECT_ID', required=True)
   args = parser.parse_args()

   # create Pub/Sub notification topic
   logging.basicConfig(format='%(levelname)s: %(message)s', level=logging.INFO)
   publisher = pubsub_v1.PublisherClient()
   event_type = publisher.topic_path(args.project,TOPIC)
   try:
      publisher.create_topic(request={"name": event_type})
      logging.info('Creating pub/sub topic {}'.format(TOPIC))
   except AlreadyExists:
      #Creating New topics
      logging.info('Reusing pub/sub topic {}'.format(TOPIC))
   except InvalidArgument:
    print("Please choose either BINARY or JSON as a valid message encoding type.")
      
   # notify about each line in the input file
   programStartTime = datetime.datetime.utcnow() 
   with gzip.open(INPUT, 'rb') as ifp:
      header = ifp.readline()  # skip header
      firstObsTime = peek_timestamp(ifp)
      logging.info('Sending sensor data from {}'.format(firstObsTime))
      simulate(event_type, ifp, firstObsTime, programStartTime, args.speedFactor)
