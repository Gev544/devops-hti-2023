import boto3
import botocore.exceptions

def delete_resource_if_no_tags_match(resource_type, tag_key, tag_value):
    client = boto3.client('ec2')

    # List resources
    if resource_type == 'vpc':
        resources = client.describe_vpcs()['Vpcs']
    elif resource_type == 'subnet':
        resources = client.describe_subnets()['Subnets']
    elif resource_type == 'instance':
        resources = client.describe_instances()['Reservations']

    # Delete each resource if none of the tags match
    for resource in resources:
        resource_id = resource['VpcId'] if resource_type == 'vpc' else (
            resource['SubnetId'] if resource_type == 'subnet' else resource['Instances'][0]['InstanceId']
        )

        # Check if none of the tags match
        tags = resource.get('Tags', [])
        if not any(tag.get('Key') == tag_key and tag.get('Value') == tag_value for tag in tags):
            print(f'Deleting {resource_type} with ID {resource_id}')

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
