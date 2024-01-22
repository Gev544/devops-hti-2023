# variables.tf

variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  default     = "ami-0c7217cdde317cfec"  # Amazon Linux 2 AMI (replace with a valid AMI for your region)
}

variable "instance_type" {
  description = "Instance type for the EC2 instance"
  default     = "t2.micro"
}

variable "key_pair_name" {
  description = "Name of the key pair used for SSH access"
  default     = "learning2"  # Replace with your actual key pair name
}
