resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_ig.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "public_1_rt" {
  subnet_id      = aws_subnet.terraform_subnet.id
  route_table_id = aws_route_table.public_route.id
}
