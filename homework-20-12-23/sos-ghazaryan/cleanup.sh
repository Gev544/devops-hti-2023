#!/bin/bash -e

function cleanResourcesByTag
{
#  $1 tag name
#  $2 tag value
  echo "cleaning resources with tag ${1} and value ${2} ..."
  if [ -n "${2}" ]
  then
   cleanInstancesByTag ${1} ${2}
    cleanGateWays ${1} ${2}
   cleanSubnets ${1} ${2}
   cleanRouteTables ${1} ${2}
   cleanSecurityGroups ${1} ${2}
   cleanVPCs ${1} ${2}
  fi
  echo 'end of cleaning...'
}

function cleanInstancesByTag
{
  # Get all instances
  instances=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*]' --output json)

#   Filter instances where tag value is not equal to EXCLUDE_TAG_VALUE
  instances_to_delete=$(echo $instances | jq -r '.[][] | select(.Tags == null or (.Tags | any(.Key == "'${1}'" and .Value != "'${2}'"))).InstanceId')
#   Loop through each instance and terminate it
  for instance_id in $instances_to_delete; do
      echo "Terminating instance $instance_id"
      aws ec2 wait terminate-instances --instance-ids $instance_id
  done
}

function cleanRouteTables
{
  route_tables=$(aws ec2 describe-route-tables --query 'RouteTables[*]' --output json)

  # Loop through the route tables
  echo "$route_tables" | jq -c '.[]' | while read -r rt; do
      # Check if it's a main route table
      is_main=$(echo "$rt" | jq '.Associations[]? | select(.Main == true) | length')
      if [[ "$is_main" -eq 0 ]]; then
          # Get the tag value for the specified tag key, if it exists
          tag_val=$(echo "$rt" | jq -r --arg KEY "$TAG_KEY" '.Tags[]? | select(.Key == $KEY).Value // empty')

          # Check if the tag doesn't exist or its value is different
          if [[ -z "$tag_val" || "$tag_val" != "$TAG_VALUE" ]]; then
              # Print Route Table ID
              rt_id=$(echo "$rt" | jq -r '.RouteTableId')
              echo "Deleting route table $rt_id"
               aws ec2 delete-route-table --route-table-id $rt_id
          fi
      fi
  done
}

function detachGateway
{
  aws ec2 detach-internet-gateway --vpc-id "${1}" --internet-gateway-id "${2}"
}

function cleanGateWays
{
  internet_gateways=$(aws ec2 describe-internet-gateways --output json)

  # Loop through the internet gateways
  echo "$internet_gateways" | jq -c '.InternetGateways[]' | while read -r igw; do
      # Check for the presence of the tag and get its value
      tag_val=$(echo "$igw" | jq -r --arg KEY "${1}" '.Tags[] | select(.Key == $KEY).Value // empty')

      # Conditions to determine if an internet gateway does not have the specified tag or tag value
      if [[ -z "${2}" && -z "$tag_val" ]] || [[ -n "${2}" && "$tag_val" != "${2}" ]]; then
          # Print Internet Gateway ID
          igw_id=$(echo "$igw" | jq -r '.InternetGatewayId')
          vpc_id=$(echo "$igw" | jq -r '.Attachments[0] | .VpcId')
          detachGateway "${vpc_id}" "${igw_id}"
          aws ec2 delete-internet-gateway --internet-gateway-id "${igw_id}"
      fi
  done
}

function cleanSubnets {
    subnets=$(aws ec2 describe-subnets --query 'Subnets[*]' --output json)
    # Filter instances where tag value is not equal to EXCLUDE_TAG_VALUE
    subnets_to_delete=$(echo $subnets | jq -r '.[] | select(.Tags == null or (.Tags | any(.Key == "'${1}'" and .Value != "'${2}'"))).SubnetId')
    for id in $subnets_to_delete; do
        echo "Deleting subnets $id"
        aws ec2 delete-subnet --subnet-id $id
    done
}

function cleanSecurityGroups {
    groups=$(aws ec2 describe-security-groups --query 'SecurityGroups[?GroupName!=`default`]' --output json)
    # Filter instances where tag value is not equal to EXCLUDE_TAG_VALUE
      groups_to_delete=$(echo $groups | jq -r '.[] | select(.Tags == null or (.Tags | any(.Key == "'${1}'" and .Value != "'${2}'"))).GroupId')
      echo $groups_to_delete
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

TO_KEEP_TAG="usage"
TO_KEEP_TAG_VALUE="permanent"

cleanResourcesByTag  "${TO_KEEP_TAG}" "${TO_KEEP_TAG_VALUE}"
