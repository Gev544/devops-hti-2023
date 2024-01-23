resource "aws_instance" "app_server" {
  ami           = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t2.micro"
  key_name      = "MyKeyPair"

  subnet_id                   = aws_subnet.terraform_subnet.id
  vpc_security_group_ids      = [aws_security_group.ssh_group.id]
  associate_public_ip_address = true

  tags = {
    Name = "terraform_ec2"

  }
}

resource "aws_security_group" "ssh_group" {
  name   = "SSH"
  vpc_id = aws_vpc.terraform_vpc.id


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

#ami-0c7217cdde317cfec
