
locals {
  region      = var.region
  project     = var.project
  environment = var.environment
  profile     = var.profile
  ssh_user    = var.ssh_user
  # key_pair_name = var.key_pair_name
  # private_key_path = var.private_key_path
  subnets        = var.subnets
  vpc_id         = var.vpc_id
  security_group = var.security_group

  vpc_cidr             = var.vpc_cidr
  public_subnets_cidr  = var.public_subnets_cidr
  private_subnets_cidr = var.private_subnets_cidr
  availability_zones   = var.availability_zones
}

provider "aws" {
  # access_key                  = "test"
  # secret_key                  = "test"
  region     = local.region
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
    ses    = "http://localhost:4566"
    sns    = "http://localhost:4566"
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


### Emails
resource "aws_ses_domain_identity" "elwork_com" {
  domain = "elywork.com" # Replace with your domain
}

resource "aws_ses_email_identity" "wmfarooqi05_gmail" {
  email = "wmfarooqi05@gmail.com"
}

resource "aws_ses_email_identity" "wmfarooqi05_outlook" {
  email = "wmfarooqi05@outlook.com"
}

resource "aws_ses_email_identity" "wmfarooqi70_gmail" {
  email = "wmfarooqi70@gmail.com"
}

resource "aws_ses_email_identity" "hazyhassan888_gmail" {
  email = "hazyhassan888@gmail.com"
}

resource "aws_ses_email_identity" "dev_appedia_gmail" {
  email = "dev.appedia@gmail.com"
}

resource "aws_ses_email_identity" "admin_elywork_com" {
  email = "admin@elywork.com"
}

# resource "aws_ses_configuration_set" "email_sns_config" {
#   name = "email_sns_config" # Replace with your desired configuration set name
# }


# resource "aws_sns_topic" "email-sns-topic" {
#   name = "email-sns-topic"
# }

# resource "aws_ses_event_destination" "event_destination_set_to_email_sns_config" {
#   name                   = "event_destination_set_to_email_sns_config"
#   configuration_set_name = aws_ses_configuration_set.email_sns_config.name
#   enabled                = true

#   matching_types = [
#     "bounce",
#     "click",
#     "complaint",
#     "delivery",
#     # "deliveryDelay",
#     "open",
#     "reject",
#     "renderingFailure",
#     # "subscription",
#   ]

#   sns_destination {
#     topic_arn = aws_sns_topic.email-sns-topic.arn
#   }
# }

# resource "aws_ses_identity_notification_topic" "email-sns-notification-topic" {
#   topic_arn                = aws_sns_topic.email-sns-topic.arn
#   notification_type        = "Bounce"
#   include_original_headers = true
# }