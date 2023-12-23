#!/bin/bash -e

function cleanResourcesByTag
{
#  $1 tag name
#  $2 tag value
  echo "cleaning resources with tag ${1} and value ${2} ..."
  if [ -n "${2}" ]
  then
   cleanInstancesByTag ${1} ${2}
   cleanRouteTables ${1} ${2}
   cleanGateWays ${1} ${2}
   cleanSubnets ${1} ${2}
   cleanSecurityGroups ${1} ${2}
   cleanVPCs ${1} ${2}
  fi
  echo 'end of cleaning...'
}

function cleanInstancesByTag
{
  # Get all instances
  instances=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*]' --output json)

  # Filter instances where tag value is not equal to EXCLUDE_TAG_VALUE
  instances_to_delete=$(echo $instances | jq -r '.[][] | select(.Tags | any(.Key == "'${1}'" and .Value != "'${2}'")).InstanceId')

  # Loop through each instance and terminate it
  for instance_id in $instances_to_delete; do
      echo "Terminating instance $instance_id"
      aws ec2 terminate-instances --instance-ids $instance_id
  done
}

function cleanRouteTables
{
  # Get all instances
    route_tables=$(aws ec2 describe-route-tables --query 'RouteTables[*]' --output json)

    # Filter instances where tag value is not equal to EXCLUDE_TAG_VALUE
    route_tables_to_delete=$(echo $route_tables | jq -r '.[] | select(.Tags | any(.Key == "'${1}'" and .Value != "'${2}'")).RouteTableId')
    # Loop through each instance and terminate it
    for id in $route_tables_to_delete; do
        echo "Deleting route table $id"
        aws ec2 delete-route-table --instance-ids $id
    done
}

function detachGateway
{
  aws ec2 detach-internet-gateway --vpc-id "${1}" --internet-gateway-id "${2}"
}

function cleanGateWays
{
  internet_gateways_to_delete=$(aws ec2 describe-internet-gateways --output json | jq -r '[.InternetGateways[]  | select(.Tags | any(.Key == "'${1}'" and .Value != "'${2}'")) | {VpcId: .Attachments[0].VpcId, InternetGatewayId: .InternetGatewayId}]')
  echo "$internet_gateways_to_delete" | jq -c '.[]' | while read -r gateway; do
      vpc_id=$(echo "$gateway" | jq -r '.VpcId')
      igw_id=$(echo "$gateway" | jq -r '.InternetGatewayId')
      echo "Deleting internet gateway with vpc id $vpc_id and gateway id $igw_id"
      detachGateway "${vpc_id}" "${igw_id}"
      aws ec2 delete-internet-gateway --internet-gateway-id "${igw_id}"
  done
}

function cleanSubnets {
    subnets=$(aws ec2 describe-subnets --query 'Subnets[*]' --output json)
    # Filter instances where tag value is not equal to EXCLUDE_TAG_VALUE
    subnets_to_delete=$(echo $subnets | jq -r '.[] | select(.Tags | any(.Key == "'${1}'" and .Value != "'${2}'")).SubnetId')
    echo $subnets_to_delete
    for id in $subnets_to_delete; do
        echo "Deleting subnets $id"
        aws ec2 delete-subnet --subnet-id $id
    done
}

function cleanSecurityGroups {
    groups=$(aws ec2 describe-security-groups --query 'SecurityGroups[*]' --output json)
    # Filter instances where tag value is not equal to EXCLUDE_TAG_VALUE
    groups_to_delete=$(echo $groups | jq -r '.[] | select(.Tags == null or (.Tags | any(.Key == "'${1}'" and .Value != "'${2}'"))).GroupId')
    for id in $groups_to_delete; do
        echo "Deleting security groups $id"
        aws ec2 delete-security-group --group-id $id
    done
}

function cleanVPCs {
    vpcs=$(aws ec2 describe-vpcs --query 'Vpcs[*]' --output json)
    # Filter instances where tag value is not equal to EXCLUDE_TAG_VALUE
    vpcs_to_delete=$(echo $vpcs | jq -r '.[] | select(.Tags == null or (.Tags | any(.Key == "'${1}'" and .Value != "'${2}'"))).VpcId')
    for id in $vpcs_to_delete; do
        echo "Deleting vpcs $id"
        aws ec2 delete-vpc --vpc-id $id
    done
}