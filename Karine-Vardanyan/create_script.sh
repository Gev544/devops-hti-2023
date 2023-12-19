#!/bin/bash


vpc_cidr_block="10.0.0.0/16"
subnet_cidr_block="10.0.1.0/24"
region="eu-north-1"
ami_id="ami-xxxxxxxxxxxx"  # Replace with your desired AMI ID
instance_type="t3.micro"
key_pair="virtual_machine"

# Create VPC
vpc_id=$(aws ec2 create-vpc --cidr-block $vpc_cidr_block --query 'Vpc.VpcId' --output text --region $region)
echo "VPC created with ID: $vpc_id"

# Enable DNS support in the VPC
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-support

# Create subnet
subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $subnet_cidr_block --availability-zone ${region}a --query 'Subnet.SubnetId' --output text)
echo "Subnet created with ID: $subnet_id"

# Create Internet Gateway
internet_gateway_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
echo "Internet Gateway created with ID: $internet_gateway_id"

# Attach Internet Gateway to VPC
aws ec2 attach-internet-gateway --internet-gateway-id $internet_gateway_id --vpc-id $vpc_id

# Create route table
route_table_id=$(aws ec2 create-route-table --vpc-id $vpc_id --query 'RouteTable.RouteTableId' --output text)
echo "Route Table created with ID: $route_table_id"

# Create route to the internet via the Internet Gateway
aws ec2 create-route --route-table-id $route_table_id --destination-cidr-block 0.0.0.0/0 --gateway-id $internet_gateway_id

# Associate route table with subnet
aws ec2 associate-route-table --route-table-id $route_table_id --subnet-id $subnet_id

# Create security group
security_group_id=$(aws ec2 create-security-group --group-name MySecurityGroup --description "My security group" --vpc-id $vpc_id --query 'GroupId' --output text)
echo "Security Group created with ID: $security_group_id"

# Allow inbound traffic on port 22 (SSH) and outbound traffic to the internet
aws ec2 authorize-security-group-ingress --group-id $security_group_id --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $security_group_id --protocol all --port all --cidr 0.0.0.0/0

# Launch EC2 instance
instance_id=$(aws ec2 run-instances --image-id $ami_id --instance-type $instance_type --subnet-id $subnet_id --security-group-ids $security_group_id --key-name $key_pair --query 'Instances[0].InstanceId' --output text)
echo "EC2 instance launched with ID: $instance_id"

# Wait for the instance to be running
aws ec2 wait instance-running --instance-ids $instance_id

# Get the public IP address of the instance
public_ip=$(aws ec2 describe-instances --instance-ids $instance_id --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
echo "Public IP address of the instance: $public_ip"

# Tag resources with usage:permanent for cleanup exemption
aws ec2 create-tags --resources $vpc_id $subnet_id $gateway_id $route_table_id $instance_id --tags Key=usage,Value=permanent