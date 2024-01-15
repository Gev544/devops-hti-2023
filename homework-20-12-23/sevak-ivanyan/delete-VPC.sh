#!/bin/bash

region="us-east-1"

allInstances=$(aws ec2 describe-instances --region $region --query 'Reservations[].Instances[].InstanceId' --output text)

instancesToDelete=()
for instanceId in $allInstances; do
    if ! aws ec2 describe-instances --instance-ids $instanceId --region $region --query 'Reservations[].Instances[?Tags[?Key==`usage` && Value==`permanent`]].InstanceId' --output text | grep -q $instanceId; then
        instancesToDelete+=($instanceId)
    fi
done

for instanceId in "${instancesToDelete[@]}"; do
    echo "Terminating instance: $instanceId"
    aws ec2 terminate-instances --instance-ids $instanceId --region $region
done

aws ec2 wait instance-terminated --instance-ids "${instancesToDelete[@]}" --region $region

vpcsToDelete=$(aws ec2 describe-instances --instance-ids "${instancesToDelete[@]}" --region $region --query 'Reservations[].Instances[].VpcId' --output text | sort -u)


for vpcId in $vpcsToDelete; do
    subnetIds=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpcId" --query 'Subnets[].SubnetId' --output text --region $region)
    for subnetId in $subnetIds; do
        echo "Deleting subnet: $subnetId"
        aws ec2 delete-subnet --subnet-id $subnetId --region $region
    done

    routeTableIds=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpcId" --query 'RouteTables[].RouteTableId' --output text --region $region)
    for routeTableId in $routeTableIds; do
        echo "Deleting route table: $routeTableId"
        aws ec2 delete-route-table --route-table-id $routeTableId --region $region
    done

    securityGroupIds=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpcId" --query 'SecurityGroups[].GroupId' --output text --region $region)
    for securityGroupId in $securityGroupIds; do
        echo "Deleting security group: $securityGroupId"
        aws ec2 delete-security-group --group-id $securityGroupId --region $region
    done

    echo "Deleting VPC: $vpcId"
    aws ec2 delete-vpc --vpc-id $vpcId --region $region
done

echo "Deletion script completed successfully"
