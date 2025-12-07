#!/bin/bash

echo "Installing Dependencies"
echo "======================================================================"
sudo dnf upgrade -y
sudo dnf install mariadb105-server httpd wget php-mysqlnd php-fpm php-mysqli php-json php php-devel -y
sudo dnf install -y nfs-utils git cronie
echo "======================================================================"

echo "Starting Services"
sudo systemctl start httpd mariadb crond
sudo systemctl enable httpd mariadb crond
echo "======================================================================"

echo "Setting Permissions"
sudo usermod -a -G apache ec2-user   
sudo chown -R ec2-user:apache /var/www     
sudo chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {} \;   
find /var/www -type f -exec sudo chmod 0664 {} \;    
echo "======================================================================"

#EFS CREATION AND MOUNTING
echo "Mounting EFS"
EFS=$(aws ssm get-parameter --name clixxdb-EFS --query Parameter.Value --output text)
MOUNT_POINT=/var/www/html
sudo mkdir -p ${MOUNT_POINT}
sudo chown ec2-user:ec2-user ${MOUNT_POINT}
sudo echo ${EFS}:/ ${MOUNT_POINT} nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0 >> /etc/fstab
sudo mount -a -t nfs4
sudo chmod -R 755 /var/www/html

DB_HOST=$(aws ssm get-parameter --name clixxdb-host --query Parameter.Value --output text)
DNS=$(aws ssm get-parameter --name clixxdb-DNS --query Parameter.Value --output text)
DB_PASS=$(aws ssm get-parameter --name clixxdb-pass --query Parameter.Value --output text)

if [ ! -f "/var/www/html/wp-config.php" ]   # Check if WordPress is not already configured
then
    git clone https://github.com/stackitgit/CliXX_Retail_Repository.git
    cp -r CliXX_Retail_Repository/* /var/www/html
    cd /var/www/html
    ## Allow wordpress to use Permalinks
    sudo sed -i 's/AllowOverride None/AllowOverride All/g' /etc/httpd/conf/httpd.conf
    sed -i "s/wordpress-db.cc5iigzknvxd.us-east-1.rds.amazonaws.com/${DB_HOST}/" /var/www/html/wp-config.php

    # Update IP to point to clixx dns
    until mysql -u wordpressuser -p"${DB_PASS}" -h ${DB_HOST} -D wordpressdb -e "SELECT 1" >/dev/null 2>&1
    do
      echo "Waiting for database to be ready..."
      sleep 10
    done

    mysql -u wordpressuser -p"${DB_PASS}" -h ${DB_HOST} -D wordpressdb <<EOF
        UPDATE wp_options SET option_value = "${DNS}" WHERE option_value LIKE '%NLB%';
EOF

    ##Restart Apache
    sudo systemctl restart httpd

    ##Enable httpd 
    sudo systemctl enable httpd 
    sudo /sbin/sysctl -w net.ipv4.tcp_keepalive_time=200
    sudo /sbin/sysctl -w net.ipv4.tcp_keepalive_intvl=200
    sudo /sbin/sysctl -w net.ipv4.tcp_keepalive_probes=5
else
    echo "WordPress is already configured on this server."

    mysql -u wordpressuser -p"${DB_PASS}" -h ${DB_HOST} -D wordpressdb <<EOF
        UPDATE wp_options SET option_value = "${DNS}" WHERE option_id = 2;
        UPDATE wp_options SET option_value = "${DNS}" WHERE option_id = 3;
EOF
fi

# update wp-config.php every minute by comparing the updated db parameters from SSM Parameter Store
echo "#!/bin/bash" > /var/www/html/wp-config_check.sh
echo "echo 'Checking for database password update'" >> /var/www/html/wp-config_check.sh
echo "NEW_PWD=\$(aws ssm get-parameter --name \"clixxdb-pass\" --query \"Parameter.Value\" --output text)" >> /var/www/html/wp-config_check.sh
echo "" >> /var/www/html/wp-config_check.sh
# DB PASSWORD check
echo "OLD_PWD=\$(grep 'DB_PASSWORD' /var/www/html/wp-config.php | awk -F\"'\" '{print \$4}')" >> /var/www/html/wp-config_check.sh
echo "if [ \"\${OLD_PWD}\" == \"\${NEW_PWD}\" ]; then" >> /var/www/html/wp-config_check.sh
echo "    echo 'wp-config.php already has the latest password'" >> /var/www/html/wp-config_check.sh
echo "else" >> /var/www/html/wp-config_check.sh
echo "    echo 'Updating wp-config.php with latest password'" >> /var/www/html/wp-config_check.sh
echo "    sudo sed -i s/\${OLD_PWD}/\${NEW_PWD}/ /var/www/html/wp-config.php" >> /var/www/html/wp-config_check.sh
echo "fi" >> /var/www/html/wp-config_check.sh

chmod +x /var/www/html/wp-config_check.sh   

TS=$(date +%Y%m%d%H%M)

# write out current crontab
crontab -l > mycron
# echo new cron into cron file
echo "* * * * * /var/www/html/wp-config_check.sh > /home/ec2-user/wpcheck_${TS}.log 2>&1" >> mycron
# Install new cron file
crontab mycron
rm mycron