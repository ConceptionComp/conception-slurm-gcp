#!/bin/bash
set -eo pipefail

LATEST_CHROME_RELEASE=$(curl -s https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json | jq '.channels.Stable')
VERSION=$(echo "$LATEST_CHROME_RELEASE" | jq -r '.version')
# CHROME_URL=$(echo "$LATEST_CHROME_RELEASE" | jq -r '.downloads.chrome[] | select(.platform == "linux64"')
CHROME_DRIVER_URL=$(echo "$LATEST_CHROME_RELEASE" | jq -r '.downloads.chromedriver[] | select(.platform == "linux64") | .url')
# Install Chrome Binary
wget --no-verbose -O /var/tmp/chrome.deb https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${VERSION}-1_amd64.deb
apt install -y /var/tmp/chrome.deb
rm /var/tmp/chrome.deb
# Install ChromeDriver

wget -N $CHROME_DRIVER_URL -P ~/
unzip ~/chromedriver-linux64.zip -d ~/
rm ~/chromedriver-linux64.zip
mv -f ~/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver
rm -rf ~/chromedriver-linux64/
chown root:root /usr/local/bin/chromedriver
chmod 0755 /usr/local/bin/chromedriver