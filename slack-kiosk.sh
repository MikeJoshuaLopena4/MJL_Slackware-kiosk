#!/bin/bash

set -e

echo "📦 Installing Google Chrome for Slackware..."

# 1. Create working directory
cd /tmp
mkdir -p google-chrome
cd google-chrome

# 2. Download SlackBuild files
echo "📥 Downloading SlackBuild files..."
wget https://mirror.slackbuilds.org/slackware/slackware64-current/extra/google-chrome/google-chrome.SlackBuild
wget https://mirror.slackbuilds.org/slackware/slackware64-current/extra/google-chrome/slack-desc
wget https://mirror.slackbuilds.org/slackware/slackware64-current/extra/google-chrome/README

# 3. Download Google Chrome .deb
echo "📥 Downloading official Google Chrome .deb package..."
wget -O google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

# 4. Make SlackBuild executable
chmod 755 google-chrome.SlackBuild

# 5. Run SlackBuild to generate Slackware package
echo "⚙️  Building Slackware package..."
./google-chrome.SlackBuild

# 6. Install the built .txz package
PACKAGE=$(ls /tmp/google-chrome-*.txz | tail -n 1)
echo "📦 Installing package: $PACKAGE"
upgradepkg --install-new "$PACKAGE"

# 7. Symlink and permissions
echo "🔗 Linking and setting executable permissions..."
ln -sf /usr/bin/google-chrome-stable /usr/bin/google-chrome
chmod +x /usr/bin/google-chrome-stable

# 8. Optional: Launch to test
echo "🚀 Testing Google Chrome..."
google-chrome &

echo "✅ Installation complete! Google Chrome should now be available in your Internet menu or by typing 'google-chrome'."
