variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-central-1"
}

variable "aws_ami" {
  description = "Instance ID (Linux Ubuntu Server)"
  type        = string
  default     = "ami-0faab6bdbac9486fb"
}

variable "aws_key_pair" {
  description = "AWS key pair name"
  type        = string
  default     = "Frankfurt_Key"
}

variable "aws_instance_type" {
  description = "AWS Instance Type"
  type        = string
  default     = "t2.micro"
}
