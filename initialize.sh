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

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

echo "Initialization complete!"