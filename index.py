import boto3
import os
import time
import json

log_group_name = os.environ['log_group_name']
log_stream_name = os.environ['log_stream_name']

logs_client = boto3.client('logs')

def lambda_handler(event, context):
    # Ensure the log stream exists
    try:
        logs_client.create_log_stream(
            logGroupName=log_group_name,
            logStreamName=log_stream_name
        )
    except logs_client.exceptions.ResourceAlreadyExistsException:
        pass

    # Create the log entry
    log_data = {
        "timestamp" : int(time.time() * 1000),
        "log_message" : f"This is an audit log entry at {time.strftime('%Y-%m-%d %H:%M:%S')}."
    }
    
    log_json = json.dumps(log_data)
    log_event = {
        'timestamp': log_data['timestamp'],
        'message' : log_json
    }
    logs_client.put_log_events(
        logGroupName=log_group_name,
        logStreamName=log_stream_name,
        logEvents=[log_event]
    )

    return {
        'statusCode': 200,
        'body': json.dumps('Log entry created successfully')
    }