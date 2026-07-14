# ====================================================================================
# Data feed from YAML file
# ====================================================================================
locals {
  vpc_data = yamldecode(file("./config/networks.yml"))

  # flatten ensures that this local value is a flat list of objects, rather
  # than a list of lists of objects.
  vpcs = flatten([
    for vpc_key, vpc in local.vpc_data : [
      {
        name     = vpc.name
        location = vpc.location
        az       = vpc.az
        cidr     = vpc.cidr
      }
    ]
  ])

  private_subnets = flatten([
    for vpc_key, vpc in local.vpc_data : [
      for az_key, az in vpc.subnets.private : [
        for subnet_key, subnet in az : [
          {
            vpc    = vpc.name
            az     = az_key
            name   = subnet.name
            cidr   = subnet.cidr
            netnum = subnet.netnum
          }
        ]
      ]
    ]
  ])

  public_subnets = flatten([
    for vpc_key, vpc in local.vpc_data : [
      for az_key, az in vpc.subnets.public : [
        for subnet_key, subnet in az : [
          {
            vpc    = vpc.name
            az     = az_key
            name   = subnet.name
            cidr   = subnet.cidr
            netnum = subnet.netnum
          }
        ]
      ]
    ]
  ])
}

# ====================================================================================
# VPCs
# ====================================================================================

resource "aws_vpc" "this" {
  provider = aws.mgmt
  # for_each block needs a map, so the for element creates a map with the name as the keys
  for_each                         = { for k, v in local.vpcs : v.name => v }
  enable_dns_hostnames             = true
  enable_dns_support               = true
  assign_generated_ipv6_cidr_block = true
  cidr_block                       = each.value.cidr
  tags = {
    Name        = each.value.name
    Terraform   = "true"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "this" {
  for_each = { for k, v in local.vpcs : v.name => v }
  provider = aws.mgmt
  vpc_id   = aws_vpc.this[each.key].id
  tags = {
    Name        = "${each.key}-rt"
    Terraform   = "true"
    Environment = var.environment
  }
}

resource "aws_subnet" "private" {
  provider                        = aws.mgmt
  for_each                        = { for k, v in local.private_subnets : "${v.vpc}-${v.name}-${v.az}" => v }
  vpc_id                          = aws_vpc.this[each.value.vpc].id
  availability_zone               = each.value.az
  cidr_block                      = each.value.cidr
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.this[each.value.vpc].ipv6_cidr_block, 8, each.value.netnum)
  assign_ipv6_address_on_creation = true
  tags = {
    Name        = "${each.value.name}-${each.value.az}"
    Terraform   = "true"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  provider                        = aws.mgmt
  for_each                        = { for k, v in local.public_subnets : "${v.vpc}-${v.name}-${v.az}" => v }
  vpc_id                          = aws_vpc.this[each.value.vpc].id
  availability_zone               = each.value.az
  cidr_block                      = each.value.cidr
  map_public_ip_on_launch         = true
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.this[each.value.vpc].ipv6_cidr_block, 8, each.value.netnum)
  assign_ipv6_address_on_creation = true
  tags = {
    Name        = "${each.value.name}-${each.value.az}"
    Terraform   = "true"
    Environment = var.environment
  }
}
