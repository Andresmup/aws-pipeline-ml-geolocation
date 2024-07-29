import requests
import json
import base64
import random
import datetime
from faker import Faker

fake = Faker()

def getTimestamp():
    now = datetime.datetime.now()
    three_days_ago = now - datetime.timedelta(days=3)
    random_timestamp = fake.date_time_between(start_date=three_days_ago, end_date=now)
    timestamp = random_timestamp.isoformat() + "Z"
    return timestamp
#Order counter
i = 0

while True:
    i=int(i)+1

    print("Number of order " + str(i))

    # Send data structure
    send_data = {
        "timestamp": getTimestamp(),
        "device_geolocation": fake.location_on_land()
    }

    # Convert to json send data
    json_send_data = json.dumps(send_data)
    print("order_data", json_send_data, "\n") #Print json send data

    # Encode data
    base64_send_data= base64.b64encode(json_send_data.encode()).decode()

    #Body request
    body = {
        "StreamName": "geolocation-dev-stream",
        "PartitionKey": "test-partition-01",
        "Data": base64_send_data    
    }
    print("body", body, "\n") #Print json body

    # Deploy api gateway endpoint
    endpoint = "https://bpxky6duyi.execute-api.us-east-1.amazonaws.com/apiv1"

    # Stage
    stage = "/devices"

    # Url requst post
    url = endpoint+stage


    # Request headers
    headers = {
        "Content-Type": "application/json"
    }

    # Make POST request
    response = requests.post(url, headers=headers, data=json.dumps(body))

    # Print response
    print("Total ingested:"+str(i) + ",HTTPStatusCode:" + str(response.status_code))
    print(response.json())
    print("--------------------")
