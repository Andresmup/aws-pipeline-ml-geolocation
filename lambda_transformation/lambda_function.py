import base64
import json
import datetime

def lambda_handler(event, context):
    # Create return value.
    firehose_records_output = {'records': []}

    # Print event
    print(event)

    # Process each record in the event
    for record in event['records']:
        # Get payload
        payload = base64.b64decode(record['data']).decode('utf-8')
        json_payload = json.loads(payload)
        
        # Print payload
        print(json_payload)

        # Create Firehose output object and add the modified payload and record ID.
        event_timestamp = datetime.datetime.fromisoformat(json_payload['timestamp'].rstrip("Z"))
        partition_keys = {"year": event_timestamp.strftime('%Y'),
                          "month": event_timestamp.strftime('%m'),
                          "day": event_timestamp.strftime('%d'),
                          "hour": event_timestamp.strftime('%H')}

        #Format to be send
        timestamp = event_timestamp.strftime('%Y-%m-%dT%H:%M:%S') + "Z"
        
        # Data to send through Firehose
        data = {"timestamp": timestamp,
                "latitude": json_payload["device_geolocation"][0],
                "longitude": json_payload["device_geolocation"][1]
        }
        
        # Convert the payload to JSON and then to Base64
        encoded_data = base64.b64encode(json.dumps(data).encode('utf-8')).decode('utf-8')

        # Create Firehose output object and add the modified payload and record ID.
        firehose_record_output = {
            'recordId': record['recordId'],
            'result': 'Ok',
            'data': encoded_data,
            'metadata': {'partitionKeys': partition_keys}
        }

        # Print firehose_record_output
        print(firehose_record_output)

        firehose_records_output['records'].append(firehose_record_output)

    print('Successfully processed {} records.'.format(len(event['records'])))

    # Return firehose_records_output "filtered and processed data"
    print('Output records send back to firehose', firehose_records_output)
    return firehose_records_output