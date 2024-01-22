# Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
 
   tags = {
    Name = "my-vpc"
  }	

}

output "vpc_id" {
  value = aws_vpc.my_vpc.id
}
