#!/bin/bash

# a. Must be run as root
if [[ $EUID -ne 0 ]]; then
  echo "Please run this script as root (use sudo or login as root)."
  exit 1
fi

# b. Change to /tmp and create folder
cd /tmp || exit
mkdir -p google-chrome
cd google-chrome || exit

# Download the .deb package
echo "Downloading Google Chrome .deb package..."
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

# c. Download SlackBuild script and required files
echo "Downloading SlackBuild files..."
wget https://mirror.slackbuilds.org/slackware/slackware64-current/extra/google-chrome/google-chrome.SlackBuild
wget https://mirror.slackbuilds.org/slackware/slackware64-current/extra/google-chrome/README
wget https://mirror.slackbuilds.org/slackware/slackware64-current/extra/google-chrome/slack-desc

# d. Run the SlackBuild script
echo "Running SlackBuild script..."
chmod 755 google-chrome.SlackBuild
sh google-chrome.SlackBuild

# Find the generated .txz package (should be in /tmp)
PKG=$(find /tmp -name "google-chrome-*.txz" | head -n 1)
if [[ -f "$PKG" ]]; then
  echo "Installing package: $PKG"
  upgradepkg --install-new "$PKG"
else
  echo "Failed to locate the .txz package"
  exit 1
fi


# f. Link to /usr/bin and make executable
echo "Linking google-chrome binary..."
ln -sf /usr/bin/google-chrome-stable /usr/bin/google-chrome
chmod +x /usr/bin/google-chrome-stable

# Try launching it
echo "Google Chrome Installed"

# Step: Setup Kiosk Environment in /home/kiosk
echo "Preparing kiosk environment..."

mkdir /home kiosk
cd /home/kiosk || exit

# Clone the JOT85/kiosk repo
echo "Downloading kiosk window manager..."
wget https://github.com/JOT85/kiosk-wm/archive/refs/heads/master.zip
unzip master.zip
cd kiosk-wm-master || exit
chmod +x kiosk-wm-run.sh kiosk-wm


