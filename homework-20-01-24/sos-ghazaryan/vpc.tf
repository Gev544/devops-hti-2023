provider "aws" {
  region = var.availability_zone_names
}

resource "aws_vpc" "main_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "test_terraform"
  }
}

resource "aws_security_group" "main_allow_tls" {
  vpc_id      = aws_vpc.main_vpc.id
  tags = {
    Name = "test_terraform"
  }
   ingress = [
    {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description      = "SSH"
        ipv6_cidr_blocks = []
        prefix_list_ids = []
        security_groups = []
        
        self = false
    },
    {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description      = "HTTP"
        ipv6_cidr_blocks = []
        prefix_list_ids = []
        security_groups = []
        self = false
    }
   ]
   egress {
    from_port = "0"
    to_port = "0"
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "-1"
   }
}

resource "aws_subnet" "main_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "test_terraform"
  }
}

resource "aws_internet_gateway" "main_gw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "test_terraform"
  }
}

resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_gw.id
  }

  tags = {
    Name = "test_terraform"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_route_table.id
}