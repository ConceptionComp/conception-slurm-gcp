#!/bin/bash
set -eo pipefail

ARCH=$(uname -m)
RELEASE=$(lsb_release -rs)

# install google cloud SDK to replace snap version

echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
# ppa:deadsnakes/ppa is added by the Ansible python role (roles/python/tasks/main.yml)

# setup nvidia container tools
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
&& curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

chgrp -Rh 2345 /opt/venv
chmod -R 775 /opt/venv

apt-get update &&  apt-get install -y google-cloud-cli nvidia-container-toolkit

cd /opt/apps

# libssl: arch- and release-conditional
if [ "$ARCH" = "x86_64" ] && [ "$RELEASE" = "20.04" ]; then
  # Legacy libssl1.0.0 — needed by some tools compiled against OpenSSL 1.0
  # Only available as amd64 deb from Ubuntu 16.04/18.04/20.04 archives
  LIBSSL_DEB="libssl1.0.0_1.0.2n-1ubuntu5_amd64.deb"
  wget -q "http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/${LIBSSL_DEB}"
  echo "f7be3a8202bc05b2765c4e2b60716f8d  ${LIBSSL_DEB}" | md5sum -c - || { echo "libssl1.0.0 checksum failed"; exit 1; }
  dpkg -i "${LIBSSL_DEB}" || true
  rm -f "${LIBSSL_DEB}"
fi

if [ "$RELEASE" = "22.04" ] && [ "$ARCH" = "x86_64" ]; then
  # libssl1.1 not in Ubuntu 22.04 repos — install from focal archive as compatibility shim
  # for legacy tools that link against OpenSSL 1.1.x (e.g. sratoolkit pre-built binary)
  wget -q "http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb"
  dpkg -i "libssl1.1_1.1.1f-1ubuntu2_amd64.deb" || true
  rm -f "libssl1.1_1.1.1f-1ubuntu2_amd64.deb"
fi

#CLEANUP
cd /opt/apps
rm -f *.gz
rm -f *.zip

# pip2 bootstrap — only needed on Ubuntu 20.04
# Ubuntu 22.04 gets python2+pip2 via apt in the python Ansible role (Phase 1)
if [ "$RELEASE" = "20.04" ]; then
  curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
  python2 get-pip.py
  rm get-pip.py
fi

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
