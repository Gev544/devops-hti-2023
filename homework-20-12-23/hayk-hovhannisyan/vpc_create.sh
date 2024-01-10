#!/bin/bash
# create-aws-vpc
#variables used in script:
availabilityZone="us-east-1a"
name="vpc_for_test"
vpcName="$name VPC"
subnetName="$name Subnet"
gatewayName="$name Gateway"
routeTableName="$name Route Table"
securityGroupName="$name Security Group"
vpcCidrBlock="10.0.0.0/16"
subNetCidrBlock="10.0.1.0/24"
port22CidrBlock="0.0.0.0/0"
destinationCidrBlock="0.0.0.0/0"
echo "Creating VPC..."
#create vpc with cidr block /16
aws_response=$(aws ec2 create-vpc --cidr-block "$vpcCidrBlock" --output json)
vpcId=$(echo -e "$aws_response" |  /usr/bin/jq '.Vpc.VpcId' | tr -d '"')
#name the vpc
aws ec2 create-tags --resources "$vpcId" --tags Key=Name,Value="$vpcName"
#add dns support
modify_response=$(aws ec2 modify-vpc-attribute --vpc-id "$vpcId" --enable-dns-support "{\"Value\":true}")
#add dns hostnames
modify_response=$(aws ec2 modify-vpc-attribute --vpc-id "$vpcId" --enable-dns-hostnames "{\"Value\":true}")
#create internet gateway
gateway_response=$(aws ec2 create-internet-gateway --output json)
gatewayId=$(echo -e "$gateway_response" |  /usr/bin/jq '.InternetGateway.InternetGatewayId' | tr -d '"')
#name the internet gateway
aws ec2 create-tags --resources "$gatewayId" --tags Key=Name,Value="$gatewayName"
#attach gateway to vpc
attach_response=$(aws ec2 attach-internet-gateway --internet-gateway-id "$gatewayId"  --vpc-id "$vpcId")
#create subnet for vpc with /24 cidr block
subnet_response=$(aws ec2 create-subnet --cidr-block "$subNetCidrBlock" --availability-zone "$availabilityZone" --vpc-id "$vpcId" --output json)
subnetId=$(echo -e "$subnet_response" |  /usr/bin/jq '.Subnet.SubnetId' | tr -d '"')
#name the subnet
aws ec2 create-tags --resources "$subnetId" --tags Key=Name,Value="$subnetName"
#enable public ip on subnet
modify_response=$(aws ec2 modify-subnet-attribute --subnet-id "$subnetId" --map-public-ip-on-launch)
#create security group
security_response=$(aws ec2 create-security-group --group-name "$securityGroupName" --description "Private: $securityGroupName" --vpc-id "$vpcId" --output json)
groupId=$(echo -e "$security_response" |  /usr/bin/jq '.GroupId' | tr -d '"')
#name the security group
aws ec2 create-tags --resources "$groupId" --tags Key=Name,Value="$securityGroupName"
#enable port 22
security_response2=$(aws ec2 authorize-security-group-ingress --group-id "$groupId" --protocol tcp --port 22 --cidr "$port22CidrBlock")
#create route table for vpc
route_table_response=$(aws ec2 create-route-table --vpc-id "$vpcId" --output json)
routeTableId=$(echo -e "$route_table_response" |  /usr/bin/jq '.RouteTable.RouteTableId' | tr -d '"')
#name the route table
aws ec2 create-tags --resources "$routeTableId" --tags Key=Name,Value="$routeTableName"
#add route for the internet gateway
route_response=$(aws ec2 create-route --route-table-id "$routeTableId" --destination-cidr-block "$destinationCidrBlock" --gateway-id "$gatewayId")
#add route to subnet
associate_response=$(aws ec2 associate-route-table --subnet-id "$subnetId" --route-table-id "$routeTableId")
echo " "
echo "VPC created:"
echo "Use subnet id $subnetId and security group id $groupId"
echo "To create your AWS instances"
# end of create-aws-vpc


ami_id=ami-0fc5d935ebf8bc3bc
instanse_type=t2.micro
key_pair=$$_key_vpc
aws ec2 create-key-pair --key-name $key_pair --query 'KeyMaterial' --output text > $key_pair.pem
#chmod 400 key-vpc-ec2.pem

instanse_id=$(aws ec2 run-instances \
    --image-id $ami_id \
    --count 1 \
    --instance-type $instanse_type \
    --key-name $key_pair \
    --security-group-ids $groupId \
    --subnet-id $subnetId \
    --associate-public-ip-address \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=for_create_test}]' \
    --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":20,"VolumeType":"gp2"}}]' \
    --query 'Instances[0].InstanceId' \
    --output text) 
echo "Instance launched with id $instanse_id"

instance_ip=$(aws ec2 describe-instances \
    --instance-ids $instanse_id \
    --query "Reservations[0].Instances[0].PublicIpAddress" --output text)  
echo "EC2 instance myServer1 IP: $instance_ip"
echo "To connect $instance_ip instance"
echo "sudo ssh -i  $key_pair.pem ubuntu@$instance_ip"
echo "to delete  key pair"
echo "aws ec2 delete-key-pair --key-name $key_pair --region us-east-1"
