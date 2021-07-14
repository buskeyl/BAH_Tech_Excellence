Install-Module -Name AWS.Tools.Common -confirm:$False
Install-Module -Name AWS.Tools.Installer -confirm:$False
Install-AWSToolsModule EC2 -confirm:$False
Install-AWSToolsModule SimpleSystemsManagement -confirm:$False


$SelectASourceAddresses = "68.131.78.164/24"

#Create a VPC

Write-Output "Creating VPC"
$VPCID = $(New-EC2VPC -cidrblock 10.0.0.0/16).VpcId 
New-EC2Tag -Resource $VPCID -Tag @{Key="Name"; Value="BAH_Team1"}

    <#
    #aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=VPC,Tags=[{Key=Name,Value=BAHTETEAM1}]'
    #>

    
# Create the Subnets 
Write-Output "Creating Subnets"
# create a subnet with a 10.0.20.0/24 CIDR block.
$PublicSubnetID = $(New-EC2Subnet -VpcId $VPCID -CidrBlock 10.0.10.0/24).SubnetId
New-EC2Tag -Resource $PublicSubnetID -Tag @{Key="Name"; Value="Public Subnet"}

    <#
    aws ec2 create-subnet --vpc-id vpc-2f09a348 --cidr-block 10.0.1.0/24
    aws ec2 create-subnet --vpc-id vpc-2f09a348 --cidr-block 10.0.0.0/24
    #>


# Create Internet Gateway 
Write-Output "Creating Internet Gateway"
$INternetGateway = $(New-EC2InternetGateway).InternetGatewayId
New-EC2Tag -Resource $INternetGateway -Tag @{Key="Name"; Value="BAH_Team1"}


    <#
    aws ec2 create-internet-gateway 
    #>

# Attach the internet gateway to your VPC.
Write-Output "Attaching Internet Gateway to Public Subnet"
Add-EC2InternetGateway -VpcId $VPCID -InternetGatewayId $INternetGateway

    <#
    aws ec2 attach-internet-gateway --vpc-id vpc-2f09a348 --internet-gateway-id igw-1ff7a07b
    #>


    
# Create a custom route table for your public subnet.
Write-Output "Creating Public Route Table"
$PublicRouteTable = $(New-EC2RouteTable -VpcId $VPCID).RouteTableId 
New-EC2Tag -Resource $PublicRouteTable -Tag @{Key="Name"; Value="BAH_Public_Routes"}

    <#
    aws ec2 create-route-table --vpc-id vpc-2f09a348
    #>

        # Create a route in the route table that points all traffic (0.0.0.0/0) to the Internet gateway.
        Write-Output "Creating routes in public route table"
        New-EC2Route -RouteTableId $PublicRouteTable -DestinationCidrBlock 0.0.0.0/0 -GatewayId $INternetGateway

            <#
            aws ec2 create-route --route-table-id rtb-c1c8faa6 --destination-cidr-block 0.0.0.0/0 --gateway-id igw-1ff7a07b
            #>

        # Associate route table to subnet
        Write-Output "Associating the route to the public subnet"
        Register-EC2RouteTable -RouteTableId $PublicRouteTable -SubnetId $PublicSubnetID 


# Create a custom route table for the private subnet.
Write-Output "Creating Private Subnet Route Table"
$PrivateRouteTable = $(New-EC2RouteTable -VpcId $VPCID).RouteTableId 
New-EC2Tag -Resource $PrivateRouteTable -Tag @{Key="Name"; Value="BAH_Private_Routes"}

        # Associate route table to subnet
        Write-Output "Associating the route to the private subnet"
        Register-EC2RouteTable -RouteTableId $PrivateRouteTable -SubnetId $PrivateSubnetID



# Create and configure Security Groups 
Write-Output "Creating Security Groups"

        # Creating Webserver Security Group
        Write-Output "Creating Webserver Security Group"
        $WebserverSGID = New-EC2SecurityGroup -VpcId "$VPCID" -GroupName "BAH_Public_Security_Group" -GroupDescription "Webserver Firewall" 

                # Allow incoming http from the net 
                $ip1 = new-object Amazon.EC2.Model.IpPermission 
                $ip1.IpProtocol = "tcp" 
                $ip1.FromPort = 80
                $ip1.ToPort = 80 
                $ip1.IpRanges.Add("10.0.0.0/24") 

                # Allow incoming https from the net 
                $ip2 = new-object Amazon.EC2.Model.IpPermission 
                $ip2.IpProtocol = "tcp" 
                $ip2.FromPort = 443
                $ip2.ToPort = 443
                $ip2.IpRanges.Add("0.0.0.0/0")

                # Allow incoming SSH from the public subnet only 
                $ip3 = new-object Amazon.EC2.Model.IpPermission 
                $ip3.IpProtocol = "tcp" 
                $ip3.FromPort = 22
                $ip3.ToPort = 22
                $ip3.IpRanges.Add("$SelectASourceAddresses")


        Grant-EC2SecurityGroupIngress -GroupId $WebserverSGID -IpPermissions @( $ip1, $ip2, $ip3 )
        New-EC2Tag -Resource $WebserverSGID -Tag @{Key="Name"; Value="Webserver Firewall"}

        
        # Creating Jenkins Security Group
        Write-Output "Creating private subnet Security Group"
        $JenkinsSGID = New-EC2SecurityGroup -VpcId "$VPCID" -GroupName "BAH_Jankins_Security_Group" -GroupDescription "Jenkins Firewall" 

               # Allow incoming http from the net 
               $ip1 = new-object Amazon.EC2.Model.IpPermission 
               $ip1.IpProtocol = "tcp" 
               $ip1.FromPort = 80
               $ip1.ToPort = 80 
               $ip1.IpRanges.Add("$SelectASourceAddresses") 

               # Allow incoming https from the net 
               $ip2 = new-object Amazon.EC2.Model.IpPermission 
               $ip2.IpProtocol = "tcp" 
               $ip2.FromPort = 443
               $ip2.ToPort = 443
               $ip2.IpRanges.Add("$SelectASourceAddresses")

               # Allow incoming SSH from the public subnet only 
               $ip3 = new-object Amazon.EC2.Model.IpPermission 
               $ip3.IpProtocol = "tcp" 
               $ip3.FromPort = 22
               $ip3.ToPort = 22
               $ip3.IpRanges.Add("$SelectASourceAddresses")

        Grant-EC2SecurityGroupIngress -GroupId $JenkinsSGID -IpPermissions @( $ip1, $ip2, $ip3 )
        New-EC2Tag -Resource $JenkinsSGID  -Tag @{Key="Name"; Value="Private Subnet Firewall"}

# Creaste a Key Pair
Write-Output "Generating key pair"
$KeyPair = New-EC2KeyPair -KeyName "BAH Team 1 Keypair"
$KeyPair.KeyMaterial | Out-File -Encoding ascii "BAH Team 1 Keypair.pem" 

# Configure Instance UserData
Write-Output "Setting up userdata objects"
$script = Get-Content -raw C:\_scripts\BAH_Tech_Excellence\Userdata.sh
$WebServerUserData = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($Script))

$script = Get-Content -raw C:\_scripts\BAH_Tech_Excellence\UserDateJenkins.sh
$JenkinsUserData = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($Script))

# Create the Elastic IP's

        # Create Webserver Elastic IP
        Write-Output "Creating the Webserver Elastic IP"
        $TagSpecification = [Amazon.EC2.Model.TagSpecification]::new()
        $TagSpecification.ResourceType = 'elastic-ip'
        $tag = [Amazon.EC2.Model.Tag]@{
            Key   = "Name"
            Value = "BAH_Team1_Webserver_Public_Address"
            }
        $TagSpecification.Tags.Add($tag)
        $WebServerElasticIP = New-EC2Address -TagSpecification $TagSpecification

        # Create Elastic IP for Jenkins 
        Write-Output "Creating Linux Jumpbox Elastic IP"
        $TagSpecification = [Amazon.EC2.Model.TagSpecification]::new()
        $TagSpecification.ResourceType = 'elastic-ip'
        $tag = [Amazon.EC2.Model.Tag]@{
            Key   = "Name"
            Value = "BAH_Team1_Linuc_Jumpbox_Address"
            }
        $TagSpecification.Tags.Add($tag)
        $JenkinsElasticIP = New-EC2Address -TagSpecification $TagSpecification


# Create the Actual Instances 
        # Create the AWS web server Instances 
        Write-Output "Creating the actual instances..."

        Write-Output `t`t"Creating the web server instance"
        $LinuxAMI = Get-SSMLatestEC2Image -Path ami-amazon-linux-latest -ImageName amzn2-ami-hvm-x86_64-gp2
        $instance = $(New-EC2Instance -ImageId $LinuxAMI -InstanceType t2.micro -SecurityGroupId $WebserverSGID  -UserData $WebServerUserData -SubnetId $PublicSubnetID  -KeyName $($KeyPair.KeyName)).ReservationId
        $instance = aws ec2 describe-instances --filters Name=reservation-id,Values="$instance" | Select-String instanceid
        $instance = $($instance -split ":")[1]
        $instance = $instance.Replace("`"","")
        $instance = $instance.Replace(",","")
        $instance = $instance.trim()
        $WebserverInstanceID=$instance
        New-EC2Tag -Resource $WebserverInstanceID -Tag @{Key="Name"; Value="Webserver"}

        # Create the AWS Jenkins Instance 
        Write-Output `t`t"Creating the Jenkins instance"
        $LinuxAMI = Get-SSMLatestEC2Image -Path ami-amazon-linux-latest -ImageName amzn2-ami-hvm-x86_64-gp2
        $instance = $(New-EC2Instance -ImageId $LinuxAMI -InstanceType t2.micro -UserData $JenkinsUserData  -SubnetId $PublicSubnetID -SecurityGroupId $JenkinsSGID  -KeyName $($KeyPair.KeyName)   ).ReservationId
        $instance = aws ec2 describe-instances --filters Name=reservation-id,Values="$instance" | Select-String instanceid
        $instance = $($instance -split ":")[1]
        $instance = $instance.Replace("`"","")
        $instance = $instance.Replace(",","")
        $instance = $instance.trim()
        $JenkinsInstanceID=$instance
        New-EC2Tag -Resource $JenkinsInstanceID -Tag @{Key="Name"; Value="Jenkins"}


# Wait for Webserver Instance to be running before registering the Elastic IP address
Write-output "Waiting for Webserver instance to start to associate elastic IP"
do {$status = Get-EC2InstanceStatus -InstanceId  $WebserverInstanceID} Until ($status.InstanceState.name.Value -eq "running")
 # Register the Elastic IP to the Webserver Instance
Register-EC2Address -InstanceId $WebserverInstanceID -AllocationId $WebserverElasticIP.AllocationId

# Wait for Jenkins Instance to be running before registering the Elastic IP address
Write-output " Waiting for Jenkins Server to start to associate it's Elastic IP"
 # Register the Elastic IP to the Linux Jumpbox Instance
do {$status = Get-EC2InstanceStatus -InstanceId  $JenkinsInstanceID} Until ($status.InstanceState.name.Value -eq "running")
 # Register the Elastic IP to the Jupbox server Instance
Register-EC2Address -InstanceId $JenkinsInstanceID -AllocationId $JenkinsElasticIP.AllocationId



# Create Billing alerts
# Create AutoScaling policy
# Create Elastic loadbalancer

