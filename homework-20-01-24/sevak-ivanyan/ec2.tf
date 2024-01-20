resource "aws_vpc" "devops_hti_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Devops Hti VPC"
  }
}

resource "aws_instance" "web_instance" {
  ami           = var.aws_ami
  instance_type = "t2.micro"
  key_name      = var.aws_key_pair

  subnet_id                   = aws_subnet.devops_hti_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.devops_hti_aws_sg.id]
  associate_public_ip_address = true

  tags = {
    "Name" : "Devops Hti Instance"
  }
}
