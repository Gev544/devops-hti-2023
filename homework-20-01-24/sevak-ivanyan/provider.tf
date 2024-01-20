provider "aws" {
  region = var.aws_region
}

resource "aws_subnet" "devops_hti_public_subnet" {
  vpc_id            = aws_vpc.devops_hti_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "1a"

  tags = {
    Name = "Devops Hti Public Subnet"
  }
}