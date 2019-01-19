#!/bin/bash

echo "----------Wait a moment --------------"

rpm -q {dialog,moreutils}  
[ $? != 0 ]  && yum install -y moreutils dialog

function check_box() {

whiptail --title "Install Compoment" --checklist \
"Lua chon cac thanh phan de cai dat :" 20 78 10 \
"Required Package- Installed" "Openstack Env Package" ON  \
"Keystone" "Openstack Indentity Service" OFF \
"Glance" "Openstack Image Service" OFF \
"Nova" "Openstack Compute Service" OFF \
"Neutron" "Openstack Networking Service" OFF

}

function env_package() {

INPUT="config/input.txt"

# open fd
exec 3>&1

# Store data to $VALUES variable
local VALUES=$(dialog --ok-label "Submit" \
          --backtitle "NTP and RabiitMQ Install" \
          --title "" \
          --form "Dien thong tin o duoi" \
15 50 0 \
        "NTP Subnet:" 1 1       "192.168.69.0/24" 1 20 20 0 \
        "RabbitMQ Password:"   2 1       "rabbitmq_123"      2 20 20 0 \
2>&1 1>&3)

[ "$?" != "0" ] && exit

# close fd
exec 3>&-

# open fd
exec 3>&1

# Store data to $VALUES variable
local VALUES_2=$(dialog --ok-label "Submit" \
          --backtitle "MarriaDB Install" \
          --title "" \
          --form "Dien thong tin o duoi" \
15 50 0 \
        "IP MarriaDB Server:" 1 1       "192.168.69.130" 1 20 20 0 \
        "Root DB Password:"   2 1       "Disabled"      2 20 20 0 \
2>&1 1>&3)

[ "$?" != "0" ] && exit

# close fd
exec 3>&-

# display values just entered

clear
(
echo "----------- Wait a moment ----------------"
echo "--- Dang cap nhat va cai cac phan mem yeu cau ---"


## cai dat moi truong 
setenforce permissive
sed -i -e "s/SELINUX=enforcing/SELINUX=permissive/g" /etc/sysconfig/selinux
hostnamectl set-hostname controller
timedatectl set-timezone Asia/Ho_Chi_Minh
systemctl start firewalld && systemctl enable firewalld


## cai dat package
yum update -y 
yum install -y epel-release sshpass 
yum -y upgrade

rpm -q {centos-release-openstack-queens,python-openstackclient,openstack-selinux,chrony,rabbitmq-server,memcached,python-memcached}
[ $? != 0 ]  && yum install -y centos-release-openstack-queens python-openstackclient openstack-selinux chrony rabbitmq-server memcached python-memcached

#NTP
echo "allow `echo $VALUES | cut -f1 -d " "` " >> /etc/chrony.conf

systemctl enable chronyd.service && systemctl stop chronyd.service
systemctl start chronyd.service

systemctl enable rabbitmq-server.service && systemctl stop rabbitmq-server.service
systemctl start rabbitmq-server.service

firewall-cmd --add-service=ntp --permanent
firewall-cmd --reload

#RabitMQ

rabbitmqctl add_user openstack `echo $VALUES | cut -f2 -d " "`
rabbitmqctl change_password openstack `echo $VALUES | cut -f2 -d " "`
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

#MYSQL

yum install -y  mariadb mariadb-server python2-PyMySQL

echo "[mysqld]
bind-address = `echo $VALUES_2 | cut -f1 -d " "`
default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8" > /etc/my.cnf.d/openstack.cnf

echo "------------------ Dang khoi dong dich vu ------------------"
systemctl restart mariadb
systemctl enable mariadb.service && systemctl start mariadb.service && systemctl restart mariadb.service
#/usr/bin/mysqladmin -u root -h localhost password `echo $VALUES_2 | cut -f2 -d " "`

systemctl enable memcached.service  
systemctl start memcached.service


) | ts '[%Y-%m-%d %H-%M-%S]'

}


function keystone() {

# open fd
exec 3>&1

# Store data to $VALUES variable
local VALUES_3=$(dialog --ok-label "Submit" \
          --backtitle "KeyStone Setup" \
          --title "" \
          --form "Dien thong tin o duoi" \
15 50 0 \
        "MariaDB User: keystone" 1 1 "Not change"  1 40 0 0 \
        "DB Password:"   2 1       "keystone_123"      2 20 20 0 \
2>&1 1>&3)

[ "$?" != "0" ] && exit

echo  `echo $VALUES_3 | cut -f1 -d " "`

(

echo "< Cau hinh Database "

mysql -u root  -e "CREATE DATABASE IF NOT EXISTS keystone";
mysql -u root  -e  "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' \
IDENTIFIED BY '`echo $VALUES_3 | cut -f1 -d " "`';GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' \
IDENTIFIED BY '`echo $VALUES_3 | cut -f1 -d " "`';"

echo "< Cau hinh Firewall"
firewall-cmd --add-port=3306/tcp --permanent ## SQL Server
firewall-cmd --add-port=5000/tcp --permanent ## Keystone Authen
firewall-cmd --add-port=35357/tcp --permanent ## Keytone Authen
firewall-cmd --reload

## Cau hinh keystone

echo "< Cai dat Package"

rpm -q {openstack-keystone,httpd,mod_wsgi,crudini}  
[ $? != 0 ]  && yum install -y  openstack-keystone httpd mod_wsgi crudini


echo "< Cau hinh Keystone"
crudini --set /etc/keystone/keystone.conf "database" "connection" "mysql+pymysql://keystone:`echo $VALUES_3 | cut -f1 -d " "`@controller/keystone"
crudini --set /etc/keystone/keystone.conf "token" "provider" "fernet"


echo "< Dong do Database"
su -s /bin/sh -c "keystone-manage db_sync" keystone
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

echo "< Bootstrap Keystone "

keystone-manage bootstrap --bootstrap-password keystone_123 \
  --bootstrap-admin-url http://controller:5000/v3/ \
  --bootstrap-internal-url http://controller:5000/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne

echo "< Khoi dong dich vu"

ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/
systemctl enable httpd.service && systemctl stop httpd.service
systemctl start httpd.service


echo "< Khoi tao tap tin RC"

echo "
export OS_USERNAME=admin
export OS_PASSWORD=keystone_123
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3 " > admin-openrc
. admin-openrc

) | ts '[%Y-%m-%d %H-%M-%S]'

echo "< Khoi tao Service Project"
openstack project create --domain default --description "Service Project" service

}  

function glance() {

# open fd
exec 3>&1

# Store data to $VALUES variable
local VALUES_4=$(dialog --ok-label "Submit" \
          --backtitle "GLance Setup" \
          --title "" \
          --form "Dien thong tin o duoi" \
15 50 0 \
        "MariaDB User: glance" 1 1 "Not change"  1 40 0 0 \
        "DB Password:"   2 1       "glance_123"      2 20 20 0 \
        "Keystone User: glance" 3 1 "Not change"  3 40 0 0 \
        "KT User Password:"   4 1       "glance_123"     4  20 20 0 \
penstack service delete nova /dev/null 2>&1

2>&1 1>&3)

[ "$?" != "0" ] && exit

clear
(

echo "< Khoi tao Database"
mysql -u root --password=hung -e "create database IF NOT EXISTS  glance"
mysql -u root --password=hung -e "GRANT ALL PRIVILEGES on glance.* to 'glance'@'localhost' IDENTIFIED BY '`echo $VALUES_4 | cut -f1 -d " "`' "
mysql -u root --password=hung -e "GRANT ALL PRIVILEGES on glance.* to 'glance'@'%'  IDENTIFIED BY  '`echo $VALUES_4 | cut -f1 -d " "`'"

echo "< Dang Nhap"
source admin-openrc

echo "< Khoi tao User"
openstack user delete glance > /dev/null 2>&1
openstack user create --domain default glance --password `echo $VALUES_4 | cut -f2 -d " "`
openstack user set --password `echo $VALUES_4 | cut -f2 -d " "`  glance
openstack role add --project service --user glance admin

echo "< Khoi tao Service Glance"  

openstack service delete glance /dev/null 2>&1

openstack service create --name glance --des "Openstack Image -- Glance" image


echo "< Khoi tao Endpoint"
openstack endpoint delete `openstack endpoint list --service glance | awk '{print $2}'` > /dev/null 2>&1
openstack endpoint create --region RegionOne image public http://controller:9292
openstack endpoint create --region RegionOne image admin http://controller:9292
openstack endpoint create --region RegionOne image internal  http://controller:9292

echo "< Cai dat Package"


rpm -q openstack-glance
[ $? != 0 ]  && yum install -y openstack-glance

yum install -y openstack-glance

echo "< Cau hinh Glance"

cp /etc/glance/glance-api.conf /etc/glance/glance-api.conf.origin
cp /etc/glance/glance-registry.conf /etc/glance/glance-registry.conf.origin
crudini --set config/glance-api.conf "database" "connection" "mysql+pymysql://glance:`echo $VALUES_4 | cut -f1 -d " "`@controller/glance"
crudini --set config/glance-registry.conf "database" "connection" "mysql+pymysql://glance:`echo $VALUES_4 | cut -f1 -d " "`@controller/glance"
crudini --set config/glance-api.conf "keystone_authtoken" "password" "`echo $VALUES_4 | cut -f2 -d " "`"
crudini --set config/glance-registry.conf "keystone_authtoken" "password" "`echo $VALUES_4 | cut -f2 -d " "`"
yes | cp config/glance-api.conf /etc/glance/glance-api.conf && chown root:glance /etc/glance/glance-api.conf
yes | cp config/glance-registry.conf /etc/glance/glance-registry.conf  && chown root:glance /etc/glance/glance-registry.conf

echo "< Dong bo Database"

su -s /bin/sh -c "glance-manage db_sync" glance

echo "< Khoi dong dich vu"

systemctl stop openstack-glance-api.service \
  openstack-glance-registry.service
systemctl start openstack-glance-api.service \
  openstack-glance-registry.service
systemctl enable openstack-glance-api.service \
  openstack-glance-registry.service
systemctl start openstack-glance-api.service \
  openstack-glance-registry.service

echo "< Cau hinh FirewallD"

firewall-cmd --add-port={11211/tcp,9191/tcp,9292/tcp} --permanent 
firewall-cmd --reload 

) | ts '[%Y-%m-%d %H-%M-%S]'


}

function nova_server() {


# open fd
exec 3>&1

# Store data to $VALUES variable
local VALUES_5=$(dialog --ok-label "Submit" \
          --backtitle "Nova Setup" \
          --title "" \
          --form "Dien thong tin o duoi" \
15 50 0 \
        "MariaDB User: nova" 1 1 "Not change"  1 40 0 0 \
        "DB Password:"   2 1       "nova_123"      2 20 20 0 \
        "Nova User: nova" 3 1 "Not change"  3 40 0 0 \
        "Nova  Password:"   4 1       "nova_123"     4  20 20 0 \
        "Placement User: placement" 5 1 "Not change"  6 40 0 0 \
        "Placement Password:"   6 1       "placement_123"   6:  20 20 0 \
2>&1 1>&3)

[ "$?" != "0" ] && exit

clear

( 
 
echo "< Dang nhap"
source admin-openrc

echo "< Khoi tao DB"

mysql -u root  <<EOF
CREATE DATABASE IF NOT EXISTS nova_api;
CREATE DATABASE IF NOT EXISTS nova;
CREATE DATABASE IF NOT EXISTS nova_cell0;
GRANT ALL PRIVILEGES on nova_api.* to 'nova'@'localhost' identified by "`echo $VALUES_5 | cut -f1 -d " "`";
GRANT ALL PRIVILEGES on nova_api.* to 'nova'@'%' identified by "`echo $VALUES_5 | cut -f1 -d " "`";
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' \
  IDENTIFIED BY "`echo $VALUES_5 | cut -f1 -d " "`";
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' \
  IDENTIFIED BY "`echo $VALUES_5 | cut -f1 -d " "`";
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' \
  IDENTIFIED BY "`echo $VALUES_5 | cut -f1 -d " "`";
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' \
  IDENTIFIED BY "`echo $VALUES_5 | cut -f1 -d " "`";
EOF


echo "< Khoi tao User Nova"

openstack user delete nova > /dev/null 2>&1
openstack user create --domain default nova --password `echo $VALUES_5 | cut -f2 -d " "`
openstack user set --password `echo $VALUES_5 | cut -f2 -d " "`  glance
openstack role add --project service --user nova admin


echo "< Khoi tao Service Nova"
openstack service delete nova > /dev/null 2>&1
openstack service create --name nova --description "Compute Service " compute

echo "Khoi tao Endpoint Nova"

openstack endpoint delete `openstack endpoint list --service nova | awk '{print $2}'` > /dev/null 2>&1
openstack endpoint create --region RegionOne compute public http://controller:8774/v2.1
openstack endpoint create --region RegionOne compute internal http://controller:8774/v2.1  
openstack endpoint create --region RegionOne compute admin http://controller:8774/v2.1

echo "< Khoi tao User Placement"

openstack user delete placement  > /dev/null 2>&1
openstack user create --domain default placement  --password `echo $VALUES_5 | cut -f3 -d " "`
openstack user set --password `echo $VALUES_5 | cut -f3 -d " "`  glance
openstack role add --project service --user placement admin


echo "< Khoi tao Service Placement"
openstack service delete placement > /dev/null 2>&1

openstack service create --name placement --description "PLacement API" placement


echo "< Khoi tao Endoint Placement"
openstack endpoint delete `openstack endpoint list --service placement | awk '{print $2}'` > /dev/null 2>&1
openstack endpoint create --region RegionOne placement public http://controller:8778
openstack endpoint create --region RegionOne placement internal http://controller:8778
openstack endpoint create --region RegionOne placement admin http://controller:8778


echo "< Cai dat Service"

yum install openstack-nova-api openstack-nova-conductor \
  openstack-nova-console openstack-nova-novncproxy \
  openstack-nova-scheduler openstack-nova-placement-api -y



echo "< Cau hinh Neutron Servcer"

cat <<EOF > /etc/nova/nova.conf 
[DEFAULT]
transport_url = rabbit://openstack:rabbitmq_123@controller
enabled_apis = osapi_compute,metadata
use_neutron = True
firewall_driver = nova.virt.firewall.NoopFirewallDriver
[api_database]
connection = mysql+pymysql://nova:`echo $VALUES_5 | cut -f1 -d " "`@controller/nova_api
[database]
connection = mysql+pymysql://nova:`echo $VALUES_5 | cut -f1 -d " "`@controller/nova
[api]
auth_strategy = keystone
[keystone_authtoken]
auth_url = http://controller:5000/v3
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = nova
password = `echo $VALUES_5 | cut -f2 -d " "`
[vnc]
enabled = true
server_listen = 0.0.0.0
server_proxyclient_address = 192.168.69.130
[glance]
api_servers = http://controller:9292
[oslo_concurrency]
lock_path = /var/lib/nova/tmp
[placement]
os_region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://controller:5000/v3
username = placement
password = `echo $VALUES_5 | cut -f3 -d " "`
EOF

echo "< Cau hinh Placement WSGI API"

echo "
<Directory /usr/bin>
   <IfVersion >= 2.4>
 Require all granted
 </IfVersion>
 <IfVersion < 2.4>
 Order allow,deny
 Allow from all
 </IfVersion>
</Directory>
" >> /etc/httpd/conf.d/00-nova-placement-api.conf

echo "< Khoi dong Service HTTPD"

systemctl stop httpd
systemctl restart httpd

echo "< Dong bo Database"
su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
su -s /bin/sh -c "nova-manage db sync" nova

nova-manage cell_v2 list_cells

echo "< Khoi dong dich vu "

systemctl stop openstack-nova-api.service \
  openstack-nova-consoleauth.service openstack-nova-scheduler.service \
  openstack-nova-conductor.service openstack-nova-novncproxy.service
systemctl start openstack-nova-api.service \
  openstack-nova-consoleauth.service openstack-nova-scheduler.service \
  openstack-nova-conductor.service openstack-nova-novncproxy.service
systemctl enable openstack-nova-api.service \
  openstack-nova-consoleauth.service openstack-nova-scheduler.service \
  openstack-nova-conductor.service openstack-nova-novncproxy.service

echo "< Cau hinh FirewallD"
firewall-cmd --add-port={11211/tcp,5672/tcp} --permanent 
firewall-cmd --add-port=8778/tcp --permanent 
firewall-cmd --add-port={6080/tcp,6081/tcp,6082/tcp,8774/tcp,8773/tcp,8775/tcp} --permanent 
firewall-cmd --add-port=5900-5999/tcp --permanent 
firewall-cmd --reload


) | ts '[%Y-%m-%d %H-%M-%S]'

}  



function neutron_controller() {


# open fd
exec 3>&1

# Store data to $VALUES variable
local VALUES_6=$(dialog --ok-label "Submit" \
          --backtitle "Nova Setup" \
          --title "" \
          --form "Dien thong tin o duoi" \
15 50 0 \
        "MariaDB User: neutron" 1 1 "Not change"  1 40 0 0 \
        "DB Password:"   2 1       "neutron"      2 20 20 0 \
        "Neutron User: neutron" 3 1 "Not change"  3 40 0 0 \
        "Neutron  Password:"   4 1       "neutron"     4  20 20 0 \
        "Network Provider Interace: " 5 1 "ens192"  5 40 0 0 \
2>&1 1>&3)

[ "$?" != "0" ] && exit

clear


echo "----------- Khoi tao database------------"

mysql -u root --password=123@123Aa <<EOF
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' \
IDENTIFIED BY 'neutron_123';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' \
IDENTIFIED BY 'neutron_123';
EOF

openstack user create --domain default --password=neutron_123 neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron \
  --description "OpenStack Networking" network


openstack endpoint create --region RegionOne \
  network public http://controller:9696
openstack endpoint create --region RegionOne \
  network internal http://controller:9696
openstack endpoint create --region RegionOne \
  network admin http://controller:9696


yum --enablerepo=centos-openstack-queens,epel -y install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch

cat << EOF > /etc/neutron/neutron.conf
[DEFAULT]
service_plugins = router
allow_overlapping_ips = True
core_plugin = ml2
auth_strategy = keystone
transport_url = rabbit://openstack:rabbitmq_123@controller
notify_nova_on_port_status_changes = true
notify_nova_on_port_data_changes = true
[database]
connection = mysql+pymysql://neutron:neutron_123@controller/neutron

[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = neutron_123

[nova]
auth_url = http://controller:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = nova
password = nova_123

[oslo_concurrency]
lock_path = /var/lib/neutron/tmp

EOF


cat << EOF > /etc/neutron/plugins/ml2/ml2_conf.ini
[ml2]
type_drivers = flat,vlan,vxlan
tenant_network_types = vxlan
mechanism_drivers = openvswitch,l2population
[ml2_type_vxlan]
vni_ranges = 1:300
EOF


cat << EOF > /etc/neutron/plugins/ml2/openvswitch_agent.ini
[ovs]
bridge_mappings = provider:br-provider
local_ip = 192.168.69.130
	
[agent]
tunnel_types = vxlan
l2_population = True

[securitygroup]
firewall_driver = iptables_hybrid
EOF


cat << EOF > /etc/neutron/l3_agent.ini
[DEFAULT]
interface_driver = openvswitch
external_network_bridge =
EOF

firewall-cmd --add-port=9696/tcp --permanent ## Neutron API
firewall-cmd --add-port=4789/udp --permanent ## VXLAN Tunnel 
firewall-cmd --reload


## DHCP Agent
 
cat <<EOF > /etc/neutron/dhcp_agent.ini
[DEFAULT]
interface_driver = openvswitch
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = true
EOF

##  Medata Agent

cat <<EOF > /etc/neutron/metadata_agent.ini
[DEFAULT]
nova_metadata_host = controller
metadata_proxy_shared_secret = metadata_123
EOF


cat <<EOF >>/etc/nova/nova.conf
[neutron]
url = http://controller:9696
auth_url = http://controller:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = neutron_123
service_metadata_proxy = true
metadata_proxy_shared_secret = metadata_123
EOF


cat << EOF > /etc/sysconfig/network-scripts/ifcfg-provider
DEVICE="br-provider"
TYPE="OVSBridge"
SLAVE="yes"
BOOTPROTO="static"
IPADDR=192.168.30.130
NETMASK=255.255.255.0
GATEWAY=192.168.30.1
DNS1=1.1.1.1
IPV6INIT="no"
NM_CONTROLLED="yes"
ONBOOT="yes"
DEFROUTE="yes"
PEERDNS="yes"
PEERROUTES="yes"
IPV4_FAILURE_FATAL="yes"
EOF

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-ens192
DEVICE="ens192"
ONBOOT="yes"
TYPE="OVSPort"
DEVICETYPE="ovs"
OVS_BRIDGE="br-provider"
EOF


} 


function cinder_controlller() {

echo "export OS_VOLUME_API_VERSION=2" >> admin-openrc
source admin-openrc

## Setup DB
mysql -u root <<EOF
CREATE DATABASE cinder;
GRANT ALL PRIVILEGES on cinder.* to 'cinder'@'localhost' identified by "cinder_123";
GRANT ALL PRIVILEGES on cinder.* to 'cinder'@'%' identified by "cinder_123";
EOF

## End DB

## User and Endpoint

openstack user create --domain default --password=cinder_123 cinder
openstack role add --project service --user cinder admin 
openstack service create --name cinderv2   --description "OpenStack Block Storage" volumev2
openstack service create --name cinderv3   --description "OpenStack Block Storage" volumev3
openstack endpoint create --region RegionOne   volumev2 public http://controller:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne   volumev2 internal http://controller:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne   volumev2 admin http://controller:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne   volumev3 public http://controller:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne   volumev3 internal http://controller:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne   volumev3 admin http://controller:8776/v3/%\(project_id\)s 



}


function add_compute_node() { 

OUTPUT="/tmp/input.txt"
>$OUTPUT

dialog --backtitle "Openstack Setup" --title "IP Manager" \
--form "\n Hay nhap dia chi manager vao day" 25 60 16 \
"MY-IP Compute Node :" 2 1 "192.168.69.131" 2 25 25 30 \
"MY-IP Compute Node :" 3 1 "192.168.69.132" 3 25 25 30 2>$OUTPUT 

response=$?

password_data="/tmp/password.txt"
>$password_data
command_data="/tmp/command.txt"
>$command_data
case $response in
   0)
        dialog --title "Dang nhap vao :  $line" \
             --inputbox "Dien mat khau tai day : " 25 60 123 2>$password_data
        clear
        ssh-keyscan $line >> $HOME/.ssh/known_hosts 
        ( echo "---------------Set up $line ---------------"
          sshpass -f /tmp/password.txt ssh-copy-id root@$line  > /dev/null 2>&1
          ssh root@$line  << EOF
              yum update -y
              yum install centos-release-openstack-queens -y && yum upgrade -y
              yum install openstack-selinux -y
              timedatectl set-timezone Asia/Ho_Chi_Minh 
              systemctl start firewalld && systemctl enable firewalld
	            setenforce permissive
              sed -i -e "s/SELINUX=enforcing/SELINUX=permissive/g" /etc/sysconfig/selinux 
EOF
	       echo "---------------- Done ---------------------"	
          ) | ts '[%Y-%m-%d %H-%M-%S]'

    ;;
   1)
    cho -e "\n Da thoat chuong trinh"

esac




}



#package_startup
#required_package
#keystone
#glance
#nova_server
nova_compute
