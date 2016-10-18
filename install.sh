#!/bin/bash
echo -e '\033[0;31m Installation du Firmware Wifi, Sudo et Nano \033[0m'
apt-get update
apt-get install sudo firmware-realtek nano
echo -e '\033[0;31m Mise en place du Hotspot via le script de Raspberry-at-Home \033[0m'
ifconfig wlan0 up
wget "http://raspberry-at-home.com/files/ap_setup.sh"
chmod +x ap_setup.sh
sudo ./ap_setup.sh
