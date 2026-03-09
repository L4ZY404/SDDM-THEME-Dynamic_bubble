#!/bin/bash

# ==============================================================================
# Dynamic Bubble - Pywal Synchronization Engine (Debug Edition)
# By L4ZY404
# ==============================================================================

THEME_NAME="Dynamic_bubble"
THEME_DIR="/usr/share/sddm/themes/$THEME_NAME"
CACHE_DIR="/var/cache/sddm-theme"
WAL_CACHE="$HOME/.cache/wal"

echo " Starting sync for $THEME_NAME..."

# 1. Verify if theme directory is writable
if [ ! -w "$THEME_DIR" ]; then
    echo "❌ ERROR: No write permission for $THEME_DIR"
    echo " Run this command once: sudo chown -R $USER:$USER $THEME_DIR"
    exit 1
fi

# 2. Verify Pywal cache
if [ ! -f "$WAL_CACHE/colors" ]; then
    echo "❌ ERROR: Pywal colors not found at $WAL_CACHE"
    exit 1
fi

# 3. Ensure Cache Directory
mkdir -p "$CACHE_DIR"

# 4. Copy Wallpaper
WALLPAPER_PATH=$(< "$WAL_CACHE/wal")
cp "$WALLPAPER_PATH" "$CACHE_DIR/current_wallpaper.jpg"

# 5. Extract Colors
BG_COLOR="#$(sed -n '1p' "$WAL_CACHE/colors" | tr -d '#')"
COLOR11="#$(sed -n '12p' "$WAL_CACHE/colors" | tr -d '#')"

# 6. Write theme.conf
# We use a temporary file first to ensure atomic write
cat <<EOF > "$THEME_DIR/theme.conf"
[General]
mode=pro
background=$CACHE_DIR/current_wallpaper.jpg
background_color=$BG_COLOR
color11=$COLOR11
username=
EOF

# 7. Refresh SDDM Timestamp
touch "$THEME_DIR/Main.qml"

echo " Sync complete!"
echo " Theme.conf path: $THEME_DIR/theme.conf"
echo " Current Accent (color11): $COLOR11"