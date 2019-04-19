#!/bin/bash

function pause(){
	read -p "$*"
}

apt-get -y update
pause '---paused---'

apt-get -y install wget htop
pause '---paused---'

#add in the koha repository
echo deb [arch=i386] http://debian.koha-community.org/koha stable main | sudo tee /etc/apt/sources.list.d/koha.list
pause '---paused---'
#get and install the koha repository key
wget -O- http://debian.koha-community.org/koha/gpg.asc | sudo apt-key add -
pause '---paused---'
#get the system updated to the latest of everything
apt-get -y update
pause '---paused---'
apt-get -y upgrade
pause '---paused---'
#free up the disk space by cleaning retrieved .deb files from the local repository.
apt-get clean
pause '---paused---'

#== Turn off nginx hack  === TODO
systemctl disable nginx
service nginx stop
#======================
pause '---paused---'

#install mysql server
apt-get -y install mysql-server
pause '---paused---'
#install Apache web server
apt-get -y install apache2
pause '---paused---'

#intall all the basic development tools
apt-get -y install build-essential
pause '---paused---'

#build the missing libraries
yes | perl -MCPAN -e "install CryptX"  #auto enter [yes]
pause '---paused---'
perl -MCPAN -e "install Mojo::JWT"
pause '---paused---'
perl -MCPAN -e "install Test::Exception"
pause '---paused---'
perl -MCPAN -e "install Test::Most"
pause '---paused---'

apt-get -y install libmojo-jwt-perl
pause '---paused---'
apt-get -y install dh-make-perl
pause '---paused---'
dh-make-perl --build --cpan CryptX
pause '---paused---'
#get the built .deb package file
filename="$(ls libcryptx-perl_*.deb)"
dpkg -i "$filename"  #dpkg -i libcryptx-perl_0.063-1_armhf.deb
pause '---paused---'

dh-make-perl --build --cpan Net::OAuth2::AuthorizationServer
#get the built .deb package file
filename="$(ls libnet-oauth2-authorizationserver-perl_*.deb)"
dpkg -i "$filename"  #dpkg -i libnet-oauth2-authorizationserver-perl_0.20-1_all.deb
pause '---paused---'

#install koha
apt-get install koha-common -y
pause '---paused---'

#update the koha config file
sed -i 's/INTRAPORT="80"/INTRAPORT="8080"/g' /etc/koha/koha-sites.conf

#Set up Apache
#enable mod_rewrite Provides a rule-based rewriting engine to rewrite
#  requested URLs on the fly
a2enmod rewrite
#enable cgi scripts
a2enmod mod_cgi allows execution of CGI scripts
systemctl restart apache2
#disable the default website (the default Apache screen)
a2dissite 000-default
#enable mod_deflate that allows output from your server to be compressed
#  before being sent to the client over the network.
a2enmod deflate

#add in additional listener in Apache
sed -i 's/Listen 80/Listen 80\n\tListen 8080/g' /etc/apache2/ports.conf

koha-create --create-db library
a2ensite library
service apache2 restart

#pull out the koha username
username = xpath -e '/yazgfs/config/user/text()' /etc/koha/sites/library/koha-config.xml
#pull out the kohan password
password = xpath -e '/yazgfs/config/pass/text()' /etc/koha/sites/library/koha-config.xml

echo "\n\n\n =================================================================="
echo "   K O H A    I N S T A L L   S C R I P T    C O M P L E T E D"
echo "=================================================================="
echo "  Username: $username"
echo "  Password: $password"
