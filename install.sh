#!/usr/bin/env bash
set -Eeuo pipefail

# Dynamic Bubble installer.
# Designed to work both standalone and when invoked by another installer.

THEME_NAME="Dynamic_bubble"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_THEME="$SCRIPT_DIR/$THEME_NAME"
THEME_ROOT="/usr/share/sddm/themes"
THEME_DIR="$THEME_ROOT/$THEME_NAME"
CACHE_DIR="/var/cache/sddm-theme"
SYNC_BIN="/usr/local/bin/dynamic-bubble-sync"
DROPIN_DIR="/etc/sddm.conf.d"
DROPIN_FILE="$DROPIN_DIR/90-dynamic-bubble.conf"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="/var/backups/dynamic-bubble/$TIMESTAMP"

log() {
    printf '[Dynamic Bubble] %s\n' "$*"
}

fail() {
    printf '[Dynamic Bubble] ERROR: %s\n' "$*" >&2
    exit 1
}

[[ "$EUID" -ne 0 ]] || fail "run ./install.sh as your normal user, not with sudo"
command -v sudo >/dev/null 2>&1 || fail "sudo is required"
[[ -d "$SOURCE_THEME" ]] || fail "theme directory not found: $SOURCE_THEME"
[[ -f "$SOURCE_THEME/Main.qml" ]] || fail "Main.qml is missing"

install_arch_dependencies() {
    command -v pacman >/dev/null 2>&1 || return 0

    local missing=()
    pacman -Q sddm >/dev/null 2>&1 || missing+=(sddm)
    pacman -Q qt6-declarative >/dev/null 2>&1 || missing+=(qt6-declarative)

    if ((${#missing[@]} > 0)); then
        log "Installing required Arch packages: ${missing[*]}"
        sudo pacman -S --needed --noconfirm "${missing[@]}"
    fi
}

backup_path() {
    local path="$1"
    [[ -e "$path" || -L "$path" ]] || return 0
    sudo install -d -m 0755 "$BACKUP_ROOT"
    sudo cp -a -- "$path" "$BACKUP_ROOT/"
}

patch_main_sddm_conf() {
    local conf="/etc/sddm.conf"
    [[ -f "$conf" ]] || return 0

    backup_path "$conf"

    local tmp
    tmp="$(mktemp)"
    awk -v theme="$THEME_NAME" '
        BEGIN { in_theme=0; theme_found=0; current_set=0 }
        /^\[Theme\][[:space:]]*$/ {
            if (in_theme && !current_set) print "Current=" theme
            in_theme=1
            theme_found=1
            current_set=0
            print
            next
        }
        /^\[[^]]+\][[:space:]]*$/ {
            if (in_theme && !current_set) {
                print "Current=" theme
                current_set=1
            }
            in_theme=0
        }
        in_theme && /^[[:space:]]*Current[[:space:]]*=/ {
            print "Current=" theme
            current_set=1
            next
        }
        { print }
        END {
            if (in_theme && !current_set) print "Current=" theme
            if (!theme_found) {
                print ""
                print "[Theme]"
                print "Current=" theme
            }
        }
    ' "$conf" > "$tmp"

    sudo install -m 0644 "$tmp" "$conf"
    rm -f "$tmp"
}

configure_display_manager() {
    sudo install -d -m 0755 "$DROPIN_DIR"
    backup_path "$DROPIN_FILE"

    printf '[Theme]\nCurrent=%s\n' "$THEME_NAME" | sudo tee "$DROPIN_FILE" >/dev/null
    patch_main_sddm_conf

    if [[ ! -e /etc/systemd/system/display-manager.service ]]; then
        log "No display manager is enabled; enabling SDDM."
        sudo systemctl enable sddm.service >/dev/null
    elif readlink -f /etc/systemd/system/display-manager.service | grep -q '/sddm.service$'; then
        log "SDDM is already the enabled display manager."
    else
        log "Another display manager is enabled; leaving it unchanged."
    fi
}

install_theme() {
    backup_path "$THEME_DIR"

    local staging
    staging="$(mktemp -d)"
    trap 'rm -rf "$staging"' EXIT

    cp -a -- "$SOURCE_THEME/." "$staging/"
    rm -f "$staging/theme.conf.user"

    sudo install -d -m 0755 "$THEME_ROOT"
    sudo rm -rf -- "$THEME_DIR"
    sudo install -d -m 0755 "$THEME_DIR"
    sudo cp -a -- "$staging/." "$THEME_DIR/"
    sudo chown -R root:root "$THEME_DIR"
    sudo find "$THEME_DIR" -type d -exec chmod 0755 {} +
    sudo find "$THEME_DIR" -type f -exec chmod 0644 {} +

    # Runtime data is intentionally separate from the root-owned theme source.
    sudo install -d -m 0755 -o "$USER" -g "$(id -gn)" "$CACHE_DIR"
    sudo ln -sfn "$CACHE_DIR/theme.conf.user" "$THEME_DIR/theme.conf.user"

    sudo install -m 0755 "$SCRIPT_DIR/sddm_sync.sh" "$SYNC_BIN"
    trap - EXIT
    rm -rf "$staging"
}

install_user_watcher() {
    local user_unit_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
    local wants_dir="$user_unit_dir/default.target.wants"

    install -d -m 0755 "$user_unit_dir" "$wants_dir"
    install -m 0644 "$SCRIPT_DIR/systemd/user/dynamic-bubble-sync.service" "$user_unit_dir/dynamic-bubble-sync.service"
    install -m 0644 "$SCRIPT_DIR/systemd/user/dynamic-bubble-sync.path" "$user_unit_dir/dynamic-bubble-sync.path"
    ln -sfn ../dynamic-bubble-sync.path "$wants_dir/dynamic-bubble-sync.path"

    if systemctl --user daemon-reload >/dev/null 2>&1; then
        systemctl --user start dynamic-bubble-sync.path >/dev/null 2>&1 || true
        log "Installed the Pywal auto-sync watcher."
    else
        log "Installed the Pywal auto-sync watcher; it will activate on the next user session."
    fi
}

initial_sync() {
    if [[ -f "${XDG_CACHE_HOME:-$HOME/.cache}/wal/colors" || -f "${XDG_CACHE_HOME:-$HOME/.cache}/wal/colors.sh" ]]; then
        if "$SYNC_BIN"; then
            return 0
        fi
        log "Pywal cache exists but could not be synchronized; using theme defaults."
    else
        log "Pywal cache not found yet; using theme defaults until dynamic-bubble-sync is run."
    fi

    if [[ ! -f "$CACHE_DIR/theme.conf.user" ]]; then
        cat > /tmp/dynamic-bubble-theme-conf.$$ <<'EOF_FALLBACK'
[General]
mode=standard
EOF_FALLBACK
        install -m 0644 /tmp/dynamic-bubble-theme-conf.$$ "$CACHE_DIR/theme.conf.user"
        rm -f /tmp/dynamic-bubble-theme-conf.$$
    fi
}

install_arch_dependencies
install_theme
configure_display_manager
install_user_watcher
initial_sync

log "Installation complete."
log "Theme: $THEME_DIR"
log "Pywal sync command: dynamic-bubble-sync"
log "The login UI is shown only on SDDM's primary monitor by default."
log "Set primaryOnly=false in theme.conf to show it on every monitor."
