#!/bin/bash -ex

region="us-east-1"

vpc_id=$(aws ec2 create-vpc --cidr-block='10.0.0.0/16' --region="$region" --query='Vpc.VpcId' --output=text)

igw_id=$(aws ec2 create-internet-gateway --region="$region" --query='InternetGateway.InternetGatewayId' --output=text)

aws ec2 attach-internet-gateway --vpc-id="$vpc_id" --internet-gateway-id="$igw_id" --region="$region"

subnet_id=$(aws ec2 create-subnet --vpc-id="$vpc_id" --cidr-block='10.0.0.0/24' --region="$region" --query='Subnet.SubnetId' --output=text)

route_table_id=$(aws ec2 create-route-table --vpc-id="$vpc_id" --region="$region" --query='RouteTable.RouteTableId' --output=text)

aws ec2 create-route --destination-cidr-block='0.0.0.0/0' --route-table-id="$route_table_id" --gateway-id="$igw_id" --region="$region"

aws ec2 associate-route-table --subnet-id="$subnet_id" --route-table-id="$route_table_id" --region="$region"

security_group_id=$(aws ec2 create-security-group --group-name="MySecurityGroup" --description="My security group description" --vpc-id="$vpc_id" --output=text --query='GroupId')

aws ec2 authorize-security-group-ingress --group-id="$security_group_id" --protocol='tcp' --port='22' --cidr='0.0.0.0/0'

aws ec2 run-instances --image-id='ami-0fe8bec493a81c7da' --count='1' --instance-type='t2.micro' --key-name='devops' --subnet-id="$subnet_id" --security-group-ids="$security_group_id" --associate-public-ip-address --region="$region"

