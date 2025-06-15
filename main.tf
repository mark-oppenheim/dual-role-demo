provider "aws" {
  region = "us-east-1"
}

# Common tags for all resources
locals {
  common_tags = {
    Project     = "DualSessionDemo"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}

# Random suffix to ensure resource names are unique
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = false
}

# Create source and destination buckets
resource "aws_s3_bucket" "source_bucket" {
  bucket = "dual-session-source-bucket-${random_string.suffix.result}"
  tags   = local.common_tags
}

resource "aws_s3_bucket" "destination_bucket" {
  bucket = "dual-session-dest-bucket-${random_string.suffix.result}"
  tags   = local.common_tags
}

# Block public access for both buckets
resource "aws_s3_bucket_public_access_block" "source_bucket_access" {
  bucket = aws_s3_bucket.source_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "destination_bucket_access" {
  bucket = aws_s3_bucket.destination_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for both buckets
resource "aws_s3_bucket_versioning" "source_versioning" {
  bucket = aws_s3_bucket.source_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "destination_versioning" {
  bucket = aws_s3_bucket.destination_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for both buckets
resource "aws_s3_bucket_server_side_encryption_configuration" "source_encryption" {
  bucket = aws_s3_bucket.source_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "destination_encryption" {
  bucket = aws_s3_bucket.destination_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Add lifecycle configuration to expire objects after 7 days
resource "aws_s3_bucket_lifecycle_configuration" "source_bucket_lifecycle" {
  bucket = aws_s3_bucket.source_bucket.id

  rule {
    id     = "expire-old-objects"
    status = "Enabled"
    
    filter {
      prefix = ""  # Empty prefix means apply to all objects
    }

    expiration {
      days = 7
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "destination_bucket_lifecycle" {
  bucket = aws_s3_bucket.destination_bucket.id

  rule {
    id     = "expire-old-objects"
    status = "Enabled"
    
    filter {
      prefix = ""  # Empty prefix means apply to all objects
    }

    expiration {
      days = 7
    }
  }
}

# Lambda execution role
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda-execution-role-${random_string.suffix.result}"
  tags = local.common_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM role for reading from source bucket
resource "aws_iam_role" "source_reader_role" {
  name = "source-reader-role-${random_string.suffix.result}"
  tags = local.common_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.lambda_execution_role.arn
        }
      }
    ]
  })
}

# IAM role for writing to destination bucket
resource "aws_iam_role" "destination_writer_role" {
  name = "destination-writer-role-${random_string.suffix.result}"
  tags = local.common_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.lambda_execution_role.arn
        }
      }
    ]
  })
}

# Policy for source reader role
resource "aws_iam_policy" "source_reader_policy" {
  name = "source-reader-policy-${random_string.suffix.result}"
  tags = local.common_tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.source_bucket.arn,
          "${aws_s3_bucket.source_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Policy for destination writer role
resource "aws_iam_policy" "destination_writer_policy" {
  name = "destination-writer-policy-${random_string.suffix.result}"
  tags = local.common_tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.destination_bucket.arn,
          "${aws_s3_bucket.destination_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Attach policies to roles
resource "aws_iam_role_policy_attachment" "source_reader_attachment" {
  role       = aws_iam_role.source_reader_role.name
  policy_arn = aws_iam_policy.source_reader_policy.arn
}

resource "aws_iam_role_policy_attachment" "destination_writer_attachment" {
  role       = aws_iam_role.destination_writer_role.name
  policy_arn = aws_iam_policy.destination_writer_policy.arn
}

# Bucket policies
resource "aws_s3_bucket_policy" "source_bucket_policy" {
  bucket = aws_s3_bucket.source_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.source_bucket.arn,
          "${aws_s3_bucket.source_bucket.arn}/*"
        ]
        Principal = {
          AWS = aws_iam_role.source_reader_role.arn
        }
      },
      {
        Action = [
          "s3:PutObject"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.source_bucket.arn,
          "${aws_s3_bucket.source_bucket.arn}/*"
        ]
        Principal = {
          AWS = aws_iam_role.lambda_execution_role.arn
        }
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "destination_bucket_policy" {
  bucket = aws_s3_bucket.destination_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.destination_bucket.arn,
          "${aws_s3_bucket.destination_bucket.arn}/*"
        ]
        Principal = {
          AWS = aws_iam_role.destination_writer_role.arn
        }
      }
    ]
  })
}

# Lambda execution policy
resource "aws_iam_policy" "lambda_execution_policy" {
  name = "lambda-execution-policy-${random_string.suffix.result}"
  tags = local.common_tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.source_bucket.arn,
          "${aws_s3_bucket.source_bucket.arn}/*"
        ]
      },
      {
        Action = [
          "sts:AssumeRole"
        ]
        Effect = "Allow"
        Resource = [
          aws_iam_role.source_reader_role.arn,
          aws_iam_role.destination_writer_role.arn
        ]
      }
    ]
  })
}

# Attach policy to Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_execution_policy.arn
}

# Create Lambda function
resource "aws_lambda_function" "dual_session_demo" {
  function_name = "dual-session-demo-${random_string.suffix.result}"
  filename      = "lambda_function.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_execution_role.arn
  timeout       = 30
  tags          = local.common_tags

  environment {
    variables = {
      SOURCE_BUCKET      = aws_s3_bucket.source_bucket.id
      DESTINATION_BUCKET = aws_s3_bucket.destination_bucket.id
      SOURCE_ROLE_ARN    = aws_iam_role.source_reader_role.arn
      DEST_ROLE_ARN      = aws_iam_role.destination_writer_role.arn
    }
  }

  # Ensure the zip file exists before deploying
  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy_attachment
  ]
}

# Outputs
output "source_bucket_name" {
  value = aws_s3_bucket.source_bucket.id
}

output "destination_bucket_name" {
  value = aws_s3_bucket.destination_bucket.id
}

output "lambda_function_name" {
  value = aws_lambda_function.dual_session_demo.function_name
}