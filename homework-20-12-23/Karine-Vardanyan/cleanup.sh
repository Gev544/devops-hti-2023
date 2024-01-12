#!/bin/bash

# Function to delete EC2 instances in a given region
delete_ec2_instances() {
  region=$1
  vpc_id=$2

  aws ec2 describe-instances --query "Reservations[*].Instances[*].[InstanceId,VpcId,PublicIpAddress,Tags[?Key=='usage' && Value=='permanent']]" \
    --output text --region $region | \
  while read -r instance_id vpc public_ip permanent_tag; do
    if [ "$vpc" == "$vpc_id" ] && [ "$permanent_tag" == "None" ]; then
      allocation_id=$(aws ec2 describe-addresses --public-ips $public_ip --query 'Addresses[*].AllocationId' --output text --region $region)
      aws ec2 terminate-instances --instance-ids $instance_id --region $region
	  echo "EC2 instance $instance_id terminated successfully."
	  
      if [ -n "$public_ip" ]; then
        aws ec2 disassociate-address --association-id $(aws ec2 describe-addresses --public-ips $public_ip --query 'Addresses[*].AssociationId' --output text --region $region) --region $region
        aws ec2 release-address --allocation-id $allocation_id --region $region
		echo "EC2 instance $public_ip released successfully."
      fi
	  
    else
       echo "Skipping termination of permanent instance: $instance_id"
    fi
  done
}



# Function to delete a security group with retries
delete_security_group_with_retries() {
  group_id=$1
  retries=8

  while [ $retries -gt 0 ]; do
    if aws ec2 delete-security-group --group-id $group_id --region $region; then
      echo "Security Group $group_id deleted successfully."
	  break
    else
      echo "Failed to delete Security Group $group_id. Retrying..."
      ((retries--))
      sleep 5  # Exponential backoff, starting with 1 second and increasing
    fi
  done

  if [ $retries -eq 0 ]; then
    echo "Max retries reached. Unable to delete Security Group $group_id."
  fi
}


# Function to delete VPC resources in a given region
cleanup_vpcs() {
  region=$1


 # Get all VPCs
 vpc_ids=($(aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key=='usage' && Value=='permanent']]' --output text --region $region | \
    grep -E '^vpc-' | awk '{print $1}'))


  for vpc_id in "${vpc_ids[@]}"; do
    permanent_tag=$(aws ec2 describe-vpcs --vpc-ids "$vpc_id" --query "Vpcs[*].Tags[?Key=='usage' && Value=='permanent'].Value" --output text --region "$region")
	if [ -z "$permanent_tag" ]; then
		# Get all instances and terminate them
		delete_ec2_instances $region $vpc_id

		# Delete security groups excluding the default security group
		security_group_ids=($(aws ec2 describe-security-groups --query "SecurityGroups[?VpcId=='$vpc_id' && GroupName!='default'].GroupId" --output text --region $region))
		for group_id in "${security_group_ids[@]}"; do
			delete_security_group_with_retries $group_id
		done
		
		sleep 2

		# Delete subnets
		subnet_ids=($(aws ec2 describe-subnets --query "Subnets[?VpcId=='$vpc_id'].SubnetId" --output text --region $region))
		for subnet_id in "${subnet_ids[@]}"; do
		  # Delete subnet
		  route_table_id=$(aws ec2 describe-route-tables --query "RouteTables[?Associations[0].SubnetId=='$subnet_id'].RouteTableId" --output text --region $region)
		  aws ec2 delete-subnet --subnet-id $subnet_id
		  echo "Subnet $subnet_id deleted successfully."
		  sleep 2
		  # Delete route table associated with the subnet
		  aws ec2 delete-route-table --route-table-id $route_table_id
		  echo "Route table $route_table_id deleted successfully." 
		done
	
		sleep 2
		
		# Detach internet gateways
		igw_ids=($(aws ec2 describe-internet-gateways --query "InternetGateways[?Attachments[0].VpcId=='$vpc_id'].InternetGatewayId" --output text --region $region))
		for igw_id in "${igw_ids[@]}"; do
		  aws ec2 detach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id
		  aws ec2 delete-internet-gateway --internet-gateway-id $igw_id
		  echo "Internet Gateway $igw_id deleted successfully."
		done
		
		sleep  2
		
		# Delete VPC
		aws ec2 delete-vpc --vpc-id $vpc_id --region $region
		echo "VPC $igw_id deleted successfully."
		
	else
		echo "Skipping deletion of permanent VPC: $vpc_id"
	fi
  done
}

cleanup_vpcs "us-east-1"



