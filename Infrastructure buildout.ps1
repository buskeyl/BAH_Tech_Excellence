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

# Create Internet Gateway 
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


# Create and configure Security Groups 

$WebserverSGID = New-EC2SecurityGroup -VpcId "$VPCID" -GroupName "BAH_Public_Security_Group" -GroupDescription "Public Subnet Firewall" 

$ip1 = new-object Amazon.EC2.Model.IpPermission 
$ip1.IpProtocol = "tcp" 
$ip1.FromPort = 22 
$ip1.ToPort = 22 
$ip1.IpRanges.Add("10.0.20.0/24") 
$ip2 = new-object Amazon.EC2.Model.IpPermission 
$ip2.IpProtocol = "tcp" 
$ip2.FromPort = 80 
$ip2.ToPort = 80
$ip2.IpRanges.Add("0.0.0.0/0") 
$ip3 = new-object Amazon.EC2.Model.IpPermission 
$ip3.IpProtocol = "tcp" 
$ip3.FromPort = 443 
$ip3.ToPort = 443
$ip3.IpRanges.Add("0.0.0.0/0") 

Grant-EC2SecurityGroupIngress -GroupId $WebserverSGID -IpPermissions @( $ip1, $ip2,$ip3 )
New-EC2Tag -Resource $WebserverSGID -Tag @{Key="Name"; Value="Webserver Firewall"}

$PrivateSubnetSGID = New-EC2SecurityGroup -VpcId "$VPCID" -GroupName "BAH_Private_Security_Group" -GroupDescription "Private Subnet Firewall" 

$ip1 = new-object Amazon.EC2.Model.IpPermission 
$ip1.IpProtocol = "tcp" 
$ip1.FromPort = 22 
$ip1.ToPort = 22 
$ip1.IpRanges.Add("0.0.0.0/0") 
Grant-EC2SecurityGroupIngress -GroupId $PrivateSubnetSGID -IpPermissions @( $ip1 )
New-EC2Tag -Resource $PrivateSubnetSGID  -Tag @{Key="Name"; Value="Private Subnet Firewall"}


 # Configure Instance UserData

 $script = Get-Content -raw C:\_scripts\BAH_Tech_Excellence\Userdata.sh
 $WebServerUserData = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($Script))


# Create the AWS web server Instances 
$LinuxAMI = Get-SSMLatestEC2Image -Path ami-amazon-linux-latest -ImageName amzn2-ami-hvm-x86_64-gp2
$instance = $(New-EC2Instance -ImageId $LinuxAMI -InstanceType t2.micro -SecurityGroupId $WebserverSGID  -UserData $WebServerUserData -SubnetId $PublicSubnetID).ReservationId
$instance = aws ec2 describe-instances --filters Name=reservation-id,Values="$instance" | Select-String instanceid
$instance = $($instance -split ":")[1]
$instance = $instance.Replace("`"","")
$instance = $instance.Replace(",","")
$instance = $instance.trim()
$WebserverInstanceID=$instance
New-EC2Tag -Resource $WebserverInstanceID -Tag @{Key="Name"; Value="Webserver"}

# Create the AWS Jumpbox Instance 
$LinuxAMI = Get-SSMLatestEC2Image -Path ami-amazon-linux-latest -ImageName amzn2-ami-hvm-x86_64-gp2
$instance = $(New-EC2Instance -ImageId $LinuxAMI -InstanceType t2.micro -SubnetId $PrivateSubnetID).ReservationId
$instance = aws ec2 describe-instances --filters Name=reservation-id,Values="$instance" | Select-String instanceid
$instance = $($instance -split ":")[1]
$instance = $instance.Replace("`"","")
$instance = $instance.Replace(",","")
$instance = $instance.trim()
$JuimpBoxInstanceID=$instance
New-EC2Tag -Resource $JuimpBoxInstanceID -Tag @{Key="Name"; Value="Jumpbox"}

# Create the AWS Jenkins Instance 
$LinuxAMI = Get-SSMLatestEC2Image -Path ami-amazon-linux-latest -ImageName amzn2-ami-hvm-x86_64-gp2
$instance = $(New-EC2Instance -ImageId $LinuxAMI -InstanceType t2.micro -SubnetId $PrivateSubnetID).ReservationId
$instance = aws ec2 describe-instances --filters Name=reservation-id,Values="$instance" | Select-String instanceid
$instance = $($instance -split ":")[1]
$instance = $instance.Replace("`"","")
$instance = $instance.Replace(",","")
$instance = $instance.trim()
$JenkinsInstanceID=$instance
New-EC2Tag -Resource $JenkinsInstanceID -Tag @{Key="Name"; Value="Jenkins"}


# Create Elastic IP and connect to the Web server Instance
$TagSpecification = [Amazon.EC2.Model.TagSpecification]::new()
$TagSpecification.ResourceType = 'elastic-ip'
$tag = [Amazon.EC2.Model.Tag]@{
    Key   = "Name"
    Value = "BAH_Team1_Public Address"
    }
   $TagSpecification.Tags.Add($tag)

$ElasticIP = New-EC2Address -TagSpecification $TagSpecification

Register-EC2Address -InstanceId $WebserverInstanceID -AllocationId $ElasticIP.AllocationId


# Creaste a new Key Pair
# Create Billing alerts
# Create AutoScaling policy
# Create Elastic Loadbalancer





