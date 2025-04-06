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

# Install the generated package
PKG=$(find /tmp -name "google-chrome-*.txz" | head -n 1)
if [[ -f "$PKG" ]]; then
  echo "Installing package: $PKG"
  upgradepkg --install-new "$PKG"
else
  echo "Failed to locate the .txz package"
  exit 1
fi

# f. Create symlink and set executable
echo "Linking google-chrome binary..."
ln -sf /usr/bin/google-chrome-stable /usr/bin/google-chrome
chmod +x /usr/bin/google-chrome-stable

# 🆕 Create kiosk user with password 'kiosk' if not exists
if id "kiosk" &>/dev/null; then
  echo "User 'kiosk' already exists."
else
  echo "Creating user 'kiosk'..."
  useradd -m -s /bin/bash kiosk
  echo "kiosk:kiosk" | chpasswd
fi

# 🆕 Prepare kiosk environment
echo "Preparing kiosk environment in /home/kiosk..."

cd /home/kiosk || exit

# Download and unzip JOT85/kiosk window manager
wget https://github.com/JOT85/kiosk-wm/archive/refs/heads/master.zip
unzip master.zip
cd kiosk-wm-master || exit
chmod +x kiosk-wm-run.sh kiosk-wm

# Go back to kiosk's home
cd /home/kiosk || exit

# Modify ~/.xinitrc
XINITRC="/home/kiosk/.xinitrc"

# Ensure file exists
touch "$XINITRC"
cp "$XINITRC" "${XINITRC}.bak"

# Comment out lines from line 28 onwards
echo "Commenting out lines 28 and onward in .xinitrc..."
total_lines=$(wc -l < "$XINITRC")
if [ "$total_lines" -ge 28 ]; then
  sed -i '28,$s/^/#/' "$XINITRC"
fi

# Prompt for incognito mode
read -rp "Do you want Chrome to launch in incognito mode? (y/n): " incognito_choice
[[ "$incognito_choice" == "y" || "$incognito_choice" == "Y" ]] && incognito_flag="--incognito" || incognito_flag=""

# Prompt for window size
read -rp "Enter screen resolution (e.g., 1920,1080) or press Enter to use default (1680,960): " screensize
[[ -z "$screensize" ]] && screensize="1680,960"

# Append custom kiosk setup to .xinitrc
cat << EOF >> "$XINITRC"

# --- Kiosk Custom Startup ---
# Disable screen blanking and power saving
/usr/bin/xset s off
/usr/bin/xset s noblank
/usr/bin/xset -dpms

# Start D-Bus session
eval \$(${DBUS_LAUNCH:-/usr/bin/dbus-launch --sh-syntax --exit-with-session})

# Wait for kiosk window manager
sleep 1
/home/kiosk/kiosk-wm-master/kiosk-wm &

# Launch Google Chrome in kiosk mode
/usr/bin/google-chrome --no-sandbox --window-position=0,0 --window-size=$screensize $incognito_flag --start-maximized &

wait
EOF

chmod +x "$XINITRC"
echo ".xinitrc is ready and executable."

echo "✅ Setup complete. You can now switch to the 'kiosk' user and run startx when ready."
