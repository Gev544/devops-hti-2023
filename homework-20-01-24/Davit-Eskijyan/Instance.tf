resource "aws_security_group" "my_sg" {
  vpc_id = aws_vpc.my_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my_sg"
  }
}

resource "aws_instance" "VM-Ubuntu_SRV" {
    ami                  = var.aws_ami
    instance_type        = var.aws_instance_type
    subnet_id            = aws_subnet.public_subnet.id
    vpc_security_group_ids = [aws_security_group.my_sg.id]
    key_name             = var.aws_key_pair
     tags = {
      Name = "VM-Ubuntu_SRV"
    }
  }
