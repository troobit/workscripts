#
### VPC
# 
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.18.1"

  name = "poc-container-simple-java-vpc"
  cidr = "19.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["19.0.1.0/24", "19.0.2.0/24"]
  public_subnets  = ["19.0.101.0/24", "19.0.102.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
  vpc_tags = {
    Name = "poc-container-simple-java"
  }

  enable_flow_log                                 = true
  create_flow_log_cloudwatch_iam_role             = true
  create_flow_log_cloudwatch_log_group            = true
  flow_log_cloudwatch_log_group_retention_in_days = 30
  flow_log_destination_type                       = "cloud-watch-logs"
  enable_dns_hostnames                            = true

}
