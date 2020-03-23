#!/bin/bash
echo "Upgrading this node"
apt update
apt upgrade
echo "Installing require programs"
apt -y install openvpn
apt -y install mlocate
apt -y install tcpdump
apt -y install python-pip
apt -y install udevil
apt -y install gstreamer1.0-plugins-base
apt -y install gstreamer1.0-plugins-good
apt -y install gir1.2-gstreamer-1.0
apt -y install python-gst-1.0
apt -y install python-redis
apt -y install python-gi
apt -y install python-setuptools
echo "Installing openOB"
pip install openob
read -p "Enter password for coastfm: " passwd
useradd -m coastfm
echo coastfm:${passwd} | chpasswd
cd /tmp
echo "Adding alias's to /etc/profile"
echo 'alias ll="ls -l --color=auto"' >> /etc/profile
. /etc/profile
echo "Setting up openvpn"
mv client.conf /etc/openvpn/
mv cacert.pem /etc/openvpn/
mv obsetup.pem /etc/openvpn/
mv obsetup.key /etc/openvpn/
echo "Restarting openvpn"
systemctl restart openvpn
cat /proc/self/net/dev
read -p "Enter the 2nd network interface: " interface_2
echo "#pci card interface used for radiodj pc etc al" >> /etc/network/interfaces
echo "allow-hotplug $interface_2" >> /etc/network/interfaces
echo "iface $interface_2 inet static" >> /etc/network/interfaces
read -p "Enter the 2nd network interface ip address \(10.222.253.???\): " ip_2
echo "address $ip_2" >> /etc/network/interfaces
echo "netmask 255.255.255.0" >> /etc/network/interfaces
echo "broadcast 10.222.253.255" >> /etc/network/interfaces
