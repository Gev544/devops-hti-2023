resource "aws_instance" "my_instance" {
  ami                          = var.aws_ami
  instance_type                = "t2.micro"
  subnet_id                    = aws_subnet.public_subnet.id
  vpc_security_group_ids       = [aws_security_group.my_sg.id]
  key_name                     = var.aws_key_pair

  tags = {
    Name = "my_instance"
  }
}
