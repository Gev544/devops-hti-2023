#!/bin/bash -ex

#source set_up.sh

region="eu-north-1"

# delete instances
ec2_ids=$(aws ec2 describe-instances --query "Reservations[?!(Instances[0].Tags && Instances[0].Tags[?Key=='usage' && Value=='permanent'])].Instances[*].InstanceId" --output text --region="$region")

if [ -n "$ec2_ids" ]; then
    aws ec2 terminate-instances --instance-ids $ec2_ids --region="$region"
    aws ec2 wait instance-terminated --instance-ids $ec2_ids --region="$region"
fi

# delete security groups
sg_ids=$(aws ec2 describe-security-groups --query "SecurityGroups[?!(Tags && Tags[?Key=='usage' && Value=='permanent']) && GroupName!='default'].GroupId" --region="$region" --output text)

for sg_id in $sg_ids; do
    aws ec2 delete-security-group --region="$region" --group-id="$sg_id"
done

## delete route table
rt_assoc_ids=$(aws ec2 describe-route-tables --query "RouteTables[?!(Tags && Tags[?Key=='usage' && Value=='permanent']) && !(Associations[0].Main)].Associations[0].RouteTableAssociationId" --region="$region" --output text)

for rt_assoc_id in $rt_assoc_ids; do
    aws ec2 disassociate-route-table --region="$region" --association-id="$rt_assoc_id"
done

rt_ids=$(aws ec2 describe-route-tables --query "RouteTables[?!(Tags && Tags[?Key=='usage' && Value=='permanent']) && !(Associations[0].Main)].RouteTableId" --region="$region" --output text)

for rt_id in $rt_ids; do
    aws ec2 delete-route-table --route-table-id="$rt_id" --region="$region"
done

## delete subnet
sn_ids=$(aws ec2 describe-subnets --query "Subnets[?!(Tags && Tags[?Key=='usage' && Value=='permanent']) && !(DefaultForAz)].SubnetId" --region="$region" --output text)

for sn_id in $sn_ids; do
    aws ec2 delete-subnet --subnet-id="$sn_id" --region="$region"
done

## detach and delete internet gateway
igw_ids=$(aws ec2 describe-internet-gateways --query "InternetGateways[?!(Tags && Tags[?Key=='usage' && Value=='permanent'])].InternetGatewayId" --region="$region" --output text)

for igw_id in $igw_ids; do
    vpc_assoc=$(aws ec2 describe-internet-gateways --internet-gateway-ids "$igw_id" --query "InternetGateways[?(Attachments)].Attachments[0].VpcId" --region="$region" --output text)

    if [ -n "$vpc_assoc" ]; then
        aws ec2 detach-internet-gateway --vpc-id="$vpc_assoc" --internet-gateway-id="$igw_id" --region="$region"
    fi

    aws ec2 delete-internet-gateway --internet-gateway-id="$igw_id" --region="$region"
done

## delete VPC
vpc_ids=$(aws ec2 describe-vpcs --query "Vpcs[?!(Tags && Tags[?Key=='usage' && Value=='permanent']) && !(IsDefault)].VpcId" --region="$region" --output text)

for vpc_id in $vpc_ids; do
    aws ec2 delete-vpc --vpc-id="$vpc_id" --region="$region"
done
