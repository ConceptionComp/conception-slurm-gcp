#!/bin/bash
set -eo pipefail

# install google cloud SDK to replace snap version

echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
apt-get update &&  apt-get install -y google-cloud-cli

cd /opt/apps

wget http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5_amd64.deb
apt-get install -y ./libssl1.0.0_1.0.2n-1ubuntu5_amd64.deb 

#CLEANUP
cd /opt/apps
rm -f *.gz
rm -f *.zip

#install pip2
curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
python2 get-pip.py
rm get-pip.py

pip3 install --upgrade requests
pip3 install --upgrade --extra-index-url  https://us-central1-python.pkg.dev/conception-cluster/conception-python-library/simple conception-python-library

echo "* soft nofile 65535" >> /etc/security/limits.conf
echo "* hard nofile 65535" >> /etc/security/limits.conf
echo "root soft nofile 65535" >> /etc/security/limits.conf
echo "root hard nofile 65535" >> /etc/security/limits.conf
echo "session required pam_limits.so" >> /etc/pam.d/common-session