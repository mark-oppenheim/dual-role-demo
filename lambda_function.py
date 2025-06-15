import boto3
import os
import time
import random
import string
import json
from botocore.exceptions import ClientError

def generate_random_content(size=1024):
    """Generate random content for the test object"""
    return ''.join(random.choices(string.ascii_letters + string.digits, k=size))

def lambda_handler(event, context):
    try:
        # Get environment variables
        source_bucket = os.environ['SOURCE_BUCKET']
        destination_bucket = os.environ['DESTINATION_BUCKET']
        source_role_arn = os.environ['SOURCE_ROLE_ARN']
        dest_role_arn = os.environ['DEST_ROLE_ARN']
        
        # Create standard S3 client with Lambda's execution role
        s3_client = boto3.client('s3')
        sts_client = boto3.client('sts')
        
        # Create a test object in the source bucket
        timestamp = str(int(time.time()))
        test_object_key = f"test-object-{timestamp}.txt"
        test_content = generate_random_content()
        
        print(f"Creating test object {test_object_key} in source bucket {source_bucket}")
        try:
            s3_client.put_object(
                Bucket=source_bucket,
                Key=test_object_key,
                Body=test_content
            )
        except ClientError as e:
            print(f"Error creating test object: {e}")
            raise
        
        # Assume source reader role
        print(f"Assuming source reader role: {source_role_arn}")
        try:
            source_role_response = sts_client.assume_role(
                RoleArn=source_role_arn,
                RoleSessionName="SourceReaderSession"
            )
        except ClientError as e:
            print(f"Error assuming source reader role: {e}")
            raise
        
        source_credentials = source_role_response['Credentials']
        source_session = boto3.Session(
            aws_access_key_id=source_credentials['AccessKeyId'],
            aws_secret_access_key=source_credentials['SecretAccessKey'],
            aws_session_token=source_credentials['SessionToken']
        )
        
        # Create S3 client with source reader role
        source_s3 = source_session.client('s3')
        
        # Assume destination writer role
        print(f"Assuming destination writer role: {dest_role_arn}")
        try:
            dest_role_response = sts_client.assume_role(
                RoleArn=dest_role_arn,
                RoleSessionName="DestinationWriterSession"
            )
        except ClientError as e:
            print(f"Error assuming destination writer role: {e}")
            raise
        
        dest_credentials = dest_role_response['Credentials']
        dest_session = boto3.Session(
            aws_access_key_id=dest_credentials['AccessKeyId'],
            aws_secret_access_key=dest_credentials['SecretAccessKey'],
            aws_session_token=dest_credentials['SessionToken']
        )
        
        # Create S3 client with destination writer role
        dest_s3 = dest_session.client('s3')
        
        # Read the object from source bucket using source session and stream to destination
        print(f"Reading object {test_object_key} from source bucket {source_bucket} and streaming to destination bucket {destination_bucket}")
        try:
            # Get the object using the source role
            response = source_s3.get_object(Bucket=source_bucket, Key=test_object_key)
            
            # Stream the object to the destination bucket using the destination role
            dest_s3.upload_fileobj(
                response['Body'],
                destination_bucket,
                test_object_key
            )
            
            # Verify the object was copied successfully
            dest_s3.head_object(Bucket=destination_bucket, Key=test_object_key)
            print(f"Successfully verified object {test_object_key} in destination bucket {destination_bucket}")
            
        except ClientError as e:
            print(f"Error during object transfer or verification: {e}")
            raise
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Dual session demo completed successfully',
                'source_bucket': source_bucket,
                'destination_bucket': destination_bucket,
                'object_key': test_object_key
            })
        }
    except Exception as e:
        print(f"Error in lambda execution: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': f'Error: {str(e)}'
            })
        }