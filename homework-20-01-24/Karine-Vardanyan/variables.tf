variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_ami" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0c7217cdde317cfec"
}

variable "aws_key_pair" {
  description = "AWS key pair name"
  type        = string
  default     = "machine"
}

variable "availability_zone" {
  description = "The availability zone for the subnet"
  type        = string
  default     = "a"
}
