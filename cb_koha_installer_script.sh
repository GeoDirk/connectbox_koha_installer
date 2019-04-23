#!/bin/bash

# set the correct environment for compiling otherwise we get errors.
export LANG=en_GB.UTF-8; export LC_ALL=en_GB.UTF-8; export LANGUAGE=en_GB.UTF-8;

function pause(){
  read -p "$*"
}

SECONDS=0

echo "=================================================================="
echo "       I N S T A L L         S T A R T I N G"
echo "=================================================================="
#fix that pesky GB keyboard...requires a reboot at some point to work
sed -i 's/XKBLAYOUT="gb"/XKBLAYOUT="us"/g' /etc/default/keyboard
apt-get -y update --fix-missing
apt-get -y install wget

echo "------------------------------------------------------------------"
echo " get and install the koha repository key"
echo "------------------------------------------------------------------"
echo deb [arch=i386] http://debian.koha-community.org/koha stable main | sudo tee /etc/apt/sources.list.d/koha.list
wget -O- http://debian.koha-community.org/koha/gpg.asc | sudo apt-key add -

echo "------------------------------------------------------------------"
echo " get the system updated to the latest of everything"
echo "------------------------------------------------------------------"
apt-get -y update --fix-missing
apt-get -y upgrade

echo "------------------------------------------------------------------"
echo " free up the disk space by cleaning retrieved .deb files from the local repository"
echo "------------------------------------------------------------------"
apt-get clean

echo "------------------------------------------------------------------"
echo " Turn off nginx hack  === TODO KEEP NGINX FOR ROUTING"
echo "------------------------------------------------------------------"
systemctl disable nginx
service nginx stop

# echo "------------------------------------------------------------------"
# echo "  Disable all those firewall rules"
# echo "------------------------------------------------------------------"
# iptables-save > default_firewall_rules.fw
# iptables -P INPUT ACCEPT
# iptables -P FORWARD ACCEPT
# iptables -P OUTPUT ACCEPT
# iptables -t nat -F
# iptables -t mangle -F
# iptables -F
# iptables -X

echo "------------------------------------------------------------------"
echo " Open up port 8080 in the firewall - used for Admin access by KOHA"
echo "------------------------------------------------------------------"
iptables -A INPUT -p tcp --dport 8080 --j ACCEPT

echo "------------------------------------------------------------------"
echo "  install mysql server"
echo "------------------------------------------------------------------"
apt-get -y install mysql-server
# apt-get -y install mariadb-server

echo "------------------------------------------------------------------"
echo " install Apache web server"
echo "------------------------------------------------------------------"
apt-get -y install apache2

echo "------------------------------------------------------------------"
echo " install all the basic development tools"
echo "------------------------------------------------------------------"
apt-get -y install build-essential

echo "------------------------------------------------------------------"
echo " build the missing library: CryptX"
echo "------------------------------------------------------------------"
yes | perl -MCPAN -e "install CryptX"  #auto enter [yes]
echo "------------------------------------------------------------------"
echo " build the missing library: Mojo::JWT"
echo "------------------------------------------------------------------"
perl -MCPAN -e "install Mojo::JWT"
echo "------------------------------------------------------------------"
echo " build the missing library: Test::Exception"
echo "------------------------------------------------------------------"
perl -MCPAN -e "install Test::Exception"
echo "------------------------------------------------------------------"
echo " build the missing library: Test::Most"
echo "------------------------------------------------------------------"
perl -MCPAN -e "install Test::Most"
echo "------------------------------------------------------------------"
echo " install libmojo-jwt-perl"
echo "------------------------------------------------------------------"
apt-get -y install libmojo-jwt-perl
echo "------------------------------------------------------------------"
echo " install dh-make-perl"
echo "------------------------------------------------------------------"
apt-get -y install dh-make-perl
echo "------------------------------------------------------------------"
echo " build the missing library: CryptX"
echo "------------------------------------------------------------------"
dh-make-perl --build --cpan CryptX

echo "------------------------------------------------------------------"
echo " install the libcryptx-perl package"
echo "------------------------------------------------------------------"
filename="$(ls libcryptx-perl_*.deb)"
dpkg -i "$filename"  #dpkg -i libcryptx-perl_0.063-1_armhf.deb

echo "------------------------------------------------------------------"
echo " install the libnet-oauth2-authorizationserver-perl package"
echo "------------------------------------------------------------------"
dh-make-perl --build --cpan Net::OAuth2::AuthorizationServer
filename="$(ls libnet-oauth2-authorizationserver-perl_*.deb)"
dpkg -i "$filename"  #dpkg -i libnet-oauth2-authorizationserver-perl_0.20-1_all.deb

echo "------------------------------------------------------------------"
echo " install koha"
echo "------------------------------------------------------------------"
apt-get -y update --fix-missing
apt-get install koha-common -y

echo "------------------------------------------------------------------"
echo " update the koha config file"
echo "------------------------------------------------------------------"
# configure the admin port to be 8080
sed -i 's/INTRAPORT="80"/INTRAPORT="8080"/g' /etc/koha/koha-sites.conf
# set the domain to be just the ip address of the device
ipaddress=$(ifconfig eth0 | grep inet | awk '{ print $2 }' | head -1)
sed -i 's/DOMAIN=".myDNSname.org"/DOMAIN="$ipaddress"/g' /etc/koha/koha-sites.conf

echo "------------------------------------------------------------------"
echo " Set up Apache modules"
echo "------------------------------------------------------------------"
#enable mod_rewrite Provides a rule-based rewriting engine to rewrite
#  requested URLs on the fly
a2enmod rewrite
#enable cgi scripts allows execution of CGI scripts
a2enmod cgi 
systemctl restart apache2
#disable the default website (the default Apache screen)
a2dissite 000-default
#enable mod_deflate that allows output from your server to be compressed
#  before being sent to the client over the network.
a2enmod deflate

#add in additional listener in Apache
sed -i 's/Listen 80/Listen 80\nListen 8080/g' /etc/apache2/ports.conf

echo "------------------------------------------------------------------"
echo " Create a KOHA library called 'library'"
echo "------------------------------------------------------------------"
koha-create --create-db library
#enable the libary site in Apache
a2ensite library
service apache2 restart

#pull out the koha username
username=$(xpath -e '/yazgfs/config/user/text()' /etc/koha/sites/library/koha-conf.xml)
#pull out the kohan password
password=$(xpath -e '/yazgfs/config/pass/text()' /etc/koha/sites/library/koha-conf.xml)

echo "=================================================================="
echo "   K O H A    I N S T A L L   S C R I P T    C O M P L E T E D"
duration=$SECONDS
echo "       elapsed:  $(($duration / 60)) minutes and $(($duration % 60)) seconds"
echo "=================================================================="
echo "  Open up a web browser and walk throught the installer"
echo "  http://$ipaddress:8080"
echo "  Username: $username"
echo "  Password: $password"
