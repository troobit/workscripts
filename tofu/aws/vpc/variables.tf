variable "aws_region" {
  description = "region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Local AWS CLI profile for the management account."
  type        = string
}

variable "dev_role_arn" {
  description = "IAM role ARN assumed in the dev account."
  type        = string
}

variable "prod_role_arn" {
  description = "IAM role ARN assumed in the prod account."
  type        = string
}

variable "environment" {
  default = "dev"
}
