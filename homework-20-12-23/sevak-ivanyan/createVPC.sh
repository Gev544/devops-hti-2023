#!/bin/bash -e

region="us-east-1"

echo "start create vpc"
vpc=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text)
echo "end create vpcId $vpc"

echo "start create sbn"
subnet=$(aws ec2 create-subnet --vpc-id $vpc --cidr-block 10.0.0.1/24 --availability-zone ${region}a --query 'Subnet.SubnetId' --output text)
echo "end create sbnID $subnet"

echo "start create igw"
gateway=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
echo "end create igwID $gateway"

echo "start attach vpc igw"
aws ec2 attach-internet-gateway --vpc-id $vpc --internet-gateway-id $gateway
echo "end attach vpc igw"

echo "start create rte"
routeTable=$(aws ec2 create-route-table --vpc-id $vpc --query 'RouteTable.RouteTableId' --output text)
echo "end create rteId $routeTable"

echo "start open access"
aws ec2 create-route --route-table-id $routeTable --destination-cidr-block 0.0.0.0/0 --gateway-id $gateway
echo "end open access"

echo "start assign sbn rte"
aws ec2 associate-route-table --subnet-id $subnet --route-table-id $routeTable
echo "end assign sbn rte"




