resource "aws_security_group" "sec_group" {
  name   = "HTTP and SSH"
  vpc_id = aws_vpc.classwork_vpc.id

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
  ami           = "${var.ami_id}"
  instance_type = "t2.nano"
  key_name      = "${var.ssh_key}"

  subnet_id                   = aws_subnet.aws_pub_sub.id
  vpc_security_group_ids      = [aws_security_group.sec_group.id]
  associate_public_ip_address = true
 tags = {
    "Name" : "classwork"
  }
}

