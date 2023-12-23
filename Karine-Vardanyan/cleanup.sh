#!/bin/bash

# Function to delete EC2 instances in a given region
delete_ec2_instances() {
  region=$1
  aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId]' --output text --region $region | \
  while read -r instance_id; do
    aws ec2 terminate-instances --instance-ids $instance_id --region $region
  done
}

# Function to delete VPC resources in a given region
cleanup_vpcs() {
  region=$1

  # Get all VPCs
  vpc_ids=($(aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId]' --output text --region $region))

  for vpc_id in "${vpc_ids[@]}"; do

    # Get all instances and terminate them
    delete_ec2_instances $region

    # Delete security groups excluding the default security group
    security_group_ids=($(aws ec2 describe-security-groups --query "SecurityGroups[?VpcId=='$vpc_id' && GroupName!='default'].GroupId" --output text --region $region))
    for group_id in "${security_group_ids[@]}"; do
      aws ec2 delete-security-group --group-id $group_id --region $region
    done


    # Delete subnets
    subnet_ids=($(aws ec2 describe-subnets --query "Subnets[?VpcId=='$vpc_id'].SubnetId" --output text --region $region))
    for subnet_id in "${subnet_ids[@]}"; do
      # Delete subnet
      aws ec2 delete-subnet --subnet-id $subnet_id --region $region

      # Delete route table associated with the subnet
      route_table_id=$(aws ec2 describe-route-tables --query "RouteTables[?Associations[0].SubnetId=='$subnet_id'].RouteTableId" --output text --region $region)
      aws ec2 delete-route-table --route-table-id $route_table_id --region $region
    done

    # Detach internet gateways
    igw_ids=($(aws ec2 describe-internet-gateways --query "InternetGateways[?Attachments[0].VpcId=='$vpc_id'].InternetGatewayId" --output text --region $region))
    for igw_id in "${igw_ids[@]}"; do
      aws ec2 detach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id --region $region
      aws ec2 delete-internet-gateway --internet-gateway-id $igw_id --region $region
    done

    # Delete VPC
    aws ec2 delete-vpc --vpc-id $vpc_id --region $region
  done
}

# Replace 'your-region' with the AWS region where you want to perform cleanup
cleanup_vpcs "us-east-1"
