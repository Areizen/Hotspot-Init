#!/bin/bash
echo -e '\033[0;31m Installation du Firmware Wifi, Sudo et Nano \033[0m'
apt-get update
apt-get install sudo firmware-realtek nano
echo -e '\033[0;31m Mise en place du Hotspot via le script de Raspberry-at-Home \033[0m'
ifconfig wlan0 up
run_time=`date +%Y%m%d%H%M`
log_file="ap_setup_log.${run_time}"
echo -e '\033[0;32m Numéro de canal (1-13) :\033[0m'
read AP_CHANNEL
read -p "Entrez le nom du réseau WIFI que vous voulez créer : " AP_SSID
read  -s -p "Entrez le mot de passe de votre réseau :" AP_PASS
if[ `echo $AP_PASS | wc -c` -lt 8] || [`echo $AP_PASS` -gt 63 `];then
  echo "La taille de votre mot de passe n'est pas adaptée"
  exit 1
fi
if [ !`dpkg -l | grep usbutils` ];then
  echo -e "Installation de usbutils"
  apt-get install usbutils
fi
if [ `lsusb | grep "RTL8188CUS\|RTL8192CU" | wc -l` -ne 0 ]; then
  echo "Votre firmware Wifi demande une version spéciale de Hostapd"
  CHIPSET = "yes"
else
  CHIPSET="no"
fi
echo "Verification des Interfaces"
NONIC=`netstat -i | grep ^wlan | cut -d ' ' -f 1 | wc -l`
if [ ${NONIC} -lt 1 ]; then
        echo "Il n'y a pas d'interfaces Wifi verifiez qu'il est bien up" | tee -a ${log_file}
        exit 1
elif [ ${NONIC} -gt 1 ]; then
        echo "Vous avez plus d'un interface : " | tee -a ${log_file}
        select INTERFACE in `netstat -i | grep ^wlan | cut -d ' ' -f 1`
        do
                NIC=${INTERFACE}		
break
        done
        exit 1
else
        NIC=`netstat -i | grep ^wlan | cut -d ' ' -f 1`
fi
read -p "Veuillez définir l'interface du réseau que le WIFI partagera: " WAN 
DNS=`netstat -rn | grep ${WAN} | grep UG | tr -s " " "X" | cut -d "X" -f 2`
echo "Le DNS va être défini à  " ${DNS}               								| tee -a ${log_file}
echo "Vous pouvez changer votre dns dans /etc/dhcp/dhcpd.conf"   | tee -a ${log_file}
echo ""
read -p "Veuillez entrer votre réseau (i.e. 192.168.10.X). Veuillez mettre un X à la fin!!!  " NETWORK 

if [ `echo ${NETWORK} | grep X$ | wc -l` -eq 0 ]; then
	echo "L'adresse fourni est invalide."
	exit 4
fi	
AP_ADDRESS=`echo ${NETWORK} | tr \"X\" \"1\"`
AP_UPPER_ADDR=`echo ${NETWORK} | tr \"X\" \"9\"`
AP_LOWER_ADDR=`echo ${NETWORK} | tr \"X\" \"2\"`
SUBNET=`echo ${NETWORK} | tr \"X\" \"0\"`

echo ""
echo ""
echo "+========================================================================"
echo "Vos paramètres seront:"                                 | tee -a ${log_file}
echo "SSID : ${AP_SSID}"                                      | tee -a ${log_file}
echo "Mot de passe : ${AP_PASS}"                                  | tee -a ${log_file}
echo "AP NIC address: ${AP_ADDRESS}  "                        | tee -a ${log_file}
echo "Sous réseau:  ${SUBNET} "																		| tee -a ${log_file}
echo "Range  ${AP_LOWER_ADDR} to ${AP_UPPER_ADDR}"            | tee -a ${log_file}
echo "Masque: 255.255.255.0"                                 | tee -a ${log_file}
echo "WAN: ${WAN}"																						| tee -a ${log_file}

read -n 1 -p "Continuer ? (y/n):" GO
echo ""
        if [ ${GO,,} = "y" ]; then
                sleep 1
        else
				exit 2
        fi
echo "Paramétrage de $NIC ..."
echo "Installation de Hostapd Isch-dhcp-server Iptables"
apt-get -y install hostapd isc-dhcp-server iptables                                                     | tee -a ${log_file} 
service hostapd stop | tee -a ${log_file} > /dev/null
service isc-dhcp-server stop  | tee -a ${log_file}  > /dev/null
echo ""                 

echo "Mise en place de l'AP ..."
echo "Configure: /etc/default/isc-dhcp-server"                                                          | tee -a ${log_file} 
echo "DHCPD_CONF=\"/etc/dhcp/dhcpd.conf\""                         >  /etc/default/isc-dhcp-server
echo "INTERFACES=\"$NIC\""                                         >> /etc/default/isc-dhcp-server

echo "Configure: /etc/default/hostapd"                                                          | tee -a ${log_file} 
echo "DAEMON_CONF=\"/etc/hostapd/hostapd.conf\""                   > /etc/default/hostapd

echo "Configure: /etc/dhcp/dhcpd.conf"                                                          | tee -a ${log_file} 
echo "ddns-update-style none;"                                     >  /etc/dhcp/dhcpd.conf
echo "default-lease-time 86400;"                                     >> /etc/dhcp/dhcpd.conf
echo "max-lease-time 86400;"                                        >> /etc/dhcp/dhcpd.conf
echo "subnet ${SUBNET} netmask 255.255.255.0 {"                    >> /etc/dhcp/dhcpd.conf
echo "  range ${AP_LOWER_ADDR} ${AP_UPPER_ADDR}  ;"                >> /etc/dhcp/dhcpd.conf
echo "  option domain-name-servers 8.8.8.8, 8.8.4.4  ;"                       >> /etc/dhcp/dhcpd.conf
echo "  option domain-name \"home\";"                              >> /etc/dhcp/dhcpd.conf
echo "  option routers " ${AP_ADDRESS} " ;"                        >> /etc/dhcp/dhcpd.conf
echo "}"                                                           >> /etc/dhcp/dhcpd.conf

echo "Configure: /etc/hostapd/hostapd.conf"                                                     | tee -a ${log_file} 
if [ ! -f /etc/hostapd/hostapd.conf ]; then
	touch /etc/hostapd/hostapd.conf
fi
	
echo "interface=$NIC"                                    >  /etc/hostapd/hostapd.conf
echo "ssid=${AP_SSID}"                                   >> /etc/hostapd/hostapd.conf
echo "channel=${AP_CHANNEL}"                             >> /etc/hostapd/hostapd.conf
echo "# WPA and WPA2 configuration"                      >> /etc/hostapd/hostapd.conf
echo "macaddr_acl=0"                                     >> /etc/hostapd/hostapd.conf
echo "auth_algs=1"                                       >> /etc/hostapd/hostapd.conf
echo "ignore_broadcast_ssid=0"                           >> /etc/hostapd/hostapd.conf
echo "wpa=2"                                             >> /etc/hostapd/hostapd.conf
echo "wpa_passphrase=${AP_PASS}"               >> /etc/hostapd/hostapd.conf
echo "wpa_key_mgmt=WPA-PSK"                              >> /etc/hostapd/hostapd.conf
echo "wpa_pairwise=TKIP"                                 >> /etc/hostapd/hostapd.conf
echo "rsn_pairwise=CCMP"                                 >> /etc/hostapd/hostapd.conf
echo "# Hardware configuration"                          >> /etc/hostapd/hostapd.conf
if [ ${CHIPSET} = "yes" ]; then

	echo "driver=rtl871xdrv"                         >> /etc/hostapd/hostapd.conf
	echo "ieee80211n=1"                              >> /etc/hostapd/hostapd.conf
    echo "device_name=RTL8192CU"                     >> /etc/hostapd/hostapd.conf
    echo "manufacturer=Realtek"                      >> /etc/hostapd/hostapd.conf
else
	echo "driver=nl80211"                            >> /etc/hostapd/hostapd.conf
fi

echo "hw_mode=g"                                         >> /etc/hostapd/hostapd.conf

echo "Configure: /etc/sysctl.conf"                                                              | tee -a ${log_file} 
echo "net.ipv4.ip_forward=1"                             >> /etc/sysctl.conf 

echo "Configure: iptables"                                                                      | tee -a ${log_file} 
iptables -t nat -A POSTROUTING -o ${WAN} -j MASQUERADE
iptables -A FORWARD -i ${WAN} -o ${NIC} -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i ${NIC} -o ${WAN} -j ACCEPT
sh -c "iptables-save > /etc/iptables.ipv4.nat"

echo "Configure: /etc/network/interfaces"                                                       | tee -a ${log_file} 
echo "auto ${NIC}"                                         >>  /etc/network/interfaces
echo "allow-hotplug ${NIC}"                                >> /etc/network/interfaces
echo "iface ${NIC} inet static"                           >> /etc/network/interfaces
echo "        address ${AP_ADDRESS}"                       >> /etc/network/interfaces
echo "        netmask 255.255.255.0"                     >> /etc/network/interfaces
echo "up iptables-restore < /etc/iptables.ipv4.nat"      >> /etc/network/interfaces
if [ ${CHIPSET,,} = "yes" ]; then 
	echo "Download and install: special hostapd version"                                           | tee -a ${log_file}
	wget "http://raspberry-at-home.com/files/hostapd.gz"                                           | tee -a ${log_file}
     gzip -d hostapd.gz
     chmod 755 hostapd
     cp hostapd /usr/sbin/
fi
ifdown ${NIC}                                                                                    | tee -a ${log_file}
ifup ${NIC}                                                                                      | tee -a ${log_file}
service hostapd start                                                                          | tee -a ${log_file}
service isc-dhcp-server start                                                                  | tee -a ${log_file}

echo ""
read -n 1 -p "Voulez vous démarrer le Hotspot au Boot? (y/n): " startup_answer                       
echo ""
if [ ${startup_answer,,} = "y" ]; then
        echo "Configuration du démarrage"                                                              | tee -a ${log_file}
        update-rc.d hostapd enable                                                             | tee -a ${log_file}
        update-rc.d isc-dhcp-server enable                                                     | tee -a ${log_file}
else
        echo "Au cas ou vous changeriez d'avis executez les commandes suivantes:"                       | tee -a ${log_file}
        echo "update-rc.d hostapd enable"                                                      | tee -a ${log_file}
        echo "update-rc.d isc-dhcp-server enable"                                              | tee -a ${log_file}
fi
exit 0








