#!/bin/bash


sudo apt update
sudo apt install binutils wget php7.4 php7.4-fpm php7.4-mysql nginx build-essential libwrap0-dev libssl-dev -y

git clone https://github.com/aws/efs-utils

cd efs-utils

source build-deb.sh

sudo apt  install -y ./build/amazon-efs-utils*deb



if echo $(python3 -V 2>&1) | grep -e "Python 3.5"; then
    sudo wget https://bootstrap.pypa.io/3.5/get-pip.py -O /tmp/get-pip.py
elif echo $(python3 -V 2>&1) | grep -e "Python 3.4"; then
    sudo wget https://bootstrap.pypa.io/3.4/get-pip.py -O /tmp/get-pip.py
else
    sudo apt-get -y install python3-distutils
    sudo wget https://bootstrap.pypa.io/get-pip.py -O /tmp/get-pip.py
fi


sudo python3 /tmp/get-pip.py

sudo pip3 install botocore

cd ~/
sudo curl -o stunnel-5.63.tar.gz https://www.stunnel.org/downloads/stunnel-5.63.tar.gz

sudo tar xvfz stunnel-5.63.tar.gz
cd stunnel-5.63/

sudo ./configure

sudo make

sudo rm /bin/stunnel

sudo make install


if [[ -f /bin/stunnel ]]; then
sudo mv /bin/stunnel /root
fi

sudo ln -s /usr/local/bin/stunnel /bin/stunnel
