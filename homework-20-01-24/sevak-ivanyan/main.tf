provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "devops_hti_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Some Custom VPC"
  }
}

resource "aws_subnet" "devops_hti_public_subnet" {
  vpc_id            = aws_vpc.devops_hti_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "1a"

  tags = {
    Name = "Some Public Subnet"
  }
}

resource "aws_internet_gateway" "devops_hti_ig" {
  vpc_id = aws_vpc.devops_hti_vpc.id

  tags = {
    Name = "Internet Gateway"
  }
}

resource "aws_route_table" "public_rt" {
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
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "web_sg" {
  name   = "HTTP and SSH"
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

resource "aws_instance" "web_instance" {
  ami           = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t2.micro"
  key_name      = "sevak-aws.pem"

  subnet_id                   = aws_subnet.devops_hti_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  tags = {
    "Name" : "Instance"
  }
}
