
variable "vpc_id" {
  description = "ID of the VPC"
}

# Create public subnet for NAT Gateway
resource "aws_subnet" "public_subnet" {
  vpc_id                  = var.vpc_id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a" # Change this to your desired AZ
  map_public_ip_on_launch = true
}


# Create internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = var.vpc_id
}

# Create route table for public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}


# Associate public route table with the public subnet
resource "aws_route_table_association" "public_route_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create security group allowing SSH and outbound internet traffic
resource "aws_security_group" "my_security_group" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


output "subnet_id" {
  value = aws_subnet.public_subnet.id
}

output "security_group_id" {
  value = aws_security_group.my_security_group.id
}

