import boto3
import os
import logging
import json
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

cloudwatch = boto3.resource("logs")

def send_logs(log_message, log_group_name, log_stream_name):

    try:
        cloudwatch.put_log_events(
            log_group_name = os.environ['log_group_name'],
            log_stream_name = os.environ['log_stream_name'],
            logEvents=[
            {
                'timestamp': datetime.date,
                'message': log_message
            }
        ])
        print(f"logged message")
    
    except Exception as e:
        print(f"error message : {str(e)}")


def lambda_handler(event, context):

    send_logs()

