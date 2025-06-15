#!/bin/bash
set -e

# Load resource names
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found. Run deploy.sh first."
    exit 1
fi

# Check AWS region
AWS_REGION=$(aws configure get region)
echo "Using AWS region: $AWS_REGION"

# Invoke the Lambda function with explicit region
echo "Invoking Lambda function: $LAMBDA_FUNCTION"
aws lambda invoke --function-name $LAMBDA_FUNCTION --region us-east-1 output.json
echo "Lambda execution result:"
cat output.json

# Verify the results
echo -e "\nVerifying source bucket contents:"
aws s3 ls s3://$SOURCE_BUCKET --region us-east-1

echo -e "\nVerifying destination bucket contents:"
aws s3 ls s3://$DESTINATION_BUCKET --region us-east-1