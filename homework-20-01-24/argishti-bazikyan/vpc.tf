resource "aws_vpc" "terraform" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "terraform"
  }
}

resource "aws_internet_gateway" "terraform" {
  vpc_id = aws_vpc.terraform.id

  tags = {
    Name = "terraform"
  }
}

resource "aws_subnet" "terraform" {
  vpc_id     = aws_vpc.terraform.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "terraform"
  }
}

resource "aws_route_table" "terraform" {
  vpc_id = aws_vpc.terraform.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform.id
  }

  tags = {
    Name = "terraform"
  }
}

resource "aws_route_table_association" "terraform" {
  subnet_id      = aws_subnet.terraform.id
  route_table_id = aws_route_table.terraform.id
}

resource "aws_security_group" "terraform" {
  name        = "terraform"
  description = "terraform"
  vpc_id      = aws_vpc.terraform.id

  tags = {
    Name = "terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "terraform" {
  security_group_id = aws_security_group.terraform.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "terraform" {
  security_group_id = aws_security_group.terraform.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
