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
mkdir /home/kiosk
cd /home/kiosk || exit

# Clone the JOT85/kiosk repo
echo "Downloading kiosk window manager..."
wget https://github.com/JOT85/kiosk-wm/archive/refs/heads/master.zip
unzip master.zip
cd kiosk-wm-master || exit
chmod +x kiosk-wm-run.sh kiosk-wm.c

echo "Setting up ~/.xinitrc"

XINITRC_PATH="/etc/X11/xinit/xinitrc"

# Backup the original system xinitrc
echo "Backing up original xinitrc to ${XINITRC_PATH}.bak"
cp "$XINITRC_PATH" "${XINITRC_PATH}.bak"

# Comment out lines 28–32 (the default twm, xclock, xterm etc.)
echo "Commenting out lines 28 to 32..."
sed -i '28,32s/^/#/' "$XINITRC_PATH"

# Ask user for Chrome options
read -p "Enable Kiosk mode? (yes/no): " kiosk_mode
read -p "Enter your monitor resolution (e.g., 1920,1080) or press Enter for default 1024x768: " resolution
read -p "Enable Incognito mode? (yes/no): " incognito_mode

# Determine chrome flags
KIOSK_FLAG=""
if [[ "$kiosk_mode" == "yes" ]]; then
  KIOSK_FLAG="--kiosk"
fi

if [[ -n "$resolution" ]]; then
  RESOLUTION_FLAG="--window-size=${resolution}"
else
  RESOLUTION_FLAG="--window-size=1024,768"
fi

INCOGNITO_FLAG=""
if [[ "$incognito_mode" == "yes" ]]; then
  INCOGNITO_FLAG="--incognito"
fi

# Append new kiosk launch section
echo "Appending new Chrome launch section to $XINITRC_PATH..."

cat <<EOF >> "$XINITRC_PATH"

# Disable screen blanking and power saving 
/usr/bin/xset s off
/usr/bin/xset s noblank
/usr/bin/xset -dpms

# Start D-Bus session 
eval \$\(/usr/bin/dbus-launch --sh-syntax --exit-with-session\)

# Wait for the kiosk window manager
sleep 1
/home/kiosk/kiosk-wm-main/kiosk-wm &

# Launch Google Chrome with selected options
/usr/bin/google-chrome $KIOSK_FLAG --no-sandbox $RESOLUTION_FLAG $INCOGNITO_FLAG --start-position=0,0 --start-maximized &

wait
EOF

chmod +x ~/.xinitrc
echo "✅/etc/X11/xinit/xinitrc has been successfully updated!"
echo "Initializing Kiosk Mode Succesfull, (startx)"


