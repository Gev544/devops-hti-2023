import boto3


# Create an EC2 instance with tags
def create_ec2_instance(vpc_id, subnet_id):
    ec2_client = boto3.client('ec2')

    # Specify your EC2 instance parameters
    instance_params = {
        'ImageId': 'ami-023c11a32b0207432',
        'InstanceType': 't2.micro',
        'KeyName': 'test',
        'MinCount': 1,
        'MaxCount': 1,
        'SubnetId': subnet_id,
        'TagSpecifications': [
            {
                'ResourceType': 'instance',
                'Tags': [
                    {'Key': 'Name', 'Value': 'Test1'},
                    {'Key': 'usage', 'Value': 'permanent'}
                ]
            }
        ]
    }

    # Create the EC2 instance
    response = ec2_client.run_instances(**instance_params)
    instance_id = response['Instances'][0]['InstanceId']
    print(f'EC2 instance created with ID: {instance_id}')


# Create a subnet with tags
def create_subnet(vpc_id):
    ec2_client = boto3.client('ec2')

    # Specify your VPC ID and subnet parameters
    subnet_params = {
        'CidrBlock': '10.0.0.0/24',
        'VpcId': vpc_id,
        'TagSpecifications': [
            {
                'ResourceType': 'subnet',
                'Tags': [
                    {'Key': 'using', 'Value': 'permanent'},
                    {'Key': 'Environment', 'Value': 'Production'}
                ]
            }
        ]
    }

    # Create the subnet
    response = ec2_client.create_subnet(**subnet_params)
    subnet_id = response['Subnet']['SubnetId']
    print(f'Subnet created with ID: {subnet_id}')

    return subnet_id


# Create a VPC with tags
def create_vpc():
    ec2_client = boto3.client('ec2')

    # Specify your VPC parameters
    vpc_params = {
        'CidrBlock': '10.0.0.0/16',
        'TagSpecifications': [
            {
                'ResourceType': 'vpc',
                'Tags': [
                    {'Key': 'usage', 'Value': 'permanent'},
                    {'Key': 'Environment', 'Value': 'Production'}
                ]
            }
        ]
    }

    # Create the VPC
    response = ec2_client.create_vpc(**vpc_params)
    vpc_id = response['Vpc']['VpcId']
    print(f'VPC created with ID: {vpc_id}')

    return vpc_id



vpc_id = create_vpc()
subnet_id = create_subnet(vpc_id)
create_ec2_instance(vpc_id, subnet_id)
