
#!/bin/bash

# Check if the required arguments are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <vpc-id> <subnet-id> <region>"
    exit 1
fi

# Assign arguments to variables
vpc_id="$1"
subnet_id="$2"
region="$3"

# Delete the EC2 instance (if any)
instance_id=$(aws ec2 describe-instances \
    --filters "Name=subnet-id,Values=$subnet_id" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --region "$region" \
    --output text)

if [ -n "$instance_id" ]; then
    echo "Deleting EC2 instance: $instance_id"
    aws ec2 terminate-instances \
    --instance-ids "$instance_id" \
    --region "$region"
    aws ec2 wait instance-terminated \
    --instance-ids "$instance_id" \
    --region "$region"
    echo "EC2 instance deleted."
else
    echo "No EC2 instance found."
fi

# Disassociate and release Elastic IP (if any)
eip_allocation_id=$(aws ec2 describe-addresses \
    --filters "Name=domain,Values=vpc" \
    --query "Addresses[0].AllocationId" \
    --region "$region" \
    --output text)

if [ -n "$eip_allocation_id" ]; then
    echo "Releasing Elastic IP: $eip_allocation_id"
    aws ec2 release-address \
    --allocation-id "$eip_allocation_id" \
    --region "$region"
    echo "Elastic IP released."
else
    echo "No Elastic IP found."
fi

# Delete the security group (if any)
security_group_id=$(aws ec2 describe-security-groups \
    --filters "Name=vpc-id,Values=$vpc_id" "Name=group-name,Values=SecurityGR" \
    --query "SecurityGroups[0].GroupId" \
    --region "$region" \
    --output text)

if [ -n "$security_group_id" ]; then
    echo "Deleting Security Group: $security_group_id"
    aws ec2 delete-security-group \
    --group-id "$security_group_id" \
    --region "$region"
    echo "Security Group deleted."
else
    echo "No Security Group found."
fi

# Disassociate and delete the route table
# Function to forcefully disassociate and delete a route table
forcefully_disassociate_and_delete_route_table() {
    local table_id="$1"

    # Disassociate the main route table from the subnet
    association_id=$(aws ec2 describe-route-tables \
        --route-table-ids "$table_id" \
        --query "RouteTables[0].Associations[0].RouteTableAssociationId" \
        --output text \
        --region "$region")

    if [ -n "$association_id" ]; then
        # Forcefully disassociate the main route table
        aws ec2 disassociate-route-table \
        --association-id "$association_id" \
        --region "$region"
        echo "Route Table $table_id forcefully disassociated from subnet."
    else
        echo "No association found for the route table."
    fi

    # Delete the route table
    aws ec2 delete-route-table \
    --route-table-id "$table_id" \
    --region "$region"
    echo "Route Table $table_id deleted."
}

# Delete all route tables in the VPC
route_table_ids=$(aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=$vpc_id" \
    --query "RouteTables[*].RouteTableId" \
    --region "$region" \
    --output text)

if [ -n "$route_table_ids" ]; then
    echo "Deleting all route tables in the VPC: $vpc_id"

    for route_table_id in $route_table_ids; do
        forcefully_disassociate_and_delete_route_table "$route_table_id"
    done
else
    echo "No route tables found in the VPC: $vpc_id."
fi

# Detach and delete the internet gateway
internet_gateway_id=$(aws ec2 describe-internet-gateways \
    --filters "Name=attachment.vpc-id,Values=$vpc_id" \
    --query "InternetGateways[0].InternetGatewayId" \
    --region "$region" \
    --output text)

if [ -n "$internet_gateway_id" ]; then
    echo "Detaching Internet Gateway: $internet_gateway_id"
    aws ec2 detach-internet-gateway \
    --internet-gateway-id "$internet_gateway_id" \
    --vpc-id "$vpc_id" \
    --region "$region"
    echo "Deleting Internet Gateway: $internet_gateway_id"
    aws ec2 delete-internet-gateway \
    --internet-gateway-id "$internet_gateway_id" \
    --region "$region"
    echo "Internet Gateway deleted."
else
    echo "No Internet Gateway found."
fi

# Delete the subnet (if any)
if [ -n "$subnet_id" ]; then
    echo "Deleting Subnet: $subnet_id"
    aws ec2 delete-subnet --subnet-id "$subnet_id" --region "$region"
    echo "Subnet deleted."
else
    echo "No Subnet found."
fi

# Delete the VPC (if any)
if [ -n "$vpc_id" ]; then
    echo "Deleting VPC: $vpc_id"

    # Check if there are dependencies on the VPC
    dependency_check=$(aws ec2 describe-vpc-attribute \
        --vpc-id "$vpc_id" \
        --attribute enableDnsSupport \
        --query "EnableDnsSupport.Value" \
        --output text \
        --region "$region")

    if [ "$dependency_check" == "false" ]; then
        aws ec2 delete-vpc --vpc-id "$vpc_id" --region "$region"
        echo "VPC deleted."
    else
        echo "The VPC has dependencies and cannot be deleted directly."
        echo "Please make sure there are no remaining resources in the VPC before attempting to delete it."
    fi
else
    echo "No VPC found."
fi

echo "All resources and dependencies deleted."

