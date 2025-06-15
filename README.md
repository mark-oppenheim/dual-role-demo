# Dual Session Demo

This project demonstrates the use of dual AWS sessions in a Lambda function using Terraform and Python.

## Architecture

The demo consists of:

1. Two S3 buckets: source and destination
2. Two IAM roles:
   - Source reader role: Can read from the source bucket
   - Destination writer role: Can write to the destination bucket
3. A Lambda function that:
   - Creates a test object in the source bucket
   - Assumes the source reader role to read the object
   - Assumes the destination writer role to write the object to the destination bucket

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform installed
- Python 3.9+

## Deployment

1. Make the build script executable:
   ```
   chmod +x build.sh
   ```

2. Run the build script:
   ```
   ./build.sh
   ```

## Testing

After deployment, you can test the Lambda function using the AWS Console or CLI:

```
aws lambda invoke --function-name dual-session-demo output.json
```

Then check the contents of both buckets to verify that the object was copied successfully.

## Cleanup

To remove all resources created by this demo:

```
terraform destroy -auto-approve
```