
resource "aws_vpc" "classwork_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.vpc_name}"
  }
}

resource "aws_subnet" "aws_pub_sub" {
  vpc_id            = aws_vpc.classwork_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "public_subnet"
  }
}


resource "aws_internet_gateway" "vpc_gateway" {
  vpc_id = aws_vpc.classwork_vpc.id

  tags = {
    Name = "vpc_gateway"
  }
}
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.classwork_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_gateway.id
  }


  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "public_rt_1" {
  subnet_id      = aws_subnet.aws_pub_sub.id
  route_table_id = aws_route_table.public_rt.id
}

