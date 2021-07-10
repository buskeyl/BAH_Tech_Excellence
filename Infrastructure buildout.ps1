Install-Module -Name AWS.Tools.Common -confirm:$False
Install-Module -Name AWS.Tools.Installer -confirm:$False
Install-AWSToolsModule EC2 -confirm:$False
Install-AWSToolsModule SimpleSystemsManagement -confirm:$False

#Create a VPC

$VPCID = $(New-EC2VPC -cidrblock 10.0.0.0/16).VpcId 
New-EC2Tag -Resource $VPCID -Tag @{Key="Name"; Value="BAH_Team1"}

    <#
    #aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=VPC,Tags=[{Key=Name,Value=BAHTETEAM1}]'
    #>

# Create the Subnets 

# create a subnet with a 10.0.20.0/24 CIDR block.
$PublicSubnetID = $(New-EC2Subnet -VpcId $VPCID -CidrBlock 10.0.10.0/24).SubnetId
New-EC2Tag -Resource $PublicSubnetID -Tag @{Key="Name"; Value="Public Subnet"}

# create a subnet with a 10.0.1.0/24 CIDR block.
$PrivateSubnetID = $(New-EC2Subnet -VpcId $VPCID -CidrBlock 10.0.20.0/24).SubnetId 
New-EC2Tag -Resource $PrivateSubnetID -Tag @{Key="Name"; Value="Private Subnet"}

    <#
    aws ec2 create-subnet --vpc-id vpc-2f09a348 --cidr-block 10.0.1.0/24
    aws ec2 create-subnet --vpc-id vpc-2f09a348 --cidr-block 10.0.0.0/24
    #>

# Make the public subnet public
$INternetGateway = $(New-EC2InternetGateway).InternetGatewayId
New-EC2Tag -Resource $INternetGateway -Tag @{Key="Name"; Value="BAH_Team1"}
    <#
    aws ec2 create-internet-gateway 
    #>


# Attach the internet gateway to your VPC.
Add-EC2InternetGateway -VpcId $VPCID -InternetGatewayId $INternetGateway
    <#
    aws ec2 attach-internet-gateway --vpc-id vpc-2f09a348 --internet-gateway-id igw-1ff7a07b
    #>

# Create a custom route table for your VPC.

$RouteTable = $(New-EC2RouteTable -VpcId $VPCID).RouteTableId 
New-EC2Tag -Resource $RouteTable -Tag @{Key="Name"; Value="BAH_Team1"}

    <#
    aws ec2 create-route-table --vpc-id vpc-2f09a348
    #>

# Create a route in the route table that points all traffic (0.0.0.0/0) to the Internet gateway.

New-EC2Route -RouteTableId $RouteTable -DestinationCidrBlock 0.0.0.0/0 -GatewayId $INternetGateway

    <#
    aws ec2 create-route --route-table-id rtb-c1c8faa6 --destination-cidr-block 0.0.0.0/0 --gateway-id igw-1ff7a07b
    #>


$LinuxAMI = Get-SSMLatestEC2Image -Path ami-amazon-linux-latest -ImageName amzn2-ami-hvm-x86_64-gp2
New-EC2Instance -ImageId $LinuxAMI -InstanceType t2.micro -SubnetId $PublicSubnetID

