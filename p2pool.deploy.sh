#!/bin/bash
# Author: Chris Har
# Thanks to all who published information on the Internet!
#
# Disclaimer: Your use of this script is at your sole risk.
# This script and its related information are provided "as-is", without any warranty, 
# whether express or implied, of its accuracy, completeness, fitness for a particular 
# purpose, title or non-infringement, and none of the third-party products or information 
# mentioned in the work are authored, recommended, supported or guaranteed by The Author. 
# Further, The Author shall not be liable for any damages you may sustain by using this 
# script, whether direct, indirect, special, incidental or consequential, even if it 
# has been advised of the possibility of such damages. 
#

#
# NOTE:
# This script is based on:
# - Git Commit: 18dc987 => https://github.com/dashpay/p2pool-dash
# - Git Commit: 20bacfa => https://github.com/dashpay/dash
#
# You may have to perform your own validation / modification of the script to cope with newer 
# releases of the above software.
#
# Tested with Ubuntu 17.10
#

#
# Variables
# UPDATE THEM TO MATCH YOUR SETUP !!
#
PUBLIC_IP=46.105.148.127
EMAIL=yrmixpay@gmail.com
PAYOUT_ADDRESS=YkVP9cP5WsdSQApA7V7e3DDNV3iJKU9E7c
USER_NAME=yrmix
RPCUSER=yrmixcoin
RPCPASSWORD=3bdba63cf0ba40a8637zasdvdsv21a95332bc88f

FEE=0.5
DONATION=0.0
YRMIX_WALLET_URL=https://github.com/yrmixpay/yrmixcoin/releases/download/v0.16.3.1/yrmixcoin-0.16.3-linux64.tar.gz
YRMIX_WALLET_ZIP=yrmixcoin-0.16.3-linux64.tar.gz
YRMIX_WALLET_LOCAL=yrmixcoin-0.16.3
P2POOL_FRONTEND=https://github.com/justino/p2pool-ui-punchy
P2POOL_FRONTEND2=https://github.com/johndoe75/p2pool-node-status
P2POOL_FRONTEND3=https://github.com/hardcpp/P2PoolExtendedFrontEnd

#
# Install Prerequisites
#
cd ~
sudo apt-get --yes install python-zope.interface python-twisted python-twisted-web python-dev
sudo apt-get --yes install gcc g++
sudo apt-get --yes install git

#
# Get latest p2pool-YRMIX
#
mkdir git
cd git
git clone https://github.com/yrmixpay/p2pool-yrmixcoin
cd p2pool-yrmixcoin
#git submodule init
#git submodule update
git clone https://github.com/yrmixpay/yrmixcoin_hash
cd yrmixcoin_hash
python setup.py install --user

#
# Install Web Frontends
#
cd ..
mv web-static web-static.old
git clone $P2POOL_FRONTEND web-static
mv web-static.old web-static/legacy
cd web-static
git clone $P2POOL_FRONTEND2 status
git clone $P2POOL_FRONTEND3 ext

#
# Get specific version of Yrmixcoin wallet for Linux
#
cd ~
mkdir yrmixcoin
cd yrmixcoin
wget $YRMIX_WALLET_URL --no-check-certificate
tar -xvzf $YRMIX_WALLET_ZIP
rm $YRMIX_WALLET_ZIP

#
# Copy Yrmixcoin daemon
#
sudo cp ~/yrmixcoin/$YRMIX_WALLET_LOCAL/bin/yrmixcoind /usr/bin/yrmixcoind
sudo cp ~/yrmixcoin/$YRMIX_WALLET_LOCAL/bin/yrmixcoin-cli /usr/bin/yrmixcoin-cli
sudo chown -R $USER_NAME:$USER_NAME /usr/bin/yrmixcoind
sudo chown -R $USER_NAME:$USER_NAME /usr/bin/yrmixcoin-cli

#
# Prepare Yrmixcoin configuration
#
mkdir ~/.yrmixcoin
cat <<EOT >> ~/.yrmixcoin/yrmixcoin.conf
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
alertnotify=echo %s | mail -s "YRMIX Alert" $EMAIL
server=1
daemon=1
EOT

#
# Get latest YRMIX core
#
cd ~/git
git clone https://github.com/yrmixpay/yrmixcoin

#
# Install YRMIX daemon service and set to Auto Start
#
	
sudo ln -s /home/$USER_NAME/git/yrmixcoin/contrib/init/yrmixcoind.service yrmixcoind.service
sudo sed -i 's/User=yrmixcoin/User='"$USER_NAME"'/g' yrmixcoind.service
sudo sed -i 's/Group=yrmixcoin/Group='"$USER_NAME"'/g' yrmixcoind.service
sudo sed -i 's/\/var\/lib\/yrmixcoind/\/home\/'"$USER_NAME"'\/.yrmixcoin/g' yrmixcoind.service
sudo sed -i 's/\/etc\/yrmixcoin\/yrmixcoin.conf/\/home\/'"$USER_NAME"'\/.yrmixcoin\/yrmixcoin.conf/g' yrmixcoind.service
sudo systemctl daemon-reload
sudo systemctl enable yrmixcoind
sudo service yrmixcoind start

#
# Prepare p2pool startup script
#
cat <<EOT >> ~/p2pool.start.sh
python ~/git/p2pool-yrmixcoin/run_p2pool.py --external-ip $PUBLIC_IP -f $FEE --give-author $DONATION -a $PAYOUT_ADDRESS
EOT

if [ $? -eq 0 ]
then
echo
echo Installation Completed.
echo You can start p2pool instance by command:
echo
echo bash ~/p2pool.start.sh
echo
echo NOTE: you will need to wait until YRMIXCOIN daemon has finished
echo blockchain synchronization before the p2pool instance is usable.
echo
fi
