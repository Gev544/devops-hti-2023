import boto3


# Create AWS clients for EC2 and S3
ec2 = boto3.client('ec2')#,
s3 = boto3.client('s3')#, 

def list_and_delete_ec2_instances():
    # List EC2 instances
    comp = ec2.describe_instances()
    
    for reservation in comp['Reservations']:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']
            print(f"Terminating EC2 instance: {instance_id}")
            
            # Terminate EC2 instance
            ec2.terminate_instances(InstanceIds=[instance_id])
            print(f"EC2 instance {instance_id} terminated.")


def list_and_delete_vpcs():
      # List VPCs
      response = ec2.describe_vpcs()
      
      for vpc in response['Vpcs']:
          vpc_id = vpc['VpcId']
          print(f"Deleting VPC: {vpc_id}")
          
          # Delete all subnets in the VPC
          subnets = ec2.describe_subnets(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
          for subnet in subnets['Subnets']:
              ec2.delete_subnet(SubnetId=subnet['SubnetId'])
              print(f"Subnet {subnet['SubnetId']} deleted.")



          route = ec2.describe_route_tables()
          for route_table in route['RouteTables']:
            table_id = route_table['RouteTableId']
            print(f"Deleting route table: {table_id}")


"""
             # Delete routes in the route table
            for route in route_table.get('Routes', []):
                if route.get('GatewayId'):
                  ec2.delete_route(RouteTableId=table_id, DestinationCidrBlock=route['DestinationCidrBlock'])
                  print(f"Deleted route in route table {table_id} for {route['DestinationCidrBlock']} via {route['GatewayId']}.")
                else:
                    print("Upsssss, can't get ")

        
            # Delete the route table
            ec2.delete_route_table(RouteTableId=table_id)
            print(f"Route table {table_id} deleted.GatewayId")   




          group_name = 'Allow_SSH'
          grpn = ec2.describe_security_groups(Filters=[dict(Name='group-name', Values=[group_name])])
          group_id = grpn['SecurityGroups'][0]['GroupId']
          print("groooooooooo",group_id)
          ec2.delete_security_group(GroupId=group_id)
          print(f"Security group {group_name} deleted.")
 """

def list_and_delete_internet_gateways():
    # List internet gateways
    gtwy = ec2.describe_internet_gateways()
    
    for igw in gtwy['InternetGateways']:
        igw_id = igw['InternetGatewayId']
        print(f"Deleting internet gateway: {igw_id}")
        
        # Detach the internet gateway from VPCs
        for attachment in igw.get('Attachments', []):
            vpc_id = attachment['VpcId']
            ec2.detach_internet_gateway(InternetGatewayId=igw_id, VpcId=vpc_id)
            print(f"Detached internet gateway {igw_id} from VPC {vpc_id}.")
        
        # Delete the internet gateway
        ec2.delete_internet_gateway(InternetGatewayId=igw_id)
        print(f"Internet gateway {igw_id} deleted.")

def list_and_delete_s3_buckets():
    # List AWS S3 buckets
    buck = s3.list_buckets()
    
    for bucket in buck['Buckets']:
        bucket_name = bucket['Name']
        print(f"Deleting S3 bucket: {bucket_name}")
        
        # Delete all objects in the bucket
        objects = s3.list_objects_v2(Bucket=bucket_name)
        for obj in objects.get('Contents', []):
            s3.delete_object(Bucket=bucket_name, Key=obj['Key'])
        
        # Delete the S3 bucket
        s3.delete_bucket(Bucket=bucket_name)
        print(f"S3 bucket {bucket_name} deleted.")

# Uncomment the following line to execute the operation
# 

# Uncomment the following lines to execute the operations
list_and_delete_ec2_instances()
list_and_delete_vpcs()
list_and_delete_internet_gateways()
list_and_delete_s3_buckets()

