#!/bin/bash
set -e

# Check for AWS CLI and Terraform
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo "Terraform is not installed. Please install it first."
    exit 1
fi

# Create a zip file for the Lambda function
echo "Creating Lambda deployment package..."
zip -j lambda_function.zip lambda_function.py

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Apply Terraform configuration
echo "Applying Terraform configuration..."
terraform apply -auto-approve

# Get the Lambda function name from Terraform output
LAMBDA_FUNCTION=$(terraform output -raw lambda_function_name)
SOURCE_BUCKET=$(terraform output -raw source_bucket_name)
DESTINATION_BUCKET=$(terraform output -raw destination_bucket_name)

echo "Deployment complete!"
echo "Resources created:"
echo "- Lambda function: $LAMBDA_FUNCTION"
echo "- Source bucket: $SOURCE_BUCKET"
echo "- Destination bucket: $DESTINATION_BUCKET"
echo ""
echo "To test the Lambda function, use the AWS console or CLI:"
echo "aws lambda invoke --function-name $LAMBDA_FUNCTION output.json"
echo "cat output.json"
echo ""
echo "To verify the results, check both buckets:"
echo "aws s3 ls s3://$SOURCE_BUCKET"
echo "aws s3 ls s3://$DESTINATION_BUCKET"