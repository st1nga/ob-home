#!/bin/bash


#To install rotter
# get rotter-0.9.tar.gz from legato
# get rotter.service from legato
# apt install libmp3lame-dev
# 

set -x
cd /root
echo "Upgrading this node"
apt update
apt -y upgrade
echo "Installing require programs"
apt -y install git
apt -y install simpleproxy
apt -y install curl
apt -y install lshw
apt -y install dnsmasq
apt -y install autogen
apt -y install alsa-utils
apt -y install autoconf
apt -y install sshd
apt -y install speedtest-cli
apt -y install rsync
apt -y install openvpn
apt -y install dnsutils
apt -y install mlocate
apt -y install apache2
apt -y install tcpdump
apt -y install python-pip
apt -y install figlet
apt -y install iotop
apt -y install gstreamer1.0-plugins-base
apt -y install gstreamer1.0-plugins-good
apt -y install gir1.2-gstreamer-1.0
apt -y install python-gst-1.0
apt -y install python-redis
apt -y install python-gi
apt -y install python-setuptools
apt -y install unzip
apt -y install net-tools
apt -y install ntp
apt -y install jackd
apt -y install jackd1 # for debian9 (maybe)
apt -y install xz-utils
apt -y install libncurses5-dev
apt -y install libjack-dev
apt -y install cmake
apt -y install libssl-dev
apt -y install mtr
apt -y install mariadb-client
apt -y install beep
apt -y install samba
apt -y install libsndfile1-dev
apt -y install sipcalc
#apt -y install isc-dhcp-server
apt -y install resolvconf

#for pyenv
apt -y install zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libffi-dev
apt -y install python3-pip

echo "Starting jackd"

rm jackd.service 2> /dev/null
wget meoem.com/jackd.service
systemctl enable /root/jackd.service
systemctl start jackd

if [ ! -f njconnect-1.6.tar.xz ]
then
  wget meoem.com/njconnect-1.6.tar.xz
  tar xf njconnect-1.6.tar.xz
  cd njconnect-1.6
  make install
  cd /root
fi

node=`hostname`
echo "Refreshing locate DB"
updatedb

echo "Installing openOB"
pip install openob

echo "Setting up openvpn"
cd /etc/openvpn
rm client.conf 2> /dev/null
wget meoem.com/client.conf
chmod 400 client.conf
sed -i "s/--node--/${node}/g" /etc/openvpn/client.conf

rm ${node}-TO-IPFire.zip 2> /dev/null
wget meoem.com/${node}-TO-IPFire.zip
unzip ${node}-TO-IPFire.zip

echo "Restarting openvpn"
systemctl enable openvpn@client.service
systemctl restart openvpn

cd /root/

read -p "Irreversable changes about to be made... Continue (y)n ": yn
if [ "$yn" != "y" ]
then
  exit
fi

echo "Adding aliases to /etc/profile"
grep "alias ll" /etc/profile 2> /dev/null
if [ $? = 1 ]
then
  wget meoem.com/append_to_etc_profile
  cat append_to_etc_profile >> /etc/profile
fi

echo "Updating resolv.conf"
grep "tantive" /etc/resolf.conf 2> /dev/null
if [ $? = 1 ]
then
  wget meoem.com/append_to_resolv
  cat append_to_resolv >> /etc/resolv.conf
fi

cat /proc/self/net/dev
read -p "Enter the 2nd network interface: " interface_2
read -p "Enter the last octet of the 2nd network interface ip address \(10.222.253.???\): " last_octet
ip_2=10.222.221.${last_octet}

if [ "${interface_2}" != "" ]
then
  grep "pci card interface used" /etc/network/interfaces > /dev/null
  if [ $? = 1 ]
  then
    echo "" >> /etc/network/interfaces
    echo "# pci card interface used for radiodj pc etc al" >> /etc/network/interfaces
    echo "allow-hotplug $interface_2" >> /etc/network/interfaces
    echo "iface $interface_2 inet static" >> /etc/network/interfaces

    broadcast_2=`sipcalc ${ip_2}/24 |grep Broadcast|cut -d'-' -f2`
    echo "address $ip_2" >> /etc/network/interfaces
    netmask_2=`sipcalc 10.222.142.1/24|grep 'Network mask'|grep 255|cut -d'-' -f2`
    echo "netmask ${netmask_2}" >> /etc/network/interfaces
    echo "broadcast ${broadcast_2}" >> /etc/network/interfaces
    ifup ${interface_2}
  fi
fi

echo "Setting up openob"
rm /etc/systemd/system/openob.service 2> /dev/null
wget meoem.com/openob.service
sed -i "s/--node_name--/${node}/" /root/openob.service
sed -i "s/--link_name--/${node}/" /root/openob.service
sed -i "s/--jack_name--/${node}/" /root/openob.service
openob_port=`expr $last_octet + 3000`
sed -i "s/--port--/${openob_port}/" /root/openob.service
mv openob.service /etc/systemd/system/

echo "Setting up proxysql"
if [ ! -f /etc/apt/sources.list.d/proxysql.list ]
then
  apt-get install -y lsb-release apt-transport-https
  wget -O - 'https://repo.proxysql.com/ProxySQL/repo_pub_key' | apt-key add -
  echo deb https://repo.proxysql.com/ProxySQL/proxysql-2.0.x/$(lsb_release -sc)/ ./ | tee /etc/apt/sources.list.d/proxysql.list

#Note: For 1.4.x series releases use https://repo.proxysql.com/ProxySQL/proxysql-1.4.x/$(lsb_release -sc)/ ./ instead.

  apt-get update
  apt-get install proxysql
# OR apt-get install proxysql=version

  cd /var/lib/proxysql/
  systemctl stop proxysql
  wget meoem.com/proxysql.db
  wget meoem.com/proxysql_stats.db
  chmod 600 proxysql.db proxysql_stats.db
  chown proxysql:proxysql *
  systemctl start proxysql
  cd /root
fi

rm beep_up.service beep_down.service 2> /dev/null
wget meoem.com/beep_up.service
wget meoem.com/beep_down.service

systemctl enable /root/beep_up.service
systemctl enable /root/beep_down.service

echo "setting up samba"
if [ ! -d /mp3 ]
then
  mkdir /mp3
  echo "" >> /etc/samba/smb.conf
  echo "[mp3]" >> /etc/samba/smb.conf
  echo "comment = CoastFM music" >> /etc/samba/smb.conf
  echo "path = /mp3" >> /etc/samba/smb.conf
  echo "guest ok = yes" >> /etc/samba/smb.conf
  echo "writeable = no" >> /etc/samba/smb.conf
fi

echo "setting up dhcpd"
cd /etc/dhcp
set -x
rm /etc/dhcp/dhcpd.conf 2> /dev/null
wget meoem.com/dhcpd.conf
network_address=`sipcalc ${ip_2}/24|grep "Network address"|cut -d'-' -f2`
sed -i "s/--dhcp-network--/${network_address}/" /etc/dhcp/dhcpd.conf
ip_start=`echo $ip_2|cut -d'.' -f-3`
sed -i "s/--dhcp-start--/${ip_start}.100/" /etc/dhcp/dhcpd.conf
sed -i "s/--dhcp-end--/${ip_start}.150/" /etc/dhcp/dhcpd.conf
sed -i "s/--this-ip--/${ip_2}/" /etc/dhcp/dhcpd.conf
sed -i "s/INTERFACESv4=\"\"/INTERFACESv4=\"${interface_2}\"/" /etc/default/isc-dhcp-server

cd /var/www/html
mv index.html index.html-01
wget meoem.com/index.html

cd /root
git clone https://github.com/kmatheussen/jack_capture.git
cd jack_capture
make
make install

cd /root
git clone https://github.com/njh/jackmeter.git
cd jackmeter
./autogen.sh
./configure
make install

systemctl enable /root/simpleproxy.service
systemctl start simpleproxy

cd /home/coastfm/bin
wget meoem.com:openob_control.py
wget meoem.com:talkback_control.py
chown coastfm:coastm openob_control.py talkback_control.py
chmod u+x openob_control.py talkback_control.py
cd /root
wget meoem.com:openob_control.service
wget meoem.com:talkback_control.service
systemctl enable /root/openob_control.service
systemctl enable talkback_control.service
systemctl start openob_control
systemctl start talkback_control

ps -eaf|grep smb|grep -v grep > /dev/null
if [ $? = 0 ]
then
  echo "samba is running"
fi
ps -eaf|grep proxysql|grep -v grep > /dev/null
if [ $? = 0 ]
then
  echo "proxysql is running"
fi
ps -eaf|grep openob|grep -v grep > /dev/null
if [ $? = 0 ]
then
  echo "openob is running"
fi
ps -eaf|grep openvpn|grep -v grep > /dev/null
if [ $? = 0 ]
then
  echo "openvpn is running"
fi
ps -eaf|grep apach|grep -v grep > /dev/null
if [ $? = 0 ]
then
  echo "apache  is running"
fi

if [ ! -f /etc/banner ]
then
  cd /usr/share/figlet
  wget http://www.figlet.org/fonts/starwars.flf
  cd /root
  figlet -fstarwars coastfm `hostname` > /etc/banner
  echo "banner /etc/banner" >> /etc/ssh/sshd_config
fi
systemctl restart sshd

beep -l 350 -f 392 -D 100 -n -l 350 -f 392 -D 100 -n -l 350 -f 392 -D 100 -n -l 250 -f 311.1 -D 100 -n -l 25 -f 466.2 -D 100 -n -l 350 -f 392 -D 100 -n -l 250 -f 311.1 -D 100 -n -l 25 -f 466.2 -D 100 -n -l 700 -f 392 -D 100 -n -l 350 -f 587.32 -D 100 -n -l 350 -f 587.32 -D 100 -n -l 350 -f 587.32 -D 100 -n -l 250 -f 622.26 -D 100 -n -l 25 -f 466.2 -D 100 -n -l 350 -f 369.99 -D 100 -n -l 250 -f 311.1 -D 100 -n -l 25 -f 466.2 -D 100 -n -l 700 -f 392 -D 100 -n -l 350 -f 784 -D 100 -n -l 250 -f 392 -D 100 -n -l 25 -f 392 -D 100 -n -l 350 -f 784 -D 100 -n -l 250 -f 739.98 -D 100 -n -l 25 -f 698.46 -D 100 -n -l 25 -f 659.26 -D 100 -n -l 25 -f 622.26 -D 100 -n -l 50 -f 659.26 -D 400 -n -l 25 -f 415.3 -D 200 -n -l 350 -f 554.36 -D 100 -n -l 250 -f 523.25 -D 100 -n -l 25 -f 493.88 -D 100 -n -l 25 -f 466.16 -D 100 -n -l 25 -f 440 -D 100 -n -l 50 -f 466.16 -D 400 -n -l 25 -f 311.13 -D 200 -n -l 350 -f 369.99 -D 100 -n -l 250 -f 311.13 -D 100 -n -l 25 -f 392 -D 100 -n -l 350 -f 466.16 -D 100 -n -l 250 -f 392 -D 100 -n -l 25 -f 466.16 -D 100 -n -l 700 -f 587.32 -D 100 -n -l 350 -f 784 -D 100 -n -l 250 -f 392 -D 100 -n -l 25 -f 392 -D 100 -n -l 350 -f 784 -D 100 -n -l 250 -f 739.98 -D 100 -n -l 25 -f 698.46 -D 100 -n -l 25 -f 659.26 -D 100 -n -l 25 -f 622.26 -D 100 -n -l 50 -f 659.26 -D 400 -n -l 25 -f 415.3 -D 200 -n -l 350 -f 554.36 -D 100 -n -l 250 -f 523.25 -D 100 -n -l 25 -f 493.88 -D 100 -n -l 25 -f 466.16 -D 100 -n -l 25 -f 440 -D 100 -n -l 50 -f 466.16 -D 400 -n -l 25 -f 311.13 -D 200 -n -l 350 -f 392 -D 100 -n -l 250 -f 311.13 -D 100 -n -l 25 -f 466.16 -D 100 -n -l 300 -f 392.00 -D 150 -n -l 250 -f 311.13 -D 100 -n -l 25 -f 466.16 -D 100 -n -l 700 -f 392
echo "Done. You may want to do '. /etc/profile'"
