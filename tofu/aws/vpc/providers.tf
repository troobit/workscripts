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
    role_arn = "arn:aws:iam::767827085228:role/terraform"
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
    role_arn = "arn:aws:iam::107932403193:role/terraform"
  }
  default_tags {
    tags = {
      OpenTofu = "true"
    }
  }
}

