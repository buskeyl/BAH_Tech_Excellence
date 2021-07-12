#!/bin/bash

## Jenkins installation on AWS EC2 using YUM ##
###############################################
 
## Add Jenkins repo to your yum repository
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat/jenkins.repo
 
## Import a key file from Jenkins-CI to enable installation from the package
sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key
 
## Install Jenkins
sudo yum install jenkins -y
 
## Start and enable Jenkins service
sudo systemctl start jenkins
sudo systemctl enable jenkins
sudo systemctl status jenkins
 
## Get the initial administrative password 
sudo cat /var/lib/jenkins/secrets/initialAdminPassword