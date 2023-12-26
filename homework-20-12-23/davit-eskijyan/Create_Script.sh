#!/bin/bash

# Check if the required arguments are provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <vpc-cidr> <subnet-cidr> <region> <instance-type>"
    exit 1
fi

# Assign arguments to variables
vpc_cidr="$1"
subnet_cidr="$2"
region="$3"
instance_type="$4"

# Find the Ubuntu for region
ami_id=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*" \
  --query "Images[0].ImageId" \
  --region "$region" \
  --output text)

# Create VPC
vpc_output=$(aws ec2 create-vpc \
   --cidr-block "$vpc_cidr" \
   --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=NewVPC}]' \
   --region "$region")
vpc_id=$(echo "$vpc_output" | jq -r '.Vpc.VpcId')
echo "-VPC Created: $vpc_id"


# Enable DNS hostnames for the VPC
aws ec2 modify-vpc-attribute \
   --vpc-id "$vpc_id" \
   --enable-dns-hostnames
echo "-Enabled DNS hostname for VPC"

# Enable DNS support for the VPC
aws ec2 modify-vpc-attribute \
  --vpc-id "$vpc_id" \
  --enable-dns-support
echo "-Enabled DNS support for VPC"

# Create Subnet
subnet_output=$(aws ec2 create-subnet \
   --vpc-id "$vpc_id" \
   --cidr-block "$subnet_cidr" \
   --region "$region")
subnet_id=$(echo "$subnet_output" | jq -r '.Subnet.SubnetId')
echo "-Subnet Created: $subnet_id"

# Enable auto-assign public IPv4 addresses for the subnet
aws ec2 modify-subnet-attribute \
  --subnet-id "$subnet_id" \
  --map-public-ip-on-launch
echo "-Public IPv4 address assigned to ec2"

# Create Internet Gateway
internet_gateway_output=$(aws ec2 create-internet-gateway \
 --region "$region")
internet_gateway_id=$(echo "$internet_gateway_output" | jq -r '.InternetGateway.InternetGatewayId')
echo "-Internet Gateway created: $internet_gateway_id"

# Attach Internet Gateway to VPC
aws ec2 attach-internet-gateway \
  --internet-gateway-id "$internet_gateway_id" \
  --vpc-id "$vpc_id" \
  --region "$region"
echo "-Internet Gateway Attuched to VPC"

# Create Route Table
route_table_output=$(aws ec2 create-route-table \
  --vpc-id "$vpc_id" \
  --region "$region")
route_table_id=$(echo "$route_table_output" | jq -r '.RouteTable.RouteTableId')
echo "-Routing Table created: $route_table_id"

# Create Route
aws ec2 create-route \
  --route-table-id "$route_table_id" \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id "$internet_gateway_id" \
  --region "$region"
echo "-Route created to Internet"

# Associate Route Table with Subnet
aws ec2 associate-route-table \
 --route-table-id "$route_table_id" \
 --subnet-id "$subnet_id" \
 --region "$region"
echo "-Route Table associated with Subnet"

# Allocate Elastic IP
eip_allocation=$(aws ec2 allocate-address \
 --domain vpc --region "$region")
eip_allocation_id=$(echo "$eip_allocation" | jq -r '.AllocationId')
echo "-Elastic Ip attuchd to EC2"

# Create VM in New VPC
  
key_name="Frankfurt_Key"  # Replace with your actual key pair name
instance_name="New-Ubuntu"  # Name tag for the instance

# Run instance with Elastic IP
instance_output=$(aws ec2 run-instances \
  --image-id "$ami_id" \
  --instance-type "$instance_type" \
  --key-name "$key_name" \
  --subnet-id "$subnet_id" \
  --associate-public-ip-address \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value='"$instance_name"'}]' \
  --region "$region")
echo "Instance Created: $instance_name, type: $instance_type"

# Extract instance ID
instance_id=$(echo "$instance_output" | jq -r '.Instances[0].InstanceId')

#Security Group variables
security_group_name="SecurityGR"
description="Allow SSH for 0.0.0.0/0"

# Create a new security group
security_group_id=$(aws ec2 create-security-group \
  --group-name "$security_group_name" \
  --description "$description" \
  --vpc-id "$vpc_id" \
  --output text \
  --query 'GroupId')
echo "-Security Group Created: name $security_group_name"

# Add an inbound rule to allow SSH traffic from any IP address
ssh_rule=$(aws ec2 authorize-security-group-ingress \
  --group-id "$security_group_id" \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0)
echo "-Allowd SSH from 0.0.0.0/0"

# Associate the security group with the instance
aws ec2 modify-instance-attribute \
  --instance-id "$instance_id" \
  --groups "$security_group_id"
echo "-Security group associated with the instance."

