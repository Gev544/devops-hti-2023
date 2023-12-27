#!/bin/bash -e

region="us-east-1"
keyPairName="*"
amiId="ami-*"

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

echo "start creating EC2 instance"
instance=$(aws ec2 run-instances --image-id $amiId --instance-type t2.micro --key-name $keyPairName --subnet-id $subnet --query 'Instances[0].InstanceId' --output text --region $region)
echo "end EC2 instance created $instance"

echo "start running EC2 instance"
aws ec2 wait instance-running --instance-ids $instance --region $region
echo "EC2 instance running"

echo "elastic IP allocate"
publicIp=$(aws ec2 allocate-address --domain vpc --query 'PublicIp' --output text --region $region)
echo "elastic IP allocated $publicIp"

echo "associate the IP with the instance"
aws ec2 associate-address --instance-id $instance --public-ip $publicIp --region $region
echo "elastic IP associated"




