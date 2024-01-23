variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "ami_id" {
  type    = string
  default = "ami-0c7217cdde317cfec"
}
variable "vpc_name" {
  type    = string
  default = "classwork_vpc"
}

variable "ssh_key" {
  type    = string
  default = "###"
}

