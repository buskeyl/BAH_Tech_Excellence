

# Update your Instance
sudo yum update -y

# install the Apache web server
sudo yum install -y httpd

# Start the Apache web server.
sudo systemctl start httpd

# Use the systemctl command to configure the Apache web server to start at each system boot.
sudo systemctl enable httpd

# You can verify that httpd is on by running the following command:
sudo systemctl is-enabled httpd

# Add your user (in this case, ec2-user) to the apache group.
sudo usermod -a -G apache ec2-user

# Change the group ownership of /var/www and its contents to the apache group.
sudo chown -R ec2-user:apache /var/www

# To add group write permissions and to set the group ID on future subdirectories, change the directory permissions of /var/www and its subdirectories.
sudo chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {} \;

# To add group write permissions, recursively change the file permissions of /var/www and its subdirectories:
find /var/www -type f -exec sudo chmod 0664 {} \;
