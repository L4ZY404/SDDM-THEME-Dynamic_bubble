#!/bin/bash

# ==============================================================================
# Dynamic Bubble
# Author: L4ZY404
# Description: Automates theme deployment, permissions, and cache setup.
# ==============================================================================

THEME_NAME="Dynamic_bubble"
SYS_THEME_DIR="/usr/share/sddm/themes/$THEME_NAME"
CACHE_DIR="/var/cache/sddm-theme"

echo " Starting installation of $THEME_NAME..."

# 1. Check if the theme folder exists in the current directory
if [ ! -d "$THEME_NAME" ]; then
    echo "❌ Error: Directory '$THEME_NAME' not found in the current path."
    echo " Make sure you are running this script from the root of the repo."
    exit 1
fi

# 2. Copy theme to the system directory
echo " Copying theme to $SYS_THEME_DIR..."
sudo cp -r "$THEME_NAME" /usr/share/sddm/themes/

# 3. Take ownership of the theme folder (Crucial for sudo-free sync)
echo " Setting up sudo-free permissions for the theme..."
sudo chown -R $USER:$USER "$SYS_THEME_DIR"

# 4. Setup the global wallpaper cache directory
echo "  Setting up wallpaper cache at $CACHE_DIR..."
if [ ! -d "$CACHE_DIR" ]; then
    sudo mkdir -p "$CACHE_DIR"
fi
sudo chown -R $USER:$USER "$CACHE_DIR"

# 5. Make the sync script executable
if [ -f "sddm_sync.sh" ]; then
    chmod +x sddm_sync.sh
    echo "✅ Sync script is now executable."
fi

# 6. Final Instructions
echo ""
echo "-------------------------------------------------------"
echo " Installation successful!"
echo "-------------------------------------------------------"
echo "Next steps:"
echo "1. Set '$THEME_NAME' as your current theme in /etc/sddm.conf"
echo "1.1. If /etc/sddm.conf does not exist run: sudo cp /usr/lib/sddm/sddm.conf.d/default.conf /etc/sddm.conf.d
echo "2. Run './sddm_sync.sh' to apply your Pywal colors."
echo "3. Log out to see your new creation in action!"
echo "-------------------------------------------------------"
