terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.25"
    }
  }
}


provider "aws" {
  profile = var.profile

  default_tags {
    tags = {
      OpenTofu    = "true"
    }
  }
}
