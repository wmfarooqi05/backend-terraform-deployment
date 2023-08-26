variable "region" {
  type    = string
  default = "ca-central-1"
}

variable "project" {
  type    = string
  default = "GlobalEmployment"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "profile" {
  type    = string
  default = "default"
}

variable "vpc_id" {
  type = string
}

variable "subnets" {
  type = list(string)
}

variable "security_group" {
  type = string
}

variable "ssh_user" {
  type    = string
  default = "ec2-user"
}

variable "key_pair_name" {
  type    = string
  default = "gel-api-dev-waleed"
}

# variable "private_key_path" {
#   type = string
# }

# variable "s3_bucket_id" {
#   type = string
# }
