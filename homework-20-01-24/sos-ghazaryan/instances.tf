resource "aws_instance" "aws_web_instance" {
  ami           = "${var.aim_image}"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.main_subnet.id
  associate_public_ip_address = "true"
  vpc_security_group_ids = [
    aws_security_group.main_allow_tls.id
  ]
  key_name        = var.aws_key_pair
  tags = {
    Name = "test_terraform"
  }
}