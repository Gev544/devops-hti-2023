#!/bin/bash -ex

source ./helpers.sh

AWS_REGION="us-east-1"

unset VPC_ID
check "aws ec2 create-vpc --cidr-block 10.0.0.0/24 --region ${AWS_REGION} --query Vpc.VpcId --output text" true RESULT
VPC_ID=$RESULT


unset SECURITY_GROUP_ID
check "aws ec2 create-security-group --group-name security-group-name --description description --vpc-id ${VPC_ID} --query GroupId --output text" true RESULT
SECURITY_GROUP_ID=$RESULT


check "aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 22 --cidr 0.0.0.0/0" false
check "aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 80 --cidr 0.0.0.0/0" false

unset SUBNET_ID
check "aws ec2 create-subnet  --vpc-id ${VPC_ID}  --cidr-block 10.0.0.0/25 --query Subnet.SubnetId --output text" true RESULT
SUBNET_ID=$RESULT


unset GETWAY_ID
check "aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text" treu RESULT
GETWAY_ID=$RESULT


check "aws ec2 attach-internet-gateway  --internet-gateway-id ${GETWAY_ID}  --vpc-id ${VPC_ID}" false

unset ROUTE_TABLE_ID
check "aws ec2 create-route-table --vpc-id ${VPC_ID} --query RouteTable.RouteTableId --output text" true RESULT
ROUTE_TABLE_ID=$RESULT


check "aws ec2 create-route --route-table-id ${ROUTE_TABLE_ID} --destination-cidr-block 0.0.0.0/0 --gateway-id  ${GETWAY_ID}" false

check "aws ec2 associate-route-table --route-table-id ${ROUTE_TABLE_ID} --subnet-id ${SUBNET_ID}" false

unset INSTANCE_ID
check "aws ec2 run-instances --image-id ami-0533f2ba8a1995cf9 --instance-type t2.micro --count 1 --subnet-id ${SUBNET_ID} --security-group-ids ${SECURITY_GROUP_ID} --associate-public-ip-address --key-name cli-keyPair --query Instances[0].InstanceId --output text" true RESULT
INSTANCE_ID=$RESULT


