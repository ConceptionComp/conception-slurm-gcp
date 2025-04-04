#!/bin/bash
set -eo pipefail

# install google cloud SDK to replace snap version

echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
add-apt-repository -y ppa:deadsnakes/ppa

# setup nvidia container tools
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
&& curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

chgrp -Rh 2345 /opt/venv
chmod -R 775 /opt/venv

apt-get update &&  apt-get install -y google-cloud-cli nvidia-container-toolkit

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

curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
apt-get install -y git-lfs

pip3 install --upgrade requests
pip3 install --upgrade --extra-index-url  https://us-central1-python.pkg.dev/conception-cluster/conception-python-library/simple conception-python-library

mkdir -p /opt/apps/nextflow/latest
mkdir -p /opt/apps/modulefiles/nextflow/
cd /opt/apps/nextflow/latest
curl -s https://get.nextflow.io | bash 
chmod +x nextflow
echo 'prepend_path("PATH", "/opt/apps/nextflow/latest")' > /opt/apps/modulefiles/nextflow/latest.lua

echo "* soft nofile 65535" >> /etc/security/limits.conf
echo "* hard nofile 65535" >> /etc/security/limits.conf
echo "root soft nofile 65535" >> /etc/security/limits.conf
echo "root hard nofile 65535" >> /etc/security/limits.conf
# echo "session required pam_limits.so" >> /etc/pam.d/common-session/