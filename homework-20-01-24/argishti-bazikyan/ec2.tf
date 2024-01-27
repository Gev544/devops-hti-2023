resource "aws_instance" "terraform" {
  ami                         = "ami-0c7217cdde317cfec"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.terraform.id
  vpc_security_group_ids      = [aws_security_group.terraform.id]
  associate_public_ip_address = "true"
  key_name                    = "terraform_rsa"

  tags = {
    Name = "terraform"
  }
}