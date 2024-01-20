variable "aws_region" {
  description = "region"
  type        = string
  default     = "us-east-1"
}

variable "aws_ami" {
  description = "AMI"
  type        = string
  default     = "*"
}

variable "aws_key_pair" {
  description = "pair key"
  type        = string
  default     = "machine"
}