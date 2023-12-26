#!/bin/bash


region="us-east-1a"


has_permanent_tag() {
    resource_id=$1
    tag_value=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$resource_id" "Name=key,Values=usage" --query "Tags[0].Value" --output text)
    [ "$tag_value" == "permanent" ]
}


delete_resource() {
    resource_id=$1
    resource_type=$2

    if has_permanent_tag "$resource_id"; then
        echo "$resource_type with ID $resource_id has 'usage:permanent' tag. Skipping deletion."
    else
        echo "Deleting $resource_type with ID $resource_id"
        aws ec2 delete-"$resource_type" --"$resource_type"-id "$resource_id" --region "$region"
    fi
}


delete_resource "$instance_id" "instances"
delete_resource "$internet_gateway_id" "internet-gateway"
delete_resource "$route_table_id" "route-table"
delete_resource "$subnet_id" "subnet"
delete_resource "$security_group_id" "security-group"
delete_resource "$vpc_id" "vpc"

echo "Cleanup script execution completed."

