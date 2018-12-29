
#!/bin/bash

echo "------------------------------------------------------"
echo "-----Install Wordpres with HTTPD, PHP & MarriaDB------"
echo "------------------------------------------------------"


function check()
{


cd /etc/
echo -e "\n"
echo "1. Kiem tra va cai dat packaget"
list_pack=(httpd php70-php php70-php-mysqlnd mariadb-server wget unzip)
list_remove=(nginx mysql-*)

echo "- Dang cai dat Repository"

yum -y install http://rpms.famillecollet.com/enterprise/remi-release-7.rpm &> /dev/null
yum -y install epel-release &> /dev/null


echo "- Kiem tra phan mem xung dot "

for remove in "${list_remove[@]}"
do

rpm -qa | grep $remove &> /dev/null

if [ $? -eq 0 ]
then

   echo "-- Dang go cai dat $remove"

   yum remove -y $remove &> /dev/null 

   echo "-- Go thanh cong"

else 

  echo "-- Chua cai dat $remove "

fi
done

echo $remove



for pack in "${list_pack[@]}"
do 


rpm -qa | grep $pack.* &> /dev/null

if [ $? != 0 ]
then

   echo "- Dang cai dat $pack"

   yum install -y $pack &> /dev/null 

   echo "- Cai dat thanh cong $pack"
else

   echo "- Package $pack da cai dat"

fi

done


}

function wordpress() {

echo -e "\n"
echo "2. Cau hinh Wordpress"

echo "- Dang khoi dong "

    rm -rf /tmp/wordpress.zip ||:
    rm -rf /tmp/wordpress ||:
    rm -rf /var/www/html/* ||:

    wget https://wordpress.org/latest.zip -O /tmp/wordpress.zip &> /dev/null
    unzip /tmp/wordpress.zip -d /tmp/ &> /dev/null
    cd /tmp/wordpress
    cp wp-config-sample.php wp-config.php
    systemctl start mariadb
    systemctl enable mariadb


    MYSQLPW="zgwhPE3GZo0a8R0A9yo="

    WPDB=`openssl rand -base64 14`

    echo -e "Mat khau ROOT MYSQL : ${MYSQLPW}\n Mat khau MYSQL WORDPRESS : ${WPDB}"  > /root/passwd.txt
    sed -i -e "s/database_name_here/wordpress/" /tmp/wordpress/wp-config.php

    sed -i -e "s/username_here/sysadmin/" /tmp/wordpress/wp-config.php

    sed -i -e "s/password_here/$WPDB/" /tmp/wordpress/wp-config.php


    /usr/bin/mysqladmin -u root -h localhost password $MYSQLPW &> /dev/null

mysql -u root --password=$MYSQLPW  <<EOF
DROP DATABASE IF EXISTS wordpress;
CREATE USER 'sysadmin' IDENTIFIED BY 'mypassword';
CREATE DATABASE wordpress;
EOF
mysql -u root -pzgwhPE3GZo0a8R0A9yo= -e "GRANT ALL PRIVILEGES ON wordpress.* TO sysadmin@localhost  IDENTIFIED BY '"$WPDB"'"
  mv -u /tmp/wordpress/* /var/www/html/

echo "- Cau hinh thanh cong"


}

function service() {

echo -e "\n"
echo "3. Khoi dong dich vu va firewall"

echo "- Dang khoi dong "


(
systemctl -n 0 start firewalld
systemctl -n 0 enable firewalld
systemctl -n 0 start httpd
systemctl -n 0 restart httpd
systemctl -n 0 enable httpd 
systemctl -n 0 start mariadb
systemctl -n 0 restart mariadb
systemctl -n 0 enable mariadb


firewall-cmd --add-service=http --permanent 
firewall-cmd --reload

) > /dev/null 2>&1

echo "-------------------------Da khoi dong thanh dong-------------------"
echo "------------- Mat khau duoc luu tai : /root/passwd.txt-------------"



}


check 
wordpress
service
