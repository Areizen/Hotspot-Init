#!/bin/bash

echo -e '\033[0;31m Installation du Firmware Wifi, Sudo et Nano \033[0m'
apt-get update
apt-get install sudo firmware-realtek usbutils nano

echo -e '\033[0;31m Mise en place du Hotspot via le script de Raspberry-at-Home \033[0m'
ifconfig wlan0 up

run_time=`date +%Y%m%d%H%M`
log_file="ap_setup_log.${run_time}"

echo -e '\033[0;32m] Numéro de canal (1-13) :'
read AP_CHANNEL

echo "Updating repositories ... "
apt-get update
read -p "Entrez le nom du réseau WIFI que vous voulez créer" AP_SSID
read  -s -p "Entrez le mot de passe de votre réseau" AP_PASS

if[ `echo $AP_PASS | wc -c` -lt 8] || [`echo $AP_PASS` -gt 63 ];then
//TODO
