import boto3
import botocore.exceptions
import time

def print_resource_tags(resource_type, resource):
    resource_id = get_resource_id(resource_type, resource)
    tags = resource.get('Tags', [])

    print(f'Tags for {resource_type} with ID {resource_id}:')
    for tag in tags:
        print(f'    Key: {tag["Key"]}, Value: {tag["Value"]}')

def delete_resource_if_no_tags_match(resource_type, tag_key, tag_value):
    client = boto3.client('ec2')

    # Get the resource list based on the resource type
    if resource_type == 'vpc':
        resources = client.describe_vpcs()['Vpcs']
    elif resource_type == 'subnet':
        resources = client.describe_subnets()['Subnets']
    elif resource_type == 'instance':
        reservations = client.describe_instances()['Reservations']
        resources = [instance for reservation in reservations for instance in reservation.get('Instances', [])]
    else:
        print(f'Unsupported resource type: {resource_type}')
        return

    # Delete each resource if none of the tags match
    for resource in resources:
        resource_id = get_resource_id(resource_type, resource)

        # Check if it's the default VPC (VPC ID starts with 'vpc-') and skip deletion
        if resource_type == 'vpc' and resource.get('IsDefault', False):
            print(f'Skipping default VPC {resource_id}')
            continue

        # Check if none of the tags match
        tags = resource.get('Tags', [])
        if not any(tag.get('Key') == tag_key and tag.get('Value') == tag_value for tag in tags):
            # If resource is an instance, check if it is in the terminating state
            if resource_type == 'instance':
                instance_state = resource.get('State', {}).get('Name')
                if instance_state == 'terminated':
                    print(f'Skipping terminated instance {resource_id}')
                    continue

            # Print resource tags before deletion
            print_resource_tags(resource_type, resource)

            print(f'Deleting {resource_type} with ID {resource_id}')

            # Confirm the deletion with the user
            user_confirmation = input("Do you want to proceed with deletion? (yes/no): ").lower()

            if user_confirmation == 'yes':
                try:
                    delete_resource(client, resource_type, resource_id)

                    # If deleting an instance, wait for it to be terminated
                    if resource_type == 'instance':
                        wait_for_instance_termination(client, resource_id)

                except botocore.exceptions.ClientError as e:
                    print(f'Error: {e}')
            else:
                print('Deletion aborted by user.')

def wait_for_instance_termination(client, instance_id):
    waiter = client.get_waiter('instance_terminated')
    waiter.wait(InstanceIds=[instance_id])
    print(f'Instance {instance_id} has been terminated.')

def get_resource_id(resource_type, resource):
    if resource_type == 'vpc':
        return resource['VpcId']
    elif resource_type == 'subnet':
        return resource['SubnetId']
    elif resource_type == 'instance':
        return resource['InstanceId']
    else:
        return None

def delete_resource(client, resource_type, resource_id):
    try:
        if resource_type == 'vpc':
            client.delete_vpc(VpcId=resource_id)
        elif resource_type == 'subnet':
            # Check for instances in the subnet before deleting
            instances = client.describe_instances(Filters=[{'Name': 'subnet-id', 'Values': [resource_id]}])
            if not instances['Reservations']:
                client.delete_subnet(SubnetId=resource_id)
            else:
                print(f'Subnet {resource_id} has instances and cannot be deleted.')
        elif resource_type == 'instance':
            client.terminate_instances(InstanceIds=[resource_id])
    except botocore.exceptions.ClientError as e:
        print(f'Error: {e}')

# Specify the tag to match for deletion
tag_key_to_match = '1'
tag_value_to_match = '1'

# Delete subnets if none of the tags match
delete_resource_if_no_tags_match('subnet', tag_key_to_match, tag_value_to_match)

# Delete VPCs if none of the tags match
delete_resource_if_no_tags_match('vpc', tag_key_to_match, tag_value_to_match)

# Terminate instances if none of the tags match
delete_resource_if_no_tags_match('instance', tag_key_to_match, tag_value_to_match)

