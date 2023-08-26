
locals {
  region           = var.region
  project          = var.project
  environment      = var.environment
  profile          = var.profile
  ssh_user         = var.ssh_user
  key_pair_name    = var.key_pair_name
  # private_key_path = var.private_key_path
  subnets          = var.subnets
  vpc_id           = var.vpc_id
  security_group   = var.security_group
}

provider "aws" {
  # access_key                  = "test"
  # secret_key                  = "test"
  region = local.region
  access_key = "my-access-key"
  secret_key = "my-secret-key"

  # only required for non virtual hosted-style endpoint use case.
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs#s3_force_path_style
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3     = "http://localhost:4566"
    lambda = "http://localhost:4566"
    iam    = "http://localhost:4566"
    sqs    = "http://localhost:4566"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_s3_bucket" "main_bucket" {
  bucket = "${local.project}-bucket-${local.environment}" # Replace with the desired name for the cloned bucket
  acl    = "private"                                      # Set the appropriate ACL for your use case

  policy = file("/Users/waleedfarooqi/projects/qasid/staffing/infra/s3/gel-api-dev-serverlessdeploymentbucket-d34v77eas9bz/bucket-policy.json")

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256" # Change to your desired encryption algorithm
      }
    }
  }
}

resource "aws_sqs_queue" "job_queue" {
  name = "${local.project}-job-queue-${local.environment}"

  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 120
  receive_wait_time_seconds = 10

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.job_dlq.arn,
    maxReceiveCount     = 5 # Number of times a message can be received before moving to the DLQ
  })
}

resource "aws_sqs_queue" "job_dlq" {
  name                       = "${local.project}-job-dlq-${local.environment}"
  visibility_timeout_seconds = 30
  max_message_size           = 262144
  message_retention_seconds  = 120
  delay_seconds              = 0
}

resource "aws_sqs_queue" "email_queue" {
  name = "${local.project}-email_queue-${local.environment}"

  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 120
  receive_wait_time_seconds = 10

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.email_dlq.arn,
    maxReceiveCount     = 5 # Number of times a message can be received before moving to the DLQ
  })
}

resource "aws_sqs_queue" "email_dlq" {
  name                       = "${local.project}-email-dlq-${local.environment}"
  visibility_timeout_seconds = 30
  max_message_size           = 262144
  message_retention_seconds  = 120
  delay_seconds              = 0
}

resource "aws_sqs_queue" "notification_queue" {
  name = "${local.project}-notification_queue-${local.environment}"

  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 120
  receive_wait_time_seconds = 10

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notification_dlq.arn,
    maxReceiveCount     = 5 # Number of times a message can be received before moving to the DLQ
  })
}

resource "aws_sqs_queue" "notification_dlq" {
  name                       = "${local.project}-notification-dlq-${local.environment}"
  visibility_timeout_seconds = 30
  max_message_size           = 262144
  message_retention_seconds  = 120
  delay_seconds              = 0
}


resource "aws_sqs_queue" "image_processing_queue" {
  name = "${local.project}-image_processing_queue-${local.environment}"

  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 120
  receive_wait_time_seconds = 10

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.image_processing_dlq.arn,
    maxReceiveCount     = 5 # Number of times a message can be received before moving to the DLQ
  })
}

resource "aws_sqs_queue" "image_processing_dlq" {
  name                       = "${local.project}-image_processing-dlq-${local.environment}"
  visibility_timeout_seconds = 30
  max_message_size           = 262144
  message_retention_seconds  = 120
  delay_seconds              = 0
}

# resource "aws_lambda_function" "script" {
#   filename      = "script.zip"
#   role          = aws_iam_role.lambda_role.arn
#   function_name = "script"
#   handler       = "script.script"
#   runtime       = "python3.8"
# }

# resource "aws_dynamodb_table" "dynamodbtable" {
#   name         = "terratable"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "id"
#   range_key    = "filename"
#   attribute {
#     name = "id"
#     type = "S"
#   }
#   attribute {
#     name = "filename"
#     type = "S"
#   }
# }


# resource "aws_s3_bucket_notification" "aws-lambda-trigger" {
#   bucket = aws_s3_bucket.bucket.id
#   lambda_function {
#     lambda_function_arn = aws_lambda_function.script.arn
#     events              = ["s3:ObjectCreated:*"]
#   }
#   depends_on = [aws_lambda_permission.test]
# }


# resource "aws_lambda_permission" "test" {
#   statement_id  = "AllowExecutionFromS3Bucket"
#   action        = "lambda:InvokeFunction"
#   function_name = "script"
#   principal     = "s3.amazonaws.com"
#   source_arn    = "arn:aws:s3:::${aws_s3_bucket.bucket.id}"
# }


# resource "aws_iam_role" "lambda_role" {
#   name = "lambda_role_name"

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "lambda.amazonaws.com"
#       },
#       "Action": "*"
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role_policy" "revoke_keys_role_policy" {
#   name = "lambda_iam_policy_name"
#   role = aws_iam_role.lambda_role.id

#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "Stmt1687200984534",
#       "Action": "*",
#       "Effect": "Allow",
#       "Resource": "*"
#     }
#   ]
# }
# EOF
# }
