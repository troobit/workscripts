terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.25"
    }
  }
}

provider "aws" {
  profile = var.aws_profile
  alias   = "mgmt"
  default_tags {
    tags = {
      OpenTofu = "true"
    }
  }
}

provider "aws" {
  profile = var.aws_profile
  alias   = "dev"
  assume_role {
    # The role ARN within Account B to AssumeRole into. Created in step 1.
    role_arn = var.dev_role_arn
  }
  default_tags {
    tags = {
      OpenTofu = "true"
    }
  }
}

provider "aws" {
  profile = var.aws_profile
  alias   = "prod"
  assume_role {
    # The role ARN within Account B to AssumeRole into. Created in step 1.
    role_arn = var.prod_role_arn
  }
  default_tags {
    tags = {
      OpenTofu = "true"
    }
  }
}

