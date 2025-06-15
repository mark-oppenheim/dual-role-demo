#!/bin/bash
set -e

# Apply Terraform configuration
echo "Applying Terraform configuration..."
terraform apply -auto-approve

# Get the resource names from Terraform output
LAMBDA_FUNCTION=$(terraform output -raw lambda_function_name)
SOURCE_BUCKET=$(terraform output -raw source_bucket_name)
DESTINATION_BUCKET=$(terraform output -raw destination_bucket_name)

echo "Deployment complete!"
echo "Resources created:"
echo "- Lambda function: $LAMBDA_FUNCTION"
echo "- Source bucket: $SOURCE_BUCKET"
echo "- Destination bucket: $DESTINATION_BUCKET"

# Save resource names for run script
echo "LAMBDA_FUNCTION=$LAMBDA_FUNCTION" > .env
echo "SOURCE_BUCKET=$SOURCE_BUCKET" >> .env
echo "DESTINATION_BUCKET=$DESTINATION_BUCKET" >> .env