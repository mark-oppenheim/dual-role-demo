#!/bin/bash
set -e

# Load resource names
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found. Run deploy.sh first."
    exit 1
fi

# Invoke the Lambda function
echo "Invoking Lambda function: $LAMBDA_FUNCTION"
aws lambda invoke --function-name $LAMBDA_FUNCTION output.json
echo "Lambda execution result:"
cat output.json

# Verify the results
echo -e "\nVerifying source bucket contents:"
aws s3 ls s3://$SOURCE_BUCKET

echo -e "\nVerifying destination bucket contents:"
aws s3 ls s3://$DESTINATION_BUCKET