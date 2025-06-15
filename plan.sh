#!/bin/bash
set -e

# Create a zip file for the Lambda function
echo "Creating Lambda deployment package..."
zip -j lambda_function.zip lambda_function.py

# Show Terraform plan
echo "Generating Terraform plan..."
terraform plan

echo "Plan complete!"