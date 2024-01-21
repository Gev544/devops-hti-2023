variable "aim_image" {
  type = string
  default = "ami-0c7217cdde317cfec"
}

variable "availability_zone_names" {
  type    = string
  default = "us-east-1"
}

variable "aws_key_pair" {
  type = string
  default = "test"
}