import boto3
ec2 = boto3.resource('ec2')



# create a file to store the key locally
outfile = open('ec2-keypair.pem', 'w')

# call the boto ec2 function to create a key pair
key_pair = ec2.create_key_pair(KeyName='ec2-keypair')

# capture the key and store it in a file
KeyPairOut = str(key_pair.key_material)
outfile.write(KeyPairOut)


# create VPC
vpc = ec2.create_vpc(CidrBlock='172.16.0.0/16')

# assign a name to our VPC
vpc.create_tags(Tags=[{"Key": "Name", "Value": "my_vpc"}])
vpc.wait_until_available()
if vpc.id:
    print("First step is done, we have AWS VPC with id:",vpc.id)
else:
    print("Look carefully, seems thet you missing something")
    exit()

# enable public dns hostname so that we can SSH into it later
ec2Client = boto3.client('ec2')
ec2Client.modify_vpc_attribute( VpcId = vpc.id , EnableDnsSupport = { 'Value': True } )
ec2Client.modify_vpc_attribute( VpcId = vpc.id , EnableDnsHostnames = { 'Value': True } )

# create an internet gateway and attach it to VPC
internetgateway = ec2.create_internet_gateway()
vpc.attach_internet_gateway(InternetGatewayId=internetgateway.id)
if internetgateway.id:
    print("You have got an internet access for yor vpc with GW_ID",internetgateway.id)
else:
    print("Something went wrong, our vpc doesn't have an internet access")
    exit()
# create a route table and a public route
routetable = vpc.create_route_table()
route = routetable.create_route(DestinationCidrBlock='0.0.0.0/0', GatewayId=internetgateway.id)
if routetable.id:
    print("Go on, now you have got your default route with id=", routetable.id)
else:
    print("Somenthing went wrong, I can't create ROUTETABLE ID")
    exit()

# create subnet and associate it with route table
subnet = ec2.create_subnet(CidrBlock='172.16.1.0/24', VpcId=vpc.id)
routetable.associate_with_subnet(SubnetId=subnet.id)
if subnet.id:
    print("Good news!! You have associated subnet with route table, your subnet id is ",subnet.id)
else:
    print("Hey Man, be careful!! You missed something")
    exit()
# Create a security group and allow SSH inbound rule through the VPC
securitygroup = ec2.create_security_group(GroupName='Allow_SSH', Description='only allow SSH traffic', VpcId=vpc.id)
securitygroup.authorize_ingress(CidrIp='0.0.0.0/0', IpProtocol='tcp', FromPort=22, ToPort=22)

# Create a linux instance in the subnet
instances = ec2.create_instances(
 ImageId="ami-00b8917ae86a424c9",
 InstanceType='t2.micro',
 MaxCount=1,
 MinCount=1,
 NetworkInterfaces=[{
 'SubnetId': subnet.id,
 'DeviceIndex': 0,
 'AssociatePublicIpAddress': True,
 'Groups': [securitygroup.group_id]
 }],
 KeyName='ec2-keypair')

print("Well done")
