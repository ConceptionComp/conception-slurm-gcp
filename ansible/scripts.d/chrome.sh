#!/bin/bash
set -eo pipefail

if [ "$(uname -m)" != "x86_64" ]; then
  echo "chrome.sh: skipping Chrome/ChromeDriver installation on $(uname -m) — x86_64 only"
  exit 0
fi

# Install Google Chrome stable via apt repo (more reliable than constructing .deb URLs)
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
  > /etc/apt/sources.list.d/google-chrome.list
apt-get update
apt-get install -y google-chrome-stable

# Install matching ChromeDriver from Chrome for Testing
CHROME_DRIVER_URL=$(curl -s https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json | \
  jq -r '.channels.Stable.downloads.chromedriver[] | select(.platform == "linux64") | .url')
wget -N "$CHROME_DRIVER_URL" -P ~/
unzip ~/chromedriver-linux64.zip -d ~/
rm ~/chromedriver-linux64.zip
mv -f ~/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver
rm -rf ~/chromedriver-linux64/
chown root:root /usr/local/bin/chromedriver
chmod 0755 /usr/local/bin/chromedriver