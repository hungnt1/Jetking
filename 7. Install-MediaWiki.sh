
yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum -y install yum-utils
yum update
yum-config-manager --enable remi-php72
yum -y install wget php php-opcache php php-mysql php-gd php-xml mariadb-server mariadb php-mbstring
systemctl start mariadb
systemctl enable mariadb
mysql -u root <<EOF
CREATE DATABASE wikidatabase;  
CREATE USER 'wiki'@'localhost' IDENTIFIED BY '123@123Aa';
GRANT ALL PRIVILEGES ON wikidatabase.* TO 'wiki'@'localhost';
EOF
cd /var/www/html
wget https://releases.wikimedia.org/mediawiki/1.32/mediawiki-1.32.0.tar.gz
tar xf  mediawiki*.tar.gz 
mv mediawiki-1.32.0/* /var/www/html/
firewall-cmd --add-service=http --permanent
firewall-cmd --reload
systemctl start httpd
systemctl enable httpd
