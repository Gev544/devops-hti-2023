

variable "ami_id" {
  description = "Amazon Linux 2 AMI (replace with a valid AMI for your region)"
}

variable "instance_type" {
  description = "Amazon instance_type"
}

variable "subnet_id" {
  description = "ID of the subnet where the EC2 instance will be launched"
}

variable "security_group_id" {
  description = "ID of the security group for the EC2 instance"
}

variable "key_name" {
  description = "Name of the key pair used for SSH access"
}


# Create EC2 instance in the private subnet
resource "aws_instance" "my_ec2_instance" {
  ami             = var.ami_id
  instance_type   = var.instance_type
  subnet_id       = var.subnet_id
  key_name        = var.key_name

  vpc_security_group_ids = [var.security_group_id]

  associate_public_ip_address = true

}
