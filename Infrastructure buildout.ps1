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
New-EC2Tag -Resource $RouteTable -Tag @{Key="Name"; Value="BAH_Public_Routes"}

    <#
    aws ec2 create-route-table --vpc-id vpc-2f09a348
    #>

# Create a route in the route table that points all traffic (0.0.0.0/0) to the Internet gateway.

New-EC2Route -RouteTableId $RouteTable -DestinationCidrBlock 0.0.0.0/0 -GatewayId $INternetGateway

    <#
    aws ec2 create-route --route-table-id rtb-c1c8faa6 --destination-cidr-block 0.0.0.0/0 --gateway-id igw-1ff7a07b
    #>


# Associate route table to subnet
 Register-EC2RouteTable -RouteTableId $RouteTable -SubnetId $PublicSubnetID 

 # Confiure UserData


# Create the AWS web server Instances 
$LinuxAMI = Get-SSMLatestEC2Image -Path ami-amazon-linux-latest -ImageName amzn2-ami-hvm-x86_64-gp2
$instance = $(New-EC2Instance -ImageId $LinuxAMI -InstanceType t2.micro -SubnetId $PublicSubnetID).ReservationId
$instance = aws ec2 describe-instances --filters Name=reservation-id,Values="$instance" | Select-String instanceid
$instance = $($instance -split ":")[1]
$instance = $instance.Replace("`"","")
$instance = $instance.Replace(",","")
$instance = $instance.trim()
$instance_id=$instance
New-EC2Tag -Resource $instance_id -Tag @{Key="Name"; Value="Webserver"}

# Create the AWS Jumpbox Instance 
$LinuxAMI = Get-SSMLatestEC2Image -Path ami-amazon-linux-latest -ImageName amzn2-ami-hvm-x86_64-gp2
$instance = $(New-EC2Instance -ImageId $LinuxAMI -InstanceType t2.micro -SubnetId $PrivateSubnetID).ReservationId
$instance = aws ec2 describe-instances --filters Name=reservation-id,Values="$instance" | Select-String instanceid
$instance = $($instance -split ":")[1]
$instance = $instance.Replace("`"","")
$instance = $instance.Replace(",","")
$instance = $instance.trim()
$instance_id=$instance
New-EC2Tag -Resource $instance_id -Tag @{Key="Name"; Value="Jumpbox"}

# Create the AWS Jenkins Instance 
$LinuxAMI = Get-SSMLatestEC2Image -Path ami-amazon-linux-latest -ImageName amzn2-ami-hvm-x86_64-gp2
$instance = $(New-EC2Instance -ImageId $LinuxAMI -InstanceType t2.micro -SubnetId $PrivateSubnetID).ReservationId
$instance = aws ec2 describe-instances --filters Name=reservation-id,Values="$instance" | Select-String instanceid
$instance = $($instance -split ":")[1]
$instance = $instance.Replace("`"","")
$instance = $instance.Replace(",","")
$instance = $instance.trim()
$instance_id=$instance
New-EC2Tag -Resource $instance_id -Tag @{Key="Name"; Value="Jenkins"}

# Create Elastic IP and connect to the Web server Instance
# Allocate, Associate to VPC, assign to instance.


# Configure Security Groups
    # Allow 80 & 443 from 0.0.0.0
    # Allow SSH from Private Subnet

# Creaste a new Key Pair

# Create Billing alerts

# Create AutoScaling policy

# Create Elastic Loadbalancer





