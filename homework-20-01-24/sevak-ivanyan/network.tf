resource "aws_internet_gateway" "devops_hti_ig" {
  vpc_id = aws_vpc.devops_hti_vpc.id

  tags = {
    Name = "Internet Gateway"
  }
}

resource "aws_route_table" "devops_hti_public_rt" {
  vpc_id = aws_vpc.devops_hti_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devops_hti_ig.id
  }

  tags = {
    Name = "Public Route Table"
  }
}
resource "aws_route_table_association" "devops_hti_public_rt_a" {
  subnet_id      = aws_subnet.devops_hti_public_subnet.id
  route_table_id = aws_route_table.devops_hti_public_rt.id
}

resource "aws_security_group" "devops_hti_aws_sg" {
  name   = "SSH"
  vpc_id = aws_vpc.devops_hti_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}
