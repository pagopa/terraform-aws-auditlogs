import boto3
import os
import time
import json

# Retrieve environment variables
log_throuput = int(os.environ['log_throuput'])  # Ensure log_throuput is an integer
log_group_name = os.environ['log_group_name']
log_stream_name = os.environ['log_stream_name']

# Initialize boto3 client for CloudWatch Logs
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

    # Loop to create logs
    for i in range(1, 2):
        for j in range(1, log_throuput + 1):
            # Create the log entry
            log_data = {
                "timestamp": int(time.time() * 1000),
                "log_message": f"This is an audit log entry at {time.strftime('%Y-%m-%d %H:%M:%S')}.",
                "audit": "true",
                "customProperty": "test-2-count1000"
            }

            # Convert log data to JSON
            log_json = json.dumps(log_data)
            log_event = {
                'timestamp': log_data['timestamp'],
                'message': log_json
            }

            # Send log event to CloudWatch Logs
            logs_client.put_log_events(
                logGroupName=log_group_name,
                logStreamName=log_stream_name,
                logEvents=[log_event],
            )
    #    j=j+1
    #i=i+1    
    #time.sleep(1)

    # Return success response
    return {
        'statusCode': 200,
        'body': json.dumps('Log entry created successfully')
    }