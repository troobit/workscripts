
resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this["a4l-vpc1"].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this["a4l-vpc1"].id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.this["a4l-vpc1"].id
  }

  tags = {
    Name        = "a4l-vpc1-rt-web"
    OpenTofu    = "true"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.this.id
}
