# connectbox_koha_installer
Script for installing KOHA library system onto a ConnectBox RPi image

Download and burn onto your microSD card the latest version of ConnectBox OS for the RPi.  

[ConnectBox Releases](https://github.com/ConnectBox/connectbox-pi/releases/)

This script has been tested against the [20181021](https://github.com/ConnectBox/connectbox-pi/releases/tag/v20181021) RPi image. It may or may not work for more current releases if they are published.

Instructions:

Plug in your RPi to an active LAN cable allowing the unit access to the internet. Connect up to your RPi using SSH.  Default username: root and default password: connectbox

Once inside, type/paste in the below instructions:


```
curl -O https://raw.githubusercontent.com/GeoDirk/connectbox_koha_installer/master/cb_koha_installer_script.sh

chmod 755 cb_koha_installer_script.sh

./cb_koha_installer_script.sh | tee koha_install.log
```
Sit back and wait an hour or so for the script to run full.  After that, connect using the web to http:\\192.168.88.69:8080 which is the admin port.  Using the new username and password shown at the end of the script, log in and complete the KOHA setup usng the web installer.

You can install eBooks or other media into the /media/usb0 directory or on an external USB stick.  Reference them like in this format from within KOHA:

http://rpi_ip_address:8082/media.pdf
