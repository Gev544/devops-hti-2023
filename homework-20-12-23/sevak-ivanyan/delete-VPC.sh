#!/bin/bash

ec2_instances=$(aws ec2 describe-instances --output json | jq -r '.Reservations[].Instances[] | select(.Tags[] | .Key == "usage" and .Value == "permanent" | not) | .InstanceId' | tr -d '"')

while read -r ec2_id
do
	if [ -z "$ec2_id" ]; then
		break
	elif [ "$(aws ec2 describe-instances --output json | jq -r '.Reservations[].Instances[] | select(.InstanceId == "'"$ec2_id"'") | .State.Name' | tr -d '"')" = "terminated" ]; then
		:
	else
		echo "Terminating EC2 instances that do not have Key 'usage' and Value 'permanent' tags"
		aws ec2 terminate-instances --instance-ids "$ec2_id"
	fi
done <<< "$ec2_instances"

echo "Sleeping for 30 seconds while waiting for instances to be fully terminated."
sleep 30

vpcs_to_delete=$(aws ec2 describe-vpcs --output json | jq -r '.Vpcs[] | select(.Tags[] | .Key == "usage" and .Value == "permanent" | not) | .VpcId' | tr -d '"')

while read -r vpc_id
do
	if [ -z "$vpc_id" ]; then
		echo "Did not find any VPCs"
		break
	else
		igw=$(aws ec2 describe-internet-gateways --output json | jq -r '.InternetGateways[] | select(.Attachments[].VpcId == "'"$vpc_id"'") | .InternetGatewayId' | tr -d '"')

		if [ ! -z "$igw" ]; then
			echo "Detaching Internet Gateway"
			aws ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$vpc_id"
			echo "Deleting Internet Gateway"
			aws ec2 delete-internet-gateway --internet-gateway-id "$igw"
		fi

		# Subnet delete
		subnets=$(aws ec2 describe-subnets --output json | jq -r '.Subnets[] | select(.VpcId == "'"$vpc_id"'") | .SubnetId' | tr -d '"')
		while read -r subnet_id
		do
			if [ ! -z "$subnet_id" ]; then
				echo "Deleting Subnet"
				aws ec2 delete-subnet --subnet-id "$subnet_id"
			fi
		done <<< "$subnets"

		# Delete route table
		route_tables=$(aws ec2 describe-route-tables --output json | jq -r '.RouteTables[] | select(.VpcId == "'"$vpc_id"'") | .RouteTableId ' | tr -d '"')
		while read -r rtbl_id
		do
			if [ ! -z "$rtbl_id" ]; then
				echo "Deleting Route Table"
				aws ec2 delete-route-table --route-table-id "$rtbl_id"
			fi
		done <<< "$route_tables"

		sec_groups=$(aws ec2 describe-security-groups --output json | jq -r '.SecurityGroups[] | select(.VpcId == "'"$vpc_id"'") | .GroupId' | tr -d '"')
		while read -r sec_grp_id
		do
			if [ ! -z "$sec_grp_id" ]; then
				echo "Deleting Security Groups"
				aws ec2 delete-security-group --group-id "$sec_grp_id"
			fi
		done <<< "$sec_groups"

		echo "Deleting VPC $vpc_id"
		aws ec2 delete-vpc --vpc-id "$vpc_id"
	fi
done <<< "$vpcs_to_delete"
